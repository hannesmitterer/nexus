#!/usr/bin/env python3
"""
Integration Test Suite for NEXUS Security Modules
Tests all three scenarios and their components
"""

import sys
import time
from typing import Dict, Any


def test_scenario_a() -> Dict[str, Any]:
    """Test Scenario A: Spionage und Datenextraktion"""
    print("\n" + "="*60)
    print("TESTING SCENARIO A: Spionage und Datenextraktion")
    print("="*60)
    
    results = {"passed": 0, "failed": 0, "tests": []}
    
    # Test 1: Quantum Encryption
    try:
        from quantum_encryption import NTRUEncryption, encrypt_message, decrypt_message
        ntru = NTRUEncryption()
        priv_key, pub_key = ntru.generate_keypair()
        
        message = "Test quantum-safe message"
        encrypted = encrypt_message(message, pub_key)
        decrypted = decrypt_message(encrypted, priv_key)
        
        assert message == decrypted, "Decryption failed"
        results["tests"].append(("Quantum Encryption", "PASS"))
        results["passed"] += 1
        print("✓ Quantum Encryption: PASS")
    except Exception as e:
        results["tests"].append(("Quantum Encryption", f"FAIL: {str(e)}"))
        results["failed"] += 1
        print(f"✗ Quantum Encryption: FAIL - {str(e)}")
    
    # Test 2: EM Hardening
    try:
        from em_hardening import EMHardeningSystem
        em_system = EMHardeningSystem()
        
        # Enable Faraday protection
        faraday = em_system.enable_faraday_protection()
        assert faraday["status"] == "active", "Faraday protection not active"
        
        # Test frequency hopping
        profile = em_system.adaptive_frequency_hop()
        assert profile.frequency > 0, "Invalid frequency"
        
        # Test SDR detection
        detection = em_system.detect_em_scan(-25.0, 2400.0)
        assert "threat_level" in detection, "SDR detection failed"
        
        results["tests"].append(("EM Hardening", "PASS"))
        results["passed"] += 1
        print("✓ EM Hardening: PASS")
    except Exception as e:
        results["tests"].append(("EM Hardening", f"FAIL: {str(e)}"))
        results["failed"] += 1
        print(f"✗ EM Hardening: FAIL - {str(e)}")
    
    # Test 3: ML Early Warning
    try:
        from ml_early_warning import MLEarlyWarningSystem, ProtocolEvent
        import numpy as np
        
        ml_system = MLEarlyWarningSystem(threshold=0.85)
        
        # Create training data
        training_events = [
            ProtocolEvent(
                timestamp=time.time(),
                protocol_type="TCP",
                packet_size=np.random.randint(500, 1500),
                frequency=2400.0 + np.random.uniform(-10, 10),
                source_ip=f"192.168.1.{i}",
                destination_ip="10.0.0.1",
                flags=["SYN", "ACK"]
            )
            for i in range(50)
        ]
        
        # Train baseline
        train_result = ml_system.train_baseline(training_events)
        assert train_result["status"] == "success", "Training failed"
        
        # Test detection
        test_event = ProtocolEvent(
            timestamp=time.time(),
            protocol_type="TCP",
            packet_size=1000,
            frequency=2405.0,
            source_ip="192.168.1.50",
            destination_ip="10.0.0.1",
            flags=["SYN"]
        )
        
        detection = ml_system.detect_anomaly(test_event)
        assert "anomaly_score" in detection, "Anomaly detection failed"
        
        results["tests"].append(("ML Early Warning", "PASS"))
        results["passed"] += 1
        print("✓ ML Early Warning: PASS")
    except Exception as e:
        results["tests"].append(("ML Early Warning", f"FAIL: {str(e)}"))
        results["failed"] += 1
        print(f"✗ ML Early Warning: FAIL - {str(e)}")
    
    return results


