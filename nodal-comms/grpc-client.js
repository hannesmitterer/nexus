// gRPC Client for Nodal Communication
// Connects to other nodes and external repositories

const grpc = require('@grpc/grpc-js');
const protoLoader = require('@grpc/proto-loader');
const path = require('path');

// Load proto definition
const PROTO_PATH = path.join(__dirname, 'proto', 'nodal-communication.proto');
const packageDefinition = protoLoader.loadSync(PROTO_PATH, {
  keepCase: true,
  longs: String,
  enums: String,
  defaults: true,
  oneofs: true
});

const nodalProto = grpc.loadPackageDefinition(packageDefinition).nexus.nodal;

class NodalCommunicationClient {
  constructor(serverAddress = 'localhost:50051') {
    this.client = new nodalProto.NodalCommunication(
      serverAddress,
      grpc.credentials.createInsecure()
    );
    this.serverAddress = serverAddress;
  }

  // Share node state with the server
  async shareNodeState(nodeId, stateData, metadata = {}) {
    return new Promise((resolve, reject) => {
      this.client.ShareNodeState(
        {
          node_id: nodeId,
          state_data: JSON.stringify(stateData),
          timestamp: Date.now(),
          metadata
        },
        (error, response) => {
          if (error) {
            reject(error);
          } else {
            resolve(response);
          }
        }
      );
    });
  }

  // Stream node states from the server
  streamNodeStates(nodeId, filterTags = [], onUpdate) {
    const call = this.client.StreamNodeStates({
      node_id: nodeId,
      filter_tags: filterTags,
      batch_size: 100
    });

    call.on('data', (update) => {
      if (onUpdate) {
        onUpdate(update);
      }
    });

    call.on('error', (error) => {
      console.error('Stream error:', error);
    });

    call.on('end', () => {
      console.log('Stream ended');
    });

    return call;
  }

  // Sync data with LexAmoris
  async syncWithLexAmoris(requestType, dataPayload, sourceRepo = 'nexus') {
    return new Promise((resolve, reject) => {
      this.client.SyncWithLexAmoris(
        {
          request_type: requestType,
          data_payload: JSON.stringify(dataPayload),
          source_repo: sourceRepo,
          timestamp: Date.now()
        },
        (error, response) => {
          if (error) {
            reject(error);
          } else {
            resolve(response);
          }
        }
      );
    });
  }

  // Bidirectional data exchange
  exchangeData(onReceive) {
    const call = this.client.ExchangeData();

    call.on('data', (dataPacket) => {
      if (onReceive) {
        onReceive(dataPacket);
      }
    });

    call.on('error', (error) => {
      console.error('Exchange error:', error);
    });

    call.on('end', () => {
      console.log('Exchange ended');
    });

    return {
      send: (packetId, dataType, payload, headers = {}) => {
        call.write({
          packet_id: packetId,
          data_type: dataType,
          payload: Buffer.from(JSON.stringify(payload)),
          timestamp: Date.now(),
          headers
        });
      },
      end: () => call.end()
    };
  }

  // Broadcast EAL update to all nodes
  async broadcastEALUpdate(version, ipfsCid, description) {
    return new Promise((resolve, reject) => {
      this.client.BroadcastEALUpdate(
        {
          version,
          ipfs_cid: ipfsCid,
          update_description: description,
          timestamp: Date.now()
        },
        (error, response) => {
          if (error) {
            reject(error);
          } else {
            resolve(response);
          }
        }
      );
    });
  }

  // Health check
  async healthCheck(nodeId = 'client') {
    return new Promise((resolve, reject) => {
      this.client.HealthCheck(
        { node_id: nodeId },
        (error, response) => {
          if (error) {
            reject(error);
          } else {
            resolve(response);
          }
        }
      );
    });
  }

  // Close the client connection
  close() {
    this.client.close();
    console.log(`gRPC client disconnected from ${this.serverAddress}`);
  }
}

module.exports = NodalCommunicationClient;
