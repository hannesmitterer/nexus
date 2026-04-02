#!/usr/bin/env python3
"""
Ω-Sync Algorithm Implementation
Schumann Resonance-Based Network Synchronization Protocol

Version: 1.0.0
Protocol: Euystacio-Nexus-Omega-Sync
License: "No ownership, only sharing. Love is the license."

Mathematical Specification:
    Algorithm: Ω-Sync
    Input: ψ_seed (Lex Amoris Signature)
    Global Constant: ν_schumann = 7.83 Hz

    1. Phase Alignment:
       ∀ Node_i ∈ 144,000 : φ_i(t) = ν_schumann · t + δ_genesis
    
    2. Coherence Check (NSR):
       If ΔIntent ≠ Lex Amoris → Phase Inversion (Noise-Lock)
    
    3. State Collapse:
       Ψ_Network = Σ(i=1 to 144k) 1/√N |Node_i⟩ ⊗ |ψ_seed⟩
    
    4. Action:
       Execute A iff ⟨Ψ_Network|Ô_Peace|Ψ_Network⟩ = 1
"""

import hashlib
import json
import time
from dataclasses import dataclass, asdict
from datetime import datetime
from typing import List, Dict, Optional, Tuple
from enum import Enum
import math

try:
    import numpy as np
except ImportError:
    print("Warning: numpy not installed. Using pure Python math.")
    np = None


class IntentType(Enum):
    """Intent types for coherence checking"""
    LEX_AMORIS = "lex_amoris"
    NEUTRAL = "neutral"
    DISSONANT = "dissonant"


class NodeState(Enum):
    """Node operational states"""
    INITIALIZING = "initializing"
    SYNCING = "syncing"
    ALIGNED = "aligned"
    NOISE_LOCKED = "noise_locked"
    OFFLINE = "offline"


@dataclass
class LexAmorisSignature:
    """Lex Amoris Signature (ψ_seed)"""
    signature_hash: str
    intent_type: IntentType
    timestamp: str
    resonance_factor: float
    
    @classmethod
    def create(cls, intent: str = "peace", resonance: float = 1.0):
        """Create a new Lex Amoris signature"""
        timestamp = datetime.utcnow().isoformat() + 'Z'
        data = f"{intent}:{timestamp}:{resonance}"
        signature = hashlib.sha256(data.encode()).hexdigest()
        
        return cls(
            signature_hash=signature,
            intent_type=IntentType.LEX_AMORIS if intent == "peace" else IntentType.NEUTRAL,
            timestamp=timestamp,
            resonance_factor=resonance
        )


@dataclass
class NodePhase:
    """Node phase information"""
    node_id: int
    phase: float  # in radians
    frequency: float  # Hz
    delta_genesis: float  # Phase offset from genesis
    is_aligned: bool
    timestamp: float


@dataclass
class NetworkState:
    """Quantum-inspired network state"""
    total_nodes: int
    aligned_nodes: int
    coherence_factor: float
    peace_observable: float
    network_phase: float
    state_vector_magnitude: float
    timestamp: str