def test_scenario_b() -> Dict[str, Any]:
    """Test Scenario B: Systemstörungen und Sabotage"""
    print("\n" + "="*60)
    print("TESTING SCENARIO B: Systemstörungen und Sabotage")
    print("="*60)
    
    results = {"passed": 0, "failed": 0, "tests": []}
    
    # Test 1: Blockchain Fork Detection
    try:
        from blockchain_fork_detector import BlockchainForkDetector, BlockHeader
        import hashlib
        
        detector = BlockchainForkDetector()
        
        # Create canonical chain
        prev_hash = "0" * 64
        for i in range(5):
            header = BlockHeader(
                block_number=i,
                timestamp=time.time() + i,
                previous_hash=prev_hash,
                merkle_root=hashlib.sha256(f"merkle{i}".encode()).hexdigest(),
                nonce=i * 1000,
                difficulty=1000000
            )
            result = detector.add_block(header)
            prev_hash = header.hash()
        
        # Verify continuity
        stats = detector.get_fork_statistics()
        assert "total_forks" in stats, "Fork statistics failed"
        
        results["tests"].append(("Blockchain Fork Detection", "PASS"))
        results["passed"] += 1
        print("✓ Blockchain Fork Detection: PASS")
    except Exception as e:
        results["tests"].append(("Blockchain Fork Detection", f"FAIL: {str(e)}"))
        results["failed"] += 1
        print(f"✗ Blockchain Fork Detection: FAIL - {str(e)}")
    
    # Test 2: AI Data Validation
    try:
        from ai_data_validator import AIDataValidator, DataSample
        import numpy as np
        
        validator = AIDataValidator(poisoning_threshold=0.7)
        
        # Create test samples
        samples = []
        for i in range(5):
            sample = DataSample(
                sample_id=f"sample_{i}",
                data=[np.random.randn() for _ in range(10)],
                label=i % 2,
                source="trusted_source",
                timestamp=time.time(),
                metadata={"version": "1.0", "format": "array"}
            )
            samples.append(sample)
        
        # Validate batch
        batch_result = validator.validate_batch(samples)
        assert "accepted" in batch_result, "Batch validation failed"
        assert batch_result["total_samples"] == 5, "Wrong sample count"
        
        results["tests"].append(("AI Data Validation", "PASS"))
        results["passed"] += 1
        print("✓ AI Data Validation: PASS")
    except Exception as e:
        results["tests"].append(("AI Data Validation", f"FAIL: {str(e)}"))
        results["failed"] += 1
        print(f"✗ AI Data Validation: FAIL - {str(e)}")
    
    return results


def test_scenario_c() -> Dict[str, Any]:
    """Test Scenario C: Globale Angriffe und Koordination"""
    print("\n" + "="*60)
    print("TESTING SCENARIO C: Globale Angriffe und Koordination")
    print("="*60)
    
    results = {"passed": 0, "failed": 0, "tests": []}
    
    # Test 1: Geo-Zone Filtering
    try:
        from geo_zone_filter import GeoZoneFilter, ActivityEvent, GeoLocation
        
        geofilter = GeoZoneFilter()
        
        # Test trusted zone
        event = ActivityEvent(
            event_id="evt_001",
            ip_address="192.168.1.1",
            location=GeoLocation(47.3769, 8.5417, "CH", "Zurich", "Zurich"),
            activity_type="transact",
            timestamp=time.time(),
            metadata={"amount": 100}
        )
        
        result = geofilter.filter_activity(event)
        assert result["action"] == "ALLOW", "Trusted zone filtering failed"
        
        # Test restricted zone
        event2 = ActivityEvent(
            event_id="evt_002",
            ip_address="203.0.113.1",
            location=GeoLocation(39.9042, 116.4074, "CN", "Beijing", "Beijing"),
            activity_type="write",
            timestamp=time.time(),
            metadata={}
        )
        
        result2 = geofilter.filter_activity(event2)
        assert result2["action"] == "BLOCK", "Restricted zone filtering failed"
        
        results["tests"].append(("Geo-Zone Filtering", "PASS"))
        results["passed"] += 1
        print("✓ Geo-Zone Filtering: PASS")
    except Exception as e:
        results["tests"].append(("Geo-Zone Filtering", f"FAIL: {str(e)}"))
        results["failed"] += 1
        print(f"✗ Geo-Zone Filtering: FAIL - {str(e)}")
    
    # Test 2: Mesh Networking
    try:
        from mesh_network import MeshNetwork, MeshNode, NodeStatus
        
        mesh = MeshNetwork(node_id="node_alpha", min_peer_count=3)
        
        # Add peers
        peer1 = MeshNode(
            node_id="node_beta",
            ip_address="10.0.0.2",
            public_key="pub_key_beta",
            status=NodeStatus.ACTIVE,
            reputation=0.9,
            connected_peers=["node_alpha"],
            last_seen=time.time(),
            capabilities=["routing"]
        )
        
        result = mesh.add_peer(peer1)
        assert result["status"] == "connected", "Peer connection failed"
        
        # Check network health
        stats = mesh.get_network_statistics()
        assert stats["total_nodes"] == 2, "Wrong node count"
        
        results["tests"].append(("Mesh Networking", "PASS"))
        results["passed"] += 1
        print("✓ Mesh Networking: PASS")
    except Exception as e:
        results["tests"].append(("Mesh Networking", f"FAIL: {str(e)}"))
        results["failed"] += 1
        print(f"✗ Mesh Networking: FAIL - {str(e)}")
    
    return results


