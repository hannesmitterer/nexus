// Kafka Configuration for Nexus Nodal Communication
// Enables streaming and distributed system interactions

const { Kafka } = require('kafkajs');

// Kafka cluster configuration
const kafkaConfig = {
  clientId: 'nexus-node',
  brokers: process.env.KAFKA_BROKERS ? process.env.KAFKA_BROKERS.split(',') : ['localhost:9092'],
  connectionTimeout: 10000,
  requestTimeout: 30000,
  retry: {
    retries: 5,
    initialRetryTime: 100,
    factor: 2,
    maxRetryTime: 30000
  }
};

// Initialize Kafka client
const kafka = new Kafka(kafkaConfig);

// Topic configurations for nodal communication
const topics = {
  NODE_STATE: 'nexus-node-state',
  SYNC_EVENTS: 'nexus-sync-events',
  LEXAMORIS_EXCHANGE: 'lexamoris-data-exchange',
  EAL_UPDATES: 'eal-updates',
  SENTINEL_EVENTS: 'sentinel-events'
};

// Producer configuration
const producerConfig = {
  allowAutoTopicCreation: true,
  transactionTimeout: 60000
};

// Consumer group configurations
const consumerGroups = {
  NODE_STATE_CONSUMER: 'nexus-node-state-group',
  SYNC_CONSUMER: 'nexus-sync-group',
  LEXAMORIS_CONSUMER: 'lexamoris-exchange-group'
};

module.exports = {
  kafka,
  topics,
  producerConfig,
  consumerGroups,
  kafkaConfig
};
