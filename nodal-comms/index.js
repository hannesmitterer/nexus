// Main entry point for Nodal Communication System
// Demonstrates how to start and use the nodal communication infrastructure

const NodalCommunicationServer = require('./grpc-server');
const NodalAPIServer = require('./api-server');
const NexusKafkaProducer = require('./kafka-producer');
const NexusKafkaConsumer = require('./kafka-consumer');

async function startNodalSystem() {
  console.log('=== Starting Nexus Nodal Communication System ===\n');

  // 1. Start gRPC server
  const grpcServer = new NodalCommunicationServer(
    process.env.GRPC_SERVER_PORT || '50051'
  );
  grpcServer.start();
  console.log('✓ gRPC server started\n');

  // 2. Start API server
  const apiServer = new NodalAPIServer(
    process.env.API_SERVER_PORT || 3000
  );
  
  await apiServer.initialize(
    process.env.GRPC_SERVER_ADDRESS || 'localhost:50051'
  );
  apiServer.start();
  console.log('✓ API server started\n');

  // 3. Setup Kafka consumer with handlers
  const kafkaConsumer = new NexusKafkaConsumer();
  await kafkaConsumer.connect();

  // Subscribe to topics with handlers
  await kafkaConsumer.subscribeToNodeStates(async (data, metadata) => {
    console.log('Node state update received:', {
      nodeId: data.nodeId,
      timestamp: data.timestamp
    });
  });

  await kafkaConsumer.subscribeToSyncEvents(async (data, metadata) => {
    console.log('Sync event received:', {
      eventType: data.eventType,
      timestamp: data.timestamp
    });
  });

  await kafkaConsumer.subscribeToLexAmoris(async (data, metadata) => {
    console.log('LexAmoris data received:', {
      messageType: data.messageType,
      source: data.source
    });
  });

  await kafkaConsumer.start();
  console.log('✓ Kafka consumer started and subscribed\n');

  console.log('=== Nodal Communication System Ready ===');
  console.log(`API: http://localhost:${process.env.API_SERVER_PORT || 3000}`);
  console.log(`gRPC: localhost:${process.env.GRPC_SERVER_PORT || 50051}`);
  console.log('\nPress Ctrl+C to shutdown\n');

  // Graceful shutdown
  const shutdown = async () => {
    console.log('\n\nShutting down gracefully...');
    await apiServer.shutdown();
    await kafkaConsumer.disconnect();
    await grpcServer.stop();
    process.exit(0);
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

// Run if executed directly
if (require.main === module) {
  startNodalSystem().catch(error => {
    console.error('Fatal error starting nodal system:', error);
    process.exit(1);
  });
}

module.exports = { startNodalSystem };
