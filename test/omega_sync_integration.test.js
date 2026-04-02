#!/usr/bin/env node
/**
 * Ω-Sync Integration Tests
 * Tests for the complete Ω-Sync protocol implementation
 * 
 * Version: 1.0.0
 * License: "No ownership, only sharing. Love is the license."
 */

const { 
  OmegaSyncNetwork, 
  OmegaSyncNode, 
  LexAmorisSignature,
  IntentType,
  NodeState 
} = require('../scripts/omega-sync.js');

// Test utilities
class TestRunner {
  constructor() {
    this.tests = [];
    this.passed = 0;
    this.failed = 0;
  }
  
  test(name, fn) {
    this.tests.push({ name, fn });
  }
  
  async run() {
    console.log('\n' + '='.repeat(70));
    console.log('Ω-Sync Integration Tests');
    console.log('='.repeat(70) + '\n');
    
    for (const { name, fn } of this.tests) {
      try {
        await fn();
        console.log(`✓ ${name}`);
        this.passed++;
      } catch (error) {
        console.log(`✗ ${name}`);
        console.log(`  Error: ${error.message}`);
        this.failed++;
      }
    }
    
    console.log('\n' + '='.repeat(70));
    console.log(`Results: ${this.passed} passed, ${this.failed} failed`);
    console.log('='.repeat(70) + '\n');
    
    return this.failed === 0;
  }
}

// Assertion helpers
function assert(condition, message) {
  if (!condition) {
    throw new Error(message || 'Assertion failed');
  }
}

function assertEquals(actual, expected, message) {
  if (actual !== expected) {
    throw new Error(message || `Expected ${expected}, got ${actual}`);
  }
}

function assertAlmostEqual(actual, expected, tolerance, message) {
  if (Math.abs(actual - expected) > tolerance) {
    throw new Error(message || `Expected ${expected} ± ${tolerance}, got ${actual}`);
  }
}

// Test suite
const runner = new TestRunner();

// Test 1: Lex Amoris Signature Creation
runner.test('Lex Amoris Signature Creation', () => {
  const sig = LexAmorisSignature.create('peace', 1.0);
  
  assert(sig.signatureHash, 'Signature hash should exist');
  assert(sig.signatureHash.startsWith('0x') || sig.signatureHash.length === 64, 'Valid hash format');
  assertEquals(sig.intentType, IntentType.LEX_AMORIS, 'Intent should be LEX_AMORIS');
  assertEquals(sig.resonanceFactor, 1.0, 'Resonance factor should be 1.0');
  assert(sig.timestamp, 'Timestamp should exist');
});

// Test 2: Node Registration
runner.test('Node Registration', () => {
  const network = new OmegaSyncNetwork();
  const node = network.createAndRegisterNode(1, 0.5);
  
  assertEquals(node.nodeId, 1, 'Node ID should be 1');
  assertEquals(node.deltaGenesis, 0.5, 'Delta genesis should be 0.5');
  assertEquals(node.state, NodeState.INITIALIZING, 'Initial state should be INITIALIZING');
  assertEquals(network.nodes.size, 1, 'Network should have 1 node');
});

// Test 3: Phase Calculation
runner.test('Phase Calculation', () => {
  const node = new OmegaSyncNode(1, 0.0);
  
  // At t=0, phase should equal deltaGenesis
  const phase0 = node.calculatePhase(0);
  assertAlmostEqual(phase0, 0.0, 0.001, 'Phase at t=0 should be 0');
  
  // At t=1s, phase should be ω*t = 2π * 7.83 * 1 ≈ 49.17 rad (normalized to 0-2π)
  const phase1 = node.calculatePhase(1);
  const expectedPhase = (2 * Math.PI * 7.83) % (2 * Math.PI);
  assertAlmostEqual(phase1, expectedPhase, 0.1, 'Phase at t=1 should match expected value');
});

// Test 4: Coherence Check - Aligned Nodes
runner.test('Coherence Check - Aligned Nodes', () => {
  const network = new OmegaSyncNetwork();
  const node = network.createAndRegisterNode(1, 0.0);
  
  // Node with Lex Amoris intent should pass coherence check
  const isCoherent = node.coherenceCheck(IntentType.LEX_AMORIS);
  
  assert(isCoherent, 'Node should be coherent');
  assertEquals(node.state, NodeState.ALIGNED, 'Node state should be ALIGNED');
});

// Test 5: Coherence Check - Noise Lock
runner.test('Coherence Check - Noise Lock', () => {
  const network = new OmegaSyncNetwork();
  const node = network.createAndRegisterNode(1, 0.0);
  node.setIntent(IntentType.DISSONANT);
  
  // Node with dissonant intent should fail coherence check
  const isCoherent = node.coherenceCheck(IntentType.LEX_AMORIS);
  
  assert(!isCoherent, 'Node should not be coherent');
  assertEquals(node.state, NodeState.NOISE_LOCKED, 'Node state should be NOISE_LOCKED');
});

