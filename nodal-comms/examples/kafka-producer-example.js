// Example: Publishing Node States via Kafka
// This example demonstrates how to publish node state updates to Kafka

const NexusKafkaProducer = require('../kafka-producer');

async function publishNodeStateExample() {
  const producer = new NexusKafkaProducer();
  
  try {
    // Connect to Kafka
    await producer.connect();
    console.log('Connected to Kafka');

    // Example 1: Publish basic node state
    await producer.publishNodeState('nexus-node-1', {
      status: 'active',
      role: 'primary',
      metrics: {
        cpu_usage: 45.2,
        memory_usage: 62.1,
        disk_usage: 34.5
      },
      last_heartbeat: new Date().toISOString()
    });
    console.log('Published basic node state');

    // Example 2: Publish node state with metadata
    await producer.publishNodeState('nexus-node-2', {
      status: 'active',
      role: 'secondary',
      capabilities: ['processing', 'storage', 'relay']
    });
    console.log('Published node state with capabilities');

    // Example 3: Publish sync event
    await producer.publishSyncEvent('eal_sync_initiated', {
      version: 'v1.2.0',
      source_node: 'nexus-node-1',
      target_nodes: ['nexus-node-2', 'nexus-node-3'],
      timestamp: new Date().toISOString()
    });
    console.log('Published sync event');

    // Example 4: Publish to LexAmoris
    await producer.publishToLexAmoris('data_export', {
      export_type: 'sentiment_analysis',
      data: {
        entries: 150,
        avg_score: 0.78,
        period: '2026-01-01 to 2026-01-13'
      }
    });
    console.log('Published to LexAmoris');

    // Example 5: Publish EAL update
    await producer.publishEALUpdate('v1.2.0', 'QmXYZ123...', {
      description: 'Updated ethical parameters for sentiment analysis',
      author: 'efa-team',
      approved_by: 'ggc-vote-2026-01',
      changes: ['parameter_tuning', 'bias_correction']
    });
    console.log('Published EAL update');

  } catch (error) {
    console.error('Error in example:', error);
  } finally {
    // Cleanup
    await producer.disconnect();
    console.log('Disconnected from Kafka');
  }
}

// Run if executed directly
if (require.main === module) {
  publishNodeStateExample().catch(console.error);
}

module.exports = { publishNodeStateExample };
