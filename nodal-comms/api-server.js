// REST API Server for Inter-Repository Data Exchange
// Provides HTTP endpoints for real-time communication with LexAmoris and other repos

const express = require('express');
const cors = require('cors');
const NexusKafkaProducer = require('./kafka-producer');
const NexusKafkaConsumer = require('./kafka-consumer');
const NodalCommunicationClient = require('./grpc-client');

class NodalAPIServer {
  constructor(port = 3000) {
    this.app = express();
    this.port = port;
    this.kafkaProducer = new NexusKafkaProducer();
    this.kafkaConsumer = new NexusKafkaConsumer();
    this.grpcClient = null;
    this.recentEvents = [];
    this.maxRecentEvents = 100;
    
    this.setupMiddleware();
    this.setupRoutes();
  }

  setupMiddleware() {
    this.app.use(cors());
    this.app.use(express.json());
    this.app.use(express.urlencoded({ extended: true }));
    
    // Request logging
    this.app.use((req, res, next) => {
      console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
      next();
    });
  }

  setupRoutes() {
    // Health check endpoint
    this.app.get('/health', (req, res) => {
      res.json({
        status: 'healthy',
        service: 'nexus-nodal-api',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
      });
    });

    // Publish node state
    this.app.post('/api/node-state', async (req, res) => {
      try {
        const { nodeId, state } = req.body;
        
        if (!nodeId || !state) {
          return res.status(400).json({ 
            error: 'nodeId and state are required' 
          });
        }

        await this.kafkaProducer.publishNodeState(nodeId, state);
        
        this.addRecentEvent('node_state_published', { nodeId });
        
        res.json({
          success: true,
          message: 'Node state published successfully',
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        console.error('Error publishing node state:', error);
        res.status(500).json({ error: error.message });
      }
    });

    // Publish sync event
    this.app.post('/api/sync-event', async (req, res) => {
      try {
        const { eventType, data } = req.body;
        
        if (!eventType || !data) {
          return res.status(400).json({ 
            error: 'eventType and data are required' 
          });
        }

        await this.kafkaProducer.publishSyncEvent(eventType, data);
        
        this.addRecentEvent('sync_event_published', { eventType });
        
        res.json({
          success: true,
          message: 'Sync event published successfully',
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        console.error('Error publishing sync event:', error);
        res.status(500).json({ error: error.message });
      }
    });

    // LexAmoris data exchange endpoint
    this.app.post('/api/lexamoris/exchange', async (req, res) => {
      try {
        const { messageType, payload } = req.body;
        
        if (!messageType || !payload) {
          return res.status(400).json({ 
            error: 'messageType and payload are required' 
          });
        }

        await this.kafkaProducer.publishToLexAmoris(messageType, payload);
        
        this.addRecentEvent('lexamoris_exchange', { messageType });
        
        res.json({
          success: true,
          message: 'Data sent to LexAmoris successfully',
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        console.error('Error exchanging data with LexAmoris:', error);
        res.status(500).json({ error: error.message });
      }
    });

    // LexAmoris sync via gRPC
    this.app.post('/api/lexamoris/grpc-sync', async (req, res) => {
      try {
        if (!this.grpcClient) {
          return res.status(503).json({ 
            error: 'gRPC client not initialized' 
          });
        }

        const { requestType, dataPayload } = req.body;
        
        const response = await this.grpcClient.syncWithLexAmoris(
          requestType, 
          dataPayload
        );
        
        this.addRecentEvent('lexamoris_grpc_sync', { requestType });
        
        res.json({
          success: true,
          syncId: response.sync_id,
          response: JSON.parse(response.response_data),
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        console.error('Error in gRPC sync with LexAmoris:', error);
        res.status(500).json({ error: error.message });
      }
    });

    // Publish EAL update
    this.app.post('/api/eal-update', async (req, res) => {
      try {
        const { version, cid, metadata } = req.body;
        
        if (!version || !cid) {
          return res.status(400).json({ 
            error: 'version and cid are required' 
          });
        }

        await this.kafkaProducer.publishEALUpdate(version, cid, metadata);
        
        this.addRecentEvent('eal_update_published', { version, cid });
        
        res.json({
          success: true,
          message: 'EAL update published successfully',
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        console.error('Error publishing EAL update:', error);
        res.status(500).json({ error: error.message });
      }
    });

    // Get recent events
    this.app.get('/api/events/recent', (req, res) => {
      const limit = parseInt(req.query.limit) || 50;
      res.json({
        events: this.recentEvents.slice(-limit),
        count: this.recentEvents.length,
        timestamp: new Date().toISOString()
      });
    });

    // gRPC health check endpoint
    this.app.get('/api/grpc/health', async (req, res) => {
      try {
        if (!this.grpcClient) {
          return res.status(503).json({ 
            error: 'gRPC client not initialized' 
          });
        }

        const health = await this.grpcClient.healthCheck();
        
        res.json({
          grpc: health,
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        console.error('Error checking gRPC health:', error);
        res.status(500).json({ error: error.message });
      }
    });

    // Stream SSE endpoint for real-time updates
    this.app.get('/api/stream/events', (req, res) => {
      res.setHeader('Content-Type', 'text/event-stream');
      res.setHeader('Cache-Control', 'no-cache');
      res.setHeader('Connection', 'keep-alive');

      const sendEvent = (data) => {
        res.write(`data: ${JSON.stringify(data)}\n\n`);
      };

      // Send initial connection event
      sendEvent({ type: 'connected', timestamp: new Date().toISOString() });

      // Send periodic heartbeat
      const heartbeat = setInterval(() => {
        sendEvent({ type: 'heartbeat', timestamp: new Date().toISOString() });
      }, 30000);

      req.on('close', () => {
        clearInterval(heartbeat);
        console.log('SSE client disconnected');
      });
    });
  }

  addRecentEvent(type, data) {
    this.recentEvents.push({
      type,
      data,
      timestamp: new Date().toISOString()
    });

    // Keep only recent events
    if (this.recentEvents.length > this.maxRecentEvents) {
      this.recentEvents.shift();
    }
  }

  async initialize(grpcServerAddress = null) {
    try {
      // Connect Kafka producer
      await this.kafkaProducer.connect();
      console.log('Kafka producer connected');

      // Initialize gRPC client if server address provided
      if (grpcServerAddress) {
        this.grpcClient = new NodalCommunicationClient(grpcServerAddress);
        console.log(`gRPC client initialized for ${grpcServerAddress}`);
      }

      return true;
    } catch (error) {
      console.error('Initialization error:', error);
      throw error;
    }
  }

  start() {
    this.app.listen(this.port, () => {
      console.log(`Nodal API Server running on port ${this.port}`);
      console.log(`Health check: http://localhost:${this.port}/health`);
    });
  }

  async shutdown() {
    console.log('Shutting down Nodal API Server...');
    
    if (this.kafkaProducer) {
      await this.kafkaProducer.disconnect();
    }
    
    if (this.kafkaConsumer) {
      await this.kafkaConsumer.disconnect();
    }
    
    if (this.grpcClient) {
      this.grpcClient.close();
    }
    
    console.log('Shutdown complete');
  }
}

module.exports = NodalAPIServer;
