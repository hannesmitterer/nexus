/**
 * Klimabaum Test Suite
 * 
 * Basic tests for monitoring and optimization functionality
 */

const KlimabaumMonitor = require('./monitoring/intelligent_monitor');
const NSRResourceOptimizer = require('./algorithms/nsr_optimizer');

console.log('🧪 Running Klimabaum Tests...\n');

let passedTests = 0;
let failedTests = 0;

function assert(condition, testName) {
  if (condition) {
    console.log(`  ✓ ${testName}`);
    passedTests++;
  } else {
    console.log(`  ✗ ${testName}`);
    failedTests++;
  }
}

// Test 1: Monitor initialization
console.log('Test Suite 1: Monitor Initialization');
try {
  const monitor = new KlimabaumMonitor();
  assert(monitor !== null, 'Monitor should initialize');
  assert(monitor.nodes instanceof Map, 'Monitor should have nodes Map');
  assert(monitor.alertThresholds !== undefined, 'Monitor should have alert thresholds');
} catch (error) {
  console.log(`  ✗ Monitor initialization failed: ${error.message}`);
  failedTests++;
}

// Test 2: Node registration
console.log('\nTest Suite 2: Node Registration');
try {
  const monitor = new KlimabaumMonitor();
  const nodeConfig = {
    node_id: 'KB-TEST-000001',
    location: {
      latitude: 45.0,
      longitude: 9.0,
      city: 'TestCity',
      country: 'TestCountry'
    },
    node_type: 'primary',
    monitoring_capabilities: {
      air_quality: true,
      temperature: true
    },
    status: 'active'
  };
  
  const nodeId = monitor.registerNode(nodeConfig);
  assert(nodeId === 'KB-TEST-000001', 'Node should register with correct ID');
  assert(monitor.nodes.has('KB-TEST-000001'), 'Node should be stored in monitor');
  
  const node = monitor.nodes.get('KB-TEST-000001');
  assert(node.registeredAt !== undefined, 'Node should have registration timestamp');
  assert(node.metrics !== undefined, 'Node should have metrics object');
} catch (error) {
  console.log(`  ✗ Node registration failed: ${error.message}`);
  failedTests++;
}

// Test 3: Data collection
console.log('\nTest Suite 3: Data Collection');
try {
  const monitor = new KlimabaumMonitor();
  const nodeConfig = {
    node_id: 'KB-TEST-000002',
    location: { latitude: 45.0, longitude: 9.0, city: 'Test', country: 'Test' },
    node_type: 'primary',
    monitoring_capabilities: { temperature: true },
    status: 'active'
  };
  
  monitor.registerNode(nodeConfig);
  
  const readings = {
    temperature: 25.5,
    humidity: 60,
    air_quality_index: 45
  };
  
  monitor.collectData('KB-TEST-000002', readings);
  const node = monitor.nodes.get('KB-TEST-000002');
  
  assert(node.metrics.readings.length === 1, 'Should have one reading');
  assert(node.metrics.readings[0].temperature === 25.5, 'Temperature should be stored correctly');
} catch (error) {
  console.log(`  ✗ Data collection failed: ${error.message}`);
  failedTests++;
}

// Test 4: Climate risk calculation
console.log('\nTest Suite 4: Climate Risk Analysis');
try {
  const monitor = new KlimabaumMonitor();
  const nodeConfig = {
    node_id: 'KB-TEST-000003',
    location: { latitude: 45.0, longitude: 9.0, city: 'Test', country: 'Test' },
    node_type: 'primary',
    monitoring_capabilities: { temperature: true, air_quality: true },
    status: 'active',
    nsr_compliance: { compliant: true, compliance_score: 90, last_audit: new Date().toISOString(), violations: [] }
  };
  
  monitor.registerNode(nodeConfig);
  
  // Add multiple readings to build history
  const MIN_READINGS_FOR_ANALYSIS = 25;
  for (let i = 0; i < MIN_READINGS_FOR_ANALYSIS; i++) {
    monitor.collectData('KB-TEST-000003', {
      temperature: 30 + Math.random() * 10,
      air_quality_index: 80 + Math.random() * 40
    });
  }
  
  const node = monitor.nodes.get('KB-TEST-000003');
  const riskScore = node.predictive_metrics?.climate_risk_score;
  
  assert(riskScore !== undefined, 'Climate risk score should be calculated');
  assert(riskScore >= 0 && riskScore <= 100, 'Risk score should be 0-100');
} catch (error) {
  console.log(`  ✗ Climate risk analysis failed: ${error.message}`);
  failedTests++;
}

