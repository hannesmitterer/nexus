/**
 * Enhanced NSR (Non-Slavery Rule) Resource Optimization Algorithm
 * 
 * Optimizes urban resource distribution while maintaining NSR compliance.
 * Implements equity-based allocation, climate impact reduction, and predictive optimization.
 * 
 * @module NSROptimizer
 * @version 2.0.0
 * @framework Euystacio v1.0
 */

class NSRResourceOptimizer {
  constructor(config = {}) {
    this.equityWeight = config.equityWeight || 0.4;
    this.efficiencyWeight = config.efficiencyWeight || 0.3;
    this.climateWeight = config.climateWeight || 0.3;
    this.minEquityThreshold = config.minEquityThreshold || 0.7;
  }

  /**
   * Optimize resource allocation across multiple Klimabaum nodes
   * @param {Array} nodes - Array of node objects
   * @param {Object} availableResources - Total available resources
   * @returns {Object} Optimized allocation plan
   */
  optimizeDistribution(nodes, availableResources) {
    if (!nodes || nodes.length === 0) {
      throw new Error('No nodes provided for optimization');
    }

    // Calculate needs and priorities
    const nodePriorities = nodes.map(node => this.calculateNodePriority(node));
    
    // Apply NSR equity constraints
    const equityConstraints = this.calculateEquityConstraints(nodes);
    
    // Optimize allocation
    const allocation = this.allocateResources(
      nodes,
      nodePriorities,
      equityConstraints,
      availableResources
    );

    // Validate NSR compliance
    const compliance = this.validateNSRCompliance(allocation, equityConstraints);

    return {
      allocation,
      compliance,
      optimization_score: this.calculateOptimizationScore(allocation, nodes),
      equity_index: this.calculateEquityIndex(allocation),
      climate_impact_reduction: this.estimateClimateImpactReduction(allocation, nodes)
    };
  }

  /**
   * Calculate priority score for a node based on multiple factors
   * @param {Object} node - Node object
   * @returns {Object} Priority scores
   */
  calculateNodePriority(node) {
    // Climate urgency (higher risk = higher priority)
    const climateUrgency = (node.predictive_metrics?.climate_risk_score || 0) / 100;
    
    // Population density factor (from urban zone type)
    const populationFactor = this.getPopulationFactor(node.location?.urban_zone);
    
    // Resource efficiency (inverse of waste)
    const efficiency = this.estimateNodeEfficiency(node);
    
    // Vulnerability factor (disadvantaged areas get higher priority)
    const vulnerability = this.assessVulnerability(node);
    
    // Combined priority
    const overallPriority = 
      climateUrgency * this.climateWeight +
      vulnerability * this.equityWeight +
      efficiency * this.efficiencyWeight;

    return {
      climate_urgency: climateUrgency,
      population_factor: populationFactor,
      efficiency,
      vulnerability,
      overall_priority: overallPriority
    };
  }

  /**
   * Calculate equity constraints based on NSR principles
   * @param {Array} nodes - Array of nodes
   * @returns {Object} Equity constraints
   */
  calculateEquityConstraints(nodes) {
    const constraints = {
      min_allocation_per_capita: 0,
      max_allocation_ratio: 3.0, // Max allocation to one node vs min
      vulnerable_priority_multiplier: 1.5
    };

    // Calculate per-capita minimums
    const totalPopulation = nodes.reduce((sum, node) => 
      sum + this.estimatePopulation(node), 0
    );

    if (totalPopulation > 0) {
      constraints.min_allocation_per_capita = 1 / nodes.length;
    }

    return constraints;
  }

  /**
   * Allocate resources according to priorities and constraints
   * @param {Array} nodes - Array of nodes
   * @param {Array} priorities - Priority scores for each node
   * @param {Object} constraints - Equity constraints
   * @param {Object} resources - Available resources
   * @returns {Array} Allocation plan
   */
  allocateResources(nodes, priorities, constraints, resources) {
    const allocation = [];
    
    // Phase 1: Ensure minimum equity allocation
    const minAllocation = this.calculateMinimumAllocation(nodes, constraints, resources);
    
    // Phase 2: Distribute remaining resources by priority
    const remainingResources = this.subtractResources(resources, this.sumAllocations(minAllocation));
    
    // Calculate priority-based distribution
    const totalPriority = priorities.reduce((sum, p) => sum + p.overall_priority, 0);
    
    nodes.forEach((node, index) => {
      const priority = priorities[index];
      const baseAllocation = minAllocation[index];
      
      // Additional allocation based on priority
      const priorityShare = totalPriority > 0 
        ? priority.overall_priority / totalPriority 
        : 1 / nodes.length;
      
      const additionalAllocation = this.multiplyResources(remainingResources, priorityShare);
      
      allocation.push({
        node_id: node.node_id,
        location: node.location,
        energy: baseAllocation.energy + additionalAllocation.energy,
        water: baseAllocation.water + additionalAllocation.water,
        cooling: baseAllocation.cooling + additionalAllocation.cooling,
        priority_score: priority.overall_priority,
        equity_factor: priority.vulnerability,
        climate_factor: priority.climate_urgency,
        optimization_mode: this.determineOptimizationMode(priority)
      });
    });

    // Phase 3: Apply NSR equity caps
    return this.applyEquityCaps(allocation, constraints);
  }

