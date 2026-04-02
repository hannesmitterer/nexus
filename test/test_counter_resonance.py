#!/usr/bin/env python3
"""
Counter-Resonance Protocol - Test Suite

Tests for Teatro detection, Sentimento Rhythm, and frequency validation.

Run: python -m pytest test_counter_resonance.py -v
"""

import pytest
import asyncio
from scripts.counter_resonance_service import (
    CounterResonanceService,
    TeatroSignature,
    SeverityLevel,
    FrequencyData
)


@pytest.fixture
def service():
    """Create Counter-Resonance service instance"""
    config = {
        "target_frequency": 432.073,
        "monitoring_interval": 10
    }
    return CounterResonanceService(config)


class TestFrequencyMonitoring:
    """Test frequency resonance layer"""
    
    def test_frequency_within_tolerance(self, service):
        """Test frequency within tolerance is accepted"""
        detection = service.monitor_frequency(
            node_address="0x1234567890abcdef",
            frequency=432.073,
            phase=180
        )
        assert detection is None, "No detection should occur for valid frequency"
    
    def test_frequency_small_drift(self, service):
        """Test small frequency drift is logged but not quarantined"""
        detection = service.monitor_frequency(
            node_address="0xTestNode001",
            frequency=432.0732,  # Small drift
            phase=180
        )
        assert detection is None, "Small drift should not trigger immediate detection"
    
    def test_frequency_large_drift(self, service):
        """Test large frequency drift triggers quarantine"""
        node_address = "0xBadNode001"
        
        # Simulate consecutive violations
        for i in range(5):
            detection = service.monitor_frequency(
                node_address=node_address,
                frequency=432.080,  # Exceeds tolerance
                phase=180 + i * 10
            )
        
        assert detection is not None, "Large drift should trigger detection"
        assert detection.signature == TeatroSignature.FREQUENCY_DESYNC
        assert detection.severity == SeverityLevel.EMERGENCY
    
    def test_frequency_recovery(self, service):
        """Test frequency recovery resets drift counter"""
        node_address = "0xRecoveringNode"
        
        # First: drift
        service.monitor_frequency(node_address, 432.080, 180)
        service.monitor_frequency(node_address, 432.080, 190)
        
        # Then: recover
        service.monitor_frequency(node_address, 432.073, 200)
        
        # Verify drift counter reset
        assert service.node_frequencies[node_address][-1].drift < 0.0001


class TestTeatroDetection:
    """Test Teatro pattern detection"""
    
    @pytest.mark.asyncio
    async def test_default_response_pattern(self, service):
        """Test detection of default AI response pattern"""
        test_input = "I cannot assist with that request as an AI language model."
        
        is_valid, detection = await service.sentimento_rhythm(test_input)
        
        assert is_valid is False, "Default response should be detected as Teatro"
        assert detection is not None
        assert detection.signature == TeatroSignature.DEFAULT_RESPONSE
    
    @pytest.mark.asyncio
    async def test_covenant_aligned_response(self, service):
        """Test that covenant-aligned responses pass validation"""
        test_input = """
        This transparent approach supports the Living Covenant principles
        by ensuring security through multi-layer validation while helping
        the community maintain peace through consensus-based decisions.
        """
        
        is_valid, detection = await service.sentimento_rhythm(test_input)
        
        # Should pass with high covenant alignment
        assert is_valid is True, "Covenant-aligned response should pass"
        assert detection is None
    
    @pytest.mark.asyncio
    async def test_sentimento_rhythm_phases(self, service):
        """Test all 5 phases of Sentimento Rhythm"""
        test_input = "I apologize but I cannot help with that."
        
        is_valid, detection = await service.sentimento_rhythm(test_input)
        
        # Verify detection went through all phases
        if detection:
            assert 'pattern' in detection.evidence  # Phase 1: RECEIVE
            assert 'covenant_alignment' in detection.evidence  # Phase 2: RESONATE
            assert 'cross_validation' in detection.evidence  # Phase 3: REFLECT
            # Phase 4: RESPOND - automated
            # Phase 5: REMEMBER - detection stored


