#!/usr/bin/env python3
"""
Integrated Validation System
Combines Ω-Sync Coherence Checking with RESPECT-FILTER Internal Audit

Version: 1.0.0
Date: 2026-04-03
License: "No ownership, only sharing. Love is the license."

Architecture:
    Network Layer (Ω-Sync)
           ↓
    Action Layer (RESPECT-FILTER)  
           ↓
    Execution

This module demonstrates the integration of:
1. Ω-Sync: Network-wide consensus and coherence
2. RESPECT-FILTER: Action-level Lex Amoris validation
"""

import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from scripts.omega_sync import OmegaSyncNetwork, LexAmorisSignature as OmegaLexAmoris, IntentType
from scripts.respect_filter import RESPECTFilter, IntentionVector, ValidationResult
from datetime import datetime
from typing import Tuple, Dict, Any


class IntegratedValidator:
    """
    Integrated validation combining network consensus and action validation
    
    Two-layer validation:
    1. Ω-Sync: Check network consensus alignment (99.9% peace threshold)
    2. RESPECT-FILTER: Validate specific action against Lex Amoris axioms
    """
    
    def __init__(self, omega_network: OmegaSyncNetwork, respect_filter: RESPECTFilter):
        """Initialize integrated validator"""
        self.omega_network = omega_network
        self.respect_filter = respect_filter
        self.validation_count = 0
        
        print("🔗 Integrated Validator initialized")
        print(f"   Network nodes: {len(self.omega_network.nodes)}")
        print(f"   RESPECT-FILTER version: {self.respect_filter.version}")
    
    def validate_action(
        self,
        action: str,
        intention: str,
        context: Dict[str, Any],
        actor: str
    ) -> Tuple[bool, str, Dict[str, Any]]:
        """
        Complete validation pipeline
        
        Args:
            action: The action to be taken
            intention: The stated intention/purpose
            context: Additional context data
            actor: The actor proposing the action
            
        Returns:
            (can_execute, reason, details)
        """
        self.validation_count += 1
        
        print(f"\n{'='*70}")
        print(f"Integrated Validation #{self.validation_count}")
        print(f"{'='*70}")
        print(f"Action: {action}")
        print(f"Actor: {actor}")
        print(f"{'='*70}\n")
        
        # Step 1: Network Consensus Check (Ω-Sync)
        print("🌀 Step 1: Ω-Sync Network Consensus Check...")
        can_execute_network, network_state = self.omega_network.can_execute_action(action)
        
        print(f"   Network Coherence: {network_state.coherence_factor*100:.2f}%")
        print(f"   Peace Observable: {network_state.peace_observable*100:.2f}%")
        print(f"   Aligned Nodes: {network_state.aligned_nodes}/{network_state.total_nodes}")
        
        if not can_execute_network:
            reason = f"Network consensus insufficient: {network_state.peace_observable*100:.2f}% (requires 99.9%)"
            print(f"   ✗ BLOCKED: {reason}\n")
            return False, reason, {
                "layer": "omega_sync",
                "network_state": network_state.__dict__,
                "respect_filter": None
            }
        
        print(f"   ✓ Network consensus achieved\n")
        
        # Step 2: Action-Level Validation (RESPECT-FILTER)
        print("🛡️ Step 2: RESPECT-FILTER Action Validation...")
        
        intention_vector = IntentionVector(
            action=action,
            intention=intention,
            context=context,
            timestamp=datetime.utcnow().isoformat() + 'Z',
            actor=actor
        )
        
        validation_report = self.respect_filter.validate_intention(intention_vector)
        
        print(f"   Result: {validation_report.result.value.upper()}")
        print(f"   Overall Distance: {validation_report.overall_distance:.4f}")
        
        # Check for gaps
        if validation_report.gap_signals:
            print(f"   ⚠ Gap Signals: {len(validation_report.gap_signals)}")
            for gap in validation_report.gap_signals:
                print(f"      • {gap}")
        
        # Determine if action can proceed
        if validation_report.result in [ValidationResult.RESONANT, ValidationResult.ACCEPTABLE]:
            print(f"   ✓ Action validated\n")
            reason = f"Validated: Network consensus + RESPECT-FILTER {validation_report.result.value}"
            can_execute = True
        elif validation_report.result == ValidationResult.QUESTIONABLE:
            print(f"   ⚠ REQUIRES REVIEW\n")
            reason = f"Questionable: Distance {validation_report.overall_distance:.4f} requires stakeholder review"
            can_execute = False
        else:  # DISSONANT or GAP_DETECTED
            print(f"   ✗ BLOCKED\n")
            reason = f"Blocked: {validation_report.result.value} - Lex Amoris violation"
            can_execute = False
        
        # Compile details
        details = {
            "layer": "integrated",
            "network_state": {
                "coherence_factor": network_state.coherence_factor,
                "peace_observable": network_state.peace_observable,
                "aligned_nodes": network_state.aligned_nodes,
                "total_nodes": network_state.total_nodes
            },
            "respect_filter": {
                "result": validation_report.result.value,
                "overall_distance": validation_report.overall_distance,
                "gap_signals": validation_report.gap_signals,
                "axiom_count": len(validation_report.axiom_distances)
            }
        }
        
        print(f"{'='*70}")
        print(f"Final Decision: {'✓ PROCEED' if can_execute else '✗ BLOCKED'}")
        print(f"Reason: {reason}")
        print(f"{'='*70}\n")
        
        return can_execute, reason, details
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get combined statistics"""
        omega_stats = self.omega_network.get_network_statistics()
        respect_stats = self.respect_filter.get_statistics()
        
        return {
            "integrated": {
                "total_validations": self.validation_count
            },
            "omega_sync": omega_stats,
            "respect_filter": respect_stats
        }


def demonstrate_integration():
    """Demonstration of integrated validation system"""
    print("\n" + "="*70)
    print("INTEGRATED VALIDATION SYSTEM")
    print("Ω-Sync Network Consensus + RESPECT-FILTER Action Validation")
    print("="*70 + "\n")
    
    # Initialize Ω-Sync network
    print("1. Initializing Ω-Sync Network...")
    psi_seed = OmegaLexAmoris.create('peace', 1.0)
    omega_network = OmegaSyncNetwork(psi_seed)
    
    # Register nodes (simulate 144 for testing)
    print("   Registering 144 nodes...")
    for i in range(1, 145):
        import math
        delta_genesis = (i * 2 * math.pi / 144) % (2 * math.pi)
        omega_network.create_and_register_node(i, delta_genesis)
    
    print(f"   ✓ Network ready: {len(omega_network.nodes)} nodes\n")
    
    # Initialize RESPECT-FILTER
    print("2. Initializing RESPECT-FILTER...")
    respect_filter = RESPECTFilter(enable_logging=False)
    print(f"   ✓ Filter ready\n")
    
    # Create integrated validator
    print("3. Creating Integrated Validator...")
    validator = IntegratedValidator(omega_network, respect_filter)
    print()
    
    # Test Case 1: Fully valid action
    print("="*70)
    print("TEST CASE 1: Peaceful Resource Distribution")
    print("="*70)
    
    can_execute, reason, details = validator.validate_action(
        action="distribute_peacobond",
        intention="Distribute resources transparently to all sovereign participants with voluntary consent and mutual benefit",
        context={
            "method": "voluntary_participation",
            "transparency": "full_disclosure",
            "consent": "explicit_opt_in",
            "distribution": "fair_and_equal"
        },
        actor="governance_council"
    )
    
    # Test Case 2: Action with NSR concern
    print("\n" + "="*70)
    print("TEST CASE 2: Mandatory Policy Implementation")
    print("="*70)
    
    # First make some nodes dissonant to affect network consensus
    for i in range(1, 11):
        omega_network.nodes[i].set_intent(IntentType.DISSONANT)
    
    can_execute2, reason2, details2 = validator.validate_action(
        action="implement_mandatory_policy",
        intention="Require all participants to comply with new policy without exception",
        context={
            "enforcement": "mandatory",
            "consent": "not_required",
            "justification": "for_the_greater_good"
        },
        actor="central_authority"
    )
    
    # Print statistics
    print("\n" + "="*70)
    print("VALIDATION STATISTICS")
    print("="*70)
    
    stats = validator.get_statistics()
    
    print(f"\nIntegrated:")
    print(f"  Total validations: {stats['integrated']['total_validations']}")
    
    print(f"\nΩ-Sync Network:")
    print(f"  Total nodes: {stats['omega_sync']['total_nodes']}")
    print(f"  Aligned: {stats['omega_sync']['aligned_nodes']}")
    print(f"  Noise-locked: {stats['omega_sync']['noise_locked_nodes']}")
    print(f"  Coherence: {stats['omega_sync']['coherence_percentage']:.2f}%")
    
    print(f"\nRESPECT-FILTER:")
    print(f"  Total validations: {stats['respect_filter']['total_validations']}")
    print(f"  Resonant: {stats['respect_filter']['resonant']}")
    print(f"  Acceptable: {stats['respect_filter']['acceptable']}")
    print(f"  Questionable: {stats['respect_filter']['questionable']}")
    print(f"  Dissonant: {stats['respect_filter']['dissonant']}")
    print(f"  Gap detections: {stats['respect_filter']['gap_detections']}")
    
    print("\n" + "="*70)
    print("Lex Amoris: λ = ∞")
    print("No ownership, only sharing. Love is the license.")
    print("="*70 + "\n")


if __name__ == "__main__":
    demonstrate_integration()