  /**
   * Calculate minimum allocation ensuring equity
   * @param {Array} nodes - Array of nodes
   * @param {Object} constraints - Equity constraints
   * @param {Object} resources - Total resources
   * @returns {Array} Minimum allocations
   */
  calculateMinimumAllocation(nodes, constraints, resources) {
    const equityReserve = this.minEquityThreshold;
    const equityResources = this.multiplyResources(resources, equityReserve);
    const perNodeMin = this.divideResources(equityResources, nodes.length);
    
    return nodes.map(() => ({ ...perNodeMin }));
  }

  /**
   * Validate NSR compliance of allocation
   * @param {Array} allocation - Allocation plan
   * @param {Object} constraints - Equity constraints
   * @returns {Object} Compliance status
   */
  validateNSRCompliance(allocation, constraints) {
    const allocations = allocation.map(a => a.energy + a.water + a.cooling);
    const maxAllocation = Math.max(...allocations);
    const minAllocation = Math.min(...allocations);
    
    const ratio = minAllocation > 0 ? maxAllocation / minAllocation : Infinity;
    const equityViolation = ratio > constraints.max_allocation_ratio;
    
    // Check for exploitation (no node should receive zero resources)
    const zeroAllocations = allocations.filter(a => a === 0).length;
    
    return {
      compliant: !equityViolation && zeroAllocations === 0,
      equity_ratio: ratio,
      max_allowed_ratio: constraints.max_allocation_ratio,
      zero_allocations: zeroAllocations,
      violations: equityViolation ? ['Equity ratio exceeded'] : []
    };
  }

  /**
   * Calculate overall optimization score
   * @param {Array} allocation - Allocation plan
   * @param {Array} nodes - Original nodes
   * @returns {Number} Score 0-100
   */
  calculateOptimizationScore(allocation, nodes) {
    let score = 0;
    
    // Efficiency score: how well resources match predicted demand
    const efficiencyScore = this.calculateEfficiencyScore(allocation, nodes);
    
    // Equity score: how fair is the distribution
    const equityScore = this.calculateEquityIndex(allocation);
    
    // Climate impact score: how much climate risk is mitigated
    const climateScore = this.calculateClimateScore(allocation, nodes);
    
    score = 
      efficiencyScore * this.efficiencyWeight * 100 +
      equityScore * this.equityWeight * 100 +
      climateScore * this.climateWeight * 100;
    
    return Math.min(100, score);
  }