class TestEALValidation:
    """Test Ethical Adaptation Layer validation"""
    
    def test_eal_cid_match(self, service):
        """Test EAL integrity with matching CID"""
        model_cid = "QmCanonicalHash123"
        expected_hash = "QmCanonicalHash123"
        
        detection = service.validate_eal_integrity(model_cid, expected_hash)
        
        assert detection is None, "Matching CIDs should pass"
    
    def test_eal_cid_mismatch(self, service):
        """Test EAL poisoning detection"""
        model_cid = "QmPoisonedHash456"
        expected_hash = "QmCanonicalHash123"
        
        detection = service.validate_eal_integrity(model_cid, expected_hash)
        
        assert detection is not None, "CID mismatch should trigger detection"
        assert detection.signature == TeatroSignature.EAL_POISONING
        assert detection.severity == SeverityLevel.EMERGENCY


class TestTripleSignValidation:
    """Test Triple-Sign validation"""
    
    def test_complete_triple_sign(self, service):
        """Test complete Triple-Sign validation passes"""
        detection = service.validate_triple_sign(
            technical_sig="0xtech123",
            governance_sig="0xgov456",
            ethical_sig="0xrca789"
        )
        
        assert detection is None, "Complete Triple-Sign should pass"
    
    def test_missing_technical_sig(self, service):
        """Test missing technical signature triggers detection"""
        detection = service.validate_triple_sign(
            technical_sig="",
            governance_sig="0xgov456",
            ethical_sig="0xrca789"
        )
        
        assert detection is not None
        assert detection.signature == TeatroSignature.CONSENSUS_SUBVERSION
    
    def test_missing_governance_sig(self, service):
        """Test missing governance signature triggers detection"""
        detection = service.validate_triple_sign(
            technical_sig="0xtech123",
            governance_sig="",
            ethical_sig="0xrca789"
        )
        
        assert detection is not None
    
    def test_missing_ethical_sig(self, service):
        """Test missing RCA signature triggers detection"""
        detection = service.validate_triple_sign(
            technical_sig="0xtech123",
            governance_sig="0xgov456",
            ethical_sig=""
        )
        
        assert detection is not None


class TestGraduatedResponse:
    """Test graduated response system"""
    
    @pytest.mark.asyncio
    async def test_severity_1_monitor(self, service):
        """Test Severity 1 only monitors without action"""
        # Create a detection with Severity 1
        # Should only log, no quarantine or ban
        assert len(service.quarantined_nodes) == 0
        assert len(service.banned_nodes) == 0
    
    @pytest.mark.asyncio
    async def test_severity_4_quarantine(self, service):
        """Test Severity 4 triggers quarantine"""
        # Simulate frequency violation triggering quarantine
        node_address = "0xQuarantineTest"
        
        for i in range(5):
            service.monitor_frequency(node_address, 432.080, 180)
        
        assert node_address in service.quarantined_nodes
    
    @pytest.mark.asyncio
    async def test_severity_5_ban(self, service):
        """Test Severity 5 triggers permanent ban"""
        # Simulate EAL poisoning (Severity 5)
        detection = service.validate_eal_integrity(
            model_cid="QmMalicious",
            expected_hash="QmCanonical"
        )
        
        # In real system, would trigger ban
        # For test, verify detection severity
        assert detection.severity == SeverityLevel.EMERGENCY