def test_integrated_system() -> Dict[str, Any]:
    """Test Integrated Security System"""
    print("\n" + "="*60)
    print("TESTING INTEGRATED SECURITY SYSTEM")
    print("="*60)
    
    results = {"passed": 0, "failed": 0, "tests": []}
    
    try:
        from integrated_security import IntegratedSecuritySystem
        
        security = IntegratedSecuritySystem()
        
        # Initialize all systems
        init_result = security.initialize_defense_systems()
        assert "systems" in init_result, "Initialization failed"
        
        # Assess threat level
        status = security.assess_threat_level()
        assert status.threat_level in ["LOW", "MEDIUM", "HIGH", "CRITICAL"], "Invalid threat level"
        
        # Export report
        report = security.export_security_report()
        assert len(report) > 0, "Report export failed"
        
        results["tests"].append(("Integrated Security System", "PASS"))
        results["passed"] += 1
        print("✓ Integrated Security System: PASS")
    except Exception as e:
        results["tests"].append(("Integrated Security System", f"FAIL: {str(e)}"))
        results["failed"] += 1
        print(f"✗ Integrated Security System: FAIL - {str(e)}")
    
    return results


def main():
    """Run all tests"""
    print("\n" + "="*60)
    print("NEXUS SECURITY MODULE INTEGRATION TEST SUITE")
    print("="*60)
    
    all_results = {
        "scenario_a": test_scenario_a(),
        "scenario_b": test_scenario_b(),
        "scenario_c": test_scenario_c(),
        "integrated": test_integrated_system()
    }
    
    # Calculate totals
    total_passed = sum(r["passed"] for r in all_results.values())
    total_failed = sum(r["failed"] for r in all_results.values())
    total_tests = total_passed + total_failed
    
    # Print summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    print(f"Total Tests: {total_tests}")
    print(f"Passed: {total_passed} ({100*total_passed/total_tests if total_tests > 0 else 0:.1f}%)")
    print(f"Failed: {total_failed}")
    print()
    
    for scenario, results in all_results.items():
        print(f"{scenario.upper()}:")
        for test_name, status in results["tests"]:
            print(f"  {test_name}: {status}")
    
    print("\n" + "="*60)
    if total_failed == 0:
        print("✓ ALL TESTS PASSED - SECURITY SYSTEM OPERATIONAL")
        print("="*60)
        return 0
    else:
        print("✗ SOME TESTS FAILED - REVIEW REQUIRED")
        print("="*60)
        return 1


if __name__ == "__main__":
    sys.exit(main())
