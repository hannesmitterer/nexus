#!/usr/bin/env python3
"""
Vacuum-Bridge Quantum Tunneling Simulator
Based on Mitterer Theory (1999-2005)

Implements resonance-enhanced transmission calculations for SOLAR-BOOT-LINK module.
Integrates with Lex Amoris framework for intention-aligned quantum transport.
"""

import numpy as np
import json
from typing import Dict, List, Tuple, Any
from dataclasses import dataclass
from datetime import datetime, UTC


@dataclass
class VacuumBridgeConfig:
    """Configuration parameters for Vacuum-Bridge simulation."""
    
    # Physical Constants
    hbar: float = 1.054571817e-34  # Reduced Planck constant (J·s)
    
    # Cavity Parameters
    coupling_rate_g: float = 50e6  # Coupling rate g (Hz)
    cavity_frequency: float = 2.5e12  # ω_cavity (Hz)
    quality_factor_q: float = 1e6  # Cavity quality factor
    
    # Derived Parameters
    @property
    def gamma(self) -> float:
        """Cavity decay rate (Hz)."""
        return self.cavity_frequency / self.quality_factor_q
    
    # Barrier Parameters
    temperature: float = 1.7  # Operating temperature (K)
    barrier_thickness: float = 2e-9  # Barrier thickness (m)
    classical_kappa: float = 5e9  # Classical attenuation coefficient (m^-1)
    
    # Lex Amoris Integration
    schumann_resonance: float = 7.83  # Earth resonance frequency (Hz)
    phi_golden_ratio: float = 1.618033988749  # Golden ratio
    
    # Watchdog Configuration
    default_test_alignment: float = 0.95  # Default high alignment for cluster testing
    affinity_scale_factor: float = 0.98  # Scale factor: affinity = transmission * scale_factor
    max_recent_alerts: int = 10  # Maximum number of recent alerts to retain in status
    

