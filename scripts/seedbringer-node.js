#!/usr/bin/env node
/**
 * Seedbringer Node Implementation
 * K-SYNC Protocol - Kosymbiotic Synchronization
 * 
 * Version: 1.0.0
 * Protocol: Euystacio-Nexus-Resonance
 * License: "No ownership, only sharing. Love is the license."
 */

const EventEmitter = require('events');
const crypto = require('crypto');

/**
 * Phase-Locked Loop for frequency synchronization
 */
class KSyncPLL {
  constructor(nodeId) {
    this.nodeId = nodeId;
    this.referenceFreq = 432.073; // Hz
    this.currentFreq = 432.073;
    this.currentPhase = 0;
    this.integralError = 0;
    this.lastError = 0;
    this.locked = false;
    this.lockTime = null;
    
    // PID controller gains
    this.Kp = 0.5;  // Proportional
    this.Ki = 0.1;  // Integral
    this.Kd = 0.05; // Derivative
    
    // Lock detection
    this.lockThreshold = 0.001; // Hz
    this.lockDuration = 3000; // ms
    this.lockStartTime = null;
  }
  
  /**
   * Update PLL based on measurements from peer nodes
   */
  update(measurements) {
    if (!measurements || measurements.length === 0) {
      return this.getState();
    }
    
    // Calculate weighted average frequency from peers
    const avgFreq = this.calculateWeightedAverage(measurements);
    const freqError = this.referenceFreq - avgFreq;
    
    // PID controller
    const pTerm = this.Kp * freqError;
    const iTerm = this.Ki * this.integralError;
    const dTerm = this.Kd * (freqError - this.lastError);
    
    const correction = pTerm + iTerm + dTerm;
    
    // Update state
    this.currentFreq = this.referenceFreq + correction;
    this.integralError += freqError;
    this.lastError = freqError;
    
    // Update phase
    const dt = 0.001; // 1ms time step
    this.currentPhase += 2 * Math.PI * this.currentFreq * dt;
    this.currentPhase = this.currentPhase % (2 * Math.PI);
    
    // Lock detection
    const deviation = Math.abs(freqError);
    if (deviation < this.lockThreshold) {
      if (!this.lockStartTime) {
        this.lockStartTime = Date.now();
      } else if (Date.now() - this.lockStartTime > this.lockDuration) {
        if (!this.locked) {
          this.locked = true;
          this.lockTime = new Date();
        }
      }
    } else {
      this.locked = false;
      this.lockStartTime = null;
      this.lockTime = null;
    }
    
    return this.getState();
  }
  
  /**
   * Calculate weighted average giving more weight to locked nodes
   */
  calculateWeightedAverage(measurements) {
    let totalWeight = 0;
    let weightedSum = 0;
    
    for (const m of measurements) {
      const weight = m.locked ? 2.0 : 1.0;
      weightedSum += m.frequency * weight;
      totalWeight += weight;
    }
    
    return totalWeight > 0 ? weightedSum / totalWeight : this.referenceFreq;
  }
  
  /**
   * Get current PLL state
   */
  getState() {
    return {
      frequency: this.currentFreq,
      phase: this.currentPhase,
      locked: this.locked,
      error: this.lastError,
      deviation: Math.abs(this.currentFreq - this.referenceFreq),
      lockTime: this.lockTime,
      timestamp: new Date().toISOString()
    };
  }
  
  /**
   * Reset PLL state (for recovery)
   */
  reset() {
    this.currentFreq = this.referenceFreq;
    this.currentPhase = 0;
    this.integralError = 0;
    this.lastError = 0;
    this.locked = false;
    this.lockStartTime = null;
    this.lockTime = null;
  }
}

/**
 * Seedbringer Node - K-SYNC Protocol Implementation
 */
class SeedbringerNode extends EventEmitter {
  constructor(config = {}) {
    super();
    
    this.nodeId = config.nodeId || crypto.randomUUID();
    this.cluster = config.cluster || 'default';
    this.region = config.region || 'unknown';
    
    // Network configuration
    this.referenceFreq = 432.073;
    this.pll = new KSyncPLL(this.nodeId);
    this.peers = new Map();
    
    // Timing configuration
    this.heartbeatInterval = 12000; // 12 seconds
    this.healthCheckInterval = 144000; // 144 seconds (12 blocks)
    this.pllUpdateInterval = 1000; // 1 second
    
    // State
    this.startTime = null;
    this.lastHeartbeat = null;
    this.consensusParticipating = false;
    
    // Intervals
    this.intervals = {
      pll: null,
      heartbeat: null,
      healthCheck: null
    };
  }
  
  /**
   * Start the Seedbringer node
   */
  async start() {
    console.log(`\n🌱 Starting Seedbringer Node ${this.nodeId}`);
    console.log(`   Cluster: ${this.cluster}`);
    console.log(`   Region: ${this.region}`);
    console.log(`   Reference Frequency: ${this.referenceFreq} Hz\n`);
    
    this.startTime = new Date();
    
    // Start PLL synchronization
    this.startPLL();
    
    // Start heartbeat
    this.startHeartbeat();
    
    // Start health checks
    this.startHealthChecks();
    
    this.emit('started', {
      nodeId: this.nodeId,
      timestamp: this.startTime.toISOString()
    });
    
    console.log('✓ Node started successfully\n');
  }
  