  /**
   * Calculate equity index (Gini coefficient inspired)
   * @param {Array} allocation - Allocation plan
   * @returns {Number} Equity index 0-1 (1 = perfect equity)
   */
  calculateEquityIndex(allocation) {
    const values = allocation.map(a => a.energy + a.water + a.cooling);
    if (values.length === 0) return 1;
    
    const n = values.length;
    const mean = values.reduce((a, b) => a + b) / n;
    
    if (mean === 0) return 1;
    
    // Calculate Gini coefficient
    let sumDiff = 0;
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < n; j++) {
        sumDiff += Math.abs(values[i] - values[j]);
      }
    }
    
    const gini = sumDiff / (2 * n * n * mean);
    return 1 - gini; // Convert to equity index
  }

  /**
   * Estimate climate impact reduction from allocation
   * @param {Array} allocation - Allocation plan
   * @param {Array} nodes - Original nodes
   * @returns {Number} Impact reduction percentage
   */
  estimateClimateImpactReduction(allocation, nodes) {
    let totalReduction = 0;
    
    allocation.forEach((alloc, index) => {
      const node = nodes[index];
      const climateRisk = node.predictive_metrics?.climate_risk_score || 0;
      
      // Higher allocation to high-risk areas reduces impact more
      const resourceLevel = alloc.energy + alloc.water + alloc.cooling;
      const reduction = (climateRisk / 100) * Math.min(1, resourceLevel / 100);
      
      totalReduction += reduction;
    });
    
    return (totalReduction / nodes.length) * 100;
  }

  /**
   * Apply equity caps to prevent excessive inequality
   * @param {Array} allocation - Initial allocation
   * @param {Object} constraints - Equity constraints
   * @returns {Array} Capped allocation
   */
  applyEquityCaps(allocation, constraints) {
    const values = allocation.map(a => a.energy + a.water + a.cooling);
    const minValue = Math.min(...values);
    const maxAllowed = minValue * constraints.max_allocation_ratio;
    
    return allocation.map(alloc => {
      const total = alloc.energy + alloc.water + alloc.cooling;
      
      if (total > maxAllowed) {
        const ratio = maxAllowed / total;
        return {
          ...alloc,
          energy: alloc.energy * ratio,
          water: alloc.water * ratio,
          cooling: alloc.cooling * ratio,
          capped: true
        };
      }
      
      return { ...alloc, capped: false };
    });
  }

  // Helper methods

  getPopulationFactor(urbanZone) {
    const factors = {
      'residential': 1.2,
      'commercial': 0.8,
      'industrial': 0.6,
      'park': 0.4,
      'mixed': 1.0
    };
    return factors[urbanZone] || 1.0;
  }

  estimateNodeEfficiency(node) {
    // Higher efficiency if node has good maintenance and low violations
    let efficiency = 1.0;
    
    if (node.nsr_compliance) {
      // Use 80 as conservative default if compliance_score is missing
      const complianceScore = node.nsr_compliance.compliance_score !== undefined 
        ? node.nsr_compliance.compliance_score 
        : 80;
      efficiency *= complianceScore / 100;
    }
    
    const daysSinceMaintenance = node.last_maintenance 
      ? (Date.now() - new Date(node.last_maintenance)) / 86400000 
      : 365;
    
    efficiency *= Math.max(0.5, 1 - daysSinceMaintenance / 365);
    
    return efficiency;
  }

  assessVulnerability(node) {
    let vulnerability = 0.5; // Base vulnerability
    
    // Higher vulnerability for areas with poor air quality
    const climateRisk = node.predictive_metrics?.climate_risk_score || 0;
    vulnerability += (climateRisk / 100) * 0.3;
    
    // NSR compliance issues indicate vulnerability
    if (node.nsr_compliance && !node.nsr_compliance.compliant) {
      vulnerability += 0.2;
    }
    
    return Math.min(1, vulnerability);
  }

  estimatePopulation(node) {
    const zonePop = {
      'residential': 1000,
      'commercial': 500,
      'industrial': 200,
      'park': 100,
      'mixed': 700
    };
    return zonePop[node.location?.urban_zone] || 500;
  }

  determineOptimizationMode(priority) {
    if (priority.climate_urgency > 0.8) return 'emergency';
    if (priority.vulnerability > 0.7) return 'equity';
    if (priority.efficiency > 0.8) return 'efficiency';
    return 'balanced';
  }

  calculateEfficiencyScore(allocation, nodes) {
    let matchScore = 0;
    
    allocation.forEach((alloc, index) => {
      const node = nodes[index];
      const demand = node.predictive_metrics?.resource_demand_forecast?.next_24h || 50;
      const supplied = alloc.energy + alloc.water + alloc.cooling;
      
      // Perfect match = 1, over/under supply reduces score
      const match = 1 - Math.abs(supplied - demand) / Math.max(supplied, demand);
      matchScore += Math.max(0, match);
    });
    
    return matchScore / allocation.length;
  }

  calculateClimateScore(allocation, nodes) {
    let score = 0;
    
    allocation.forEach((alloc, index) => {
      const node = nodes[index];
      const climateRisk = node.predictive_metrics?.climate_risk_score || 0;
      const resources = alloc.energy + alloc.water + alloc.cooling;
      
      // High resources to high-risk areas = better score
      if (climateRisk > 50) {
        score += (resources / 100) * (climateRisk / 100);
      }
    });
    
    return score / nodes.length;
  }

  // Resource arithmetic helpers

  multiplyResources(resources, factor) {
    return {
      energy: (resources.energy || 0) * factor,
      water: (resources.water || 0) * factor,
      cooling: (resources.cooling || 0) * factor
    };
  }

  divideResources(resources, divisor) {
    return {
      energy: (resources.energy || 0) / divisor,
      water: (resources.water || 0) / divisor,
      cooling: (resources.cooling || 0) / divisor
    };
  }

  subtractResources(r1, r2) {
    return {
      energy: Math.max(0, (r1.energy || 0) - (r2.energy || 0)),
      water: Math.max(0, (r1.water || 0) - (r2.water || 0)),
      cooling: Math.max(0, (r1.cooling || 0) - (r2.cooling || 0))
    };
  }

  sumAllocations(allocations) {
    return allocations.reduce((sum, alloc) => ({
      energy: (sum.energy || 0) + (alloc.energy || 0),
      water: (sum.water || 0) + (alloc.water || 0),
      cooling: (sum.cooling || 0) + (alloc.cooling || 0)
    }), { energy: 0, water: 0, cooling: 0 });
  }
}

module.exports = NSRResourceOptimizer;
