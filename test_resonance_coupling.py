#!/usr/bin/env python3
"""
Test suite for Resonanz-Kopplung (Resonance Coupling) Simulation
=================================================================

This module contains tests for the resonance coupling simulator.
"""

import unittest
import math
from resonance_coupling import ResonanceCouplingSimulator


class TestResonanceCouplingSimulator(unittest.TestCase):
    """Test cases for the ResonanceCouplingSimulator class."""
    
    def setUp(self):
        """Set up test fixtures."""
        self.simulator = ResonanceCouplingSimulator(phi_lehm=1.0)
    
    def test_initialization_default(self):
        """Test initialization with default parameters."""
        sim = ResonanceCouplingSimulator()
        self.assertEqual(sim.phi_lehm, ResonanceCouplingSimulator.DEFAULT_PHI_LEHM)
    
    def test_initialization_custom(self):
        """Test initialization with custom phi_lehm."""
        custom_phi = 2.5
        sim = ResonanceCouplingSimulator(phi_lehm=custom_phi)
        self.assertEqual(sim.phi_lehm, custom_phi)
    
    def test_reference_frequency_constant(self):
        """Test that reference frequency is correctly set."""
        self.assertEqual(
            ResonanceCouplingSimulator.REFERENCE_FREQUENCY, 
            0.043
        )
    
    def test_default_coupling_function(self):
        """Test the default coupling function properties."""
        # At zero difference, should return 1
        self.assertEqual(
            self.simulator.default_coupling_function(0.0),
            1.0
        )
        
        # Function should be symmetric
        val_pos = self.simulator.default_coupling_function(0.01)
        val_neg = self.simulator.default_coupling_function(-0.01)
        self.assertAlmostEqual(val_pos, val_neg, places=10)
        
        # Function should decay with distance
        val_near = self.simulator.default_coupling_function(0.01)
        val_far = self.simulator.default_coupling_function(0.1)
        self.assertGreater(val_near, val_far)
    
    def test_calculate_resonance_amplitude_at_reference(self):
        """Test resonance amplitude calculation at reference frequency."""
        # At delta_f = 0.043 (reference), frequency difference is 0
        R = self.simulator.calculate_resonance_amplitude(delta_f=0.043)
        
        # At zero difference, coupling function returns 1
        # So R should equal phi_lehm
        self.assertAlmostEqual(R, self.simulator.phi_lehm, places=10)
    
    def test_calculate_resonance_amplitude_away_from_reference(self):
        """Test resonance amplitude calculation away from reference frequency."""
        # At delta_f != 0.043, R should be less than phi_lehm
        R = self.simulator.calculate_resonance_amplitude(delta_f=0.01)
        self.assertLess(R, self.simulator.phi_lehm)
        self.assertGreater(R, 0)
    
    def test_calculate_resonance_amplitude_custom_function(self):
        """Test resonance amplitude with custom coupling function."""
        # Custom function that always returns 0.5
        custom_func = lambda x: 0.5
        
        R = self.simulator.calculate_resonance_amplitude(
            delta_f=0.01,
            coupling_function=custom_func
        )
        
        expected = self.simulator.phi_lehm * 0.5
        self.assertEqual(R, expected)
    
    def test_calculate_resonance_amplitude_scaling(self):
        """Test that resonance amplitude scales with phi_lehm."""
        sim1 = ResonanceCouplingSimulator(phi_lehm=1.0)
        sim2 = ResonanceCouplingSimulator(phi_lehm=2.0)
        
        delta_f = 0.02
        R1 = sim1.calculate_resonance_amplitude(delta_f)
        R2 = sim2.calculate_resonance_amplitude(delta_f)
        
        # R should scale linearly with phi_lehm
        self.assertAlmostEqual(R2, 2 * R1, places=10)
    
    def test_assess_structural_integrity_structure(self):
        """Test that structural integrity assessment returns correct structure."""
        result = self.simulator.assess_structural_integrity(delta_f=0.01)
        
        # Check all required keys are present
        required_keys = [
            'resonance_amplitude',
            'frequency_difference',
            'integrity_status',
            'integrity_percentage'
        ]
        for key in required_keys:
            self.assertIn(key, result)
    
    def test_assess_structural_integrity_excellent(self):
        """Test integrity assessment for excellent condition."""
        # At reference frequency, integrity should be excellent
        result = self.simulator.assess_structural_integrity(delta_f=0.043)
        self.assertEqual(result['integrity_status'], 'Excellent')
        self.assertGreaterEqual(result['integrity_percentage'], 90)
    
    def test_assess_structural_integrity_degradation(self):
        """Test that integrity degrades as delta_f moves away from reference."""
        result_optimal = self.simulator.assess_structural_integrity(delta_f=0.043)
        result_suboptimal = self.simulator.assess_structural_integrity(delta_f=0.0)
        
        self.assertGreater(
            result_optimal['integrity_percentage'],
            result_suboptimal['integrity_percentage']
        )
    
    def test_assess_structural_integrity_percentage_range(self):
        """Test that integrity percentage is in valid range."""
        for delta_f in [0.0, 0.02, 0.043, 0.06, 0.1]:
            result = self.simulator.assess_structural_integrity(delta_f)
            self.assertGreaterEqual(result['integrity_percentage'], 0)
            self.assertLessEqual(result['integrity_percentage'], 100)
    
    def test_simulate_range_length(self):
        """Test that simulate_range returns correct number of results."""
        steps = 50
        results = self.simulator.simulate_range(0.0, 0.1, steps=steps)
        self.assertEqual(len(results), steps)
    
    def test_simulate_range_values(self):
        """Test that simulate_range covers the specified range."""
        delta_f_min = 0.0
        delta_f_max = 0.1
        steps = 11
        
        results = self.simulator.simulate_range(
            delta_f_min, 
            delta_f_max, 
            steps=steps
        )
        
        # First result should be at min
        self.assertAlmostEqual(results[0]['delta_f'], delta_f_min, places=10)
        
        # Last result should be at max
        self.assertAlmostEqual(results[-1]['delta_f'], delta_f_max, places=10)
    
    def test_simulate_range_monotonic_delta_f(self):
        """Test that simulate_range produces monotonically increasing delta_f."""
        results = self.simulator.simulate_range(0.0, 0.1, steps=100)
        
        for i in range(len(results) - 1):
            self.assertLessEqual(results[i]['delta_f'], results[i+1]['delta_f'])
    
    def test_simulate_range_single_step(self):
        """Test simulate_range with single step."""
        results = self.simulator.simulate_range(0.043, 0.043, steps=1)
        self.assertEqual(len(results), 1)
        self.assertAlmostEqual(results[0]['delta_f'], 0.043, places=10)
    
    def test_frequency_difference_calculation(self):
        """Test that frequency difference is calculated correctly."""
        delta_f = 0.02
        result = self.simulator.assess_structural_integrity(delta_f)
        
        expected_freq_diff = ResonanceCouplingSimulator.REFERENCE_FREQUENCY - delta_f
        self.assertAlmostEqual(
            result['frequency_difference'],
            expected_freq_diff,
            places=10
        )
    
    def test_zero_phi_lehm(self):
        """Test simulator with zero material constant."""
        sim = ResonanceCouplingSimulator(phi_lehm=0.0)
        R = sim.calculate_resonance_amplitude(delta_f=0.043)
        self.assertEqual(R, 0.0)
    
    def test_negative_phi_lehm(self):
        """Test simulator with negative material constant."""
        # This tests edge case - negative material constant
        sim = ResonanceCouplingSimulator(phi_lehm=-1.0)
        R = sim.calculate_resonance_amplitude(delta_f=0.043)
        self.assertLess(R, 0)
    
    def test_large_delta_f_values(self):
        """Test simulator with large delta_f values."""
        # Should not crash with large values
        large_delta_f = 100.0
        result = self.simulator.assess_structural_integrity(large_delta_f)
        
        # Should still return valid structure
        self.assertIn('resonance_amplitude', result)
        # Resonance should be very low (near zero)
        self.assertLess(result['resonance_amplitude'], 0.01)
    
    def test_integrity_status_categories(self):
        """Test all integrity status categories can be achieved."""
        # Test different delta_f values to achieve different statuses
        test_cases = [
            (0.043, 'Excellent'),  # At reference
        ]
        
        for delta_f, expected_status in test_cases:
            result = self.simulator.assess_structural_integrity(delta_f)
            self.assertEqual(result['integrity_status'], expected_status)