// Test 5: NSR Optimizer initialization
console.log('\nTest Suite 5: NSR Optimizer');
try {
  const optimizer = new NSRResourceOptimizer();
  assert(optimizer !== null, 'Optimizer should initialize');
  assert(optimizer.equityWeight !== undefined, 'Optimizer should have equity weight');
  assert(optimizer.efficiencyWeight !== undefined, 'Optimizer should have efficiency weight');
  assert(optimizer.climateWeight !== undefined, 'Optimizer should have climate weight');
} catch (error) {
  console.log(`  ✗ Optimizer initialization failed: ${error.message}`);
  failedTests++;
}

// Test 6: Resource optimization
console.log('\nTest Suite 6: Resource Optimization');
try {
  const optimizer = new NSRResourceOptimizer();
  
  const nodes = [
    {
      node_id: 'KB-TEST-001',
      location: { city: 'City1', country: 'Country1', urban_zone: 'residential' },
      predictive_metrics: { climate_risk_score: 50, resource_demand_forecast: { next_24h: 60 } },
      nsr_compliance: { compliant: true, compliance_score: 90 },
      last_maintenance: new Date().toISOString()
    },
    {
      node_id: 'KB-TEST-002',
      location: { city: 'City2', country: 'Country2', urban_zone: 'commercial' },
      predictive_metrics: { climate_risk_score: 80, resource_demand_forecast: { next_24h: 85 } },
      nsr_compliance: { compliant: true, compliance_score: 85 },
      last_maintenance: new Date().toISOString()
    }
  ];
  
  const resources = { energy: 200, water: 200, cooling: 200 };
  
  const plan = optimizer.optimizeDistribution(nodes, resources);
  
  assert(plan !== null, 'Optimization plan should be generated');
  assert(plan.allocation !== undefined, 'Plan should have allocation');
  assert(plan.allocation.length === 2, 'Should have allocation for both nodes');
  assert(plan.compliance !== undefined, 'Plan should have compliance check');
  assert(plan.optimization_score >= 0 && plan.optimization_score <= 100, 'Optimization score should be 0-100');
  assert(plan.equity_index >= 0 && plan.equity_index <= 1, 'Equity index should be 0-1');
} catch (error) {
  console.log(`  ✗ Resource optimization failed: ${error.message}`);
  failedTests++;
}

// Test 7: NSR compliance validation
console.log('\nTest Suite 7: NSR Compliance Validation');
try {
  const optimizer = new NSRResourceOptimizer();
  
  const allocation = [
    { node_id: 'N1', energy: 100, water: 100, cooling: 100 },
    { node_id: 'N2', energy: 100, water: 100, cooling: 100 }
  ];
  
  const constraints = { max_allocation_ratio: 3.0 };
  
  const compliance = optimizer.validateNSRCompliance(allocation, constraints);
  
  assert(compliance !== null, 'Compliance validation should return result');
  assert(compliance.compliant === true, 'Equal allocation should be compliant');
  assert(compliance.equity_ratio === 1.0, 'Equity ratio should be 1.0 for equal allocation');
} catch (error) {
  console.log(`  ✗ NSR compliance validation failed: ${error.message}`);
  failedTests++;
}

// Test 8: Equity index calculation
console.log('\nTest Suite 8: Equity Index Calculation');
try {
  const optimizer = new NSRResourceOptimizer();
  
  // Perfect equity: all equal
  const equalAlloc = [
    { energy: 100, water: 100, cooling: 100 },
    { energy: 100, water: 100, cooling: 100 },
    { energy: 100, water: 100, cooling: 100 }
  ];
  
  const equityIndex = optimizer.calculateEquityIndex(equalAlloc);
  
  assert(equityIndex > 0.99, 'Equal allocation should have equity index close to 1.0');
  
  // Unequal allocation
  const unequalAlloc = [
    { energy: 50, water: 50, cooling: 50 },
    { energy: 100, water: 100, cooling: 100 },
    { energy: 150, water: 150, cooling: 150 }
  ];
  
  const unequalEquity = optimizer.calculateEquityIndex(unequalAlloc);
  
  assert(unequalEquity < 1.0, 'Unequal allocation should have equity index less than 1.0');
  assert(unequalEquity < equityIndex, 'Unequal should have lower equity than equal');
} catch (error) {
  console.log(`  ✗ Equity index calculation failed: ${error.message}`);
  failedTests++;
}

// Summary
console.log('\n' + '='.repeat(50));
console.log('Test Summary:');
console.log(`  Total Tests: ${passedTests + failedTests}`);
console.log(`  Passed: ${passedTests} ✓`);
console.log(`  Failed: ${failedTests} ✗`);
console.log('='.repeat(50));

if (failedTests === 0) {
  console.log('\n🎉 All tests passed!\n');
  process.exit(0);
} else {
  console.log(`\n❌ ${failedTests} test(s) failed.\n`);
  process.exit(1);
}
