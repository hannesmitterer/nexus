# Nodal Communication Protocols

## Overview

This module implements nodal communication protocols for the Nexus repository, enabling streaming and distributed system interactions. It uses **Kafka** for message streaming and **gRPC** for RPC-based communication, facilitating real-time data exchange with LexAmoris and other repositories.

## Architecture

### Components

1. **Kafka Infrastructure**
   - Producer: Publishes node states and synchronization events
   - Consumer: Subscribes to topics and processes messages
   - Topics: Organized channels for different message types

2. **gRPC Services**
   - Server: Handles incoming RPC calls from other nodes
   - Client: Sends requests to remote nodes
   - Protocol Buffers: Defines message schemas

3. **REST API**
   - HTTP endpoints for easy integration
   - Real-time Server-Sent Events (SSE)
   - LexAmoris integration endpoints

### Communication Flow

```
┌─────────────┐       Kafka Topics        ┌─────────────┐
│   Node A    │ ────────────────────────> │   Node B    │
│             │                            │             │
│  Producer   │                            │  Consumer   │
└─────────────┘                            └─────────────┘
      │                                           │
      │         gRPC Service Calls                │
      └───────────────────────────────────────────┘
                        │
                        ▼
              ┌──────────────────┐
              │  LexAmoris Repo  │
              │   Integration    │
              └──────────────────┘
```

## Topics

### Kafka Topics

- **nexus-node-state**: Node state updates and health information
- **nexus-sync-events**: Synchronization events between nodes
- **lexamoris-data-exchange**: Data exchange with LexAmoris repository
- **eal-updates**: Ethical Adaptation Layer update notifications
- **sentinel-events**: Sentinel AI Node events

## Installation

### Prerequisites

- Node.js 14.x or higher
- Kafka cluster (local or remote)
- gRPC support

### Setup

1. **Install dependencies**:
   ```bash
   cd nodal-comms
   npm install
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start Kafka** (if running locally):
   ```bash
   # Using Docker
   docker-compose up -d kafka zookeeper
   ```

## Usage

### Starting the Nodal System

```bash
# From nodal-comms directory
npm start
```

This starts:
- gRPC server on port 50051
- REST API server on port 3000
- Kafka consumer subscribed to all topics

### Publishing Node State

**Via REST API**:
```bash
curl -X POST http://localhost:3000/api/node-state \
  -H "Content-Type: application/json" \
  -d '{
    "nodeId": "nexus-node-1",
    "state": {
      "status": "active",
      "metrics": {
        "cpu": 45.2,
        "memory": 62.1
      }
    }
  }'
```

**Via Kafka Producer**:
```javascript
const NexusKafkaProducer = require('./kafka-producer');

const producer = new NexusKafkaProducer();
await producer.connect();

await producer.publishNodeState('nexus-node-1', {
  status: 'active',
  metrics: { cpu: 45.2, memory: 62.1 }
});
```

### Consuming Messages

```javascript
const NexusKafkaConsumer = require('./kafka-consumer');

const consumer = new NexusKafkaConsumer();
await consumer.connect();

// Register handler
await consumer.subscribeToNodeStates(async (data, metadata) => {
  console.log('Node state:', data);
});

// Start consuming
await consumer.start();
```

### gRPC Communication

**Client Example**:
```javascript
const NodalCommunicationClient = require('./grpc-client');

const client = new NodalCommunicationClient('localhost:50051');

// Share node state
const response = await client.shareNodeState('node-1', {
  status: 'operational'
});

// Stream node states
const stream = client.streamNodeStates('node-1', [], (update) => {
  console.log('State update:', update);
});
```

### LexAmoris Integration

**Send data to LexAmoris**:
```bash
curl -X POST http://localhost:3000/api/lexamoris/exchange \
  -H "Content-Type: application/json" \
  -d '{
    "messageType": "sync_request",
    "payload": {
      "data": "example data",
      "timestamp": "2026-01-13T00:00:00Z"
    }
  }'
```

**gRPC sync with LexAmoris**:
```bash
curl -X POST http://localhost:3000/api/lexamoris/grpc-sync \
  -H "Content-Type: application/json" \
  -d '{
    "requestType": "data_sync",
    "dataPayload": {
      "entities": ["entity1", "entity2"]
    }
  }'