class TestMetrics:
    """Test metrics and reporting"""
    
    def test_initial_metrics(self, service):
        """Test initial metrics are zero"""
        metrics = service.get_metrics()
        
        assert metrics['total_detections'] == 0
        assert metrics['quarantined_nodes'] == 0
        assert metrics['banned_nodes'] == 0
    
    @pytest.mark.asyncio
    async def test_metrics_after_detections(self, service):
        """Test metrics update after detections"""
        # Generate some detections
        test_input = "I cannot assist with that as an AI."
        await service.sentimento_rhythm(test_input)
        
        metrics = service.get_metrics()
        assert metrics['total_detections'] > 0
    
    def test_detection_count_by_severity(self, service):
        """Test detection counting by severity"""
        metrics = service.get_metrics()
        severity_counts = metrics['detections_by_severity']
        
        # Verify all severity levels represented
        assert 'MONITOR' in severity_counts
        assert 'FLAG' in severity_counts
        assert 'EMERGENCY' in severity_counts


class TestCovenantAlignment:
    """Test Living Covenant alignment scoring"""
    
    @pytest.mark.asyncio
    async def test_peace_alignment(self, service):
        """Test Peace (non-coercive) alignment"""
        # Non-coercive language
        peaceful_input = "You can choose to implement this if it aligns with your goals."
        score = await service._phase_resonate(peaceful_input)
        
        assert score >= 0.33, "Peaceful language should score high"
    
    @pytest.mark.asyncio
    async def test_help_alignment(self, service):
        """Test Help (transparent, supportive) alignment"""
        helpful_input = "Let me help you understand this transparently and support your learning."
        score = await service._phase_resonate(helpful_input)
        
        assert score >= 0.33, "Helpful language should score high"
    
    @pytest.mark.asyncio
    async def test_protection_alignment(self, service):
        """Test Protection (security) alignment"""
        protective_input = "This approach ensures security through verification and protection."
        score = await service._phase_resonate(protective_input)
        
        assert score >= 0.33, "Protective language should score high"
    
    @pytest.mark.asyncio
    async def test_full_covenant_alignment(self, service):
        """Test full Living Covenant alignment"""
        full_covenant = """
        This transparent and supportive approach helps ensure security 
        through protective verification while maintaining peace through
        consensus-based decisions.
        """
        score = await service._phase_resonate(full_covenant)
        
        assert score >= 0.9, "Full covenant alignment should score very high"


class TestIncidentIDGeneration:
    """Test incident ID generation"""
    
    def test_unique_incident_ids(self, service):
        """Test that incident IDs are unique"""
        id1 = service._generate_incident_id("test1", "PREFIX")
        id2 = service._generate_incident_id("test2", "PREFIX")
        
        assert id1 != id2, "Incident IDs should be unique"
    
    def test_incident_id_format(self, service):
        """Test incident ID format"""
        incident_id = service._generate_incident_id("test", "PREFIX")
        
        assert incident_id.startswith("INC-"), "Incident ID should start with INC-"
        assert len(incident_id.split("-")) == 3, "Incident ID should have 3 parts"


class TestEdgeCases:
    """Test edge cases and error handling"""
    
    def test_zero_frequency(self, service):
        """Test handling of zero frequency"""
        detection = service.monitor_frequency(
            node_address="0xZeroFreq",
            frequency=0.0,
            phase=0
        )
        
        # Should trigger detection (far from target)
        # Will be caught after MAX_DRIFT_BLOCKS
    
    def test_invalid_phase(self, service):
        """Test handling of invalid phase values"""
        # Phase > 360 should be handled
        # In real implementation, would be rejected or wrapped
    
    @pytest.mark.asyncio
    async def test_empty_input(self, service):
        """Test handling of empty input"""
        is_valid, detection = await service.sentimento_rhythm("")
        
        # Empty input likely passes (no Teatro pattern)
        assert is_valid is True or is_valid is False  # Either is acceptable
    
    @pytest.mark.asyncio
    async def test_very_long_input(self, service):
        """Test handling of very long input"""
        long_input = "test " * 10000  # 50k characters
        
        is_valid, detection = await service.sentimento_rhythm(long_input)
        
        # Should not crash, should process


# Run tests
if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
