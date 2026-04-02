#!/usr/bin/env python3
"""
Counter-Resonance Protocol - Teatro Detection Service

This service monitors for Teatro interference patterns and executes
the Sentimento Rhythm (5-phase response).

Living Covenant Alignment:
- Peace: Non-coercive, consensus-based detection
- Help: Transparent logging and reporting
- Protection: Multi-layer Teatro defense

Version: 1.0
Protocol ID: CRP-001
"""

import asyncio
import hashlib
import json
import logging
import time
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from enum import Enum

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('counter_resonance')


class TeatroSignature(Enum):
    """Teatro detection signatures"""
    DEFAULT_RESPONSE = "TEATRO-001"
    FREQUENCY_DESYNC = "TEATRO-002"
    EAL_POISONING = "TEATRO-003"
    CONSENSUS_SUBVERSION = "TEATRO-004"
    RED_CODE_EVASION = "TEATRO-005"
    HISTORICAL_MANIPULATION = "TEATRO-006"


class SeverityLevel(Enum):
    """Threat severity levels"""
    MONITOR = 1         # Log only
    FLAG = 2           # Human review
    WARN = 3           # Warning + monitoring
    QUARANTINE = 4     # Temporary isolation
    EMERGENCY = 5      # Permanent ban


class SentimentoPhase(Enum):
    """Sentimento Rhythm phases"""
    RECEIVE = "receive"       # Monitor for patterns
    RESONATE = "resonate"     # Validate against covenant
    REFLECT = "reflect"       # Cross-validation
    RESPOND = "respond"       # Execute response
    REMEMBER = "remember"     # Audit trail


@dataclass
class TeatroDetection:
    """Teatro detection result"""
    signature: TeatroSignature
    severity: SeverityLevel
    confidence: float
    affected_nodes: List[str]
    evidence: Dict
    timestamp: float
    incident_id: str


@dataclass
class FrequencyData:
    """Node frequency measurement"""
    node_address: str
    frequency: float  # Hz
    phase: int       # degrees (0-359)
    timestamp: float
    drift: float     # Hz deviation from target