  /**
   * Stop the node
   */
  stop() {
    console.log(`\n🛑 Stopping Seedbringer Node ${this.nodeId}\n`);
    
    // Clear all intervals
    Object.values(this.intervals).forEach(interval => {
      if (interval) clearInterval(interval);
    });
    
    this.emit('stopped', {
      nodeId: this.nodeId,
      timestamp: new Date().toISOString()
    });
    
    console.log('✓ Node stopped\n');
  }
  
  /**
   * Start PLL synchronization loop
   */
  startPLL() {
    this.intervals.pll = setInterval(() => {
      // Collect measurements from peers
      const measurements = this.collectPeerMeasurements();
      
      // Update PLL
      const state = this.pll.update(measurements);
      
      // Emit state update
      this.emit('pll-update', state);
      
      // Log lock status changes
      if (state.locked && !this.consensusParticipating) {
        this.consensusParticipating = true;
        console.log(`🔒 Node LOCKED at ${state.frequency.toFixed(6)} Hz`);
        console.log(`   Deviation: ${state.deviation.toFixed(6)} Hz`);
        console.log(`   Participating in consensus\n`);
      } else if (!state.locked && this.consensusParticipating) {
        this.consensusParticipating = false;
        console.log(`🔓 Node UNLOCKED - synchronizing...`);
        console.log(`   Current frequency: ${state.frequency.toFixed(6)} Hz`);
        console.log(`   Deviation: ${state.deviation.toFixed(6)} Hz\n`);
      }
    }, this.pllUpdateInterval);
  }
  
  /**
   * Start heartbeat broadcast
   */
  startHeartbeat() {
    this.intervals.heartbeat = setInterval(() => {
      const heartbeat = this.generateHeartbeat();
      this.broadcastHeartbeat(heartbeat);
      this.lastHeartbeat = new Date();
    }, this.heartbeatInterval);
  }
  
  /**
   * Start health check monitoring
   */
  startHealthChecks() {
    this.intervals.healthCheck = setInterval(() => {
      const health = this.performHealthCheck();
      this.emit('health-check', health);
      
      if (!health.overall_healthy) {
        console.warn(`⚠️  Node health degraded:`);
        console.warn(`   Frequency locked: ${health.frequency_locked}`);
        console.warn(`   Peers connected: ${health.peers_connected}`);
        console.warn(`   Consensus active: ${health.consensus_active}\n`);
      }
    }, this.healthCheckInterval);
  }
  
  /**
   * Generate heartbeat message
   */
  generateHeartbeat() {
    const state = this.pll.getState();
    const uptime = this.startTime ? (Date.now() - this.startTime.getTime()) / 1000 : 0;
    
    return {
      protocol: 'K-SYNC',
      version: '1.0.0',
      message_type: 'heartbeat',
      node_id: this.nodeId,
      cluster: this.cluster,
      region: this.region,
      timestamp: new Date().toISOString(),
      frequency_data: {
        current_frequency: state.frequency,
        deviation: state.deviation,
        locked: state.locked,
        phase: state.phase,
        lock_time: state.lockTime ? state.lockTime.toISOString() : null,
        stability_duration: state.lockTime ? (Date.now() - state.lockTime.getTime()) / 1000 : 0
      },
      node_status: {
        uptime: uptime,
        peers_connected: this.peers.size,
        consensus_participating: this.consensusParticipating,
        health: this.getHealth()
      },
      lex_amoris_compliance: {
        validated: true,
        last_check: new Date().toISOString(),
        violations: 0
      }
    };
  }
  
  /**
   * Broadcast heartbeat to peers
   */
  broadcastHeartbeat(heartbeat) {
    // Emit heartbeat event (in real implementation, send to network)
    this.emit('heartbeat', heartbeat);
  }
  
  /**
   * Collect frequency measurements from peers
   */
  collectPeerMeasurements() {
    const measurements = [];
    
    for (const [peerId, peer] of this.peers) {
      measurements.push({
        nodeId: peerId,
        frequency: peer.frequency || this.referenceFreq,
        locked: peer.locked || false,
        phase: peer.phase || 0,
        timestamp: peer.timestamp
      });
    }
    
    return measurements;
  }
  
  /**
   * Perform comprehensive health check
   */
  performHealthCheck() {
    const state = this.pll.getState();
    const peersHealthy = this.countHealthyPeers();
    const minPeers = 25;
    
    return {
      timestamp: new Date().toISOString(),
      frequency_locked: state.locked,
      frequency_deviation: state.deviation,
      peers_connected: this.peers.size,
      peers_healthy: peersHealthy,
      consensus_active: state.locked && this.peers.size >= minPeers,
      overall_healthy: state.locked && this.peers.size >= minPeers && peersHealthy > minPeers * 0.8,
      uptime: this.startTime ? (Date.now() - this.startTime.getTime()) / 1000 : 0
    };
  }
  
