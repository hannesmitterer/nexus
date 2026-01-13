// Kafka Producer for Node State Sharing
// Publishes node states and synchronization data to Kafka topics

const { kafka, topics, producerConfig } = require('./kafka-config');

class NexusKafkaProducer {
  constructor() {
    this.producer = kafka.producer(producerConfig);
    this.isConnected = false;
  }

  async connect() {
    try {
      await this.producer.connect();
      this.isConnected = true;
      console.log('Nexus Kafka Producer: Connected successfully');
    } catch (error) {
      console.error('Nexus Kafka Producer: Connection failed', error);
      throw error;
    }
  }

  async disconnect() {
    if (this.isConnected) {
      await this.producer.disconnect();
      this.isConnected = false;
      console.log('Nexus Kafka Producer: Disconnected');
    }
  }

  async publishNodeState(nodeId, state) {
    if (!this.isConnected) {
      throw new Error('Producer not connected');
    }

    const message = {
      key: nodeId,
      value: JSON.stringify({
        nodeId,
        state,
        timestamp: new Date().toISOString(),
        version: '1.0.0'
      })
    };

    try {
      const result = await this.producer.send({
        topic: topics.NODE_STATE,
        messages: [message]
      });
      console.log(`Node state published for ${nodeId}`, result);
      return result;
    } catch (error) {
      console.error('Failed to publish node state', error);
      throw error;
    }
  }

  async publishSyncEvent(eventType, data) {
    if (!this.isConnected) {
      throw new Error('Producer not connected');
    }

    const message = {
      key: eventType,
      value: JSON.stringify({
        eventType,
        data,
        timestamp: new Date().toISOString()
      })
    };

    try {
      const result = await this.producer.send({
        topic: topics.SYNC_EVENTS,
        messages: [message]
      });
      console.log(`Sync event published: ${eventType}`, result);
      return result;
    } catch (error) {
      console.error('Failed to publish sync event', error);
      throw error;
    }
  }

  async publishToLexAmoris(messageType, payload) {
    if (!this.isConnected) {
      throw new Error('Producer not connected');
    }

    const message = {
      key: messageType,
      value: JSON.stringify({
        messageType,
        payload,
        source: 'nexus',
        timestamp: new Date().toISOString()
      })
    };

    try {
      const result = await this.producer.send({
        topic: topics.LEXAMORIS_EXCHANGE,
        messages: [message]
      });
      console.log(`Message sent to LexAmoris: ${messageType}`, result);
      return result;
    } catch (error) {
      console.error('Failed to publish to LexAmoris', error);
      throw error;
    }
  }

  async publishEALUpdate(version, cid, metadata) {
    if (!this.isConnected) {
      throw new Error('Producer not connected');
    }

    const message = {
      key: version,
      value: JSON.stringify({
        version,
        cid,
        metadata,
        timestamp: new Date().toISOString()
      })
    };

    try {
      const result = await this.producer.send({
        topic: topics.EAL_UPDATES,
        messages: [message]
      });
      console.log(`EAL update published: ${version}`, result);
      return result;
    } catch (error) {
      console.error('Failed to publish EAL update', error);
      throw error;
    }
  }
}

module.exports = NexusKafkaProducer;
