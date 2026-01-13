// Kafka Consumer for Node State Synchronization
// Subscribes to Kafka topics and processes incoming messages

const { kafka, topics, consumerGroups } = require('./kafka-config');

class NexusKafkaConsumer {
  constructor(groupId = consumerGroups.NODE_STATE_CONSUMER) {
    this.consumer = kafka.consumer({ 
      groupId,
      sessionTimeout: 30000,
      heartbeatInterval: 3000
    });
    this.isConnected = false;
    this.handlers = new Map();
    this.subscribedTopics = new Set();
  }

  async connect() {
    try {
      await this.consumer.connect();
      this.isConnected = true;
      console.log('Nexus Kafka Consumer: Connected successfully');
    } catch (error) {
      console.error('Nexus Kafka Consumer: Connection failed', error);
      throw error;
    }
  }

  async disconnect() {
    if (this.isConnected) {
      await this.consumer.disconnect();
      this.isConnected = false;
      console.log('Nexus Kafka Consumer: Disconnected');
    }
  }

  registerHandler(topic, handler) {
    this.handlers.set(topic, handler);
  }

  async subscribe(topicsList) {
    if (!this.isConnected) {
      throw new Error('Consumer not connected');
    }

    for (const topic of topicsList) {
      if (!this.subscribedTopics.has(topic)) {
        await this.consumer.subscribe({ topic, fromBeginning: false });
        this.subscribedTopics.add(topic);
        console.log(`Subscribed to topic: ${topic}`);
      }
    }
  }

  async start() {
    if (!this.isConnected) {
      throw new Error('Consumer not connected');
    }

    await this.consumer.run({
      eachMessage: async ({ topic, partition, message }) => {
        try {
          const value = message.value ? message.value.toString() : null;
          const key = message.key ? message.key.toString() : null;
          
          console.log(`Received message from ${topic}:`, {
            partition,
            offset: message.offset,
            key
          });

          if (value) {
            const data = JSON.parse(value);
            const handler = this.handlers.get(topic);
            
            if (handler) {
              await handler(data, { topic, partition, offset: message.offset, key });
            } else {
              console.warn(`No handler registered for topic: ${topic}`);
            }
          }
        } catch (error) {
          console.error('Error processing message', error);
        }
      }
    });
  }

  async subscribeToNodeStates(handler) {
    this.registerHandler(topics.NODE_STATE, handler);
    await this.subscribe([topics.NODE_STATE]);
  }

  async subscribeToSyncEvents(handler) {
    this.registerHandler(topics.SYNC_EVENTS, handler);
    await this.subscribe([topics.SYNC_EVENTS]);
  }

  async subscribeToLexAmoris(handler) {
    this.registerHandler(topics.LEXAMORIS_EXCHANGE, handler);
    await this.subscribe([topics.LEXAMORIS_EXCHANGE]);
  }

  async subscribeToEALUpdates(handler) {
    this.registerHandler(topics.EAL_UPDATES, handler);
    await this.subscribe([topics.EAL_UPDATES]);
  }
}

module.exports = NexusKafkaConsumer;