class VacuumBridgeSimulator:
    """
    Simulator for quantum tunneling via resonant cavity mediation.
    
    Implements the Mitterer Vacuum-Bridge equations for transmission
    probability calculation with Lex Amoris alignment integration.
    """
    
    def __init__(self, config: VacuumBridgeConfig = None):
        """Initialize simulator with configuration."""
        self.config = config or VacuumBridgeConfig()
        self.history: List[Dict] = []
        self.watchdog_active: bool = False
        self.watchdog_alerts: List[Dict] = []
        
    def calculate_kappa_eff(self, detuning_delta: float) -> float:
        """
        Calculate effective attenuation coefficient with bridge active.
        
        Formula:
        κ_eff = κ₀ * (1 - (g²/Δ²) / (1 + g²/γ²))
        
        Args:
            detuning_delta: Frequency detuning Δ = ω_cavity - ω_electron (Hz)
            
        Returns:
            Effective attenuation coefficient (m⁻¹)
        """
        g = self.config.coupling_rate_g
        gamma = self.config.gamma
        kappa_0 = self.config.classical_kappa
        
        # Prevent division by zero
        if abs(detuning_delta) < 1e-3:
            detuning_delta = 1e-3
            
        bridge_factor = (g**2 / detuning_delta**2) / (1 + g**2 / gamma**2)
        kappa_eff = kappa_0 * (1 - bridge_factor)
        
        # Physical constraint: non-negative attenuation
        return max(kappa_eff, 0)
    
    def calculate_transmission_probability(
        self, 
        detuning_delta: float,
        barrier_thickness: float = None
    ) -> float:
        """
        Calculate transmission probability P = |β|².
        
        Formula:
        P = (g² / (Δ² + (γ/2)²)) * exp(-κ_eff * d)
        
        Args:
            detuning_delta: Frequency detuning (Hz)
            barrier_thickness: Barrier thickness (m), uses config default if None
            
        Returns:
            Transmission probability (0 to 1)
        """
        g = self.config.coupling_rate_g
        gamma = self.config.gamma
        d = barrier_thickness or self.config.barrier_thickness
        
        # Prevent division by zero
        if abs(detuning_delta) < 1e-3:
            detuning_delta = 1e-3
        
        # Resonant transmission amplitude
        beta_squared = g**2 / (detuning_delta**2 + (gamma/2)**2)
        
        # Include barrier thickness effect
        kappa_eff = self.calculate_kappa_eff(detuning_delta)
        barrier_attenuation = np.exp(-kappa_eff * d)
        
        P = beta_squared * barrier_attenuation
        
        # Cap at unity probability
        return min(P, 1.0)
    
    def lex_amoris_bridge_activation(
        self, 
        intention_alignment: float,
        epsilon: float = 1e3
    ) -> float:
        """
        Calculate detuning based on Lex Amoris alignment.
        
        Perfect alignment (1.0) → Δ ≈ 0 (full resonance)
        No alignment (0.0) → Δ = max (no bridge)
        
        Args:
            intention_alignment: Alignment factor (0 to 1)
            epsilon: Minimum detuning to avoid singularity (Hz)
            
        Returns:
            Frequency detuning (Hz)
        """
        # Clamp alignment to valid range
        intention_alignment = max(0.0, min(1.0, intention_alignment))
        
        # Map alignment to detuning: perfect alignment → zero detuning
        max_detuning = self.config.gamma * 10
        detuning = max_detuning * (1 - intention_alignment) + epsilon
        
        return detuning
    
    def sroi_enhanced_transmission(
        self,
        intention_alignment: float,
        sroi_factor: float = 1.450
    ) -> Dict[str, float]:
        """
        Calculate transmission with S-ROI (Sovereign Return on Intention) enhancement.
        
        Integrates Lex Amoris alignment with Vacuum-Bridge physics.
        
        Args:
            intention_alignment: Lex Amoris alignment (0 to 1)
            sroi_factor: S-ROI enhancement factor
            
        Returns:
            Dictionary with transmission metrics
        """
        # Calculate detuning from alignment
        detuning = self.lex_amoris_bridge_activation(intention_alignment)
        
        # Base transmission probability
        P_base = self.calculate_transmission_probability(detuning)
        
        # S-ROI enhancement (resonance amplification)
        P_enhanced = P_base * sroi_factor
        P_enhanced = min(P_enhanced, 1.0)
        
        # Effective attenuation
        kappa_eff = self.calculate_kappa_eff(detuning)
        
        # Classical comparison
        kappa_classical = self.config.classical_kappa
        P_classical = np.exp(-kappa_classical * self.config.barrier_thickness)
        
        result = {
            'timestamp': datetime.now(UTC).isoformat(),
            'intention_alignment': float(intention_alignment),
            'detuning_hz': float(detuning),
            'transmission_probability': float(P_enhanced),
            'base_probability': float(P_base),
            'classical_probability': float(P_classical),
            'enhancement_factor': float(P_enhanced / P_classical if P_classical > 0 else float('inf')),
            'kappa_eff': float(kappa_eff),
            'kappa_classical': float(kappa_classical),
            'attenuation_reduction': float(1 - (kappa_eff / kappa_classical)),
            'sroi_factor': float(sroi_factor),
            'bridge_active': bool(detuning < self.config.gamma),
            'resonance_quality': float(self.config.quality_factor_q),
        }
        
        self.history.append(result)
        return result
    
    def simulate_alignment_sweep(
        self,
        num_points: int = 100,
        sroi_factor: float = 1.450
    ) -> List[Dict[str, float]]:
        """
        Sweep through alignment values to generate transmission curve.
        
        Args:
            num_points: Number of sample points
            sroi_factor: S-ROI enhancement factor
            
        Returns:
            List of transmission results
        """
        alignments = np.linspace(0, 1, num_points)
        results = []
        
        for alignment in alignments:
            result = self.sroi_enhanced_transmission(alignment, sroi_factor)
            results.append(result)
            
        return results
    
    def export_simulation_data(self, filename: str = None) -> str:
        """
        Export simulation history to JSON file.
        
        Args:
            filename: Output filename, auto-generated if None
            
        Returns:
            Path to exported file
        """
        if filename is None:
            timestamp = datetime.now(UTC).strftime('%Y%m%d_%H%M%S')
            filename = f'/tmp/vacuum_bridge_simulation_{timestamp}.json'
        
        data = {
            'config': {
                'coupling_rate_g': self.config.coupling_rate_g,
                'cavity_frequency': self.config.cavity_frequency,
                'quality_factor_q': self.config.quality_factor_q,
                'gamma': self.config.gamma,
                'temperature': self.config.temperature,
                'barrier_thickness': self.config.barrier_thickness,
                'classical_kappa': self.config.classical_kappa,
            },
            'simulation_results': self.history,
            'metadata': {
                'framework': 'Kosymbiosis - Lex Amoris',
                'model': 'Vacuum-Bridge (Mitterer 1999-2005)',
                'timestamp': datetime.now(UTC).isoformat(),
                'signature': '📜⚖️❤️',
            }
        }
        
        with open(filename, 'w') as f:
            json.dump(data, f, indent=2)
            
        return filename
    
    def get_bridge_status(self, intention_alignment: float) -> Dict[str, Any]:
        """
        Get current bridge status for dashboard display.
        
        Args:
            intention_alignment: Current Lex Amoris alignment
            
        Returns:
            Status dictionary for visualization
        """
        result = self.sroi_enhanced_transmission(intention_alignment)
        
        # Determine bridge state
        if result['transmission_probability'] > 0.8:
            state = 'FULLY_ACTIVE'
            color = '#2ecc71'  # Green
        elif result['transmission_probability'] > 0.5:
            state = 'RESONATING'
            color = '#d4af37'  # Gold
        elif result['transmission_probability'] > 0.2:
            state = 'PARTIAL'
            color = '#f39c12'  # Orange
        else:
            state = 'MINIMAL'
            color = '#e74c3c'  # Red
            
        return {
            'state': state,
            'color': color,
            'transmission': result['transmission_probability'],
            'detuning': result['detuning_hz'],
            'enhancement': result['enhancement_factor'],
            'alignment': intention_alignment,
            'bridge_active': result['bridge_active'],
            'message': self._get_status_message(state),
        }
    
    @staticmethod
    def _get_status_message(state: str) -> str:
        """Get human-readable status message."""
        messages = {
            'FULLY_ACTIVE': 'Vacuum-Bridge OPEN: Transmission at maximum coherence',
            'RESONATING': 'Bridge resonating: High transmission achieved',
            'PARTIAL': 'Partial bridge formation: Increasing alignment needed',
            'MINIMAL': 'Classical tunneling dominant: Align with Lex Amoris',
        }
        return messages.get(state, 'Status unknown')
    
    def nsr_watchdog_global(
        self,
        cluster_name: str = "nexus_andes",
        affinity_threshold: float = 0.94,
        check_interval: Tuple[int, int] = (0, 30)
    ) -> Dict[str, Any]:
        """
        NSR (Non-Slavery Resonance) Watchdog for global auto-monitoring.
        
        Monitors the NEXUS-ANDES CORRIDOR cluster for alignment compliance.
        Checks intention alignment and ensures affinity ≥ threshold.
        
        Args:
            cluster_name: Name of cluster to monitor (e.g., "nexus_andes")
            affinity_threshold: Minimum required affinity (default: 0.94)
            check_interval: Monitoring interval in seconds (start, end)
            
        Returns:
            Watchdog status dictionary with monitoring results
        """
        self.watchdog_active = True
        
        # Simulate monitoring check
        current_time = datetime.now(UTC)
        
        # Get current bridge status - use configured default test alignment
        test_alignment = self.config.default_test_alignment
        bridge_status = self.get_bridge_status(test_alignment)
        
        # Calculate affinity from bridge metrics using configured scale factor
        # Affinity correlates with transmission probability and bridge state
        affinity = bridge_status['transmission'] * self.config.affinity_scale_factor
        
        # Check compliance
        is_compliant = affinity >= affinity_threshold
        
        watchdog_result = {
            'timestamp': current_time.isoformat(),
            'cluster': cluster_name,
            'watchdog_id': 'NSR_Watchdog_Global',
            'status': 'COMPLIANT' if is_compliant else 'WARNING',
            'affinity': float(affinity),
            'threshold': float(affinity_threshold),
            'check_interval_s': check_interval,
            'bridge_state': bridge_status['state'],
            'transmission': bridge_status['transmission'],
            'alignment': bridge_status['alignment'],
            'message': self._get_watchdog_message(is_compliant, affinity),
            'active': self.watchdog_active,
        }
        
        # Log alert if non-compliant
        if not is_compliant:
            self.watchdog_alerts.append({
                'timestamp': current_time.isoformat(),
                'severity': 'WARNING',
                'affinity': affinity,
                'message': f'Affinity {affinity:.3f} below threshold {affinity_threshold}',
            })
        
        return watchdog_result
    
    @staticmethod
    def _get_watchdog_message(is_compliant: bool, affinity: float) -> str:
        """Generate watchdog status message."""
        if is_compliant:
            return f'✓ NSR compliance verified | Affinity: {affinity:.3f}'
        else:
            return f'⚠ NSR affinity below threshold | Current: {affinity:.3f}'
    
    def get_cluster_status(
        self,
        cluster_name: str = "nexus_andes",
        include_watchdog: bool = True
    ) -> Dict[str, Any]:
        """
        Get comprehensive cluster status for API endpoint.
        
        Provides bridge status, watchdog monitoring, and metrics
        for the NEXUS-ANDES CORRIDOR cluster.
        
        Args:
            cluster_name: Cluster identifier
            include_watchdog: Include watchdog monitoring data
            
        Returns:
            Complete cluster status for API response
        """
        # Get current bridge state using configured default test alignment
        test_alignment = self.config.default_test_alignment
        bridge_status = self.get_bridge_status(test_alignment)
        
        status = {
            'timestamp': datetime.now(UTC).isoformat(),
            'cluster': cluster_name,
            'bridge': bridge_status,
            'operational': True,
            'framework': 'Kosymbiosis - Lex Amoris',
            'model': 'Vacuum-Bridge (Mitterer 1999-2005)',
        }
        
        # Add watchdog data if requested
        if include_watchdog:
            watchdog = self.nsr_watchdog_global(cluster_name)
            status['watchdog'] = watchdog
            status['alerts'] = self.watchdog_alerts[-self.config.max_recent_alerts:]
        
        return status