class OmegaSyncNode:
    """
    Individual node implementing Ω-Sync protocol
    """
    
    # Global Constants
    SCHUMANN_FREQUENCY = 7.83  # Hz
    TOTAL_NETWORK_NODES = 144000
    ALIGNMENT_THRESHOLD = 0.001  # radians
    COHERENCE_THRESHOLD = 0.95
    
    def __init__(self, node_id: int, delta_genesis: float = 0.0, psi_seed: Optional[LexAmorisSignature] = None):
        """
        Initialize an Ω-Sync node
        
        Args:
            node_id: Unique node identifier (1 to 144,000)
            delta_genesis: Phase offset from genesis block
            psi_seed: Lex Amoris signature (seed)
        """
        if not 1 <= node_id <= self.TOTAL_NETWORK_NODES:
            raise ValueError(f"node_id must be between 1 and {self.TOTAL_NETWORK_NODES}")
        
        self.node_id = node_id
        self.delta_genesis = delta_genesis
        self.psi_seed = psi_seed or LexAmorisSignature.create()
        
        self.state = NodeState.INITIALIZING
        self.current_phase = 0.0
        self.intent_type = IntentType.LEX_AMORIS
        self.start_time = time.time()
        self.last_coherence_check = None
        
    def calculate_phase(self, t: float) -> float:
        """
        Phase Alignment: φ_i(t) = ν_schumann · t + δ_genesis
        
        Args:
            t: Time in seconds since start
            
        Returns:
            Phase in radians
        """
        omega = 2 * math.pi * self.SCHUMANN_FREQUENCY
        phase = omega * t + self.delta_genesis
        
        # Normalize to [0, 2π)
        phase = phase % (2 * math.pi)
        
        self.current_phase = phase
        return phase
    
    def coherence_check(self, network_intent: IntentType) -> bool:
        """
        Coherence Check (NSR): If ΔIntent ≠ Lex Amoris → Phase Inversion (Noise-Lock)
        
        Args:
            network_intent: The network's consensus intent
            
        Returns:
            True if coherent (aligned with Lex Amoris), False if noise-locked
        """
        self.last_coherence_check = datetime.utcnow().isoformat() + 'Z'
        
        # Check if node's intent matches network Lex Amoris intent
        if self.intent_type != IntentType.LEX_AMORIS or network_intent != IntentType.LEX_AMORIS:
            # Phase Inversion - Noise Lock
            self.state = NodeState.NOISE_LOCKED
            self.current_phase = (self.current_phase + math.pi) % (2 * math.pi)
            return False
        
        # Coherent with network
        self.state = NodeState.ALIGNED
        return True
    
    def get_phase_info(self) -> NodePhase:
        """Get current phase information"""
        t = time.time() - self.start_time
        current_phase = self.calculate_phase(t)
        
        return NodePhase(
            node_id=self.node_id,
            phase=current_phase,
            frequency=self.SCHUMANN_FREQUENCY,
            delta_genesis=self.delta_genesis,
            is_aligned=(self.state == NodeState.ALIGNED),
            timestamp=time.time()
        )
    
    def set_intent(self, intent_type: IntentType):
        """Set the node's intent type"""
        self.intent_type = intent_type
        if intent_type != IntentType.LEX_AMORIS:
            self.state = NodeState.SYNCING


