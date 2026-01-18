/**
 * Klimabaum Intelligent Monitoring System
 * 
 * Implements intelligent monitoring and predictive analytics for urban climate nodes.
 * Integrates with the SAIN Protocol and Euystacio framework for NSR compliance.
 * 
 * @module KlimabaumMonitor
 * @version 1.0.0
 * @framework Euystacio v1.0
 */

class KlimabaumMonitor {
  constructor(config = {}) {
    this.nodes = new Map();
    this.alertThresholds = config.alertThresholds || {
      climateRisk: 75,
      anomalyProbability: 0.8,
      nsrCompliance: 80
    };
    this.monitoringInterval = config.monitoringInterval || 300000; // 5 minutes
    this.predictiveWindow = config.predictiveWindow || 86400000; // 24 hours
  }

  /**
   * Register a new Klimabaum node for monitoring
   * @param {Object} nodeConfig - Node configuration object
   * @returns {String} node_id
   */
  registerNode(nodeConfig) {
    if (!this.validateNodeConfig(nodeConfig)) {
      throw new Error('Invalid node configuration');
    }

    const node = {
      ...nodeConfig,
      registeredAt: new Date().toISOString(),
      metrics: {
        readings: [],
        alerts: [],
        predictions: {}
      }
    };

    this.nodes.set(nodeConfig.node_id, node);
    return nodeConfig.node_id;
  }

  /**
   * Validate node configuration against schema
   * @param {Object} config - Node configuration
   * @returns {Boolean}
   */
  validateNodeConfig(config) {
    const required = ['node_id', 'location', 'node_type', 'monitoring_capabilities', 'status'];
    return required.every(field => config.hasOwnProperty(field));
  }

  /**
   * Collect real-time data from a node
   * @param {String} nodeId - Klimabaum node identifier
   * @param {Object} readings - Sensor readings
   */
  collectData(nodeId, readings) {
    const node = this.nodes.get(nodeId);
    if (!node) {
      throw new Error(`Node ${nodeId} not found`);
    }

    const dataPoint = {
      timestamp: new Date().toISOString(),
      ...readings
    };

    node.metrics.readings.push(dataPoint);
    
    // Keep only last 1000 readings
    if (node.metrics.readings.length > 1000) {
      node.metrics.readings = node.metrics.readings.slice(-1000);
    }

    // Trigger intelligent analysis
    this.analyzeNodeData(nodeId);
  }

  /**
   * Intelligent analysis of node data using predictive algorithms
   * @param {String} nodeId - Node identifier
   */
  analyzeNodeData(nodeId) {
    const node = this.nodes.get(nodeId);
    if (!node || node.metrics.readings.length < 10) {
      return; // Need minimum data for analysis
    }

    const analysis = {
      climateRiskScore: this.calculateClimateRisk(node),
      anomalyProbability: this.detectAnomalies(node),
      resourceForecast: this.predictResourceDemand(node),
      nsrCompliance: this.assessNSRCompliance(node)
    };

    // Update node predictions
    node.predictive_metrics = {
      climate_risk_score: analysis.climateRiskScore,
      anomaly_probability: analysis.anomalyProbability,
      resource_demand_forecast: analysis.resourceForecast,
      recommendation: this.generateRecommendation(analysis),
      last_updated: new Date().toISOString()
    };

    // Generate alerts if necessary
    this.checkAlerts(nodeId, analysis);

    return analysis;
  }

  /**
   * Calculate climate risk score based on environmental readings
   * @param {Object} node - Node object
   * @returns {Number} Risk score 0-100
   */
  calculateClimateRisk(node) {
    const recent = node.metrics.readings.slice(-20);
    if (recent.length === 0) return 0;

    let riskScore = 0;
    let factors = 0;

    // Temperature risk assessment
    if (recent.some(r => r.temperature)) {
      const avgTemp = recent.reduce((sum, r) => sum + (r.temperature || 0), 0) / recent.length;
      const tempVariance = this.calculateVariance(recent.map(r => r.temperature || 0));
      
      // High temperature increases risk
      if (avgTemp > 35) riskScore += 30;
      else if (avgTemp > 30) riskScore += 20;
      else if (avgTemp > 25) riskScore += 10;
      
      // High variance increases risk
      if (tempVariance > 10) riskScore += 15;
      
      factors++;
    }

    // Air quality risk
    if (recent.some(r => r.air_quality_index)) {
      const avgAQI = recent.reduce((sum, r) => sum + (r.air_quality_index || 0), 0) / recent.length;
      
      if (avgAQI > 150) riskScore += 40;
      else if (avgAQI > 100) riskScore += 25;
      else if (avgAQI > 50) riskScore += 10;
      
      factors++;
    }

    // CO2 levels risk
    if (recent.some(r => r.co2_ppm)) {
      const avgCO2 = recent.reduce((sum, r) => sum + (r.co2_ppm || 0), 0) / recent.length;
      
      if (avgCO2 > 800) riskScore += 30;
      else if (avgCO2 > 600) riskScore += 20;
      else if (avgCO2 > 450) riskScore += 10;
      
      factors++;
    }

    return factors > 0 ? Math.min(100, riskScore / factors) : 0;
  }