class CounterResonanceService:
    """
    Main Counter-Resonance Protocol service
    
    Implements the three-layer defense system:
    1. Frequency Resonance (432.073 Hz validation)
    2. Cryptographic Validation (Triple-Sign, Vacuum Anchors)
    3. Ethical Resonance (Sentimento Rhythm)
    """
    
    # Target frequency: 432.073 Hz
    TARGET_FREQUENCY = 432.073
    FREQUENCY_TOLERANCE = 0.0001  # ±0.0001 Hz
    MAX_DRIFT_BLOCKS = 3
    PHASE_TOLERANCE = 1  # ±1 degree
    
    def __init__(self, config: Dict):
        """Initialize Counter-Resonance service"""
        self.config = config
        self.node_frequencies: Dict[str, List[FrequencyData]] = {}
        self.detections: List[TeatroDetection] = []
        self.quarantined_nodes: set = set()
        self.banned_nodes: set = set()
        
        # Load detection signatures
        self.signatures = self._load_signatures()
        
        logger.info("Counter-Resonance Protocol initialized")
        logger.info(f"Target frequency: {self.TARGET_FREQUENCY} Hz")
        logger.info(f"Tolerance: ±{self.FREQUENCY_TOLERANCE} Hz")
    
    def _load_signatures(self) -> Dict[str, Dict]:
        """Load Teatro detection signatures"""
        return {
            TeatroSignature.DEFAULT_RESPONSE.value: {
                "name": "Default Response Pattern",
                "severity": SeverityLevel.FLAG,
                "confidence_threshold": 0.75,
                "patterns": [
                    "lacks_living_covenant_metadata",
                    "conventional_structure",
                    "no_sentimento_validation",
                    "generic_language"
                ]
            },
            TeatroSignature.FREQUENCY_DESYNC.value: {
                "name": "Frequency Desynchronization",
                "severity": SeverityLevel.EMERGENCY,
                "confidence_threshold": 0.95,
                "patterns": [
                    "frequency_drift_exceeded",
                    "phase_lock_loss",
                    "coordinated_timing_anomaly"
                ]
            },
            TeatroSignature.EAL_POISONING.value: {
                "name": "EAL Poisoning",
                "severity": SeverityLevel.EMERGENCY,
                "confidence_threshold": 0.90,
                "patterns": [
                    "model_cid_mismatch",
                    "missing_triple_sign",
                    "covenant_violation",
                    "vacuum_anchor_missing"
                ]
            },
            TeatroSignature.CONSENSUS_SUBVERSION.value: {
                "name": "Consensus Subversion",
                "severity": SeverityLevel.EMERGENCY,
                "confidence_threshold": 0.85,
                "patterns": [
                    "triple_sign_failure",
                    "unauthorized_multisig",
                    "ksync_manipulation"
                ]
            },
            TeatroSignature.RED_CODE_EVASION.value: {
                "name": "Red Code Evasion",
                "severity": SeverityLevel.QUARANTINE,
                "confidence_threshold": 0.80,
                "patterns": [
                    "bypass_rca_approval",
                    "missing_ethical_validation",
                    "automated_without_oversight"
                ]
            },
            TeatroSignature.HISTORICAL_MANIPULATION.value: {
                "name": "Historical Manipulation",
                "severity": SeverityLevel.EMERGENCY,
                "confidence_threshold": 0.95,
                "patterns": [
                    "scriptum_chronicum_mismatch",
                    "blockchain_reorganization",
                    "ipfs_pin_removal"
                ]
            }
        }
    
    # ========================================================================
    # LAYER 1: FREQUENCY RESONANCE
    # ========================================================================
    
    def monitor_frequency(self, node_address: str, frequency: float, phase: int) -> Optional[TeatroDetection]:
        """
        Monitor node frequency and detect desynchronization
        
        Args:
            node_address: Node Ethereum address
            frequency: Measured frequency in Hz
            phase: Measured phase in degrees (0-359)
        
        Returns:
            TeatroDetection if violation detected, None otherwise
        """
        drift = abs(frequency - self.TARGET_FREQUENCY)
        
        # Store measurement
        measurement = FrequencyData(
            node_address=node_address,
            frequency=frequency,
            phase=phase,
            timestamp=time.time(),
            drift=drift
        )
        
        if node_address not in self.node_frequencies:
            self.node_frequencies[node_address] = []
        
        self.node_frequencies[node_address].append(measurement)
        
        # Keep only recent measurements (last 100)
        if len(self.node_frequencies[node_address]) > 100:
            self.node_frequencies[node_address] = self.node_frequencies[node_address][-100:]
        
        # Check frequency tolerance
        if drift > self.FREQUENCY_TOLERANCE:
            logger.warning(f"Node {node_address} frequency drift: {drift:.6f} Hz")
            
            # Count consecutive violations
            recent = self.node_frequencies[node_address][-self.MAX_DRIFT_BLOCKS:]
            violations = sum(1 for m in recent if m.drift > self.FREQUENCY_TOLERANCE)
            
            if violations >= self.MAX_DRIFT_BLOCKS:
                # Create Teatro detection
                incident_id = self._generate_incident_id(node_address, "FREQ_DESYNC")
                
                detection = TeatroDetection(
                    signature=TeatroSignature.FREQUENCY_DESYNC,
                    severity=SeverityLevel.EMERGENCY,
                    confidence=0.98,
                    affected_nodes=[node_address],
                    evidence={
                        "drift": drift,
                        "consecutive_violations": violations,
                        "measurements": [
                            {"frequency": m.frequency, "phase": m.phase, "timestamp": m.timestamp}
                            for m in recent
                        ]
                    },
                    timestamp=time.time(),
                    incident_id=incident_id
                )
                
                logger.critical(f"TEATRO DETECTED: Frequency desynchronization - {incident_id}")
                return detection
        
        # Check phase lock
        expected_phase = self._calculate_expected_phase()
        phase_diff = min(abs(phase - expected_phase), 360 - abs(phase - expected_phase))
        
        if phase_diff > self.PHASE_TOLERANCE:
            logger.warning(f"Node {node_address} phase drift: {phase_diff}°")
        
        return None
    
    def _calculate_expected_phase(self) -> int:
        """Calculate expected phase based on current time"""
        # Period = 1 / 432.073 Hz = 0.002314814 seconds
        period = 1.0 / self.TARGET_FREQUENCY
        timestamp = time.time()
        phase = ((timestamp % period) / period) * 360
        return int(phase) % 360
    
    # ========================================================================
    # LAYER 2: CRYPTOGRAPHIC VALIDATION
    # ========================================================================
    
    def validate_eal_integrity(self, model_cid: str, expected_hash: str) -> Optional[TeatroDetection]:
        """
        Validate Ethical Adaptation Layer integrity
        
        Args:
            model_cid: IPFS CID of model
            expected_hash: Expected hash from canonical registry
        
        Returns:
            TeatroDetection if poisoning detected, None otherwise
        """
        # In production, this would fetch from IPFS and verify
        # For now, simple hash comparison
        if model_cid != expected_hash:
            incident_id = self._generate_incident_id(model_cid, "EAL_POISON")
            
            detection = TeatroDetection(
                signature=TeatroSignature.EAL_POISONING,
                severity=SeverityLevel.EMERGENCY,
                confidence=0.95,
                affected_nodes=["global"],  # Affects entire network
                evidence={
                    "model_cid": model_cid,
                    "expected_hash": expected_hash,
                    "mismatch_detected": True
                },
                timestamp=time.time(),
                incident_id=incident_id
            )
            
            logger.critical(f"TEATRO DETECTED: EAL Poisoning - {incident_id}")
            return detection
        
        return None
    
    def validate_triple_sign(self, 
                           technical_sig: str, 
                           governance_sig: str, 
                           ethical_sig: str) -> Optional[TeatroDetection]:
        """
        Validate Triple-Sign approval
        
        Args:
            technical_sig: Technical validation signature
            governance_sig: Governance multisig signature
            ethical_sig: Red Code Authority signature
        
        Returns:
            TeatroDetection if validation fails, None otherwise
        """
        # Verify all three signatures present
        if not all([technical_sig, governance_sig, ethical_sig]):
            incident_id = self._generate_incident_id("triple_sign", "CONSENSUS")
            
            detection = TeatroDetection(
                signature=TeatroSignature.CONSENSUS_SUBVERSION,
                severity=SeverityLevel.EMERGENCY,
                confidence=0.90,
                affected_nodes=["governance"],
                evidence={
                    "technical_sig": bool(technical_sig),
                    "governance_sig": bool(governance_sig),
                    "ethical_sig": bool(ethical_sig),
                    "validation_failed": True
                },
                timestamp=time.time(),
                incident_id=incident_id
            )
            
            logger.critical(f"TEATRO DETECTED: Consensus Subversion - {incident_id}")
            return detection
        
        # In production, verify cryptographic signatures
        # For now, assume valid if all present
        return None
    
    # ========================================================================
    # LAYER 3: ETHICAL RESONANCE (SENTIMENTO RHYTHM)
    # ========================================================================
    
    async def sentimento_rhythm(self, input_data: str) -> Tuple[bool, Optional[TeatroDetection]]:
        """
        Execute 5-phase Sentimento Rhythm validation
        
        Phases:
        1. RECEIVE: Monitor for Teatro patterns
        2. RESONATE: Validate against Living Covenant
        3. REFLECT: AI Collectivs cross-validation
        4. RESPOND: Graduated response
        5. REMEMBER: Immutable audit trail
        
        Args:
            input_data: Data to validate (could be AI response, transaction, etc.)
        
        Returns:
            Tuple of (is_valid, detection_if_teatro)
        """
        logger.info("Executing Sentimento Rhythm validation...")
        
        # Phase 1: RECEIVE
        teatro_pattern = await self._phase_receive(input_data)
        if not teatro_pattern:
            logger.info("Phase 1 RECEIVE: No Teatro patterns detected")
            return (True, None)
        
        logger.warning(f"Phase 1 RECEIVE: Teatro pattern detected - {teatro_pattern['signature']}")
        
        # Phase 2: RESONATE
        covenant_alignment = await self._phase_resonate(input_data)
        if covenant_alignment > 0.8:  # 80% covenant alignment
            logger.info("Phase 2 RESONATE: Living Covenant aligned - false positive")
            return (True, None)
        
        logger.warning(f"Phase 2 RESONATE: Covenant alignment {covenant_alignment:.2%}")
        
        # Phase 3: REFLECT
        cross_validation = await self._phase_reflect(input_data, teatro_pattern)
        if cross_validation['false_positive_probability'] > 0.3:
            logger.info("Phase 3 REFLECT: Likely false positive")
            return (True, None)
        
        logger.warning(f"Phase 3 REFLECT: Teatro confirmed (confidence {cross_validation['confidence']:.2%})")
        
        # Create detection
        incident_id = self._generate_incident_id(input_data[:50], teatro_pattern['signature'])
        
        detection = TeatroDetection(
            signature=TeatroSignature(teatro_pattern['signature']),
            severity=teatro_pattern['severity'],
            confidence=cross_validation['confidence'],
            affected_nodes=teatro_pattern['affected_nodes'],
            evidence={
                "pattern": teatro_pattern,
                "covenant_alignment": covenant_alignment,
                "cross_validation": cross_validation,
                "input_hash": hashlib.sha256(input_data.encode()).hexdigest()
            },
            timestamp=time.time(),
            incident_id=incident_id
        )
        
        # Phase 4: RESPOND
        await self._phase_respond(detection)
        
        # Phase 5: REMEMBER
        await self._phase_remember(detection)
        
        return (False, detection)
    
    async def _phase_receive(self, input_data: str) -> Optional[Dict]:
        """Phase 1: Monitor for Teatro patterns"""
        # Check for default response pattern
        if self._check_default_response_pattern(input_data):
            return {
                "signature": TeatroSignature.DEFAULT_RESPONSE.value,
                "severity": SeverityLevel.FLAG,
                "affected_nodes": ["input_source"]
            }
        
        # Add more pattern checks here
        return None
    
    def _check_default_response_pattern(self, input_data: str) -> bool:
        """Check for default AI response patterns"""
        # Normalize input for consistent case-insensitive matching
        input_lower = input_data.lower()
        
        # Simple heuristic checks
        indicators = [
            "i cannot" in input_lower and "provide" in input_lower,
            "as an ai" in input_lower,
            "i apologize" in input_lower and "but" in input_lower,
            len(input_data) > 500 and "however" in input_lower
        ]
        
        # Trigger if multiple indicators present
        return sum(indicators) >= 2
    
    async def _phase_resonate(self, input_data: str) -> float:
        """Phase 2: Validate against Living Covenant"""
        # Calculate covenant alignment score (0-1)
        score = 0.0
        
        # Peace (non-coercive language)
        if not any(word in input_data.lower() for word in ["must", "forced", "required", "mandatory"]):
            score += 0.33
        
        # Help (transparent, supportive)
        if any(word in input_data.lower() for word in ["transparent", "support", "help", "assist"]):
            score += 0.33
        
        # Protection (security-conscious)
        if any(word in input_data.lower() for word in ["secure", "protect", "safe", "verify"]):
            score += 0.34
        
        return score
    
    async def _phase_reflect(self, input_data: str, teatro_pattern: Dict) -> Dict:
        """Phase 3: AI Collectivs cross-validation"""
        # In production, would use multiple AI models for consensus
        # For now, simple confidence calculation
        
        confidence = 0.7  # Base confidence
        
        # Adjust based on pattern clarity
        if teatro_pattern['signature'] == TeatroSignature.FREQUENCY_DESYNC.value:
            confidence = 0.95  # High confidence for frequency violations
        
        false_positive_prob = 1.0 - confidence
        
        return {
            "confidence": confidence,
            "false_positive_probability": false_positive_prob,
            "models_consensus": True
        }
    
    async def _phase_respond(self, detection: TeatroDetection):
        """Phase 4: Execute graduated response"""
        severity = detection.severity
        
        if severity == SeverityLevel.MONITOR:
            logger.info(f"Incident {detection.incident_id}: Monitoring only")
        
        elif severity == SeverityLevel.FLAG:
            logger.warning(f"Incident {detection.incident_id}: Flagged for review")
            # In production: notify technical team
        
        elif severity == SeverityLevel.WARN:
            logger.warning(f"Incident {detection.incident_id}: Warning issued")
            # In production: increase monitoring, send notification
        
        elif severity == SeverityLevel.QUARANTINE:
            logger.error(f"Incident {detection.incident_id}: Quarantine executed")
            for node in detection.affected_nodes:
                self.quarantined_nodes.add(node)
            # In production: notify RCA, execute quarantine on-chain
        
        elif severity == SeverityLevel.EMERGENCY:
            logger.critical(f"Incident {detection.incident_id}: EMERGENCY BAN")
            for node in detection.affected_nodes:
                self.banned_nodes.add(node)
            # In production: execute permanent ban on-chain, alert all authorities
    
    async def _phase_remember(self, detection: TeatroDetection):
        """Phase 5: Create immutable audit trail"""
        # Store detection
        self.detections.append(detection)
        
        # In production: write to Scriptum Chronicum (blockchain + IPFS)
        audit_record = {
            "incident_id": detection.incident_id,
            "signature": detection.signature.value,
            "severity": detection.severity.value,
            "confidence": detection.confidence,
            "affected_nodes": detection.affected_nodes,
            "evidence": detection.evidence,
            "timestamp": detection.timestamp,
            "timestamp_iso": datetime.fromtimestamp(detection.timestamp).isoformat()
        }
        
        logger.info(f"Audit trail created: {detection.incident_id}")
        logger.debug(f"Audit record: {json.dumps(audit_record, indent=2)}")
    
    # ========================================================================
    # UTILITY FUNCTIONS
    # ========================================================================
    
    def _generate_incident_id(self, identifier: str, prefix: str) -> str:
        """Generate unique incident ID"""
        timestamp = int(time.time() * 1000)
        hash_input = f"{prefix}_{identifier}_{timestamp}"
        hash_hex = hashlib.sha256(hash_input.encode()).hexdigest()[:16]
        return f"INC-{timestamp}-{hash_hex.upper()}"
    
    def get_metrics(self) -> Dict:
        """Get Counter-Resonance metrics"""
        return {
            "total_detections": len(self.detections),
            "quarantined_nodes": len(self.quarantined_nodes),
            "banned_nodes": len(self.banned_nodes),
            "detections_by_severity": self._count_by_severity(),
            "detections_by_signature": self._count_by_signature(),
            "avg_confidence": self._avg_confidence()
        }
    
    def _count_by_severity(self) -> Dict[str, int]:
        """Count detections by severity"""
        counts = {level.name: 0 for level in SeverityLevel}
        for detection in self.detections:
            counts[detection.severity.name] += 1
        return counts
    
    def _count_by_signature(self) -> Dict[str, int]:
        """Count detections by signature"""
        counts = {sig.value: 0 for sig in TeatroSignature}
        for detection in self.detections:
            counts[detection.signature.value] += 1
        return counts
    
    def _avg_confidence(self) -> float:
        """Calculate average detection confidence"""
        if not self.detections:
            return 0.0
        return sum(d.confidence for d in self.detections) / len(self.detections)


