// gRPC Server Implementation for Nodal Communication
// Handles incoming RPC calls and state synchronization

const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const path = require('path');

// Load proto definition
const PROTO_PATH = path.join(__dirname, 'proto', 'nodal-communication.proto');
const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true
});

const nodalProto = grpc.loadPackageDefinition(packageDefinition).nexus.nodal;

class NodalCommunicationServer {
  constructor(port = '50051') {
    this.server = new grpc.Server();
    this.port = port;
    this.nodeStates = new Map();
    this.streamSubscribers = new Set();
    this.startTime = Date.now();
  }

  // Share node state handler
  shareNodeState(call, callback) {
    const { node_id, state_data, timestamp, metadata } = call.request;
    
    console.log(`Received node state from ${node_id}`);
    
    // Store node state
    this.nodeStates.set(node_id, {
      state_data,
      timestamp,
      metadata,
      updated_at: Date.now()
    });

    // Notify streaming subscribers
    this.notifySubscribers({
      node_id,
      state_type: 'update',
      state_data,
      timestamp,
      sequence_number: this.nodeStates.size
    });

    callback(null, {
      success: true,
      message: 'Node state received successfully',
      processed_at: Date.now()
    });
  }

  // Stream node states handler
  streamNodeStates(call) {
    const { node_id, filter_tags, batch_size } = call.request;
    
    console.log(`Stream initiated for ${node_id}`);
    
    this.streamSubscribers.add(call);

    // Send existing states
    let sequence = 0;
    for (const [nodeId, state] of this.nodeStates.entries()) {
      call.write({
        node_id: nodeId,
        state_type: 'initial',
        state_data: state.state_data,
        timestamp: state.timestamp,
        sequence_number: sequence++
      });
    }

    // Handle client disconnect
    call.on('cancelled', () => {
      console.log(`Stream cancelled for ${node_id}`);
      this.streamSubscribers.delete(call);
    });
  }

  // Sync with LexAmoris handler
  syncWithLexAmoris(call, callback) {
    const { request_type, data_payload, source_repo, timestamp } = call.request;
    
    console.log(`LexAmoris sync request: ${request_type} from ${source_repo}`);

    // Process sync request
    const syncId = `sync-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    
    callback(null, {
      success: true,
      response_data: JSON.stringify({ status: 'processed', request_type }),
      sync_id: syncId,
      synced_at: Date.now()
    });
  }

  // Bidirectional data exchange handler
  exchangeData(call) {
    console.log('Bidirectional data exchange initiated');

    call.on('data', (dataPacket) => {
      console.log(`Received data packet: ${dataPacket.packet_id}`);
      
      // Echo back with processing confirmation
      call.write({
        packet_id: `response-${dataPacket.packet_id}`,
        data_type: 'acknowledgement',
        payload: Buffer.from(JSON.stringify({ 
          original_id: dataPacket.packet_id,
          status: 'processed' 
        })),
        timestamp: Date.now(),
        headers: { processed_by: 'nexus-node' }
      });
    });

    call.on('end', () => {
      console.log('Data exchange stream ended');
      call.end();
    });
  }

  // Broadcast EAL update handler
  broadcastEALUpdate(call, callback) {
    const { version, ipfs_cid, update_description, timestamp } = call.request;
    
    console.log(`Broadcasting EAL update ${version} (CID: ${ipfs_cid})`);

    const notifiedNodes = Array.from(this.nodeStates.keys());

    // Notify all streaming subscribers about the update
    this.notifySubscribers({
      node_id: 'system',
      state_type: 'eal_update',
      state_data: JSON.stringify({ version, ipfs_cid, update_description }),
      timestamp,
      sequence_number: 0
    });

    callback(null, {
      acknowledged: true,
      nodes_notified: notifiedNodes.length,
      node_ids: notifiedNodes
    });
  }

  // Health check handler
  healthCheck(call, callback) {
    const uptime = Math.floor((Date.now() - this.startTime) / 1000);
    
    callback(null, {
      healthy: true,
      status: 'operational',
      uptime_seconds: uptime,
      metrics: {
        node_count: String(this.nodeStates.size),
        stream_subscribers: String(this.streamSubscribers.size),
        uptime: String(uptime)
      }
    });
  }

  // Notify all streaming subscribers
  notifySubscribers(update) {
    for (const subscriber of this.streamSubscribers) {
      try {
        subscriber.write(update);
      } catch (error) {
        console.error('Error notifying subscriber:', error);
        this.streamSubscribers.delete(subscriber);
      }
    }
  }

  // Start the server
  start() {
    this.server.addService(nodalProto.NodalCommunication.service, {
      ShareNodeState: this.shareNodeState.bind(this),
      StreamNodeStates: this.streamNodeStates.bind(this),
      SyncWithLexAmoris: this.syncWithLexAmoris.bind(this),
      ExchangeData: this.exchangeData.bind(this),
      BroadcastEALUpdate: this.broadcastEALUpdate.bind(this),
      HealthCheck: this.healthCheck.bind(this)
    });

    const address = `0.0.0.0:${this.port}`;
    this.server.bindAsync(
      address,
      grpc.ServerCredentials.createInsecure(),
      (error, port) => {
        if (error) {
          console.error('Failed to start gRPC server:', error);
          return;
        }
        console.log(`Nexus gRPC server running on ${address}`);
        this.server.start();
      }
    );
  }

  // Stop the server
  stop() {
    return new Promise((resolve) => {
      this.server.tryShutdown(() => {
        console.log('gRPC server stopped');
        resolve();
      });
    });
  }
}

module.exports = NodalCommunicationServer;
