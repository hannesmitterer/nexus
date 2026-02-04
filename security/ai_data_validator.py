#!/usr/bin/env python3
"""
AI Data Validator - Detects and Reduces Data Poisoning
Implements validation and sanitization for AI training data
Part of Scenario B: Systemstörungen und Sabotage defense
"""

import json
import hashlib
import time
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass, asdict
import numpy as np


@dataclass
class DataSample:
    """Represents a training data sample"""
    sample_id: str
    data: Any
    label: Optional[Any]
    source: str
    timestamp: float
    metadata: Dict[str, Any]


@dataclass
class ValidationResult:
    """Result of data validation"""
    is_valid: bool
    confidence: float
    anomalies: List[str]
    poisoning_indicators: List[str]
    recommendation: str


class AIDataValidator:
    """
    Validates AI training data to detect and prevent data poisoning attacks
    """
    
    def __init__(self, poisoning_threshold: float = 0.7):
        """
        Initialize AI data validator
        
        Args:
            poisoning_threshold: Threshold for poisoning detection (0-1)
        """
        self.poisoning_threshold = poisoning_threshold
        self.validated_samples: List[DataSample] = []
        self.rejected_samples: List[DataSample] = []
        self.data_fingerprints: set = set()
        self.source_reputation: Dict[str, float] = {}
    
    def validate_sample(self, sample: DataSample) -> ValidationResult:
        """
        Validate a single data sample for poisoning
        
        Args:
            sample: Data sample to validate
            
        Returns:
            Validation result
        """
        anomalies = []
        poisoning_indicators = []
        confidence = 1.0
        
        # Check 1: Duplicate detection
        fingerprint = self._generate_fingerprint(sample)
        if fingerprint in self.data_fingerprints:
            anomalies.append("duplicate_sample")
            confidence *= 0.5
        
        # Check 2: Source reputation
        source_score = self.source_reputation.get(sample.source, 0.5)
        if source_score < 0.3:
            poisoning_indicators.append("low_reputation_source")
            confidence *= 0.7
        
        # Check 3: Statistical anomaly detection
        if isinstance(sample.data, (list, np.ndarray)):
            stat_anomalies = self._detect_statistical_anomalies(sample.data)
            anomalies.extend(stat_anomalies)
            if stat_anomalies:
                confidence *= 0.6
        
        # Check 4: Label consistency (if applicable)
        if sample.label is not None:
            label_check = self._check_label_consistency(sample)
            if not label_check["consistent"]:
                poisoning_indicators.append("inconsistent_label")
                confidence *= 0.5
        
        # Check 5: Metadata validation
        metadata_issues = self._validate_metadata(sample.metadata)
        if metadata_issues:
            anomalies.extend(metadata_issues)
            confidence *= 0.8
        
        # Calculate poisoning score
        poisoning_score = 1.0 - confidence
        is_poisoned = poisoning_score >= self.poisoning_threshold
        
        # Determine recommendation
        if is_poisoned:
            recommendation = "REJECT"
        elif poisoning_score >= 0.5:
            recommendation = "QUARANTINE"
        else:
            recommendation = "ACCEPT"
        
        result = ValidationResult(
            is_valid=not is_poisoned,
            confidence=confidence,
            anomalies=anomalies,
            poisoning_indicators=poisoning_indicators,
            recommendation=recommendation
        )
        
        # Store result
        if result.is_valid:
            self.validated_samples.append(sample)
            self.data_fingerprints.add(fingerprint)
        else:
            self.rejected_samples.append(sample)
        
        # Update source reputation
        self._update_source_reputation(sample.source, result.is_valid)
        
        return result
    
    def validate_batch(self, samples: List[DataSample]) -> Dict[str, Any]:
        """
        Validate a batch of samples
        
        Args:
            samples: List of data samples
            
        Returns:
            Batch validation results
        """
        results = []
        accepted = 0
        rejected = 0
        quarantined = 0
        
        for sample in samples:
            result = self.validate_sample(sample)
            results.append({
                "sample_id": sample.sample_id,
                "result": asdict(result)
            })
            
            if result.recommendation == "ACCEPT":
                accepted += 1
            elif result.recommendation == "REJECT":
                rejected += 1
            else:
                quarantined += 1
        
        return {
            "total_samples": len(samples),
            "accepted": accepted,
            "rejected": rejected,
            "quarantined": quarantined,
            "acceptance_rate": accepted / len(samples) if samples else 0,
            "results": results,
            "timestamp": time.time()
        }
    
    def detect_poisoning_campaign(self, window_size: int = 100) -> Dict[str, Any]:
        """
        Detect coordinated poisoning campaigns
        
        Args:
            window_size: Number of recent samples to analyze
            
        Returns:
            Campaign detection results
        """
        if len(self.rejected_samples) < 10:
            return {"status": "insufficient_data"}
        
        recent_rejected = self.rejected_samples[-window_size:]
        
        # Analyze patterns
        sources = {}
        timestamps = []
        
        for sample in recent_rejected:
            sources[sample.source] = sources.get(sample.source, 0) + 1
            timestamps.append(sample.timestamp)
        
        # Check for concentrated sources (potential attacker)
        suspicious_sources = {
            src: count for src, count in sources.items()
            if count >= 5
        }
        
        # Check for temporal clustering
        if len(timestamps) >= 2:
            time_diffs = np.diff(sorted(timestamps))
            avg_time_diff = np.mean(time_diffs)
            temporal_clustering = avg_time_diff < 60.0  # Less than 1 minute apart
        else:
            temporal_clustering = False
        
        campaign_detected = len(suspicious_sources) > 0 or temporal_clustering
        
        return {
            "campaign_detected": campaign_detected,
            "suspicious_sources": suspicious_sources,
            "temporal_clustering": temporal_clustering,
            "rejected_in_window": len(recent_rejected),
            "threat_level": "HIGH" if campaign_detected else "LOW",
            "timestamp": time.time()
        }
    
    def sanitize_dataset(self, samples: List[DataSample]) -> Tuple[List[DataSample], Dict[str, Any]]:
        """
        Sanitize a dataset by removing poisoned samples
        
        Args:
            samples: Dataset to sanitize
            
        Returns:
            Tuple of (clean_samples, sanitization_report)
        """
        clean_samples = []
        removed_count = 0
        
        for sample in samples:
            result = self.validate_sample(sample)
            if result.recommendation == "ACCEPT":
                clean_samples.append(sample)
            else:
                removed_count += 1
        
        report = {
            "original_size": len(samples),
            "cleaned_size": len(clean_samples),
            "removed_count": removed_count,
            "removal_rate": removed_count / len(samples) if samples else 0,
            "sanitization_timestamp": time.time()
        }
        
        return clean_samples, report
    
    def _generate_fingerprint(self, sample: DataSample) -> str:
        """Generate unique fingerprint for sample"""
        data_str = json.dumps(sample.data, sort_keys=True, default=str)
        return hashlib.sha256(data_str.encode()).hexdigest()
    
    def _detect_statistical_anomalies(self, data: Any) -> List[str]:
        """Detect statistical anomalies in data"""
        anomalies = []
        
        try:
            if isinstance(data, (list, np.ndarray)):
                arr = np.array(data, dtype=float)
                
                # Check for extreme values
                if len(arr) > 0:
                    mean = np.mean(arr)
                    std = np.std(arr)
                    
                    if std > 0:
                        z_scores = np.abs((arr - mean) / std)
                        if np.any(z_scores > 5):
                            anomalies.append("extreme_outliers")
                
                # Check for suspicious patterns
                if len(arr) > 10:
                    # Check for constant values
                    if np.std(arr) < 1e-6:
                        anomalies.append("constant_values")
                    
                    # Check for infinite or NaN values
                    if np.any(np.isinf(arr)) or np.any(np.isnan(arr)):
                        anomalies.append("invalid_values")
        
        except Exception:
            anomalies.append("malformed_data")
        
        return anomalies
    
    def _check_label_consistency(self, sample: DataSample) -> Dict[str, Any]:
        """Check if label is consistent with similar samples"""
        # Simplified consistency check
        # In production, would use nearest neighbors or clustering
        
        if not self.validated_samples:
            return {"consistent": True, "confidence": 0.5}
        
        # For now, assume consistency
        return {"consistent": True, "confidence": 0.8}
    
    def _validate_metadata(self, metadata: Dict[str, Any]) -> List[str]:
        """Validate sample metadata"""
        issues = []
        
        # Check for required fields
        required_fields = ["version", "format"]
        for field in required_fields:
            if field not in metadata:
                issues.append(f"missing_{field}")
        
        # Check for suspicious metadata
        if "injected" in str(metadata).lower() or "poisoned" in str(metadata).lower():
            issues.append("suspicious_metadata_content")
        
        return issues
    
    def _update_source_reputation(self, source: str, is_valid: bool):
        """Update reputation score for data source"""
        current_score = self.source_reputation.get(source, 0.5)
        
        # Update using exponential moving average
        alpha = 0.1
        new_score = current_score + alpha * (1.0 if is_valid else -0.5)
        
        # Clamp between 0 and 1
        self.source_reputation[source] = max(0.0, min(1.0, new_score))
    
    def get_validation_statistics(self) -> Dict[str, Any]:
        """Get overall validation statistics"""
        total_processed = len(self.validated_samples) + len(self.rejected_samples)
        
        return {
            "total_processed": total_processed,
            "validated": len(self.validated_samples),
            "rejected": len(self.rejected_samples),
            "rejection_rate": len(self.rejected_samples) / total_processed if total_processed > 0 else 0,
            "unique_sources": len(self.source_reputation),
            "source_reputations": dict(sorted(
                self.source_reputation.items(),
                key=lambda x: x[1],
                reverse=True
            )[:10]),  # Top 10 sources
            "timestamp": time.time()
        }


if __name__ == "__main__":
    # Example usage
    validator = AIDataValidator(poisoning_threshold=0.7)
    
    # Create test samples
    samples = []
    
    # Normal samples
    for i in range(10):
        sample = DataSample(
            sample_id=f"normal_{i}",
            data=[np.random.randn() for _ in range(10)],
            label=i % 2,
            source="trusted_source",
            timestamp=time.time(),
            metadata={"version": "1.0", "format": "array"}
        )
        samples.append(sample)
    
    # Poisoned sample
    poisoned = DataSample(
        sample_id="poisoned_1",
        data=[1000.0] * 10,  # Extreme values
        label=1,
        source="unknown_source",
        timestamp=time.time(),
        metadata={}  # Missing required fields
    )
    samples.append(poisoned)
    
    # Validate batch
    results = validator.validate_batch(samples)
    print(json.dumps(results, indent=2, default=str))
    
    # Check for campaigns
    campaign = validator.detect_poisoning_campaign()
    print(f"\nCampaign Detection: {campaign}")
    
    # Get statistics
    stats = validator.get_validation_statistics()
    print(f"\nValidation Statistics: {json.dumps(stats, indent=2)}")
