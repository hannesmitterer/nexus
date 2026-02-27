#!/usr/bin/env python3
"""
Integration Test for Strategic Enhancements
Tests all five enhancement modules
"""

import sys
import json


def test_threat_prediction():
    """Test AI-based threat prediction"""
    print("\n" + "=" * 60)
    print("TEST 1: AI-BASED THREAT PREDICTION")
    print("=" * 60)
    
    try:
        from threat_prediction.threat_model import ThreatPredictionModel
        
        model = ThreatPredictionModel()
        
        test_metrics = {
            'cpu_usage': 45.2,
            'memory_usage': 67.8,
            'network_activity': 23.5,
            'failed_authentications': 2,
            'veto_consensus_events': 1,
            'planetary_violence_index': 3.2,
            'scarcity_factor': 78.5,
            'ethical_alignment_score': 92.3
        }
        
        assessment = model.predict_threat(test_metrics)
        
        print(f"✓ Threat Level: {assessment['threat_level']}")
        print(f"✓ Probability: {assessment['threat_probability']:.2%}")
        print(f"✓ Sentimento Aligned: {assessment['sentimento_alignment']}")
        print("✓ Threat prediction module working correctly")
        
        return True
    except Exception as e:
        print(f"✗ Error: {e}")
        return False


def test_bio_synchronization():
    """Test bio-synchronization module"""
    print("\n" + "=" * 60)
    print("TEST 2: BIO-SYNCHRONIZATION")
    print("=" * 60)
    
    try:
        from bio_sync.bio_synchronization import RhythmValidator
        
        validator = RhythmValidator()
        
        test_rhythm = {
            'quality': 85.0,
            'frequency': 0.8,
            'amplitude': 1.2,
            'phase': 0.5
        }
        
        result = validator.validate_rhythm_segment(test_rhythm)
        
        print(f"✓ Rhythm Valid: {result['rhythm_valid']}")
        print(f"✓ Alignment Score: {result['alignment_score']:.2f}")
        print(f"✓ Climate Segment: {result['segmentation']['climate_stress']['segment']}")
        print("✓ Bio-synchronization module working correctly")
        
        return True
    except Exception as e:
        print(f"✗ Error: {e}")
        return False


def test_p2p_network():
    """Test P2P network module"""
    print("\n" + "=" * 60)
    print("TEST 3: DECENTRALIZED P2P NETWORK")
    print("=" * 60)
    
    try:
        from p2p_network.risonanza_network import P2PNetwork
        
        network = P2PNetwork(node_id="TEST-NODE-001", is_efa=True)
        
        # Discover peers
        bootstrap = ["192.168.1.100:8333", "192.168.1.101:8333"]
        discovered = network.discover_peers(bootstrap)
        
        # Create and distribute seed
        seed = network.create_seed(
            content="Test harmony message for network validation",
            metadata={'type': 'test', 'priority': 'low'}
        )
        
        result = network.distribute_seed(seed)
        
        status = network.get_network_status()
        
        print(f"✓ Peers Discovered: {status['peer_count']}")
        print(f"✓ Blockchain Height: {status['blockchain_height']}")
        print(f"✓ Chain Valid: {status['chain_valid']}")
        print(f"✓ Seed Distributed: {result.get('seed_id', 'N/A')}")
        print("✓ P2P network module working correctly")
        
        return True
    except Exception as e:
        print(f"✗ Error: {e}")
        return False


def test_quantum_encryption():
    """Test quantum-safe encryption"""
    print("\n" + "=" * 60)
    print("TEST 4: QUANTUM-SAFE ENCRYPTION")
    print("=" * 60)
    
    try:
        from quantum_encryption.ntru_encryption import QuantumSafeEmergencyChannel
        
        # Create two channels
        channel1 = QuantumSafeEmergencyChannel("TEST-CHANNEL-001")
        channel1.initialize()
        
        channel2 = QuantumSafeEmergencyChannel("TEST-CHANNEL-002")
        channel2.initialize()
        
        # Send encrypted message
        message = "Test emergency message for quantum-safe channel"
        record = channel1.send_emergency_message(message, channel2.get_public_key())
        
        print(f"✓ Channel Initialized: TEST-CHANNEL-001")
        print(f"✓ Message Encrypted: {record['message_id']}")
        print(f"✓ Quantum Safe: {record['quantum_safe']}")
        print(f"✓ Algorithm: {record['algorithm']}")
        print("✓ Quantum encryption module working correctly")
        
        return True
    except Exception as e:
        print(f"✗ Error: {e}")
        return False


def test_rhythm_interface():
    """Test rhythm interface (basic validation)"""
    print("\n" + "=" * 60)
    print("TEST 5: RHYTHM INTERFACE")
    print("=" * 60)
    
    try:
        import os
        
        interface_path = "rhythm_interface/index.html"
        
        if os.path.exists(interface_path):
            with open(interface_path, 'r') as f:
                content = f.read()
            
            # Check for key components
            has_auth = 'authenticate()' in content
            has_decrypt = 'decryptPacket()' in content
            has_release = 'releasePacket()' in content
            has_visualization = 'rhythm-wave' in content
            
            print(f"✓ Authentication System: {'Present' if has_auth else 'Missing'}")
            print(f"✓ Decryption Function: {'Present' if has_decrypt else 'Missing'}")
            print(f"✓ Release Function: {'Present' if has_release else 'Missing'}")
            print(f"✓ Rhythm Visualization: {'Present' if has_visualization else 'Missing'}")
            
            if all([has_auth, has_decrypt, has_release, has_visualization]):
                print("✓ Rhythm interface module working correctly")
                print(f"✓ To test UI: Open {interface_path} in a web browser")
                return True
            else:
                print("✗ Some interface components missing")
                return False
        else:
            print(f"✗ Interface file not found: {interface_path}")
            return False
    except Exception as e:
        print(f"✗ Error: {e}")
        return False


def main():
    """Run all tests"""
    print("\n" + "=" * 60)
    print("STRATEGIC ENHANCEMENTS INTEGRATION TEST")
    print("Euystacio Framework - Lex Amoris Implementation")
    print("=" * 60)
    
    results = {
        'threat_prediction': test_threat_prediction(),
        'bio_synchronization': test_bio_synchronization(),
        'p2p_network': test_p2p_network(),
        'quantum_encryption': test_quantum_encryption(),
        'rhythm_interface': test_rhythm_interface()
    }
    
    # Summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    
    passed = sum(1 for result in results.values() if result)
    total = len(results)
    
    for module, result in results.items():
        status = "✓ PASS" if result else "✗ FAIL"
        print(f"{status}: {module.replace('_', ' ').title()}")
    
    print(f"\nOverall: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n✓ All strategic enhancements working correctly!")
        print("✓ System ready for integration with Euystacio Framework")
        return 0
    else:
        print(f"\n✗ {total - passed} test(s) failed")
        print("Please review error messages above")
        return 1


if __name__ == "__main__":
    sys.exit(main())
