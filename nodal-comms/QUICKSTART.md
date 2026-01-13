# Nodal Communication Quick Start Guide

This guide will help you get the Nexus nodal communication system up and running quickly.

## Prerequisites

1. **Node.js** (v14 or higher)
2. **Kafka** (for message streaming)
3. **npm** or **yarn**

## Installation

### Step 1: Install Dependencies

```bash
cd nodal-comms
npm install
```

### Step 2: Configure Environment

Copy the example environment file and adjust settings:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:
```bash
KAFKA_BROKERS=localhost:9092
GRPC_SERVER_PORT=50051
API_SERVER_PORT=3000
NODE_ID=nexus-node-1
```

### Step 3: Start Kafka (if running locally)

Using Docker:
```bash
docker run -d --name kafka \
  -p 9092:9092 \
  -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
  apache/kafka:latest
```

Or use Docker Compose (recommended):
```yaml
version: '3'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      
  kafka:
    image: confluentinc/cp-kafka:latest
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
```

## Starting the System

### Option 1: Start Everything

```bash
npm start
```

This starts:
- gRPC server (port 50051)
- REST API server (port 3000)
- Kafka consumer (listening to all topics)

### Option 2: Start Components Individually

**Start gRPC Server:**
```javascript
const NodalCommunicationServer = require('./grpc-server');
const server = new NodalCommunicationServer('50051');
server.start();
```

**Start API Server:**
```javascript
const NodalAPIServer = require('./api-server');
const apiServer = new NodalAPIServer(3000);
await apiServer.initialize('localhost:50051');
apiServer.start();
```

## Basic Usage

### Publishing a Node State

**Using REST API:**
```bash
curl -X POST http://localhost:3000/api/node-state \
  -H "Content-Type: application/json" \
  -d '{
    "nodeId": "nexus-node-1",
    "state": {
      "status": "active",
      "metrics": { "cpu": 45, "memory": 62 }
    }
  }'
```

**Using Kafka Producer:**
```javascript
const NexusKafkaProducer = require('./kafka-producer');

const producer = new NexusKafkaProducer();
await producer.connect();
await producer.publishNodeState('node-1', { status: 'active' });
```

### Consuming Messages

```javascript
const NexusKafkaConsumer = require('./kafka-consumer');

const consumer = new NexusKafkaConsumer();
await consumer.connect();

await consumer.subscribeToNodeStates(async (data) => {
  console.log('Node state:', data);
});

await consumer.start();
```

### Syncing with LexAmoris

```bash
curl -X POST http://localhost:3000/api/lexamoris/exchange \
  -H "Content-Type: application/json" \
  -d '{
    "messageType": "data_sync",
    "payload": { "entities": ["entity1", "entity2"] }
  }'
```

## Running Examples

We provide several examples to help you get started:

```bash
# Kafka producer example
node examples/kafka-producer-example.js

# Kafka consumer example
node examples/kafka-consumer-example.js

# gRPC client example
node examples/grpc-client-example.js

# REST API example (requires axios: npm install axios)
node examples/api-example.js
```

## Verify Setup

### Check API Health

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "nexus-nodal-api",
  "timestamp": "2026-01-13T...",
  "uptime": 123.45
}
```

### Check gRPC Health

```bash
curl http://localhost:3000/api/grpc/health
```

### View Recent Events

```bash
curl http://localhost:3000/api/events/recent?limit=10
```

## Common Issues

### Kafka Connection Failed

**Problem**: Cannot connect to Kafka
**Solution**: 
- Ensure Kafka is running: `docker ps | grep kafka`
- Check `KAFKA_BROKERS` in `.env`
- Verify network connectivity

### gRPC Server Not Starting

**Problem**: Port already in use
**Solution**: 
- Change `GRPC_SERVER_PORT` in `.env`
- Kill process using port: `lsof -ti:50051 | xargs kill`

### Messages Not Being Received

**Problem**: Consumer not receiving messages
**Solution**:
- Verify topics exist in Kafka
- Check consumer group IDs
- Ensure producer and consumer are connected

## Next Steps

1. **Integrate with K-SYNC**: Connect the nodal system with existing K-SYNC protocol
2. **Add Authentication**: Implement TLS/SSL for production
3. **Monitor Metrics**: Set up dashboards for health monitoring
4. **Scale**: Add more nodes and configure load balancing

## Resources

- [Full Documentation](README.md)
- [API Reference](README.md#api-endpoints)
- [gRPC Services](README.md#grpc-services)
- [Kafka Configuration](kafka-config.js)
- [Examples](examples/)

## Support

For issues or questions:
- Check the [main README](README.md)
- Review [example code](examples/)
- Contact the GGI governance team

---

**Last Updated**: 2026-01-13  
**Version**: 1.0.0