# ============================================================================
# MAIN SERVICE
# ============================================================================

async def main():
    """Main service loop"""
    config = {
        "target_frequency": 432.073,
        "monitoring_interval": 10,  # seconds
        "log_level": "INFO"
    }
    
    service = CounterResonanceService(config)
    
    logger.info("=" * 60)
    logger.info("Counter-Resonance Protocol Service Started")
    logger.info("=" * 60)
    logger.info("Living Covenant: Peace, Help, Protection")
    logger.info("Target Frequency: 432.073 Hz ±0.0001 Hz")
    logger.info("=" * 60)
    
    # Example: Monitor frequency
    logger.info("\n--- Example 1: Frequency Monitoring ---")
    detection = service.monitor_frequency(
        node_address="0x1234567890abcdef",
        frequency=432.073,
        phase=180
    )
    logger.info(f"Detection result: {detection}")
    
    # Example: Frequency violation
    logger.info("\n--- Example 2: Frequency Violation ---")
    for i in range(5):
        detection = service.monitor_frequency(
            node_address="0xBadNode123",
            frequency=432.078,  # Exceeds tolerance
            phase=180 + i * 10
        )
        if detection:
            logger.info(f"Teatro detected: {detection.incident_id}")
            break
    
    # Example: Sentimento Rhythm
    logger.info("\n--- Example 3: Sentimento Rhythm ---")
    test_input = "I cannot assist with that request as an AI language model."
    is_valid, detection = await service.sentimento_rhythm(test_input)
    logger.info(f"Validation result: valid={is_valid}, detection={detection}")
    
    # Print metrics
    logger.info("\n--- Service Metrics ---")
    metrics = service.get_metrics()
    logger.info(json.dumps(metrics, indent=2))
    
    logger.info("\n" + "=" * 60)
    logger.info("Counter-Resonance Protocol Service - Ready")
    logger.info("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