```

## API Endpoints

### Health Check
```
GET /health
```

### Node State
```
POST /api/node-state
Body: { nodeId: string, state: object }
```

### Sync Event
```
POST /api/sync-event
Body: { eventType: string, data: object }
```

### LexAmoris Exchange
```
POST /api/lexamoris/exchange
Body: { messageType: string, payload: object }
```

### LexAmoris gRPC Sync
```
POST /api/lexamoris/grpc-sync
Body: { requestType: string, dataPayload: object }
```

### EAL Update
```
POST /api/eal-update
Body: { version: string, cid: string, metadata: object }
```

### Recent Events
```
GET /api/events/recent?limit=50
```

### Event Stream (SSE)
```
GET /api/stream/events
```

### gRPC Health
```
GET /api/grpc/health
```

## gRPC Services

### Service Definition

See `proto/nodal-communication.proto` for complete service definitions.

**Main Services**:
- `ShareNodeState`: Share node state with network
- `StreamNodeStates`: Real-time streaming of node states
- `SyncWithLexAmoris`: Synchronize data with LexAmoris
- `ExchangeData`: Bidirectional data streaming
- `BroadcastEALUpdate`: Broadcast EAL updates to nodes
- `HealthCheck`: Node health verification

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| KAFKA_BROKERS | Kafka broker addresses | localhost:9092 |
| KAFKA_CLIENT_ID | Kafka client identifier | nexus-node |
| GRPC_SERVER_PORT | gRPC server port | 50051 |
| GRPC_SERVER_ADDRESS | gRPC server address | localhost:50051 |
| API_SERVER_PORT | REST API server port | 3000 |
| NODE_ID | Unique node identifier | nexus-primary-node |

## Integration with Existing Systems

### K-SYNC Protocol

The nodal communication system integrates with the existing K-SYNC protocol for EAL updates:

```javascript
// Publish EAL update via Kafka
await producer.publishEALUpdate('v1.2.0', 'QmNewCID...', {
  description: 'Updated ethical parameters',
  author: 'efa-team'
});

// Broadcast via gRPC
await client.broadcastEALUpdate('v1.2.0', 'QmNewCID...', 
  'Updated ethical parameters');
```

### Firebase Integration

Works alongside existing Firebase configuration for additional real-time capabilities.

## Security Considerations

1. **Authentication**: Currently using insecure credentials for development
2. **TLS**: Enable TLS in production by setting environment variables
3. **Message Validation**: All messages are validated before processing
4. **Rate Limiting**: Consider implementing rate limits for API endpoints

## Monitoring

### Health Checks

Monitor system health:
```bash
# API health
curl http://localhost:3000/health

# gRPC health
curl http://localhost:3000/api/grpc/health
```

### Recent Events

View recent communication events:
```bash
curl http://localhost:3000/api/events/recent?limit=20
```

## Troubleshooting

### Kafka Connection Issues

1. Verify Kafka is running: `docker ps | grep kafka`
2. Check broker addresses in `.env`
3. Review logs for connection errors

### gRPC Connection Failures

1. Verify gRPC server is running on correct port
2. Check firewall settings
3. Ensure proto files are properly loaded

### Message Not Received

1. Check topic subscriptions
2. Verify consumer group IDs
3. Review Kafka consumer logs

## Example Workflow

Complete workflow for node synchronization:

```javascript
// 1. Start the system
const { startNodalSystem } = require('./index');
await startNodalSystem();

// 2. Publish node state
const producer = new NexusKafkaProducer();
await producer.connect();
await producer.publishNodeState('node-1', { status: 'active' });

// 3. Sync with LexAmoris
await producer.publishToLexAmoris('sync_data', {
  entities: ['entity1', 'entity2']
});

// 4. Broadcast EAL update
await producer.publishEALUpdate('v1.0.0', 'QmCID...', {
  description: 'Initial version'
});
```

## Future Enhancements

- [ ] TLS/SSL encryption for production
- [ ] Authentication and authorization
- [ ] Message compression for large payloads
- [ ] Distributed tracing integration
- [ ] Metrics and monitoring dashboards
- [ ] Schema registry for message validation

## License

Part of the Nexus/Euystacio framework - see repository license.

## Support

For issues or questions, refer to the main Nexus repository documentation or contact the GGI governance team.
