#!/usr/bin/env python3
"""
Nexus Forensic Response Automation
Monitors logs for suspicious activity and triggers automated responses
including Tor/VPN routing activation.
"""

import os
import re
import sys
import time
import json
import logging
import subprocess
import glob
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Set
from collections import defaultdict

try:
    import requests
except ImportError:
    requests = None

# Configuration
CONFIG_FILE = os.environ.get('FORENSICS_CONFIG', '/etc/nexus/forensics-config.json')
LOG_PATHS = [
    '/var/log/auth.log',
    '/var/log/syslog',
    '/var/log/nexus/*.log'
]

# Suspicious activity patterns
SUSPICIOUS_PATTERNS = {
    'failed_login': r'Failed password for .* from (\d+\.\d+\.\d+\.\d+)',
    'invalid_user': r'Invalid user .* from (\d+\.\d+\.\d+\.\d+)',
    'unauthorized_access': r'(?i)(unauthorized|forbidden|access denied)',
    'port_scan': r'Port \d+ .* refused',
    'brute_force': r'authentication failure.*rhost=(\d+\.\d+\.\d+\.\d+)',
    'sql_injection': r'(?i)(union.*select|drop.*table|insert.*into)',
    'xss_attempt': r'(?i)(<script|javascript:|onerror=)',
    'intrusion_detection': r'(?i)(intrusion|malware|virus|trojan)',
}

# Thresholds
FAILED_LOGIN_THRESHOLD = 5
TIME_WINDOW_SECONDS = 300  # 5 minutes

