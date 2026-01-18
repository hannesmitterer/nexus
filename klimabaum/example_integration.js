/**
 * Klimabaum Integration Example
 * 
 * Demonstrates how to use the Klimabaum monitoring and optimization system
 * with the Euystacio framework and SAIN Protocol.
 */

const KlimabaumMonitor = require('./monitoring/intelligent_monitor');
const NSRResourceOptimizer = require('./algorithms/nsr_optimizer');
const fs = require('fs');

// Load configuration
const config = JSON.parse(fs.readFileSync('./config/default.json', 'utf8'));
const sampleNodes = JSON.parse(fs.readFileSync('./data/sample_nodes.json', 'utf8'));

// Initialize the monitoring system
console.log('🌳 Initializing Klimabaum Intelligent Monitoring System...\n');

const monitor = new KlimabaumMonitor({
  alertThresholds: config.monitoring.alert_thresholds,
  monitoringInterval: config.monitoring.interval_seconds * 1000,
  predictiveWindow: config.monitoring.predictive_window_hours * 3600000
});

// Register sample nodes
console.log('📍 Registering Klimabaum nodes:\n');
sampleNodes.forEach(nodeConfig => {
  try {
    const nodeId = monitor.registerNode(nodeConfig);
    console.log(`  ✓ Node registered: ${nodeId} (${nodeConfig.location.city}, ${nodeConfig.location.country})`);
  } catch (error) {
    console.error(`  ✗ Failed to register node: ${error.message}`);
  }
});

console.log('\n📊 Simulating sensor data collection...\n');

// Simulate data collection for each node
const simulateDataCollection = () => {
  sampleNodes.forEach((node, index) => {
    // Generate simulated sensor readings
    const readings = {
      temperature: 20 + Math.random() * 15 + (index * 2), // Varying base temps
      humidity: 40 + Math.random() * 40,
      air_quality_index: 30 + Math.random() * 70,
      co2_ppm: 400 + Math.random() * 200,
      energy_consumption: 50 + Math.random() * 50,
      water_usage: 30 + Math.random() * 40
    };
    
    try {
      monitor.collectData(node.node_id, readings);
      console.log(`  📈 Data collected from ${node.node_id}:`);
      console.log(`     Temperature: ${readings.temperature.toFixed(1)}°C`);
      console.log(`     AQI: ${readings.air_quality_index.toFixed(0)}`);
      console.log(`     CO2: ${readings.co2_ppm.toFixed(0)} ppm\n`);
    } catch (error) {
      console.error(`  ✗ Data collection failed: ${error.message}`);
    }
  });
};

// Collect initial data (run multiple times to build history)
for (let i = 0; i < 15; i++) {
  simulateDataCollection();
}

console.log('🔍 Analyzing node statuses:\n');

// Get and display node statuses
sampleNodes.forEach(node => {
  try {
    const status = monitor.getNodeStatus(node.node_id);
    console.log(`Node: ${status.node_id} (${status.location.city})`);
    console.log(`  Status: ${status.status}`);
    console.log(`  Climate Risk: ${status.predictive_metrics?.climate_risk_score || 0}/100`);
    console.log(`  Anomaly Probability: ${((status.predictive_metrics?.anomaly_probability || 0) * 100).toFixed(1)}%`);
    console.log(`  NSR Compliance: ${status.nsr_compliance?.compliance_score || 0}/100`);
    console.log(`  Active Alerts: ${status.recent_alerts?.length || 0}`);
    
    if (status.predictive_metrics?.recommendation) {
      console.log(`  💡 Recommendation: ${status.predictive_metrics.recommendation}`);
    }
    console.log('');
  } catch (error) {
    console.error(`  ✗ Failed to get status: ${error.message}`);
  }
});

console.log('📋 All nodes summary:\n');
const summary = monitor.getAllNodesSummary();
console.table(summary);

// Initialize NSR Resource Optimizer
console.log('\n🎯 Initializing NSR Resource Optimization...\n');

const optimizer = new NSRResourceOptimizer({
  equityWeight: config.optimization.weights.equity,
  efficiencyWeight: config.optimization.weights.efficiency,
  climateWeight: config.optimization.weights.climate,
  minEquityThreshold: config.optimization.constraints.min_equity_threshold
});

// Get current node states for optimization
const nodesForOptimization = sampleNodes.map(nodeConfig => {
  try {
    const status = monitor.getNodeStatus(nodeConfig.node_id);
    return {
      ...nodeConfig,
      predictive_metrics: status.predictive_metrics,
      nsr_compliance: status.nsr_compliance
    };
  } catch (error) {
    console.error(`Failed to get node status for optimization: ${error.message}`);
    return nodeConfig;
  }
});

