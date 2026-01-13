// Example: Using the REST API
// This example demonstrates how to interact with the nodal communication REST API

const axios = require('axios');

const API_BASE_URL = 'http://localhost:3000';

async function apiExamples() {
  try {
    console.log('=== REST API Examples ===\n');

    // Example 1: Health check
    console.log('1. Health check...');
    const health = await axios.get(`${API_BASE_URL}/health`);
    console.log('Status:', health.data.status);
    console.log('Uptime:', health.data.uptime, 'seconds\n');

    // Example 2: Publish node state
    console.log('2. Publishing node state...');
    const nodeState = await axios.post(`${API_BASE_URL}/api/node-state`, {
      nodeId: 'api-example-node',
      state: {
        status: 'active',
        metrics: {
          cpu: 42.5,
          memory: 65.3,
          network_latency: 15
        }
      }
    });
    console.log('Result:', nodeState.data.message, '\n');

    // Example 3: Publish sync event
    console.log('3. Publishing sync event...');
    const syncEvent = await axios.post(`${API_BASE_URL}/api/sync-event`, {
      eventType: 'manual_sync',
      data: {
        source: 'api-client',
        action: 'full_sync',
        timestamp: new Date().toISOString()
      }
    });
    console.log('Result:', syncEvent.data.message, '\n');

    // Example 4: Exchange data with LexAmoris
    console.log('4. Exchanging data with LexAmoris...');
    const lexamoris = await axios.post(`${API_BASE_URL}/api/lexamoris/exchange`, {
      messageType: 'sentiment_export',
      payload: {
        analysis_results: {
          positive: 78,
          neutral: 15,
          negative: 7
        },
        date_range: '2026-01-01 to 2026-01-13'
      }
    });
    console.log('Result:', lexamoris.data.message, '\n');

    // Example 5: Publish EAL update
    console.log('5. Publishing EAL update...');
    const ealUpdate = await axios.post(`${API_BASE_URL}/api/eal-update`, {
      version: 'v1.4.0',
      cid: 'QmExampleCID789',
      metadata: {
        description: 'Performance optimization',
        approved_by: 'ggc-vote-2026-01-13'
      }
    });
    console.log('Result:', ealUpdate.data.message, '\n');

    // Example 6: Get recent events
    console.log('6. Retrieving recent events...');
    const events = await axios.get(`${API_BASE_URL}/api/events/recent?limit=10`);
    console.log('Recent events:', events.data.count);
    events.data.events.slice(0, 3).forEach(event => {
      console.log(`  - ${event.type} at ${event.timestamp}`);
    });
    console.log('\n');

    // Example 7: gRPC health check via API
    console.log('7. Checking gRPC health via API...');
    try {
      const grpcHealth = await axios.get(`${API_BASE_URL}/api/grpc/health`);
      console.log('gRPC Status:', grpcHealth.data.grpc.status);
      console.log('gRPC Uptime:', grpcHealth.data.grpc.uptime_seconds, 'seconds\n');
    } catch (error) {
      console.log('gRPC may not be running\n');
    }

    console.log('=== Examples completed successfully ===');

  } catch (error) {
    if (error.response) {
      console.error('API Error:', error.response.status, error.response.data);
    } else if (error.request) {
      console.error('No response from API. Is the server running?');
      console.error('Start it with: npm start');
    } else {
      console.error('Error:', error.message);
    }
  }
}

// Run if executed directly
if (require.main === module) {
  apiExamples().catch(console.error);
}

module.exports = { apiExamples };