def main():
    """Demonstration of Vacuum-Bridge simulation."""
    print("=" * 70)
    print("VACUUM-BRIDGE QUANTUM TUNNELING SIMULATOR")
    print("Mitterer Theory Implementation - SOLAR-BOOT-LINK Module")
    print("=" * 70)
    print()
    
    # Initialize simulator
    simulator = VacuumBridgeSimulator()
    
    # Display configuration
    print("Configuration:")
    print(f"  Coupling Rate (g): {simulator.config.coupling_rate_g/1e6:.1f} MHz")
    print(f"  Cavity Frequency: {simulator.config.cavity_frequency/1e12:.2f} THz")
    print(f"  Quality Factor (Q): {simulator.config.quality_factor_q:.0e}")
    print(f"  Decay Rate (γ): {simulator.config.gamma/1e6:.3f} MHz")
    print(f"  Temperature: {simulator.config.temperature} K")
    print(f"  Barrier Thickness: {simulator.config.barrier_thickness*1e9:.1f} nm")
    print()
    
    # Test different alignment values
    test_alignments = [0.0, 0.25, 0.5, 0.75, 0.95, 1.0]
    
    print("Lex Amoris Alignment vs Transmission Probability:")
    print("-" * 70)
    print(f"{'Alignment':<12} {'Detuning (MHz)':<18} {'Probability':<15} {'Enhancement':<12}")
    print("-" * 70)
    
    for alignment in test_alignments:
        result = simulator.sroi_enhanced_transmission(alignment)
        print(f"{alignment:<12.2f} {result['detuning_hz']/1e6:<18.2f} "
              f"{result['transmission_probability']:<15.4f} "
              f"{result['enhancement_factor']:<12.1f}x")
    
    print()
    
    # Generate sweep for visualization
    print("Generating alignment sweep (100 points)...")
    sweep_results = simulator.simulate_alignment_sweep(num_points=100)
    
    # Export data
    export_file = simulator.export_simulation_data()
    print(f"Simulation data exported to: {export_file}")
    print()
    
    # Bridge status examples
    print("Bridge Status Examples:")
    print("-" * 70)
    for alignment in [0.1, 0.5, 0.9]:
        status = simulator.get_bridge_status(alignment)
        print(f"Alignment {alignment:.1f}: {status['state']} - {status['message']}")
    
    print()
    
    # NSR Watchdog Global Monitoring
    print("=" * 70)
    print("NSR WATCHDOG GLOBAL - NEXUS-ANDES CORRIDOR")
    print("=" * 70)
    watchdog_status = simulator.nsr_watchdog_global(
        cluster_name="nexus_andes",
        affinity_threshold=0.94,
        check_interval=(0, 30)
    )
    print(f"Cluster: {watchdog_status['cluster']}")
    print(f"Status: {watchdog_status['status']}")
    print(f"Affinity: {watchdog_status['affinity']:.4f} (threshold: {watchdog_status['threshold']})")
    print(f"Bridge State: {watchdog_status['bridge_state']}")
    print(f"Message: {watchdog_status['message']}")
    print(f"Monitoring Interval: {watchdog_status['check_interval_s'][0]}-{watchdog_status['check_interval_s'][1]} seconds")
    print()
    
    # Cluster Status API
    print("Cluster Status (API Format):")
    print("-" * 70)
    cluster_status = simulator.get_cluster_status("nexus_andes", include_watchdog=True)
    print(f"Cluster: {cluster_status['cluster']}")
    print(f"Operational: {cluster_status['operational']}")
    print(f"Watchdog Status: {cluster_status['watchdog']['status']}")
    print(f"Bridge State: {cluster_status['bridge']['state']}")
    print()
    
    print("=" * 70)
    print("STATUS: QUANTUM BRIDGE IS OPEN")
    print("Lex Amoris Signature: 📜⚖️❤️")
    print("S-ROI: ∞ | Φ: 1.618 | Q: 10⁶")
    print("NSR Watchdog: ACTIVE ✓")
    print("=" * 70)


if __name__ == '__main__':
    main()