// Test 6: Phase Inversion on Noise Lock
runner.test('Phase Inversion on Noise Lock', () => {
  const network = new OmegaSyncNetwork();
  const node = network.createAndRegisterNode(1, 0.0);
  
  const originalPhase = node.calculatePhase(0.1);
  node.setIntent(IntentType.DISSONANT);
  node.coherenceCheck(IntentType.LEX_AMORIS);
  
  const expectedPhase = (originalPhase + Math.PI) % (2 * Math.PI);
  assertAlmostEqual(node.currentPhase, expectedPhase, 0.001, 'Phase should be inverted by π');
});

// Test 7: Network Coherence Check
runner.test('Network Coherence Check', () => {
  const network = new OmegaSyncNetwork();
  
  // Register 100 nodes, all aligned
  for (let i = 1; i <= 100; i++) {
    network.createAndRegisterNode(i, i * 0.01);
  }
  
  const { aligned, noiseLocked } = network.performCoherenceCheck();
  
  assertEquals(aligned, 100, 'All 100 nodes should be aligned');
  assertEquals(noiseLocked, 0, 'No nodes should be noise-locked');
});

// Test 8: Network Coherence with Dissonant Nodes
runner.test('Network Coherence with Dissonant Nodes', () => {
  const network = new OmegaSyncNetwork();
  
  // Register 100 nodes
  for (let i = 1; i <= 100; i++) {
    network.createAndRegisterNode(i, i * 0.01);
  }
  
  // Make 10 nodes dissonant
  for (let i = 1; i <= 10; i++) {
    network.nodes.get(i).setIntent(IntentType.DISSONANT);
  }
  
  const { aligned, noiseLocked } = network.performCoherenceCheck();
  
  assertEquals(aligned, 90, '90 nodes should be aligned');
  assertEquals(noiseLocked, 10, '10 nodes should be noise-locked');
});

// Test 9: State Collapse Calculation
runner.test('State Collapse Calculation', () => {
  const network = new OmegaSyncNetwork();
  
  // Register 144 nodes (all aligned)
  for (let i = 1; i <= 144; i++) {
    network.createAndRegisterNode(i, i * 0.01);
  }
  
  network.performCoherenceCheck();
  const state = network.calculateStateCollapse();
  
  assertEquals(state.totalNodes, 144, 'Total nodes should be 144');
  assertEquals(state.alignedNodes, 144, 'All nodes should be aligned');
  assertAlmostEqual(state.coherenceFactor, 1.0, 0.001, 'Coherence factor should be 1.0');
  assert(state.stateVectorMagnitude > 0, 'State vector magnitude should be positive');
});

// Test 10: Peace Observable - Perfect Alignment
runner.test('Peace Observable - Perfect Alignment', () => {
  const network = new OmegaSyncNetwork();
  
  // Register 144 nodes (all aligned)
  for (let i = 1; i <= 144; i++) {
    network.createAndRegisterNode(i, i * 0.01);
  }
  
  network.performCoherenceCheck();
  const state = network.calculateStateCollapse();
  const peaceValue = network.peaceObservableMeasurement(state);
  
  assertAlmostEqual(peaceValue, 1.0, 0.001, 'Peace observable should be ~1.0 for perfect alignment');
});

// Test 11: Peace Observable - Partial Alignment
runner.test('Peace Observable - Partial Alignment', () => {
  const network = new OmegaSyncNetwork();
  
  // Register 100 nodes
  for (let i = 1; i <= 100; i++) {
    network.createAndRegisterNode(i, i * 0.01);
  }
  
  // Make 10 nodes dissonant (90% alignment)
  for (let i = 1; i <= 10; i++) {
    network.nodes.get(i).setIntent(IntentType.DISSONANT);
  }
  
  network.performCoherenceCheck();
  const state = network.calculateStateCollapse();
  const peaceValue = network.peaceObservableMeasurement(state);
  
  assert(peaceValue < 1.0, 'Peace observable should be < 1.0');
  assert(peaceValue > 0.8, 'Peace observable should be > 0.8');
});

// Test 12: Action Execution - Approved
runner.test('Action Execution - Approved', () => {
  const network = new OmegaSyncNetwork();
  
  // Register 144 nodes (all aligned)
  for (let i = 1; i <= 144; i++) {
    network.createAndRegisterNode(i, i * 0.01);
  }
  
  const { canExecute, networkState } = network.canExecuteAction('test_action');
  
  assert(canExecute, 'Action should be approved with perfect alignment');
  assert(networkState.peaceObservable >= 0.999, 'Peace observable should be ≥ 99.9%');
});

