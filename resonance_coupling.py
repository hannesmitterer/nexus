#!/usr/bin/env python3
"""
Resonanz-Kopplung (Resonance Coupling) Simulation
==================================================

This module implements a Python simulation for calculating the structural 
integrity of clay walls based on resonance coupling (R).

Mathematical Model:
-------------------
R = φ_Lehm * f(0.043 - Δf)

Variables:
----------
R : float
    Resonanz-Amplitude (Resonance Amplitude) - Information radiation density 
    of a structure
φ_Lehm : float
    Materialkonstante für Lehm (Material constant for clay)
Δf : float
    Beeinflussungs-Rauschen (Influence noise) - modern or endogenous
f : function
    Coupling function that processes the frequency difference (0.043 - Δf)

Reference:
----------
Based on UIFS (Universal Information Flow System) workflow baselines
"""

import math
from typing import Callable, Optional


class ResonanceCouplingSimulator:
    """
    Simulator for calculating structural integrity of clay walls using 
    resonance coupling principles.
    """
    
    # Default material constant for clay (Lehm)
    DEFAULT_PHI_LEHM = 1.0
    
    # Reference frequency constant from UIFS baseline
    REFERENCE_FREQUENCY = 0.043
    
    def __init__(self, phi_lehm: Optional[float] = None):
        """
        Initialize the resonance coupling simulator.
        
        Parameters:
        -----------
        phi_lehm : float, optional
            Material constant for clay. If not provided, uses default value.
        
        Raises:
        -------
        ValueError
            If phi_lehm is provided but is NaN or infinite.
        """
        if phi_lehm is None:
            self.phi_lehm = self.DEFAULT_PHI_LEHM
        else:
            if math.isnan(phi_lehm) or math.isinf(phi_lehm):
                raise ValueError("phi_lehm must be a finite number")
            self.phi_lehm = phi_lehm
    
    @staticmethod
    def default_coupling_function(x: float) -> float:
        """
        Default coupling function f(x) for resonance calculation.
        
        This function models the relationship between frequency difference
        and structural coupling. Uses a Gaussian-like response centered
        around the reference frequency.
        
        Parameters:
        -----------
        x : float
            Frequency difference (0.043 - Δf)
        
        Returns:
        --------
        float
            Coupling factor
        """
        # Exponential decay function for resonance coupling
        # This models how deviation from reference frequency affects coupling
        return math.exp(-abs(x) * 10)
    
    def calculate_resonance_amplitude(
        self, 
        delta_f: float,
        coupling_function: Optional[Callable[[float], float]] = None
    ) -> float:
        """
        Calculate the resonance amplitude R for given parameters.
        
        R = φ_Lehm * f(0.043 - Δf)
        
        Parameters:
        -----------
        delta_f : float
            Influence noise (Beeinflussungs-Rauschen) - represents modern
            or endogenous disturbances affecting the structure
        coupling_function : callable, optional
            Custom coupling function f(x). If not provided, uses default.
        
        Returns:
        --------
        float
            Resonance amplitude R - information radiation density
        """
        # Use default coupling function if none provided
        f = coupling_function if coupling_function is not None else self.default_coupling_function
        
        # Calculate frequency difference from reference
        freq_diff = self.REFERENCE_FREQUENCY - delta_f
        
        # Apply coupling function
        coupling_factor = f(freq_diff)
        
        # Calculate resonance amplitude
        R = self.phi_lehm * coupling_factor
        
        return R
    
    def assess_structural_integrity(
        self,
        delta_f: float,
        coupling_function: Optional[Callable[[float], float]] = None
    ) -> dict:
        """
        Assess the structural integrity of a clay wall based on resonance coupling.
        
        Parameters:
        -----------
        delta_f : float
            Influence noise affecting the structure
        coupling_function : callable, optional
            Custom coupling function. If not provided, uses default.
        
        Returns:
        --------
        dict
            Dictionary containing:
            - 'resonance_amplitude': R value
            - 'frequency_difference': Calculated frequency difference
            - 'integrity_status': Qualitative assessment
            - 'integrity_percentage': Quantitative assessment (0-100%)
        """
        R = self.calculate_resonance_amplitude(delta_f, coupling_function)
        freq_diff = self.REFERENCE_FREQUENCY - delta_f
        
        # Normalize R to percentage (assuming R ranges from 0 to phi_lehm)
        # Handle division by zero for phi_lehm = 0
        if self.phi_lehm != 0:
            integrity_percentage = (R / self.phi_lehm) * 100
        else:
            # If phi_lehm is 0, R is also 0, so integrity is 0%
            integrity_percentage = 0.0
        
        # Qualitative assessment based on integrity percentage
        if integrity_percentage >= 90:
            status = "Excellent"
        elif integrity_percentage >= 75:
            status = "Good"
        elif integrity_percentage >= 50:
            status = "Fair"
        elif integrity_percentage >= 25:
            status = "Poor"
        else:
            status = "Critical"
        
        return {
            'resonance_amplitude': R,
            'frequency_difference': freq_diff,
            'integrity_status': status,
            'integrity_percentage': integrity_percentage
        }
    
    def simulate_range(
        self,
        delta_f_min: float,
        delta_f_max: float,
        steps: int = 100,
        coupling_function: Optional[Callable[[float], float]] = None
    ) -> list:
        """
        Simulate structural integrity across a range of influence noise values.
        
        Parameters:
        -----------
        delta_f_min : float
            Minimum influence noise value
        delta_f_max : float
            Maximum influence noise value
        steps : int
            Number of simulation steps (must be > 0)
        coupling_function : callable, optional
            Custom coupling function
        
        Returns:
        --------
        list of dict
            List of assessment results for each delta_f value
        
        Raises:
        -------
        ValueError
            If steps <= 0
        """
        if steps <= 0:
            raise ValueError("steps must be greater than 0")
        
        results = []
        delta_f_step = (delta_f_max - delta_f_min) / (steps - 1) if steps > 1 else 0
        
        for i in range(steps):
            delta_f = delta_f_min + i * delta_f_step
            assessment = self.assess_structural_integrity(delta_f, coupling_function)
            assessment['delta_f'] = delta_f
            results.append(assessment)
        
        return results