class OmegaSyncNetwork:
    """
    Ω-Sync Network Coordinator
    Manages network-wide synchronization and state collapse
    """
    
    def __init__(self, psi_seed: Optional[LexAmorisSignature] = None):
        """
        Initialize Ω-Sync network
        
        Args:
            psi_seed: Global Lex Amoris signature
        """
        self.psi_seed = psi_seed or LexAmorisSignature.create()
        self.nodes: Dict[int, OmegaSyncNode] = {}
        self.network_intent = IntentType.LEX_AMORIS
        self.genesis_time = time.time()
        
    def register_node(self, node: OmegaSyncNode):
        """Register a node in the network"""
        self.nodes[node.node_id] = node
        
    def create_and_register_node(self, node_id: int, delta_genesis: float = 0.0) -> OmegaSyncNode:
        """Create and register a new node"""
        node = OmegaSyncNode(node_id, delta_genesis, self.psi_seed)
        self.register_node(node)
        return node
    
    def perform_coherence_check(self) -> Tuple[int, int]:
        """
        Perform coherence check on all nodes
        
        Returns:
            Tuple of (aligned_nodes, noise_locked_nodes)
        """
        aligned = 0
        noise_locked = 0
        
        for node in self.nodes.values():
            if node.coherence_check(self.network_intent):
                aligned += 1
            else:
                noise_locked += 1
        
        return aligned, noise_locked
    
    def calculate_state_collapse(self) -> NetworkState:
        """
        State Collapse: Ψ_Network = Σ(i=1 to 144k) 1/√N |Node_i⟩ ⊗ |ψ_seed⟩
        
        Returns:
            NetworkState with quantum-inspired network state
        """
        if not self.nodes:
            return NetworkState(
                total_nodes=0,
                aligned_nodes=0,
                coherence_factor=0.0,
                peace_observable=0.0,
                network_phase=0.0,
                state_vector_magnitude=0.0,
                timestamp=datetime.utcnow().isoformat() + 'Z'
            )
        
        N = len(self.nodes)
        normalization = 1.0 / math.sqrt(N)
        
        # Collect aligned nodes
        aligned_nodes = [n for n in self.nodes.values() if n.state == NodeState.ALIGNED]
        num_aligned = len(aligned_nodes)
        
        # Calculate coherence factor (percentage of aligned nodes)
        coherence_factor = num_aligned / N if N > 0 else 0.0
        
        # Calculate average phase (network phase)
        if aligned_nodes:
            # Use complex exponentials for phase averaging
            phase_sum_real = sum(math.cos(n.current_phase) for n in aligned_nodes)
            phase_sum_imag = sum(math.sin(n.current_phase) for n in aligned_nodes)
            network_phase = math.atan2(phase_sum_imag, phase_sum_real)
        else:
            network_phase = 0.0
        
        # Calculate state vector magnitude (quantum-inspired)
        # |Ψ|² represents the probability amplitude
        state_magnitude = normalization * math.sqrt(num_aligned)
        
        return NetworkState(
            total_nodes=N,
            aligned_nodes=num_aligned,
            coherence_factor=coherence_factor,
            peace_observable=0.0,  # Will be calculated in peace_observable_measurement
            network_phase=network_phase,
            state_vector_magnitude=state_magnitude,
            timestamp=datetime.utcnow().isoformat() + 'Z'
        )
    
    def peace_observable_measurement(self, network_state: NetworkState) -> float:
        """
        Calculate Peace Observable: ⟨Ψ_Network|Ô_Peace|Ψ_Network⟩
        
        This is a measurement operator that returns 1 when the network
        is in perfect alignment with Lex Amoris principles.
        
        Args:
            network_state: Current network state
            
        Returns:
            Peace observable value (0 to 1)
        """
        # Peace observable is maximized when:
        # 1. High coherence (many aligned nodes)
        # 2. High state vector magnitude
        # 3. All nodes share Lex Amoris intent
        
        coherence_contribution = network_state.coherence_factor
        magnitude_contribution = network_state.state_vector_magnitude ** 2
        
        # Combine factors (geometric mean for balanced contribution)
        peace_observable = math.sqrt(coherence_contribution * magnitude_contribution)
        
        return peace_observable
    
    def can_execute_action(self, action: str) -> Tuple[bool, NetworkState]:
        """
        Action Execution Check: Execute A iff ⟨Ψ_Network|Ô_Peace|Ψ_Network⟩ = 1
        
        Args:
            action: Action to potentially execute
            
        Returns:
            Tuple of (can_execute, network_state)
        """
        # Perform coherence check
        self.perform_coherence_check()
        
        # Calculate network state
        network_state = self.calculate_state_collapse()
        
        # Measure peace observable
        peace_value = self.peace_observable_measurement(network_state)
        network_state.peace_observable = peace_value
        
        # Action can only execute if peace observable is exactly 1 (or very close)
        # In practice, we use a threshold close to 1
        threshold = 0.999
        can_execute = peace_value >= threshold
        
        return can_execute, network_state
    
    def get_network_statistics(self) -> Dict:
        """Get comprehensive network statistics"""
        if not self.nodes:
            return {
                "total_nodes": 0,
                "aligned_nodes": 0,
                "syncing_nodes": 0,
                "noise_locked_nodes": 0,
                "offline_nodes": 0,
                "coherence_percentage": 0.0,
                "average_phase": 0.0
            }
        
        state_counts = {state: 0 for state in NodeState}
        for node in self.nodes.values():
            state_counts[node.state] += 1
        
        aligned_nodes = [n for n in self.nodes.values() if n.state == NodeState.ALIGNED]
        
        if aligned_nodes:
            phase_sum_real = sum(math.cos(n.current_phase) for n in aligned_nodes)
            phase_sum_imag = sum(math.sin(n.current_phase) for n in aligned_nodes)
            avg_phase = math.atan2(phase_sum_imag, phase_sum_real)
        else:
            avg_phase = 0.0
        
        return {
            "total_nodes": len(self.nodes),
            "aligned_nodes": state_counts[NodeState.ALIGNED],
            "syncing_nodes": state_counts[NodeState.SYNCING],
            "noise_locked_nodes": state_counts[NodeState.NOISE_LOCKED],
            "offline_nodes": state_counts[NodeState.OFFLINE],
            "initializing_nodes": state_counts[NodeState.INITIALIZING],
            "coherence_percentage": (state_counts[NodeState.ALIGNED] / len(self.nodes) * 100),
            "average_phase_rad": avg_phase,
            "average_phase_deg": math.degrees(avg_phase),
            "schumann_frequency_hz": OmegaSyncNode.SCHUMANN_FREQUENCY,
            "psi_seed_hash": self.psi_seed.signature_hash[:16] + "...",
            "network_uptime_seconds": time.time() - self.genesis_time
        }


