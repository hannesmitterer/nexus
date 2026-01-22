"""
Example usage of the S-ROI Sovereign Protocol

This script demonstrates the key features of the protocol including:
- State transitions
- Cooldown mechanism
- Logging
- Custom configuration
"""

import time
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from s_roi_protocol import SROISovereignProtocol, ProtocolState, ProtocolConfig


def example_basic_usage():
    """Demonstrate basic protocol usage"""
    print("=" * 60)
    print("Example 1: Basic Usage")
    print("=" * 60)
    
    protocol = SROISovereignProtocol()
    
    # Test different resonance values
    test_values = [0.5, 0.4, 0.32, 0.28, 0.25]
    
    for value in test_values:
        protocol.update_resonance(value)
        print(f"Resonance: {value:.2f} -> State: {protocol.state}")
    
    print()


def example_state_info():
    """Demonstrate state information retrieval"""
    print("=" * 60)
    print("Example 2: State Information")
    print("=" * 60)
    
    protocol = SROISovereignProtocol()
    protocol.update_resonance(0.32)
    
    info = protocol.get_state_info()
    print(f"Current State: {info['state']}")
    print(f"Resonance: {info['current_resonance']:.4f}")
    print(f"Can activate stealth: {info['can_activate_stealth']}")
    print(f"Cooldown remaining: {info['stealth_cooldown_remaining']:.1f}s")
    
    print()


def example_cooldown_mechanism():
    """Demonstrate cooldown mechanism"""
    print("=" * 60)
    print("Example 3: Cooldown Mechanism")
    print("=" * 60)
    
    # Use short cooldown for demonstration
    config = ProtocolConfig(STEALTH_COOLDOWN_SECONDS=3)
    protocol = SROISovereignProtocol(config)
    
    print("First stealth activation...")
    protocol.update_resonance(0.25)
    print(f"State: {protocol.state}")
    
    print("\nTrying to exit and re-enter stealth immediately...")
    protocol.update_resonance(0.5)  # Try to exit
    print(f"State after exit attempt: {protocol.state}")
    
    protocol.update_resonance(0.25)  # Try to re-enter
    info = protocol.get_state_info()
    print(f"State: {protocol.state}")
    print(f"Cooldown remaining: {info['stealth_cooldown_remaining']:.1f}s")
    
    print("\nWaiting for cooldown to expire...")
    time.sleep(3.5)
    
    protocol.update_resonance(0.5)   # Exit stealth
    protocol.update_resonance(0.25)  # Re-enter stealth
    print(f"State after cooldown: {protocol.state}")
    
    print()


def example_warning_state():
    """Demonstrate WARNING state functionality"""
    print("=" * 60)
    print("Example 4: WARNING State")
    print("=" * 60)
    
    protocol = SROISovereignProtocol()
    
    # Test values in warning zone
    warning_values = [0.35, 0.33, 0.31, 0.30]
    
    print("Testing WARNING state thresholds:")
    for value in warning_values:
        protocol.update_resonance(value)
        print(f"Resonance: {value:.2f} -> State: {protocol.state}")
    
    print()


def example_custom_config():
    """Demonstrate custom configuration"""
    print("=" * 60)
    print("Example 5: Custom Configuration")
    print("=" * 60)
    
    # Create custom configuration with different thresholds
    config = ProtocolConfig(
        STEALTH_THRESHOLD=0.2,
        WARNING_THRESHOLD=0.4,
        STEALTH_COOLDOWN_SECONDS=600
    )
    
    protocol = SROISovereignProtocol(config)
    
    print(f"Custom thresholds:")
    print(f"  STEALTH: ≤ {config.STEALTH_THRESHOLD}")
    print(f"  WARNING: {config.STEALTH_THRESHOLD} - {config.WARNING_THRESHOLD}")
    print(f"  NORMAL: > {config.WARNING_THRESHOLD}")
    print(f"  Cooldown: {config.STEALTH_COOLDOWN_SECONDS}s")
    
    print("\nTesting with custom thresholds:")
    test_values = [0.5, 0.3, 0.15]
    for value in test_values:
        protocol.update_resonance(value)
        print(f"Resonance: {value:.2f} -> State: {protocol.state}")
    
    print()


def example_force_state():
    """Demonstrate manual state forcing"""
    print("=" * 60)
    print("Example 6: Manual State Control")
    print("=" * 60)
    
    protocol = SROISovereignProtocol()
    
    print("Normal state transition:")
    protocol.update_resonance(0.5)
    print(f"State: {protocol.state}")
    
    print("\nForcing to STEALTH (emergency override):")
    protocol.force_state(ProtocolState.STEALTH, reason="Emergency test")
    print(f"State: {protocol.state}")
    
    print("\nForcing back to NORMAL:")
    protocol.force_state(ProtocolState.NORMAL, reason="Recovery")
    print(f"State: {protocol.state}")
    
    print()


def example_monitoring_scenario():
    """Simulate a realistic monitoring scenario"""
    print("=" * 60)
    print("Example 7: Realistic Monitoring Scenario")
    print("=" * 60)
    
    protocol = SROISovereignProtocol()
    
    # Simulate changing resonance values over time
    scenario = [
        (0.5, "System startup"),
        (0.45, "Normal operation"),
        (0.38, "Slight degradation"),
        (0.33, "Warning: approaching threshold"),
        (0.29, "Critical: entering stealth mode"),
        (0.27, "Stealth mode active"),
        (0.35, "Recovery initiated"),
        (0.42, "System stabilized"),
    ]
    
    for resonance, description in scenario:
        protocol.update_resonance(resonance)
        info = protocol.get_state_info()
        
        print(f"\n{description}")
        print(f"  Resonance: {resonance:.2f}")
        print(f"  State: {info['state']}")
        if info['stealth_cooldown_remaining'] > 0:
            print(f"  Cooldown: {info['stealth_cooldown_remaining']:.1f}s")
    
    print()


if __name__ == "__main__":
    print("\nS-ROI Sovereign Protocol - Examples\n")
    
    # Run all examples
    example_basic_usage()
    example_state_info()
    example_cooldown_mechanism()
    example_warning_state()
    example_custom_config()
    example_force_state()
    example_monitoring_scenario()
    
    print("=" * 60)
    print("All examples completed successfully!")
    print("=" * 60)