def main():
    """
    Example usage of the Resonance Coupling Simulator.
    """
    print("=" * 70)
    print("Resonanz-Kopplung Simulation - Clay Wall Structural Integrity")
    print("=" * 70)
    print()
    
    # Initialize simulator with default clay material constant
    simulator = ResonanceCouplingSimulator(phi_lehm=1.0)
    
    # Example 1: Single assessment
    print("Example 1: Single Assessment")
    print("-" * 70)
    delta_f = 0.01
    result = simulator.assess_structural_integrity(delta_f)
    print(f"Influence Noise (Δf): {delta_f}")
    print(f"Resonance Amplitude (R): {result['resonance_amplitude']:.6f}")
    print(f"Frequency Difference: {result['frequency_difference']:.6f}")
    print(f"Integrity Status: {result['integrity_status']}")
    print(f"Integrity Percentage: {result['integrity_percentage']:.2f}%")
    print()
    
    # Example 2: Range simulation
    print("Example 2: Range Simulation")
    print("-" * 70)
    print(f"{'Δf':<10} {'R':<15} {'Freq Diff':<15} {'Status':<12} {'Integrity %'}")
    print("-" * 70)
    
    results = simulator.simulate_range(0.0, 0.086, steps=10)
    for r in results:
        print(f"{r['delta_f']:<10.4f} "
              f"{r['resonance_amplitude']:<15.6f} "
              f"{r['frequency_difference']:<15.6f} "
              f"{r['integrity_status']:<12} "
              f"{r['integrity_percentage']:.2f}%")
    print()
    
    # Example 3: Assessment at reference frequency (optimal condition)
    print("Example 3: Optimal Condition (Δf = 0.043, at reference frequency)")
    print("-" * 70)
    optimal = simulator.assess_structural_integrity(0.043)
    print(f"Resonance Amplitude (R): {optimal['resonance_amplitude']:.6f}")
    print(f"Integrity Status: {optimal['integrity_status']}")
    print(f"Integrity Percentage: {optimal['integrity_percentage']:.2f}%")
    print()
    
    print("=" * 70)
    print("Simulation Complete")
    print("=" * 70)


if __name__ == "__main__":
    main()