// Define available resources
const availableResources = {
  energy: config.resources.default_allocation.energy * sampleNodes.length,
  water: config.resources.default_allocation.water * sampleNodes.length,
  cooling: config.resources.default_allocation.cooling * sampleNodes.length
};

console.log('💧 Available Resources:');
console.log(`  Energy: ${availableResources.energy}`);
console.log(`  Water: ${availableResources.water}`);
console.log(`  Cooling: ${availableResources.cooling}\n`);

// Optimize resource distribution
console.log('⚙️  Optimizing resource distribution...\n');

try {
  const optimizationPlan = optimizer.optimizeDistribution(
    nodesForOptimization,
    availableResources
  );

  console.log('✨ Optimization Results:\n');
  console.log(`  Overall Score: ${optimizationPlan.optimization_score.toFixed(2)}/100`);
  console.log(`  Equity Index: ${optimizationPlan.equity_index.toFixed(3)}`);
  console.log(`  Climate Impact Reduction: ${optimizationPlan.climate_impact_reduction.toFixed(1)}%`);
  console.log(`  NSR Compliant: ${optimizationPlan.compliance.compliant ? '✓ Yes' : '✗ No'}`);
  
  if (!optimizationPlan.compliance.compliant) {
    console.log(`  Violations: ${optimizationPlan.compliance.violations.join(', ')}`);
  }
  
  console.log(`  Equity Ratio: ${optimizationPlan.compliance.equity_ratio.toFixed(2)} (max allowed: ${optimizationPlan.compliance.max_allowed_ratio})`);
  
  console.log('\n📦 Resource Allocation Plan:\n');
  
  optimizationPlan.allocation.forEach(alloc => {
    console.log(`${alloc.node_id} (${alloc.location.city}):`);
    console.log(`  Energy: ${alloc.energy.toFixed(2)}`);
    console.log(`  Water: ${alloc.water.toFixed(2)}`);
    console.log(`  Cooling: ${alloc.cooling.toFixed(2)}`);
    console.log(`  Priority Score: ${alloc.priority_score.toFixed(3)}`);
    console.log(`  Mode: ${alloc.optimization_mode}`);
    console.log(`  Capped: ${alloc.capped ? 'Yes' : 'No'}\n`);
  });

  // Generate SAIN Protocol SEP (Sentinel Evidence Package) for audit trail
  console.log('🔐 Generating SAIN Protocol Evidence Package...\n');
  
  const sep = {
    SEP_ID: generateSEPID(optimizationPlan),
    Timestamp_NTS: new Date().toISOString(),
    Artifact_Type: 'RESOURCE_OPTIMIZATION',
    Optimization_Score: optimizationPlan.optimization_score,
    Equity_Index: optimizationPlan.equity_index,
    Climate_Impact_Reduction: optimizationPlan.climate_impact_reduction,
    NSR_Compliant: optimizationPlan.compliance.compliant,
    Allocation_Count: optimizationPlan.allocation.length,
    Total_Resources_Allocated: {
      energy: optimizationPlan.allocation.reduce((sum, a) => sum + a.energy, 0),
      water: optimizationPlan.allocation.reduce((sum, a) => sum + a.water, 0),
      cooling: optimizationPlan.allocation.reduce((sum, a) => sum + a.cooling, 0)
    }
  };
  
  console.log('SEP Generated:');
  console.log(JSON.stringify(sep, null, 2));
  
  console.log('\n✅ Klimabaum Integration Example Complete!\n');
  console.log('📚 Next Steps:');
  console.log('  1. Deploy nodes in real urban environments');
  console.log('  2. Connect to actual sensor hardware');
  console.log('  3. Integrate with city infrastructure APIs');
  console.log('  4. Set up automated monitoring dashboards');
  console.log('  5. Configure alert notification systems');
  console.log('  6. Enable SAIN Protocol blockchain anchoring\n');
  
} catch (error) {
  console.error('❌ Optimization failed:', error.message);
  console.error(error.stack);
}

// Helper function to generate SEP ID
function generateSEPID(data) {
  const crypto = require('crypto');
  const hash = crypto.createHash('sha256');
  hash.update(JSON.stringify(data));
  return hash.digest('hex');
}

// Export for use in other modules
module.exports = {
  monitor,
  optimizer,
  config
};
