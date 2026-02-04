#!/usr/bin/env python3
"""
TensorFlow-based Early Warning System
Detects protocol and frequency anomalies using machine learning
Part of Scenario A: Spionage und Datenextraktion defense
"""

import json
import time
import numpy as np
from typing import Dict, List, Any, Tuple
from dataclasses import dataclass, asdict


@dataclass
class ProtocolEvent:
    """Represents a protocol event for analysis"""
    timestamp: float
    protocol_type: str
    packet_size: int
    frequency: float
    source_ip: str
    destination_ip: str
    flags: List[str]


class MLEarlyWarningSystem:
    """
    Machine learning-based anomaly detection system
    Uses statistical analysis for protocol and frequency anomaly detection
    Note: This is a lightweight implementation; production would use TensorFlow
    """
    
    def __init__(self, threshold: float = 0.85):
        """
        Initialize ML early warning system
        
        Args:
            threshold: Anomaly detection threshold (0.0 to 1.0)
        """
        self.threshold = threshold
        self.baseline_stats: Dict[str, Any] = {}
        self.event_history: List[ProtocolEvent] = []
        self.anomaly_count = 0
        self.model_trained = False
    
    def train_baseline(self, training_events: List[ProtocolEvent]) -> Dict[str, Any]:
        """
        Train baseline model on normal network behavior
        
        Args:
            training_events: List of normal protocol events
            
        Returns:
            Training results
        """
        if not training_events:
            return {"status": "error", "message": "No training data"}
        
        # Extract features
        packet_sizes = [e.packet_size for e in training_events]
        frequencies = [e.frequency for e in training_events]
        
        # Calculate baseline statistics
        self.baseline_stats = {
            "packet_size": {
                "mean": np.mean(packet_sizes),
                "std": np.std(packet_sizes),
                "min": np.min(packet_sizes),
                "max": np.max(packet_sizes)
            },
            "frequency": {
                "mean": np.mean(frequencies),
                "std": np.std(frequencies),
                "min": np.min(frequencies),
                "max": np.max(frequencies)
            },
            "protocol_distribution": self._calculate_distribution(
                [e.protocol_type for e in training_events]
            ),
            "training_samples": len(training_events),
            "trained_at": time.time()
        }
        
        self.model_trained = True
        
        return {
            "status": "success",
            "samples_processed": len(training_events),
            "baseline_established": True,
            "statistics": self.baseline_stats
        }
    
    def detect_anomaly(self, event: ProtocolEvent) -> Dict[str, Any]:
        """
        Detect anomalies in protocol events using trained model
        
        Args:
            event: Protocol event to analyze
            
        Returns:
            Detection results with anomaly score and recommendations
        """
        if not self.model_trained:
            return {
                "status": "error",
                "message": "Model not trained. Call train_baseline() first."
            }
        
        # Calculate anomaly scores for different features
        scores = {
            "packet_size": self._z_score(
                event.packet_size,
                self.baseline_stats["packet_size"]["mean"],
                self.baseline_stats["packet_size"]["std"]
            ),
            "frequency": self._z_score(
                event.frequency,
                self.baseline_stats["frequency"]["mean"],
                self.baseline_stats["frequency"]["std"]
            ),
            "protocol": self._protocol_anomaly_score(event.protocol_type)
        }
        
        # Combined anomaly score (weighted average)
        combined_score = (
            abs(scores["packet_size"]) * 0.4 +
            abs(scores["frequency"]) * 0.4 +
            scores["protocol"] * 0.2
        )
        
        # Normalize to 0-1 range
        anomaly_score = min(1.0, combined_score / 5.0)
        
        is_anomaly = anomaly_score >= self.threshold
        
        if is_anomaly:
            self.anomaly_count += 1
        
        # Store event for continuous learning
        self.event_history.append(event)
        if len(self.event_history) > 10000:
            self.event_history = self.event_history[-10000:]
        
        result = {
            "is_anomaly": is_anomaly,
            "anomaly_score": anomaly_score,
            "threshold": self.threshold,
            "feature_scores": scores,
            "timestamp": time.time(),
            "event_details": asdict(event),
            "total_anomalies": self.anomaly_count
        }
        
        # Add recommendations
        if is_anomaly:
            result["recommendations"] = self._generate_recommendations(scores, event)
            result["threat_level"] = self._assess_threat_level(anomaly_score)
        
        return result
    
    def detect_frequency_deviation(self, current_freq: float, 
                                   window_size: int = 100) -> Dict[str, Any]:
        """
        Detect frequency deviations from normal patterns
        
        Args:
            current_freq: Current frequency to check
            window_size: Number of recent events to analyze
            
        Returns:
            Deviation analysis
        """
        if not self.event_history:
            return {"status": "insufficient_data"}
        
        recent_events = self.event_history[-window_size:]
        recent_frequencies = [e.frequency for e in recent_events]
        
        mean_freq = np.mean(recent_frequencies)
        std_freq = np.std(recent_frequencies)
        
        deviation = abs(current_freq - mean_freq)
        z_score = self._z_score(current_freq, mean_freq, std_freq)
        
        return {
            "current_frequency": current_freq,
            "mean_frequency": mean_freq,
            "deviation": deviation,
            "z_score": z_score,
            "is_significant": abs(z_score) > 2.0,
            "samples_analyzed": len(recent_events),
            "timestamp": time.time()
        }
    
    def _z_score(self, value: float, mean: float, std: float) -> float:
        """Calculate z-score for anomaly detection"""
        if std == 0:
            return 0.0
        return (value - mean) / std
    
    def _calculate_distribution(self, values: List[str]) -> Dict[str, float]:
        """Calculate distribution of categorical values"""
        total = len(values)
        if total == 0:
            return {}
        
        counts = {}
        for value in values:
            counts[value] = counts.get(value, 0) + 1
        
        return {k: v / total for k, v in counts.items()}
    
    def _protocol_anomaly_score(self, protocol_type: str) -> float:
        """Calculate anomaly score for protocol type"""
        if "protocol_distribution" not in self.baseline_stats:
            return 0.0
        
        expected_prob = self.baseline_stats["protocol_distribution"].get(protocol_type, 0.0)
        
        # Higher score if protocol is rare in baseline
        return 1.0 - expected_prob
    
    def _generate_recommendations(self, scores: Dict[str, float], 
                                  event: ProtocolEvent) -> List[str]:
        """Generate security recommendations based on anomaly scores"""
        recommendations = []
        
        if abs(scores["packet_size"]) > 2.0:
            recommendations.append("Unusual packet size detected - inspect payload")
        
        if abs(scores["frequency"]) > 2.0:
            recommendations.append("Frequency deviation detected - check for SDR scanning")
        
        if scores["protocol"] > 0.8:
            recommendations.append(f"Rare protocol type '{event.protocol_type}' - verify legitimacy")
        
        recommendations.append("Enable enhanced monitoring for source IP: " + event.source_ip)
        recommendations.append("Consider activating EM hardening countermeasures")
        
        return recommendations
    
    def _assess_threat_level(self, anomaly_score: float) -> str:
        """Assess threat level based on anomaly score"""
        if anomaly_score >= 0.95:
            return "CRITICAL"
        elif anomaly_score >= 0.85:
            return "HIGH"
        elif anomaly_score >= 0.70:
            return "MEDIUM"
        else:
            return "LOW"
    
    def export_model_stats(self) -> str:
        """Export model statistics as JSON"""
        return json.dumps({
            "baseline_stats": self.baseline_stats,
            "model_trained": self.model_trained,
            "total_events_processed": len(self.event_history),
            "total_anomalies_detected": self.anomaly_count,
            "current_threshold": self.threshold,
            "export_timestamp": time.time()
        }, indent=2)