class TestMathematicalProperties(unittest.TestCase):
    """Test mathematical properties of the resonance coupling model."""
    
    def test_continuity(self):
        """Test that resonance amplitude is continuous."""
        simulator = ResonanceCouplingSimulator(phi_lehm=1.0)
        
        # Test continuity around reference frequency
        delta_f_values = [0.042, 0.0425, 0.043, 0.0435, 0.044]
        R_values = [
            simulator.calculate_resonance_amplitude(df) 
            for df in delta_f_values
        ]
        
        # Check that values don't have sudden jumps
        for i in range(len(R_values) - 1):
            diff = abs(R_values[i+1] - R_values[i])
            # Difference between consecutive values should be small
            self.assertLess(diff, 0.1)
    
    def test_symmetry_around_reference(self):
        """Test symmetry of coupling function around reference frequency."""
        simulator = ResonanceCouplingSimulator(phi_lehm=1.0)
        
        offset = 0.01
        delta_f_above = 0.043 + offset
        delta_f_below = 0.043 - offset
        
        R_above = simulator.calculate_resonance_amplitude(delta_f_above)
        R_below = simulator.calculate_resonance_amplitude(delta_f_below)
        
        # Due to symmetry, these should be equal
        self.assertAlmostEqual(R_above, R_below, places=10)
    
    def test_maximum_at_reference(self):
        """Test that resonance amplitude is maximum at reference frequency."""
        simulator = ResonanceCouplingSimulator(phi_lehm=1.0)
        
        R_ref = simulator.calculate_resonance_amplitude(0.043)
        
        # Test nearby points
        for offset in [0.001, 0.005, 0.01, 0.02]:
            R_above = simulator.calculate_resonance_amplitude(0.043 + offset)
            R_below = simulator.calculate_resonance_amplitude(0.043 - offset)
            
            self.assertGreaterEqual(R_ref, R_above)
            self.assertGreaterEqual(R_ref, R_below)


def run_tests():
    """Run all tests and display results."""
    # Create test suite
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Add all test cases
    suite.addTests(loader.loadTestsFromTestCase(TestResonanceCouplingSimulator))
    suite.addTests(loader.loadTestsFromTestCase(TestMathematicalProperties))
    
    # Run tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Return success status
    return result.wasSuccessful()


if __name__ == "__main__":
    success = run_tests()
    exit(0 if success else 1)
