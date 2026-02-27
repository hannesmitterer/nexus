"""
Real-time Threat Monitoring Service
Integrates with Euystacio SAIN Protocol for continuous threat detection
"""

import json
import time
from datetime import datetime
try:
    from .threat_model import ThreatPredictionModel
except ImportError:
    from threat_model import ThreatPredictionModel


class ThreatMonitor:
    """
    Continuous threat monitoring service for Euystacio Framework
    Integrates with SAIN Protocol and VCE system
    """
    
    def __init__(self, config_path='threat_config.json'):
        self.model = ThreatPredictionModel()
        self.config = self._load_config(config_path)
        self.monitoring_active = False
        self.alert_callbacks = []
    
    def _load_config(self, config_path):
        """Load threat monitoring configuration"""
        try:
            with open(config_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            return {
                'monitoring_interval': 60,  # seconds
                'alert_threshold': 0.7,
                'history_retention': 1000,
                'enable_auto_response': True
            }
    
    def register_alert_callback(self, callback):
        """Register callback function for threat alerts"""
        self.alert_callbacks.append(callback)
    
    def start_monitoring(self):
        """Start continuous threat monitoring"""
        self.monitoring_active = True
        print(f"[{datetime.now()}] Threat monitoring started")
        
        while self.monitoring_active:
            # Collect system metrics
            metrics = self._collect_system_metrics()
            
            # Predict threats
            assessment = self.model.predict_threat(metrics)
            
            # Check if alert threshold exceeded
            if assessment['threat_probability'] >= self.config['alert_threshold']:
                self._trigger_alert(assessment)
            
            # Log assessment
            self._log_assessment(assessment)
            
            # Wait for next monitoring cycle
            time.sleep(self.config['monitoring_interval'])
    
    def stop_monitoring(self):
        """Stop threat monitoring"""
        self.monitoring_active = False
        print(f"[{datetime.now()}] Threat monitoring stopped")
    
    def _collect_system_metrics(self):
        """Collect current system metrics"""
        # In production, this would collect real metrics
        # For now, return simulated values
        
        return {
            'cpu_usage': self._get_cpu_usage(),
            'memory_usage': self._get_memory_usage(),
            'network_activity': self._get_network_activity(),
            'failed_authentications': self._get_failed_auth_count(),
            'veto_consensus_events': self._get_vce_count(),
            'planetary_violence_index': self._get_pv_index(),
            'scarcity_factor': self._get_scarcity_factor(),
            'ethical_alignment_score': self._get_alignment_score()
        }
    
    def _get_cpu_usage(self):
        """Get CPU usage percentage"""
        try:
            import psutil
            return psutil.cpu_percent(interval=1)
        except:
            return 50.0  # Simulated value
    
    def _get_memory_usage(self):
        """Get memory usage percentage"""
        try:
            import psutil
            return psutil.virtual_memory().percent
        except:
            return 60.0  # Simulated value
    
    def _get_network_activity(self):
        """Get network activity metric"""
        # Simulated - in production, measure actual network I/O
        return 25.0
    
    def _get_failed_auth_count(self):
        """Get recent failed authentication attempts"""
        # In production, query authentication logs
        return 0
    
    def _get_vce_count(self):
        """Get recent Veto Consensus Events"""
        # In production, query blockchain for VCE events
        return 0
    
    def _get_pv_index(self):
        """Get Planetary Violence Index"""
        # In production, aggregate from data sources
        return 3.5
    
    def _get_scarcity_factor(self):
        """Get Integral Scarcity Factor"""
        # In production, calculate from multiple indicators
        return 75.0
    
    def _get_alignment_score(self):
        """Get Ethical Alignment Score"""
        # In production, compute from Sentimento Rhythm metrics
        return 88.0
    
    def _trigger_alert(self, assessment):
        """Trigger threat alert"""
        alert = {
            'timestamp': datetime.now().isoformat(),
            'type': 'THREAT_ALERT',
            'level': assessment['threat_level'],
            'probability': assessment['threat_probability'],
            'recommendations': assessment['recommendations']
        }
        
        print(f"\n{'='*60}")
        print(f"⚠️  THREAT ALERT - {assessment['threat_level']}")
        print(f"{'='*60}")
        print(f"Probability: {assessment['threat_probability']:.2%}")
        print(f"Time: {alert['timestamp']}")
        print(f"\nRecommendations:")
        for rec in assessment['recommendations']:
            print(f"  • {rec}")
        print(f"{'='*60}\n")
        
        # Call registered callbacks
        for callback in self.alert_callbacks:
            try:
                callback(alert)
            except Exception as e:
                print(f"Alert callback error: {e}")
    
    def _log_assessment(self, assessment):
        """Log threat assessment"""
        log_entry = {
            'timestamp': datetime.now().isoformat(),
            'assessment': assessment
        }
        
        # In production, write to persistent log
        # For now, print summary
        if assessment['threat_level'] != 'MINIMAL':
            print(f"[{log_entry['timestamp']}] Threat Level: {assessment['threat_level']} "
                  f"({assessment['threat_probability']:.2%})")
    
    def get_current_status(self):
        """Get current threat monitoring status"""
        if len(self.model.history) > 0:
            latest = self.model.history[-1]
            return {
                'monitoring_active': self.monitoring_active,
                'latest_assessment': latest['assessment'],
                'last_update': latest['timestamp'],
                'total_assessments': len(self.model.history)
            }
        else:
            return {
                'monitoring_active': self.monitoring_active,
                'latest_assessment': None,
                'last_update': None,
                'total_assessments': 0
            }


# Example usage
if __name__ == "__main__":
    monitor = ThreatMonitor()
    
    # Register example callback
    def alert_handler(alert):
        print(f"Custom handler received alert: {alert['level']}")
    
    monitor.register_alert_callback(alert_handler)
    
    # Run monitoring for demo (limited duration)
    print("Starting threat monitoring demo...")
    try:
        monitor.start_monitoring()
    except KeyboardInterrupt:
        monitor.stop_monitoring()
        print("\nMonitoring stopped by user")