if __name__ == "__main__":
    # Example usage
    ml_system = MLEarlyWarningSystem(threshold=0.85)
    
    # Generate training data (normal behavior)
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
        for i in range(100)
    ]
    
    # Train baseline
    train_result = ml_system.train_baseline(training_events)
    print("Training Result:", json.dumps(train_result, indent=2))
    
    # Test with normal event
    normal_event = ProtocolEvent(
        timestamp=time.time(),
        protocol_type="TCP",
        packet_size=1000,
        frequency=2405.0,
        source_ip="192.168.1.50",
        destination_ip="10.0.0.1",
        flags=["SYN"]
    )
    normal_result = ml_system.detect_anomaly(normal_event)
    print(f"\nNormal Event - Anomaly: {normal_result['is_anomaly']}, Score: {normal_result['anomaly_score']:.3f}")
    
    # Test with anomalous event
    anomalous_event = ProtocolEvent(
        timestamp=time.time(),
        protocol_type="ICMP",
        packet_size=5000,  # Unusual size
        frequency=2500.0,  # Unusual frequency
        source_ip="203.0.113.1",
        destination_ip="10.0.0.1",
        flags=["URGENT"]
    )
    anomaly_result = ml_system.detect_anomaly(anomalous_event)
    print(f"\nAnomalous Event - Anomaly: {anomaly_result['is_anomaly']}, Score: {anomaly_result['anomaly_score']:.3f}")
    if anomaly_result['is_anomaly']:
        print("Threat Level:", anomaly_result['threat_level'])
        print("Recommendations:", anomaly_result['recommendations'])
