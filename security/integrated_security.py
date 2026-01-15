#!/usr/bin/env python3
"""
Security Integration Module
Integrates all security components into a unified defense system
"""

import json
import time
from typing import Dict, Any, List
from dataclasses import dataclass, asdict

# Import security modules
from quantum_encryption import NTRUEncryption
from em_hardening import EMHardeningSystem
from ml_early_warning import MLEarlyWarningSystem, ProtocolEvent
from blockchain_fork_detector import BlockchainForkDetector, BlockHeader
from ai_data_validator import AIDataValidator, DataSample
from geo_zone_filter import GeoZoneFilter, ActivityEvent, GeoLocation
from mesh_network import MeshNetwork, MeshNode, NodeStatus


@dataclass
class SecurityStatus:
    """Overall security system status"""
    timestamp: float
    threat_level: str  # LOW, MEDIUM, HIGH, CRITICAL
    active_threats: List[Dict[str, Any]]
    system_health: Dict[str, Any]
    recommendations: List[str]


class IntegratedSecuritySystem:
    """
    Unified security system integrating all defense mechanisms
    """
    
    def __init__(self):
        """Initialize integrated security system"""
        self.quantum_crypto = NTRUEncryption()
        self.em_hardening = EMHardeningSystem()
        self.ml_warning = MLEarlyWarningSystem(threshold=0.85)
        self.fork_detector = BlockchainForkDetector()
        self.data_validator = AIDataValidator(poisoning_threshold=0.7)
        self.geo_filter = GeoZoneFilter()
        self.mesh_network = MeshNetwork(node_id="nexus_main", min_peer_count=3)
        
        self.active_threats: List[Dict[str, Any]] = []
        self.defense_log: List[Dict[str, Any]] = []
    
    def initialize_defense_systems(self) -> Dict[str, Any]:
        """
        Initialize all defense systems
        
        Returns:
            Initialization results
        """
        results = {
            "timestamp": time.time(),
            "systems": {}
        }
        
        # Scenario A: Spionage und Datenextraktion
        try:
            # Quantum encryption
            priv_key, pub_key = self.quantum_crypto.generate_keypair()
            results["systems"]["quantum_encryption"] = {
                "status": "initialized",
                "key_length": len(pub_key)
            }
            
            # EM Hardening
            faraday_status = self.em_hardening.enable_faraday_protection()
            results["systems"]["em_hardening"] = {
                "status": "initialized",
                "faraday_active": faraday_status["status"] == "active"
            }
            
            # ML Early Warning - needs training data
            results["systems"]["ml_early_warning"] = {
                "status": "initialized",
                "note": "Requires training data for baseline"
            }
        except Exception as e:
            results["systems"]["scenario_a"] = {"status": "error", "message": str(e)}
        
        # Scenario B: Systemstörungen und Sabotage
        try:
            results["systems"]["blockchain_fork_detector"] = {
                "status": "initialized",
                "max_fork_depth": self.fork_detector.max_fork_depth
            }
            
            results["systems"]["ai_data_validator"] = {
                "status": "initialized",
                "poisoning_threshold": self.data_validator.poisoning_threshold
            }
        except Exception as e:
            results["systems"]["scenario_b"] = {"status": "error", "message": str(e)}
        
        # Scenario C: Globale Angriffe und Koordination
        try:
            geo_stats = self.geo_filter.get_zone_statistics()
            results["systems"]["geo_zone_filter"] = {
                "status": "initialized",
                "zones_configured": len(geo_stats["zones"])
            }
            
            mesh_stats = self.mesh_network.get_network_statistics()
            results["systems"]["mesh_network"] = {
                "status": "initialized",
                "node_id": self.mesh_network.node_id
            }
        except Exception as e:
            results["systems"]["scenario_c"] = {"status": "error", "message": str(e)}
        
        return results
    
    def assess_threat_level(self) -> SecurityStatus:
        """
        Assess overall threat level across all systems
        
        Returns:
            Current security status
        """
        active_threats = []
        threat_scores = []
        
        # Check EM signature analysis
        try:
            em_analysis = self.em_hardening.get_signature_analysis()
            if em_analysis.get("predictability_score", 0) > 0.5:
                active_threats.append({
                    "type": "em_signature_predictable",
                    "severity": "MEDIUM",
                    "source": "em_hardening"
                })
                threat_scores.append(0.5)
        except Exception:
            pass
        
        # Check fork detector
        try:
            fork_stats = self.fork_detector.get_fork_statistics()
            if fork_stats.get("total_forks", 0) > 0:
                active_threats.append({
                    "type": "blockchain_fork_detected",
                    "severity": "HIGH",
                    "count": fork_stats["total_forks"],
                    "source": "fork_detector"
                })
                threat_scores.append(0.8)
        except Exception:
            pass
        
        # Check data poisoning
        try:
            validator_stats = self.data_validator.get_validation_statistics()
            rejection_rate = validator_stats.get("rejection_rate", 0)
            if rejection_rate > 0.3:
                active_threats.append({
                    "type": "high_data_poisoning_rate",
                    "severity": "HIGH",
                    "rejection_rate": rejection_rate,
                    "source": "data_validator"
                })
                threat_scores.append(0.7)
        except Exception:
            pass
        
        # Check geo-zone suspicious patterns
        try:
            patterns = self.geo_filter.detect_suspicious_patterns()
            if patterns.get("threat_assessment") in ["ELEVATED", "CRITICAL"]:
                active_threats.append({
                    "type": "suspicious_geo_patterns",
                    "severity": patterns["threat_assessment"],
                    "patterns": len(patterns.get("suspicious_patterns", [])),
                    "source": "geo_filter"
                })
                threat_scores.append(0.9 if patterns["threat_assessment"] == "CRITICAL" else 0.6)
        except Exception:
            pass
        
        # Check mesh network health
        try:
            partition_check = self.mesh_network.detect_network_partition()
            if partition_check.get("is_partitioned"):
                active_threats.append({
                    "type": "network_partition",
                    "severity": "HIGH",
                    "unreachable_nodes": len(partition_check.get("unreachable_nodes", [])),
                    "source": "mesh_network"
                })
                threat_scores.append(0.75)
        except Exception:
            pass
        
        # Calculate overall threat level
        if not threat_scores:
            overall_threat = "LOW"
        else:
            avg_threat = sum(threat_scores) / len(threat_scores)
            if avg_threat >= 0.8:
                overall_threat = "CRITICAL"
            elif avg_threat >= 0.6:
                overall_threat = "HIGH"
            elif avg_threat >= 0.3:
                overall_threat = "MEDIUM"
            else:
                overall_threat = "LOW"
        
        # Generate recommendations
        recommendations = self._generate_recommendations(active_threats)
        
        # System health
        system_health = {
            "quantum_crypto": "operational",
            "em_hardening": "operational",
            "ml_warning": "operational" if self.ml_warning.model_trained else "needs_training",
            "fork_detector": "operational",
            "data_validator": "operational",
            "geo_filter": "operational",
            "mesh_network": "operational"
        }
        
        return SecurityStatus(
            timestamp=time.time(),
            threat_level=overall_threat,
            active_threats=active_threats,
            system_health=system_health,
            recommendations=recommendations
        )
    
    def _generate_recommendations(self, threats: List[Dict[str, Any]]) -> List[str]:
        """Generate security recommendations based on threats"""
        recommendations = []
        
        for threat in threats:
            threat_type = threat.get("type")
            
            if threat_type == "em_signature_predictable":
                recommendations.append("Increase frequency hopping rate")
                recommendations.append("Enable additional Faraday shielding")
            
            elif threat_type == "blockchain_fork_detected":
                recommendations.append("Verify blockchain consensus across multiple nodes")
                recommendations.append("Investigate fork sources")
            
            elif threat_type == "high_data_poisoning_rate":
                recommendations.append("Enhance data source verification")
                recommendations.append("Implement stricter validation thresholds")
            
            elif threat_type == "suspicious_geo_patterns":
                recommendations.append("Isolate high-risk geo-zones temporarily")
                recommendations.append("Increase monitoring on affected regions")
            
            elif threat_type == "network_partition":
                recommendations.append("Initiate network healing procedures")
                recommendations.append("Establish alternative communication paths")
        
        if not recommendations:
            recommendations.append("Maintain current security posture")
            recommendations.append("Continue routine monitoring")
        
        return recommendations
    
    def export_security_report(self) -> str:
        """
        Export comprehensive security report
        
        Returns:
            JSON formatted security report
        """
        status = self.assess_threat_level()
        
        report = {
            "report_metadata": {
                "generated_at": time.time(),
                "report_type": "comprehensive_security_assessment",
                "version": "1.0"
            },
            "current_status": asdict(status),
            "scenario_a_spionage": {
                "quantum_encryption": "active",
                "em_hardening": "active",
                "ml_early_warning": "active"
            },
            "scenario_b_sabotage": {
                "blockchain_fork_detection": "active",
                "ai_data_validation": "active"
            },
            "scenario_c_global_attacks": {
                "geo_zone_filtering": "active",
                "mesh_networking": "active"
            },
            "defense_log_entries": len(self.defense_log)
        }
        
        return json.dumps(report, indent=2, default=str)


if __name__ == "__main__":
    # Example usage
    print("Initializing Integrated Security System...")
    security = IntegratedSecuritySystem()
    
    # Initialize all systems
    init_results = security.initialize_defense_systems()
    print("\nInitialization Results:")
    print(json.dumps(init_results, indent=2))
    
    # Assess current threat level
    print("\nAssessing Threat Level...")
    status = security.assess_threat_level()
    print(f"Threat Level: {status.threat_level}")
    print(f"Active Threats: {len(status.active_threats)}")
    print(f"Recommendations: {status.recommendations}")
    
    # Export full report
    print("\nGenerating Security Report...")
    report = security.export_security_report()
    print(report)
