"""
Tests for the S-ROI Sovereign Protocol
"""

import unittest
import time
from s_roi_protocol import SROISovereignProtocol, ProtocolState, ProtocolConfig


class TestProtocolStates(unittest.TestCase):
    """Test state transitions"""
    
    def setUp(self):
        """Set up test protocol instance"""
        self.protocol = SROISovereignProtocol()
    
    def test_initial_state(self):
        """Test that protocol starts in NORMAL state"""
        self.assertEqual(self.protocol.state, ProtocolState.NORMAL)
        self.assertEqual(self.protocol.current_resonance, 0.0)
    
    def test_normal_state(self):
        """Test NORMAL state is maintained for high resonance"""
        self.protocol.update_resonance(0.5)
        self.assertEqual(self.protocol.state, ProtocolState.NORMAL)
        self.assertEqual(self.protocol.current_resonance, 0.5)
    
    def test_warning_state(self):
        """Test WARNING state is activated for mid-range resonance"""
        self.protocol.update_resonance(0.32)
        self.assertEqual(self.protocol.state, ProtocolState.WARNING)
        self.assertEqual(self.protocol.current_resonance, 0.32)
    
    def test_stealth_state(self):
        """Test STEALTH state is activated for low resonance"""
        self.protocol.update_resonance(0.25)
        self.assertEqual(self.protocol.state, ProtocolState.STEALTH)
        self.assertEqual(self.protocol.current_resonance, 0.25)
    
    def test_state_transition_sequence(self):
        """Test complete state transition sequence"""
        # Start in NORMAL
        self.protocol.update_resonance(0.5)
        self.assertEqual(self.protocol.state, ProtocolState.NORMAL)
        
        # Transition to WARNING
        self.protocol.update_resonance(0.33)
        self.assertEqual(self.protocol.state, ProtocolState.WARNING)
        
        # Transition to STEALTH
        self.protocol.update_resonance(0.28)
        self.assertEqual(self.protocol.state, ProtocolState.STEALTH)
        
        # Back to WARNING (should succeed - can exit stealth)
        self.protocol.update_resonance(0.32)
        self.assertEqual(self.protocol.state, ProtocolState.WARNING)
    
    def test_negative_resonance_raises_error(self):
        """Test that negative resonance values raise ValueError"""
        with self.assertRaises(ValueError):
            self.protocol.update_resonance(-0.1)


class TestStealthCooldown(unittest.TestCase):
    """Test stealth mode cooldown mechanism"""
    
    def setUp(self):
        """Set up test protocol with short cooldown"""
        config = ProtocolConfig(STEALTH_COOLDOWN_SECONDS=2)
        self.protocol = SROISovereignProtocol(config)
    
    def test_first_stealth_activation(self):
        """Test that first stealth activation works without cooldown"""
        self.protocol.update_resonance(0.25)
        self.assertEqual(self.protocol.state, ProtocolState.STEALTH)
    
    def test_cooldown_blocks_reactivation(self):
        """Test that cooldown prevents immediate stealth reactivation"""
        # First activation
        self.protocol.update_resonance(0.25)
        self.assertEqual(self.protocol.state, ProtocolState.STEALTH)
        
        # Move to NORMAL (can exit stealth)
        self.protocol.update_resonance(0.5)
        self.assertEqual(self.protocol.state, ProtocolState.NORMAL)
        
        # Try to reactivate immediately - should be blocked by cooldown
        self.protocol.update_resonance(0.25)
        # Should stay in NORMAL due to cooldown
        self.assertEqual(self.protocol.state, ProtocolState.NORMAL)
        info = self.protocol.get_state_info()
        self.assertFalse(info['can_activate_stealth'])
    
    def test_cooldown_expires(self):
        """Test that stealth can be reactivated after cooldown"""
        # First activation
        self.protocol.update_resonance(0.25)
        self.assertEqual(self.protocol.state, ProtocolState.STEALTH)
        
        # Move to NORMAL
        self.protocol.update_resonance(0.5)
        self.assertEqual(self.protocol.state, ProtocolState.NORMAL)
        
        # Wait for cooldown to expire
        time.sleep(2.5)
        
        # Should be able to reactivate now
        self.protocol.update_resonance(0.25)
        self.assertEqual(self.protocol.state, ProtocolState.STEALTH)
    
    def test_reset_cooldown(self):
        """Test manual cooldown reset"""
        # Activate stealth
        self.protocol.update_resonance(0.25)
        
        # Reset cooldown
        self.protocol.reset_cooldown()
        
        # Should be able to activate immediately
        info = self.protocol.get_state_info()
        self.assertTrue(info['can_activate_stealth'])