  /**
   * Count healthy peers (locked and recent heartbeat)
   */
  countHealthyPeers() {
    let count = 0;
    const maxAge = 36000; // 36 seconds (3 missed heartbeats)
    const now = Date.now();
    
    for (const peer of this.peers.values()) {
      if (peer.locked && peer.timestamp && (now - peer.timestamp < maxAge)) {
        count++;
      }
    }
    
    return count;
  }
  
  /**
   * Get current health status string
   */
  getHealth() {
    const health = this.performHealthCheck();
    return health.overall_healthy ? 'healthy' : 'degraded';
  }
  
  /**
   * Add or update peer
   */
  updatePeer(peerId, peerData) {
    this.peers.set(peerId, {
      ...peerData,
      timestamp: Date.now()
    });
  }
  
  /**
   * Remove peer
   */
  removePeer(peerId) {
    this.peers.delete(peerId);
  }
  
  /**
   * Get node statistics
   */
  getStats() {
    const state = this.pll.getState();
    const health = this.performHealthCheck();
    
    return {
      node_id: this.nodeId,
      cluster: this.cluster,
      region: this.region,
      frequency: state.frequency,
      deviation: state.deviation,
      locked: state.locked,
      lock_time: state.lockTime ? state.lockTime.toISOString() : null,
      uptime: health.uptime,
      peers_connected: this.peers.size,
      peers_healthy: health.peers_healthy,
      consensus_participating: this.consensusParticipating,
      health: this.getHealth(),
      timestamp: new Date().toISOString()
    };
  }
  
  /**
   * Print node status
   */
  printStatus() {
    const stats = this.getStats();
    
    console.log('\n' + '='.repeat(60));
    console.log('Seedbringer Node Status');
    console.log('='.repeat(60));
    console.log(`Node ID:        ${stats.node_id}`);
    console.log(`Cluster:        ${stats.cluster}`);
    console.log(`Region:         ${stats.region}`);
    console.log(`Frequency:      ${stats.frequency.toFixed(6)} Hz`);
    console.log(`Deviation:      ${stats.deviation.toFixed(6)} Hz`);
    console.log(`Locked:         ${stats.locked ? '✓ YES' : '✗ NO'}`);
    console.log(`Uptime:         ${Math.floor(stats.uptime)} seconds`);
    console.log(`Peers:          ${stats.peers_connected} (${stats.peers_healthy} healthy)`);
    console.log(`Consensus:      ${stats.consensus_participating ? '✓ ACTIVE' : '✗ INACTIVE'}`);
    console.log(`Health:         ${stats.health.toUpperCase()}`);
    console.log('='.repeat(60));
    console.log('\nLex Amoris: λ = ∞');
    console.log('No ownership, only sharing. Love is the license.\n');
  }
}

/**
 * Main function - example usage
 */
async function main() {
  console.log('\n🎵 Euystacio Nexus - Seedbringer Node 🎵\n');
  console.log('K-SYNC Protocol v1.0.0\n');
  
  // Create node
  const node = new SeedbringerNode({
    nodeId: 'seedbringer-001',
    cluster: 'europe-west',
    region: 'Europe'
  });
  
  // Set up event listeners
  node.on('started', (data) => {
    console.log(`✓ Node started at ${data.timestamp}\n`);
  });
  
  node.on('pll-update', (state) => {
    // Periodic status updates (every 30 seconds)
    if (Date.now() % 30000 < 1000) {
      console.log(`📊 Frequency: ${state.frequency.toFixed(6)} Hz | ` +
                  `Deviation: ${state.deviation.toFixed(6)} Hz | ` +
                  `Locked: ${state.locked ? '✓' : '✗'}`);
    }
  });
  
  node.on('heartbeat', (heartbeat) => {
    // Could broadcast to network here
    // console.log(`💓 Heartbeat sent at ${heartbeat.timestamp}`);
  });
  
  // Start the node
  await node.start();
  
  // Simulate some peer connections
  setTimeout(() => {
    node.updatePeer('peer-1', { frequency: 432.072, locked: true, phase: 0.5 });
    node.updatePeer('peer-2', { frequency: 432.074, locked: true, phase: 1.0 });
    node.updatePeer('peer-3', { frequency: 432.073, locked: true, phase: 1.5 });
    console.log('✓ Connected to 3 peer nodes\n');
  }, 5000);
  
  // Print status every 30 seconds
  setInterval(() => {
    node.printStatus();
  }, 30000);
  
  // Handle graceful shutdown
  process.on('SIGINT', () => {
    console.log('\n\n🛑 Received SIGINT, shutting down...');
    node.stop();
    process.exit(0);
  });
  
  // Keep process alive
  process.stdin.resume();
}

// Run if executed directly
if (require.main === module) {
  main().catch(console.error);
}

// Export for use as module
module.exports = { SeedbringerNode, KSyncPLL };
