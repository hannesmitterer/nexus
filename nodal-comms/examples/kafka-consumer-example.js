// Example: Consuming Messages from Kafka
// This example demonstrates how to consume and process messages from Kafka topics

const NexusKafkaConsumer = require('../kafka-consumer');
const { consumerGroups } = require('../kafka-config');

async function consumeMessagesExample() {
  const consumer = new NexusKafkaConsumer(consumerGroups.NODE_STATE_CONSUMER);
  
  try {
    // Connect to Kafka
    await consumer.connect();
    console.log('Connected to Kafka as consumer');

    // Register handler for node state updates
    await consumer.subscribeToNodeStates(async (data, metadata) => {
      console.log('\n=== Node State Update ===');
      console.log('Node ID:', data.nodeId);
      console.log('Status:', data.state.status);
      console.log('Timestamp:', data.timestamp);
      console.log('Partition:', metadata.partition);
      console.log('Offset:', metadata.offset);
      
      // Process the state update
      // Could trigger alerts, update dashboard, etc.
    });

    // Register handler for sync events
    await consumer.subscribeToSyncEvents(async (data, metadata) => {
      console.log('\n=== Sync Event ===');
      console.log('Event Type:', data.eventType);
      console.log('Data:', JSON.stringify(data.data, null, 2));
      console.log('Timestamp:', data.timestamp);
      
      // Process sync event
      // Could trigger synchronization procedures
    });

    // Register handler for LexAmoris messages
    await consumer.subscribeToLexAmoris(async (data, metadata) => {
      console.log('\n=== LexAmoris Message ===');
      console.log('Message Type:', data.messageType);
      console.log('Source:', data.source);
      console.log('Payload:', JSON.stringify(data.payload, null, 2));
      
      // Process LexAmoris data
      // Could update local state, trigger responses
    });

    // Register handler for EAL updates
    await consumer.subscribeToEALUpdates(async (data, metadata) => {
      console.log('\n=== EAL Update ===');
      console.log('Version:', data.version);
      console.log('IPFS CID:', data.cid);
      console.log('Metadata:', JSON.stringify(data.metadata, null, 2));
      
      // Process EAL update
      // Could trigger update procedures on local nodes
    });

    // Start consuming messages
    await consumer.start();
    console.log('\nConsumer started, waiting for messages...');
    console.log('Press Ctrl+C to exit\n');

    // Keep the process running
    process.on('SIGINT', async () => {
      console.log('\nShutting down consumer...');
      await consumer.disconnect();
      process.exit(0);
    });

  } catch (error) {
    console.error('Error in consumer example:', error);
    await consumer.disconnect();
  }
}

// Run if executed directly
if (require.main === module) {
  consumeMessagesExample().catch(console.error);
}

module.exports = { consumeMessagesExample };