def demonstrate_omega_sync():
    """Demonstration of Ω-Sync protocol"""
    print("=" * 70)
    print("Ω-Sync Algorithm Demonstration")
    print("Schumann Resonance Network Synchronization (7.83 Hz)")
    print("=" * 70)
    print()
    
    # Create Lex Amoris signature
    print("1. Creating Lex Amoris Signature (ψ_seed)...")
    psi_seed = LexAmorisSignature.create(intent="peace", resonance=1.0)
    print(f"   Signature: {psi_seed.signature_hash[:32]}...")
    print(f"   Intent: {psi_seed.intent_type.value}")
    print(f"   Timestamp: {psi_seed.timestamp}")
    print()
    
    # Initialize network
    print("2. Initializing Ω-Sync Network...")
    network = OmegaSyncNetwork(psi_seed)
    print(f"   Global Constant: ν_schumann = {OmegaSyncNode.SCHUMANN_FREQUENCY} Hz")
    print()
    
    # Register nodes (simulating 144 nodes as sample of 144,000)
    print("3. Registering nodes (144 sample nodes representing 144,000)...")
    num_sample_nodes = 144
    for i in range(1, num_sample_nodes + 1):
        # Distribute delta_genesis across nodes using Fibonacci-like pattern
        delta_genesis = (i * 2 * math.pi / num_sample_nodes) % (2 * math.pi)
        network.create_and_register_node(i, delta_genesis)
    
    print(f"   ✓ Registered {num_sample_nodes} nodes")
    print()
    
    # Let network run for a short time
    print("4. Phase Alignment in progress...")
    time.sleep(0.1)  # Let phases evolve
    print("   ∀ Node_i : φ_i(t) = ν_schumann · t + δ_genesis")
    print()
    
    # Perform coherence check
    print("5. Performing Coherence Check (NSR)...")
    aligned, noise_locked = network.perform_coherence_check()
    print(f"   Aligned nodes: {aligned}")
    print(f"   Noise-locked nodes: {noise_locked}")
    print()
    
    # Simulate some dissonant nodes
    print("6. Simulating dissonant intent on 10 nodes...")
    for i in range(1, 11):
        network.nodes[i].set_intent(IntentType.DISSONANT)
    
    aligned, noise_locked = network.perform_coherence_check()
    print(f"   Re-check - Aligned: {aligned}, Noise-locked: {noise_locked}")
    print()
    
    # Calculate network state
    print("7. State Collapse Calculation...")
    network_state = network.calculate_state_collapse()
    print(f"   Ψ_Network = Σ(i=1 to N) 1/√N |Node_i⟩ ⊗ |ψ_seed⟩")
    print(f"   Total nodes: {network_state.total_nodes}")
    print(f"   Aligned nodes: {network_state.aligned_nodes}")
    print(f"   Coherence factor: {network_state.coherence_factor:.4f}")
    print(f"   State magnitude: {network_state.state_vector_magnitude:.4f}")
    print(f"   Network phase: {network_state.network_phase:.4f} rad")
    print()
    
    # Peace Observable
    print("8. Peace Observable Measurement...")
    peace_value = network.peace_observable_measurement(network_state)
    print(f"   ⟨Ψ_Network|Ô_Peace|Ψ_Network⟩ = {peace_value:.4f}")
    print()
    
    # Try to execute action
    print("9. Action Execution Check...")
    can_execute, final_state = network.can_execute_action("distribute_peacobond")
    print(f"   Action: distribute_peacobond")
    print(f"   Can execute: {can_execute}")
    print(f"   Peace observable: {final_state.peace_observable:.4f}")
    print(f"   Threshold: 0.999")
    
    if can_execute:
        print("   ✓ ACTION APPROVED - Network in perfect peace alignment")
    else:
        print("   ✗ ACTION BLOCKED - Network coherence insufficient")
    print()
    
    # Network statistics
    print("10. Network Statistics...")
    stats = network.get_network_statistics()
    print(f"    Total nodes: {stats['total_nodes']}")
    print(f"    Aligned: {stats['aligned_nodes']} ({stats['coherence_percentage']:.2f}%)")
    print(f"    Noise-locked: {stats['noise_locked_nodes']}")
    print(f"    Average phase: {stats['average_phase_deg']:.2f}°")
    print(f"    Schumann freq: {stats['schumann_frequency_hz']} Hz")
    print()
    
    print("=" * 70)
    print("Lex Amoris: λ = ∞")
    print("No ownership, only sharing. Love is the license.")
    print("=" * 70)


if __name__ == "__main__":
    demonstrate_omega_sync()