  /**
   * Detect anomalies using statistical methods
   * @param {Object} node - Node object
   * @returns {Number} Anomaly probability 0-1
   */
  detectAnomalies(node) {
    const recent = node.metrics.readings.slice(-50);
    if (recent.length < 20) return 0;

    let anomalyScore = 0;
    let checks = 0;

    // Check temperature anomalies
    if (recent.some(r => r.temperature)) {
      const temps = recent.map(r => r.temperature || 0);
      const mean = temps.reduce((a, b) => a + b) / temps.length;
      const stdDev = Math.sqrt(this.calculateVariance(temps));
      const latest = temps[temps.length - 1];
      
      // Latest reading is more than 2 standard deviations from mean
      if (Math.abs(latest - mean) > 2 * stdDev) {
        anomalyScore += 0.4;
      }
      checks++;
    }

    // Check for sudden changes in readings
    const recentTrend = this.calculateTrend(recent.slice(-10));
    const overallTrend = this.calculateTrend(recent);
    
    if (Math.abs(recentTrend - overallTrend) > 0.5) {
      anomalyScore += 0.3;
    }
    checks++;

    return checks > 0 ? Math.min(1, anomalyScore) : 0;
  }

  /**
   * Predict resource demand using trend analysis
   * @param {Object} node - Node object
   * @returns {Object} Forecast for different time windows
   */
  predictResourceDemand(node) {
    const recent = node.metrics.readings.slice(-100);
    if (recent.length < 10) {
      return { next_24h: 0, next_7d: 0, next_30d: 0 };
    }

    // Simple trend-based prediction
    const trend = this.calculateTrend(recent);
    const currentDemand = this.estimateCurrentDemand(recent);

    return {
      next_24h: Math.max(0, currentDemand * (1 + trend * 0.1)),
      next_7d: Math.max(0, currentDemand * (1 + trend * 0.5)),
      next_30d: Math.max(0, currentDemand * (1 + trend * 1.5))
    };
  }

  /**
   * Assess NSR compliance based on node operations
   * @param {Object} node - Node object
   * @returns {Number} Compliance score 0-100
   */
  assessNSRCompliance(node) {
    let complianceScore = 100;

    // Check if node has NSR configuration
    if (!node.nsr_compliance) {
      complianceScore -= 20;
    } else {
      // Deduct points for violations
      const violations = node.nsr_compliance.violations || [];
      const unresolvedViolations = violations.filter(v => !v.resolved);
      
      unresolvedViolations.forEach(v => {
        switch(v.severity) {
          case 'critical': complianceScore -= 30; break;
          case 'high': complianceScore -= 20; break;
          case 'medium': complianceScore -= 10; break;
          case 'low': complianceScore -= 5; break;
        }
      });
    }

    // Check audit freshness
    if (node.nsr_compliance && node.nsr_compliance.last_audit) {
      const daysSinceAudit = (Date.now() - new Date(node.nsr_compliance.last_audit)) / 86400000;
      if (daysSinceAudit > 30) complianceScore -= 15;
      if (daysSinceAudit > 90) complianceScore -= 25;
    }

    // Check resource allocation fairness (NSR equity principle)
    if (node.resource_allocation && node.resource_allocation.optimization_mode !== 'equity') {
      const priorities = [
        node.resource_allocation.energy_priority || 50,
        node.resource_allocation.water_priority || 50,
        node.resource_allocation.cooling_priority || 50
      ];
      const variance = this.calculateVariance(priorities);
      if (variance > 500) complianceScore -= 10; // Highly unbalanced allocation
    }

    return Math.max(0, Math.min(100, complianceScore));
  }