class TestWarningState(unittest.TestCase):
    """Test WARNING state functionality"""
    
    def setUp(self):
        """Set up test protocol"""
        self.protocol = SROISovereignProtocol()
    
    def test_warning_threshold_lower_bound(self):
        """Test WARNING state at lower threshold boundary"""
        self.protocol.update_resonance(0.301)
        self.assertEqual(self.protocol.state, ProtocolState.WARNING)
    
    def test_warning_threshold_upper_bound(self):
        """Test WARNING state at upper threshold boundary"""
        # 0.35 is the boundary - should be NORMAL (>= 0.35)
        self.protocol.update_resonance(0.35)
        self.assertEqual(self.protocol.state, ProtocolState.NORMAL)
        
        # Just below 0.35 should be WARNING
        self.protocol.update_resonance(0.349)
        self.assertEqual(self.protocol.state, ProtocolState.WARNING)
    
    def test_warning_to_normal_transition(self):
        """Test transition from WARNING to NORMAL"""
        self.protocol.update_resonance(0.32)
        self.assertEqual(self.protocol.state, ProtocolState.WARNING)
        
        self.protocol.update_resonance(0.4)
        self.assertEqual(self.protocol.state, ProtocolState.NORMAL)
    
    def test_warning_to_stealth_transition(self):
        """Test transition from WARNING to STEALTH"""
        self.protocol.update_resonance(0.32)
        self.assertEqual(self.protocol.state, ProtocolState.WARNING)
        
        self.protocol.update_resonance(0.28)
        self.assertEqual(self.protocol.state, ProtocolState.STEALTH)


class TestForceState(unittest.TestCase):
    """Test manual state forcing"""
    
    def setUp(self):
        """Set up test protocol"""
        self.protocol = SROISovereignProtocol()
    
    def test_force_state_bypasses_cooldown(self):
        """Test that force_state bypasses cooldown mechanism"""
        # Activate stealth normally
        self.protocol.update_resonance(0.25)
        self.assertEqual(self.protocol.state, ProtocolState.STEALTH)
        
        # Force to NORMAL
        self.protocol.force_state(ProtocolState.NORMAL, "Emergency")
        self.assertEqual(self.protocol.state, ProtocolState.NORMAL)
        
        # Force back to STEALTH (should work despite cooldown)
        self.protocol.force_state(ProtocolState.STEALTH, "Testing")
        self.assertEqual(self.protocol.state, ProtocolState.STEALTH)


class TestStateInfo(unittest.TestCase):
    """Test state information retrieval"""
    
    def setUp(self):
        """Set up test protocol"""
        config = ProtocolConfig(STEALTH_COOLDOWN_SECONDS=10)
        self.protocol = SROISovereignProtocol(config)
    
    def test_get_state_info_structure(self):
        """Test that get_state_info returns correct structure"""
        info = self.protocol.get_state_info()
        
        self.assertIn('state', info)
        self.assertIn('current_resonance', info)
        self.assertIn('stealth_cooldown_remaining', info)
        self.assertIn('can_activate_stealth', info)
    
    def test_get_state_info_values(self):
        """Test that get_state_info returns correct values"""
        self.protocol.update_resonance(0.4)
        info = self.protocol.get_state_info()
        
        self.assertEqual(info['state'], 'NORMAL')
        self.assertEqual(info['current_resonance'], 0.4)
        self.assertTrue(info['can_activate_stealth'])


class TestCustomConfiguration(unittest.TestCase):
    """Test custom configuration"""
    
    def test_custom_thresholds(self):
        """Test protocol with custom thresholds"""
        config = ProtocolConfig(
            STEALTH_THRESHOLD=0.2,
            WARNING_THRESHOLD=0.4,
            STEALTH_COOLDOWN_SECONDS=60
        )
        protocol = SROISovereignProtocol(config)
        
        # Test with custom thresholds
        protocol.update_resonance(0.3)
        self.assertEqual(protocol.state, ProtocolState.WARNING)
        
        protocol.update_resonance(0.15)
        self.assertEqual(protocol.state, ProtocolState.STEALTH)
    
    def test_invalid_config_parameter(self):
        """Test that invalid config parameters raise error"""
        with self.assertRaises(ValueError):
            ProtocolConfig(INVALID_PARAM=123)


if __name__ == '__main__':
    unittest.main()