# Response actions
class ForensicResponder:
    def __init__(self, config_path: str = CONFIG_FILE):
        self.config = self.load_config(config_path)
        self.setup_logging()
        self.ip_counters = defaultdict(lambda: defaultdict(int))
        self.ip_timestamps = defaultdict(list)
        self.blocked_ips = set()
        
    def load_config(self, config_path: str) -> Dict:
        """Load forensics configuration"""
        default_config = {
            'enable_tor_routing': True,
            'enable_vpn_failover': True,
            'enable_ip_blocking': True,
            'enable_notifications': True,
            'notification_webhook': None,
            'tor_control_port': 9051,
            'vpn_config': '/etc/openvpn/nexus.conf',
            'log_retention_days': 30
        }
        
        if os.path.exists(config_path):
            with open(config_path, 'r') as f:
                user_config = json.load(f)
                default_config.update(user_config)
        
        return default_config
    
    def setup_logging(self):
        """Setup logging configuration"""
        log_dir = Path('/var/log/nexus/forensics')
        log_dir.mkdir(parents=True, exist_ok=True)
        
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(log_dir / 'forensics.log'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def analyze_log_line(self, line: str) -> List[Dict]:
        """Analyze a log line for suspicious patterns"""
        detections = []
        
        for pattern_name, pattern_regex in SUSPICIOUS_PATTERNS.items():
            match = re.search(pattern_regex, line)
            if match:
                detection = {
                    'type': pattern_name,
                    'timestamp': datetime.now().isoformat(),
                    'line': line.strip(),
                    'ip': match.group(1) if match.groups() else None
                }
                detections.append(detection)
        
        return detections
    
    def check_threshold_exceeded(self, ip: str, pattern_type: str) -> bool:
        """Check if an IP has exceeded the threshold for a pattern"""
        current_time = time.time()
        
        # Clean old timestamps
        self.ip_timestamps[ip] = [
            ts for ts in self.ip_timestamps[ip] 
            if current_time - ts < TIME_WINDOW_SECONDS
        ]
        
        # Add new timestamp
        self.ip_timestamps[ip].append(current_time)
        self.ip_counters[ip][pattern_type] += 1
        
        # Check threshold
        if pattern_type in ['failed_login', 'brute_force']:
            return len(self.ip_timestamps[ip]) >= FAILED_LOGIN_THRESHOLD
        
        return False
    
    def activate_tor_routing(self):
        """Activate Tor routing for enhanced anonymity"""
        if not self.config['enable_tor_routing']:
            return
        
        try:
            self.logger.warning("🔒 Activating Tor routing for enhanced security")
            
            # Start Tor service if not running
            subprocess.run(['systemctl', 'start', 'tor'], check=False)
            
            # Configure iptables to route through Tor
            commands = [
                'iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-ports 9050',
                'iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-ports 9050'
            ]
            
            for cmd in commands:
                subprocess.run(cmd.split(), check=False)
            
            self.logger.info("✓ Tor routing activated successfully")
            self.send_notification("Tor routing activated due to suspicious activity")
            
        except Exception as e:
            self.logger.error(f"Failed to activate Tor routing: {e}")
    
    def activate_vpn_failover(self):
        """Activate VPN failover connection"""
        if not self.config['enable_vpn_failover']:
            return
        
        try:
            self.logger.warning("🔒 Activating VPN failover connection")
            
            vpn_config = self.config['vpn_config']
            if os.path.exists(vpn_config):
                subprocess.run(
                    ['openvpn', '--config', vpn_config, '--daemon'],
                    check=False
                )
                self.logger.info("✓ VPN failover activated successfully")
                self.send_notification("VPN failover activated due to suspicious activity")
            else:
                self.logger.error(f"VPN config not found: {vpn_config}")
                
        except Exception as e:
            self.logger.error(f"Failed to activate VPN failover: {e}")
    
    def block_ip(self, ip: str, reason: str):
        """Block an IP address using iptables"""
        if not self.config['enable_ip_blocking']:
            return
        
        if ip in self.blocked_ips:
            return
        
        try:
            self.logger.warning(f"🚫 Blocking IP {ip} - Reason: {reason}")
            
            # Add iptables rule to block IP
            subprocess.run(
                ['iptables', '-A', 'INPUT', '-s', ip, '-j', 'DROP'],
                check=False
            )
            
            self.blocked_ips.add(ip)
            self.logger.info(f"✓ IP {ip} blocked successfully")
            self.send_notification(f"Blocked IP {ip} due to {reason}")
            
        except Exception as e:
            self.logger.error(f"Failed to block IP {ip}: {e}")
    
    def send_notification(self, message: str):
        """Send notification about security event"""
        if not self.config['enable_notifications']:
            return
        
        webhook_url = self.config.get('notification_webhook')
        if webhook_url and requests:
            try:
                payload = {
                    'text': f"🔔 Nexus Security Alert: {message}",
                    'timestamp': datetime.now().isoformat()
                }
                requests.post(webhook_url, json=payload, timeout=5)
            except Exception as e:
                self.logger.error(f"Failed to send notification: {e}")
    
    def handle_detection(self, detection: Dict):
        """Handle a security detection"""
        pattern_type = detection['type']
        ip = detection['ip']
        
        self.logger.warning(
            f"🔍 Suspicious activity detected: {pattern_type} from {ip}"
        )
        
        # Check if threshold exceeded
        if ip and self.check_threshold_exceeded(ip, pattern_type):
            self.logger.error(
                f"⚠️ Threshold exceeded for {pattern_type} from {ip}"
            )
            
            # Block the IP
            self.block_ip(ip, pattern_type)
            
            # Activate defensive measures
            if pattern_type in ['intrusion_detection', 'brute_force']:
                self.activate_tor_routing()
                self.activate_vpn_failover()
    
    def monitor_logs(self):
        """Monitor log files for suspicious activity"""
        self.logger.info("Starting forensic log monitoring...")
        
        # Use tail -F to follow log files
        log_files = []
        for pattern in LOG_PATHS:
            log_files.extend(glob.glob(pattern))
        
        if not log_files:
            self.logger.error("No log files found to monitor")
            return
        
        self.logger.info(f"Monitoring {len(log_files)} log file(s)")
        
        # Start tail process
        try:
            process = subprocess.Popen(
                ['tail', '-F'] + log_files,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                universal_newlines=True
            )
            
            for line in process.stdout:
                detections = self.analyze_log_line(line)
                for detection in detections:
                    self.handle_detection(detection)
                    
        except KeyboardInterrupt:
            self.logger.info("Stopping forensic monitoring...")
        except Exception as e:
            self.logger.error(f"Error during monitoring: {e}")

def main():
    """Main entry point"""
    print("Nexus Forensic Response Automation")
    print("=" * 50)
    
    responder = ForensicResponder()
    responder.monitor_logs()

if __name__ == '__main__':
    main()
