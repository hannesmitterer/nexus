// Example: gRPC Client Usage
// This example demonstrates how to use the gRPC client for inter-node communication

const NodalCommunicationClient = require('../grpc-client');

async function grpcClientExample() {
  const client = new NodalCommunicationClient('localhost:50051');
  
  try {
    console.log('=== gRPC Client Examples ===\n');

    // Example 1: Share node state
    console.log('1. Sharing node state...');
    const stateResponse = await client.shareNodeState('nexus-client-node', {
      status: 'active',
      version: '1.0.0',
      capabilities: ['processing', 'storage']
    }, {
      region: 'eu-central',
      environment: 'production'
    });
    console.log('Response:', stateResponse);

    // Example 2: Health check
    console.log('\n2. Performing health check...');
    const health = await client.healthCheck('nexus-client-node');
    console.log('Health:', health);
    console.log(`Server uptime: ${health.uptime_seconds} seconds`);

    // Example 3: Sync with LexAmoris
    console.log('\n3. Syncing with LexAmoris...');
    const syncResponse = await client.syncWithLexAmoris('sentiment_sync', {
      entities: ['entity1', 'entity2', 'entity3'],
      timestamp: new Date().toISOString()
    });
    console.log('Sync ID:', syncResponse.sync_id);
    console.log('Response:', JSON.parse(syncResponse.response_data));

    // Example 4: Broadcast EAL update
    console.log('\n4. Broadcasting EAL update...');
    const ealResponse = await client.broadcastEALUpdate(
      'v1.3.0',
      'QmNewEALCID123456',
      'Updated sentiment analysis parameters'
    );
    console.log('Nodes notified:', ealResponse.nodes_notified);
    console.log('Node IDs:', ealResponse.node_ids);

    // Example 5: Stream node states
    console.log('\n5. Streaming node states (will run for 10 seconds)...');
    const stream = client.streamNodeStates('nexus-client-node', [], (update) => {
      console.log(`  Stream update from ${update.node_id}: ${update.state_type}`);
    });

    // Let stream run for 10 seconds
    await new Promise(resolve => setTimeout(resolve, 10000));
    stream.cancel();
    console.log('Stream cancelled');

    // Example 6: Bidirectional data exchange
    console.log('\n6. Bidirectional data exchange...');
    const exchange = client.exchangeData((packet) => {
      console.log(`  Received: ${packet.data_type} (ID: ${packet.packet_id})`);
    });

    // Send some data
    exchange.send('packet-1', 'test_data', { message: 'Hello from client' });
    exchange.send('packet-2', 'test_data', { message: 'Second message' });

    // Wait for responses
    await new Promise(resolve => setTimeout(resolve, 2000));
    exchange.end();

  } catch (error) {
    console.error('Error in gRPC client example:', error);
  } finally {
    // Cleanup
    client.close();
    console.log('\ngRPC client closed');
  }
}

// Run if executed directly
if (require.main === module) {
  grpcClientExample().catch(console.error);
}

module.exports = { grpcClientExample };