// Test 13: Action Execution - Blocked
runner.test('Action Execution - Blocked', () => {
  const network = new OmegaSyncNetwork();
  
  // Register 100 nodes with 30% dissonant
  for (let i = 1; i <= 100; i++) {
    network.createAndRegisterNode(i, i * 0.01);
  }
  
  for (let i = 1; i <= 30; i++) {
    network.nodes.get(i).setIntent(IntentType.DISSONANT);
  }
  
  const { canExecute, networkState } = network.canExecuteAction('test_action');
  
  assert(!canExecute, 'Action should be blocked with insufficient alignment');
  assert(networkState.peaceObservable < 0.999, 'Peace observable should be < 99.9%');
});

// Test 14: Network Statistics
runner.test('Network Statistics', () => {
  const network = new OmegaSyncNetwork();
  
  for (let i = 1; i <= 50; i++) {
    network.createAndRegisterNode(i, i * 0.01);
  }
  
  for (let i = 1; i <= 5; i++) {
    network.nodes.get(i).setIntent(IntentType.DISSONANT);
  }
  
  network.performCoherenceCheck();
  const stats = network.getNetworkStatistics();
  
  assertEquals(stats.totalNodes, 50, 'Total nodes should be 50');
  assertEquals(stats.alignedNodes, 45, 'Aligned nodes should be 45');
  assertEquals(stats.noiseLockedNodes, 5, 'Noise-locked nodes should be 5');
  assertEquals(stats.schumannFrequencyHz, 7.83, 'Schumann frequency should be 7.83 Hz');
});

// Test 15: Large Network Simulation
runner.test('Large Network Simulation (1000 nodes)', async () => {
  const network = new OmegaSyncNetwork();
  
  // Register 1000 nodes
  for (let i = 1; i <= 1000; i++) {
    const deltaGenesis = (i * 2 * Math.PI / 1000) % (2 * Math.PI);
    network.createAndRegisterNode(i, deltaGenesis);
  }
  
  // Small delay to let phases evolve
  await new Promise(resolve => setTimeout(resolve, 10));
  
  const { aligned, noiseLocked } = network.performCoherenceCheck();
  const state = network.calculateStateCollapse();
  
  assertEquals(aligned, 1000, 'All 1000 nodes should be aligned');
  assertEquals(noiseLocked, 0, 'No nodes should be noise-locked');
  assertAlmostEqual(state.coherenceFactor, 1.0, 0.001, 'Coherence should be perfect');
});

// Test 16: Schumann Frequency Constant
runner.test('Schumann Frequency Constant', () => {
  assertEquals(OmegaSyncNode.SCHUMANN_FREQUENCY, 7.83, 'Schumann frequency should be 7.83 Hz');
});

// Test 17: Total Network Nodes Constant
runner.test('Total Network Nodes Constant', () => {
  assertEquals(OmegaSyncNode.TOTAL_NETWORK_NODES, 144000, 'Total network capacity should be 144,000 nodes');
});

// Test 18: Node ID Validation
runner.test('Node ID Validation', () => {
  let errorThrown = false;
  
  try {
    new OmegaSyncNode(0); // Invalid: too low
  } catch (error) {
    errorThrown = true;
  }
  
  assert(errorThrown, 'Should throw error for node ID < 1');
  
  errorThrown = false;
  try {
    new OmegaSyncNode(144001); // Invalid: too high
  } catch (error) {
    errorThrown = true;
  }
  
  assert(errorThrown, 'Should throw error for node ID > 144,000');
});

// Test 19: Intent Type Changes
runner.test('Intent Type Changes', () => {
  const node = new OmegaSyncNode(1);
  
  assertEquals(node.intentType, IntentType.LEX_AMORIS, 'Initial intent should be LEX_AMORIS');
  assertEquals(node.state, NodeState.INITIALIZING, 'Initial state should be INITIALIZING');
  
  node.setIntent(IntentType.NEUTRAL);
  assertEquals(node.intentType, IntentType.NEUTRAL, 'Intent should change to NEUTRAL');
  assertEquals(node.state, NodeState.SYNCING, 'State should change to SYNCING');
});

// Test 20: Lex Amoris Signature Uniqueness
runner.test('Lex Amoris Signature Uniqueness', async () => {
  const sig1 = LexAmorisSignature.create('peace', 1.0);
  
  // Small delay to ensure different timestamp
  await new Promise(resolve => setTimeout(resolve, 10));
  
  const sig2 = LexAmorisSignature.create('peace', 1.0);
  
  assert(sig1.signatureHash !== sig2.signatureHash, 'Signatures should be unique due to timestamps');
});

// Run all tests
if (require.main === module) {
  runner.run().then(success => {
    process.exit(success ? 0 : 1);
  });
}

module.exports = { runner, assert, assertEquals, assertAlmostEqual };