  /**
   * Generate AI recommendation based on analysis
   * @param {Object} analysis - Analysis results
   * @returns {String} Recommendation text
   */
  generateRecommendation(analysis) {
    const recommendations = [];

    if (analysis.climateRiskScore > 75) {
      recommendations.push('URGENT: High climate risk detected. Activate emergency cooling and increase resource allocation.');
    } else if (analysis.climateRiskScore > 50) {
      recommendations.push('Moderate climate risk. Consider increasing monitoring frequency and resource reserves.');
    }

    if (analysis.anomalyProbability > 0.7) {
      recommendations.push('Anomaly detected. Recommend immediate sensor calibration and manual inspection.');
    }

    if (analysis.nsrCompliance < 80) {
      recommendations.push('NSR compliance below threshold. Schedule audit and address outstanding violations.');
    }

    const forecast = analysis.resourceForecast;
    if (forecast.next_24h > forecast.next_7d / 7 * 1.5) {
      recommendations.push('Resource demand spike predicted. Optimize distribution and prepare reserves.');
    }

    return recommendations.length > 0 
      ? recommendations.join(' ') 
      : 'All systems nominal. Continue standard monitoring protocol.';
  }

  /**
   * Check for alert conditions and create alerts
   * @param {String} nodeId - Node identifier
   * @param {Object} analysis - Analysis results
   */
  checkAlerts(nodeId, analysis) {
    const node = this.nodes.get(nodeId);
    const alerts = [];

    if (analysis.climateRiskScore >= this.alertThresholds.climateRisk) {
      alerts.push({
        type: 'CLIMATE_RISK',
        severity: 'high',
        message: `Climate risk score ${analysis.climateRiskScore} exceeds threshold`,
        timestamp: new Date().toISOString()
      });
    }

    if (analysis.anomalyProbability >= this.alertThresholds.anomalyProbability) {
      alerts.push({
        type: 'ANOMALY_DETECTED',
        severity: 'medium',
        message: `Anomaly probability ${analysis.anomalyProbability.toFixed(2)} detected`,
        timestamp: new Date().toISOString()
      });
    }

    if (analysis.nsrCompliance < this.alertThresholds.nsrCompliance) {
      alerts.push({
        type: 'NSR_COMPLIANCE',
        severity: 'high',
        message: `NSR compliance score ${analysis.nsrCompliance} below threshold`,
        timestamp: new Date().toISOString()
      });
    }

    if (alerts.length > 0) {
      node.metrics.alerts.push(...alerts);
      // Keep only last 100 alerts
      if (node.metrics.alerts.length > 100) {
        node.metrics.alerts = node.metrics.alerts.slice(-100);
      }
    }
  }

  /**
   * Get current status of a node
   * @param {String} nodeId - Node identifier
   * @returns {Object} Node status and metrics
   */
  getNodeStatus(nodeId) {
    const node = this.nodes.get(nodeId);
    if (!node) {
      throw new Error(`Node ${nodeId} not found`);
    }

    return {
      node_id: node.node_id,
      status: node.status,
      location: node.location,
      nsr_compliance: node.nsr_compliance,
      predictive_metrics: node.predictive_metrics,
      recent_alerts: node.metrics.alerts.slice(-10),
      last_reading: node.metrics.readings.slice(-1)[0]
    };
  }

  /**
   * Get summary of all monitored nodes
   * @returns {Array} Summary of all nodes
   */
  getAllNodesSummary() {
    const summary = [];
    
    for (const [nodeId, node] of this.nodes) {
      summary.push({
        node_id: nodeId,
        status: node.status,
        location: {
          city: node.location.city,
          country: node.location.country
        },
        climate_risk: node.predictive_metrics?.climate_risk_score || 0,
        nsr_compliant: node.nsr_compliance?.compliant || false,
        active_alerts: node.metrics.alerts.filter(a => {
          const alertAge = Date.now() - new Date(a.timestamp).getTime();
          return alertAge < 3600000; // Last hour
        }).length
      });
    }

    return summary;
  }

  // Helper methods

  calculateVariance(values) {
    if (values.length === 0) return 0;
    const mean = values.reduce((a, b) => a + b) / values.length;
    return values.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0) / values.length;
  }

  calculateTrend(readings) {
    if (readings.length < 2) return 0;
    
    // Simple linear regression slope
    const n = readings.length;
    let sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    
    readings.forEach((reading, i) => {
      const y = reading.temperature || reading.air_quality_index || 0;
      sumX += i;
      sumY += y;
      sumXY += i * y;
      sumX2 += i * i;
    });
    
    return (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  }

  estimateCurrentDemand(readings) {
    if (readings.length === 0) return 0;
    
    const recent = readings.slice(-10);
    const factors = [];
    
    // Demand based on temperature
    recent.forEach(r => {
      if (r.temperature) factors.push(Math.max(0, r.temperature - 20) * 2);
      if (r.air_quality_index) factors.push(r.air_quality_index / 10);
      if (r.energy_consumption) factors.push(r.energy_consumption);
    });
    
    return factors.length > 0 
      ? factors.reduce((a, b) => a + b) / factors.length 
      : 50;
  }
}

module.exports = KlimabaumMonitor;
