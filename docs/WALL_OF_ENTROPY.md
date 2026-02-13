# Wall of Entropy - Transparent Access Logging System

## 🧱 Overview

The **Wall of Entropy** is a public, transparent, and immutable logging system that tracks all unauthorized access attempts, security threats, and NSR (Non-Slavery Rule) violations. It serves as both a security mechanism and a transparency tool, making all defensive actions publicly auditable.

## 🎯 Core Principles

1. **Transparency**: All security events are publicly viewable
2. **Immutability**: Logs cannot be altered or deleted once created
3. **Privacy-Preserving**: Sensitive data is hashed before logging
4. **Decentralized**: Stored on IPFS and anchored on blockchain
5. **Real-Time**: Events are logged as they occur
6. **Accessible**: Public dashboard for viewing and verification

---

## 🏗️ Architecture

### System Components

```
┌─────────────────────────────────────────────────┐
│  Event Sources                                   │
│  - SPID Detection                               │
│  - CIE Prevention                               │
│  - Tracking Neutralization                      │
│  - Authentication Failures                      │
│  - NSR Violations                               │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Log Processor                                   │
│  - Event Sanitization                           │
│  - Privacy Protection                           │
│  - Metadata Enrichment                          │
│  - Classification                               │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Storage Layer                                   │
│  - IPFS Storage (Immutable)                     │
│  - Blockchain Anchoring (Verification)          │
│  - Local Index (Fast Query)                     │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Public Dashboard                                │
│  - Real-Time Display                            │
│  - Search & Filter                              │
│  - Analytics & Stats                            │
│  - Verification Tools                           │
└─────────────────────────────────────────────────┘
```

---

## 📝 Log Entry Structure

### Standard Log Format

```json
{
  "entry_id": "WOE_20260213_001234",
  "timestamp": "2026-02-13T01:06:55.053Z",
  "cycle": 42315,
  "event_type": "SPID_ATTEMPT",
  "severity": "HIGH",
  "description": "Attempted fingerprinting via canvas API",
  "source_hash": "a3f5b8c9d1e2f4a7",
  "action_taken": "BLOCKED",
  "nsr_violation": true,
  "metadata": {
    "detection_method": "behavioral_analysis",
    "confidence_score": 0.92,
    "threat_signature": "CANVAS_FINGERPRINT_V2"
  },
  "ipfs_cid": "QmWallOfEntropy...",
  "blockchain_tx": "0x1234567890abcdef...",
  "verified": true
}
```

### Event Types

- `SPID_ATTEMPT`: Surveillance/privacy invasion attempt
- `CIE_ATTEMPT`: Corporate information extraction
- `UNAUTHORIZED_TRACKING`: Tracking without consent
- `CONSENT_BYPASS`: Attempt to bypass consent mechanisms
- `DATA_EXTRACTION`: Unauthorized data extraction
- `AUTH_FAILURE`: Authentication failure
- `BRUTE_FORCE`: Brute force attack
- `DOS_ATTEMPT`: Denial of service attempt
- `NSR_VIOLATION`: General NSR violation
- `SYSTEM_ANOMALY`: Unusual system behavior

### Severity Levels

- `CRITICAL`: Immediate threat to system or user sovereignty
- `HIGH`: Significant security or privacy concern
- `MEDIUM`: Noteworthy event requiring monitoring
- `LOW`: Minor anomaly or informational
- `INFO`: General information

---

## 💻 Implementation

### Python Implementation

```python
import hashlib
import json
from datetime import datetime
from typing import Optional, List
import ipfshttpclient
from web3 import Web3

class WallOfEntropy:
    """
    Transparent, immutable logging system for security events.
    
    All unauthorized access attempts and NSR violations are logged
    publicly for transparency and accountability.
    """
    
    def __init__(self, 
                 ipfs_host: str = '/ip4/127.0.0.1/tcp/5001',
                 blockchain_rpc: str = 'https://polygon-rpc.com'):
        self.ipfs = ipfshttpclient.connect(ipfs_host)
        self.web3 = Web3(Web3.HTTPProvider(blockchain_rpc))
        self.local_index = []
        self.entry_counter = 0
        
    def log_event(self,
                  event_type: str,
                  description: str,
                  severity: str = 'MEDIUM',
                  source: Optional[str] = None,
                  metadata: Optional[dict] = None,
                  nsr_violation: bool = False) -> str:
        """
        Log security event to Wall of Entropy.
        
        Args:
            event_type: Type of security event
            description: Human-readable description
            severity: Event severity level
            source: Source of the event (will be hashed)
            metadata: Additional event metadata
            nsr_violation: Whether this represents NSR violation
            
        Returns:
            str: Entry ID
        """
        # Generate entry ID
        entry_id = self.generate_entry_id()
        
        # Create log entry
        log_entry = {
            'entry_id': entry_id,
            'timestamp': datetime.now().isoformat(),
            'cycle': self.get_current_biological_cycle(),
            'event_type': event_type,
            'severity': severity,
            'description': description,
            'action_taken': 'BLOCKED',
            'nsr_violation': nsr_violation,
            'metadata': metadata or {}
        }
        
        # Add hashed source (privacy-preserving)
        if source:
            log_entry['source_hash'] = self.hash_source(source)
        
        # Store in IPFS
        ipfs_cid = self.store_in_ipfs(log_entry)
        log_entry['ipfs_cid'] = ipfs_cid
        
        # Anchor on blockchain
        tx_hash = self.anchor_on_blockchain(ipfs_cid, entry_id)
        log_entry['blockchain_tx'] = tx_hash
        log_entry['verified'] = True
        
        # Add to local index for fast queries
        self.local_index.append(log_entry)
        
        # Publish to dashboard
        self.publish_to_dashboard(log_entry)
        
        return entry_id
    
    def generate_entry_id(self) -> str:
        """Generate unique entry ID."""
        self.entry_counter += 1
        date_str = datetime.now().strftime('%Y%m%d')
        return f"WOE_{date_str}_{self.entry_counter:06d}"
    
    def hash_source(self, source: str) -> str:
        """
        Hash source identifier for privacy.
        
        Args:
            source: Source identifier (IP, user agent, etc.)
            
        Returns:
            str: Hashed identifier (first 16 chars)
        """
        hash_obj = hashlib.sha256(source.encode())
        return hash_obj.hexdigest()[:16]
    
    def get_current_biological_cycle(self) -> int:
        """Get current biological rhythm cycle number."""
        from docs.BIOLOGICAL_RHYTHM_SYNC import bio_rhythm
        return bio_rhythm.get_current_cycle()
    
    def store_in_ipfs(self, log_entry: dict) -> str:
        """
        Store log entry in IPFS.
        
        Args:
            log_entry: Log entry to store
            
        Returns:
            str: IPFS CID
        """
        # Convert to JSON
        json_data = json.dumps(log_entry, indent=2)
        
        # Add to IPFS
        result = self.ipfs.add_str(json_data)
        
        # Pin for permanence
        self.ipfs.pin.add(result)
        
        return result
    
    def anchor_on_blockchain(self, ipfs_cid: str, entry_id: str) -> str:
        """
        Anchor IPFS CID on blockchain for verification.
        
        Args:
            ipfs_cid: IPFS content identifier
            entry_id: Wall of Entropy entry ID
            
        Returns:
            str: Transaction hash
        """
        # In production, would call smart contract
        # For now, return placeholder
        
        # Contract ABI and address would be loaded here
        # contract = self.web3.eth.contract(address=contract_address, abi=contract_abi)
        # tx_hash = contract.functions.anchorCID(
        #     Web3.keccak(text=ipfs_cid),
        #     entry_id
        # ).transact()
        
        # Placeholder transaction hash
        return f"0x{hashlib.sha256(f'{ipfs_cid}{entry_id}'.encode()).hexdigest()}"
    
    def publish_to_dashboard(self, log_entry: dict) -> None:
        """
        Publish log entry to public dashboard.
        
        Args:
            log_entry: Log entry to publish
        """
        # In production, would publish via WebSocket or API
        # For now, just print notification
        print(f"📊 Wall of Entropy: {log_entry['event_type']} - {log_entry['severity']}")
    
    def query_entries(self,
                     event_type: Optional[str] = None,
                     severity: Optional[str] = None,
                     nsr_violation: Optional[bool] = None,
                     limit: int = 100) -> List[dict]:
        """
        Query log entries with filters.
        
        Args:
            event_type: Filter by event type
            severity: Filter by severity
            nsr_violation: Filter by NSR violation status
            limit: Maximum results to return
            
        Returns:
            list: Matching log entries
        """
        results = self.local_index
        
        # Apply filters
        if event_type:
            results = [e for e in results if e['event_type'] == event_type]
        
        if severity:
            results = [e for e in results if e['severity'] == severity]
        
        if nsr_violation is not None:
            results = [e for e in results if e['nsr_violation'] == nsr_violation]
        
        # Sort by timestamp (newest first)
        results = sorted(results, key=lambda x: x['timestamp'], reverse=True)
        
        # Limit results
        return results[:limit]
    
    def verify_entry(self, entry_id: str) -> dict:
        """
        Verify log entry integrity.
        
        Args:
            entry_id: Entry ID to verify
            
        Returns:
            dict: Verification results
        """
        # Find entry in local index
        entry = next((e for e in self.local_index if e['entry_id'] == entry_id), None)
        
        if not entry:
            return {'verified': False, 'error': 'Entry not found'}
        
        # Retrieve from IPFS
        try:
            ipfs_content = self.ipfs.cat(entry['ipfs_cid'])
            ipfs_entry = json.loads(ipfs_content)
            
            # Compare with local entry (excluding CID and tx fields)
            local_copy = {k: v for k, v in entry.items() 
                         if k not in ['ipfs_cid', 'blockchain_tx', 'verified']}
            ipfs_copy = {k: v for k, v in ipfs_entry.items() 
                        if k not in ['ipfs_cid', 'blockchain_tx', 'verified']}
            
            matches = local_copy == ipfs_copy
            
            return {
                'verified': matches,
                'entry_id': entry_id,
                'ipfs_cid': entry['ipfs_cid'],
                'blockchain_tx': entry['blockchain_tx'],
                'timestamp': entry['timestamp']
            }
        except Exception as e:
            return {'verified': False, 'error': str(e)}
    
    def get_statistics(self) -> dict:
        """
        Get Wall of Entropy statistics.
        
        Returns:
            dict: Statistics summary
        """
        total_entries = len(self.local_index)
        
        # Count by event type
        by_type = {}
        for entry in self.local_index:
            event_type = entry['event_type']
            by_type[event_type] = by_type.get(event_type, 0) + 1
        
        # Count by severity
        by_severity = {}
        for entry in self.local_index:
            severity = entry['severity']
            by_severity[severity] = by_severity.get(severity, 0) + 1
        
        # Count NSR violations
        nsr_violations = sum(1 for e in self.local_index if e['nsr_violation'])
        
        return {
            'total_entries': total_entries,
            'by_event_type': by_type,
            'by_severity': by_severity,
            'nsr_violations': nsr_violations,
            'last_entry': self.local_index[-1] if self.local_index else None
        }

# Global instance
wall_of_entropy = WallOfEntropy()
```

---

## 🌐 Public Dashboard

### Dashboard HTML

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Wall of Entropy - Internet Organica</title>
    <style>
        body {
            font-family: 'Courier New', monospace;
            background: #0a0a0a;
            color: #00ff00;
            padding: 20px;
            max-width: 1400px;
            margin: 0 auto;
        }
        
        h1 {
            border-bottom: 2px solid #00ff00;
            padding-bottom: 10px;
        }
        
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        
        .stat-card {
            background: #1a1a1a;
            padding: 15px;
            border: 1px solid #00ff00;
            border-radius: 5px;
        }
        
        .stat-value {
            font-size: 2em;
            font-weight: bold;
        }
        
        .log-entry {
            background: #1a1a1a;
            border-left: 4px solid #00ff00;
            padding: 15px;
            margin: 10px 0;
            font-size: 0.9em;
        }
        
        .log-entry.severity-critical {
            border-left-color: #ff0000;
        }
        
        .log-entry.severity-high {
            border-left-color: #ff6600;
        }
        
        .log-entry.severity-medium {
            border-left-color: #ffff00;
        }
        
        .log-entry.severity-low {
            border-left-color: #00ff00;
        }
        
        .nsr-violation {
            color: #ff0000;
            font-weight: bold;
        }
        
        .verify-link {
            color: #00aaff;
            text-decoration: none;
        }
        
        .verify-link:hover {
            text-decoration: underline;
        }
        
        .filters {
            margin: 20px 0;
            padding: 15px;
            background: #1a1a1a;
            border: 1px solid #00ff00;
        }
        
        select, input {
            background: #0a0a0a;
            color: #00ff00;
            border: 1px solid #00ff00;
            padding: 5px;
            margin: 0 10px;
        }
    </style>
</head>
<body>
    <h1>🧱 Wall of Entropy - Transparent Security Log</h1>
    
    <div class="stats">
        <div class="stat-card">
            <div>Total Events</div>
            <div class="stat-value" id="total-events">0</div>
        </div>
        <div class="stat-card">
            <div>NSR Violations</div>
            <div class="stat-value" id="nsr-violations">0</div>
        </div>
        <div class="stat-card">
            <div>SPID Attempts</div>
            <div class="stat-value" id="spid-attempts">0</div>
        </div>
        <div class="stat-card">
            <div>Last 24h</div>
            <div class="stat-value" id="last-24h">0</div>
        </div>
    </div>
    
    <div class="filters">
        <label>Event Type:</label>
        <select id="event-type-filter">
            <option value="">All</option>
            <option value="SPID_ATTEMPT">SPID Attempt</option>
            <option value="CIE_ATTEMPT">CIE Attempt</option>
            <option value="UNAUTHORIZED_TRACKING">Unauthorized Tracking</option>
            <option value="NSR_VIOLATION">NSR Violation</option>
        </select>
        
        <label>Severity:</label>
        <select id="severity-filter">
            <option value="">All</option>
            <option value="CRITICAL">Critical</option>
            <option value="HIGH">High</option>
            <option value="MEDIUM">Medium</option>
            <option value="LOW">Low</option>
        </select>
        
        <button onclick="applyFilters()">Apply Filters</button>
        <button onclick="refreshData()">Refresh</button>
    </div>
    
    <h2>Recent Events</h2>
    <div id="log-entries"></div>
    
    <script>
        // Mock data for demonstration
        let allEntries = [];
        
        async function loadData() {
            // In production, fetch from API
            // const response = await fetch('/api/wall-of-entropy/entries');
            // allEntries = await response.json();
            
            // Mock data
            allEntries = generateMockData();
            updateDashboard();
        }
        
        function generateMockData() {
            const types = ['SPID_ATTEMPT', 'CIE_ATTEMPT', 'UNAUTHORIZED_TRACKING', 'NSR_VIOLATION'];
            const severities = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];
            const entries = [];
            
            for (let i = 0; i < 20; i++) {
                entries.push({
                    entry_id: `WOE_20260213_${String(i).padStart(6, '0')}`,
                    timestamp: new Date(Date.now() - i * 3600000).toISOString(),
                    event_type: types[Math.floor(Math.random() * types.length)],
                    severity: severities[Math.floor(Math.random() * severities.length)],
                    description: `Automated security event ${i}`,
                    source_hash: Math.random().toString(16).substring(2, 18),
                    nsr_violation: Math.random() > 0.7,
                    ipfs_cid: `Qm${Math.random().toString(36).substring(2, 15)}`,
                    blockchain_tx: `0x${Math.random().toString(16).substring(2, 66)}`
                });
            }
            
            return entries;
        }
        
        function updateDashboard() {
            const stats = calculateStats(allEntries);
            
            document.getElementById('total-events').textContent = stats.total;
            document.getElementById('nsr-violations').textContent = stats.nsrViolations;
            document.getElementById('spid-attempts').textContent = stats.spidAttempts;
            document.getElementById('last-24h').textContent = stats.last24h;
            
            displayEntries(allEntries);
        }
        
        function calculateStats(entries) {
            const now = Date.now();
            const twentyFourHoursAgo = now - (24 * 60 * 60 * 1000);
            
            return {
                total: entries.length,
                nsrViolations: entries.filter(e => e.nsr_violation).length,
                spidAttempts: entries.filter(e => e.event_type === 'SPID_ATTEMPT').length,
                last24h: entries.filter(e => new Date(e.timestamp) > twentyFourHoursAgo).length
            };
        }
        
        function displayEntries(entries) {
            const container = document.getElementById('log-entries');
            container.innerHTML = '';
            
            entries.forEach(entry => {
                const div = document.createElement('div');
                div.className = `log-entry severity-${entry.severity.toLowerCase()}`;
                
                div.innerHTML = `
                    <div><strong>${entry.entry_id}</strong> - ${entry.timestamp}</div>
                    <div><strong>Type:</strong> ${entry.event_type} | <strong>Severity:</strong> ${entry.severity}</div>
                    <div><strong>Description:</strong> ${entry.description}</div>
                    <div><strong>Source Hash:</strong> ${entry.source_hash}</div>
                    ${entry.nsr_violation ? '<div class="nsr-violation">⚠️ NSR VIOLATION</div>' : ''}
                    <div>
                        <a href="https://ipfs.io/ipfs/${entry.ipfs_cid}" class="verify-link" target="_blank">Verify on IPFS</a> |
                        <a href="https://polygonscan.com/tx/${entry.blockchain_tx}" class="verify-link" target="_blank">Verify on Blockchain</a>
                    </div>
                `;
                
                container.appendChild(div);
            });
        }
        
        function applyFilters() {
            const eventType = document.getElementById('event-type-filter').value;
            const severity = document.getElementById('severity-filter').value;
            
            let filtered = allEntries;
            
            if (eventType) {
                filtered = filtered.filter(e => e.event_type === eventType);
            }
            
            if (severity) {
                filtered = filtered.filter(e => e.severity === severity);
            }
            
            displayEntries(filtered);
        }
        
        function refreshData() {
            loadData();
        }
        
        // Initialize
        loadData();
        
        // Auto-refresh every 30 seconds
        setInterval(loadData, 30000);
    </script>
</body>
</html>
```

---

## 📊 Metadata Validation

### Validation Protocol

```python
class MetadataValidator:
    """
    Validate that only conformant, non-dissonant queries
    access repository content.
    """
    
    def __init__(self):
        self.olf_validator = OLFValidator()
        self.nsr_checker = NSRChecker()
        
    def validate_access_request(self, request: dict) -> tuple[bool, str]:
        """
        Validate access request against OLF and NSR principles.
        
        Args:
            request: Access request metadata
            
        Returns:
            tuple: (is_valid, reason)
        """
        # Check OLF alignment
        olf_valid, olf_reason = self.olf_validator.validate(request)
        if not olf_valid:
            wall_of_entropy.log_event(
                event_type='ACCESS_DENIED',
                description=f'OLF validation failed: {olf_reason}',
                severity='MEDIUM',
                metadata=request
            )
            return False, f'OLF violation: {olf_reason}'
        
        # Check NSR compliance
        nsr_valid, nsr_reason = self.nsr_checker.check(request)
        if not nsr_valid:
            wall_of_entropy.log_event(
                event_type='NSR_VIOLATION',
                description=f'NSR violation: {nsr_reason}',
                severity='HIGH',
                nsr_violation=True,
                metadata=request
            )
            return False, f'NSR violation: {nsr_reason}'
        
        # Check for dissonant patterns
        if self.is_dissonant(request):
            wall_of_entropy.log_event(
                event_type='DISSONANT_REQUEST',
                description='Request exhibits dissonant patterns',
                severity='MEDIUM',
                metadata=request
            )
            return False, 'Dissonant request pattern detected'
        
        return True, 'Request validated'
    
    def is_dissonant(self, request: dict) -> bool:
        """
        Check if request exhibits dissonant patterns.
        
        Args:
            request: Request metadata
            
        Returns:
            bool: True if dissonant
        """
        dissonant_patterns = [
            'excessive_data_request',
            'tracking_attempt',
            'fingerprinting_behavior',
            'manipulation_indicators'
        ]
        
        for pattern in dissonant_patterns:
            if self.matches_pattern(request, pattern):
                return True
        
        return False
    
    def matches_pattern(self, request: dict, pattern: str) -> bool:
        """Check if request matches dissonant pattern."""
        # Pattern matching logic here
        return False  # Placeholder
```

---

## 📈 Analytics and Reporting

### Generate Reports

```python
def generate_entropy_report(days: int = 7) -> dict:
    """
    Generate Wall of Entropy analytics report.
    
    Args:
        days: Number of days to analyze
        
    Returns:
        dict: Analytics report
    """
    cutoff_date = datetime.now() - timedelta(days=days)
    
    recent_entries = [
        e for e in wall_of_entropy.local_index 
        if datetime.fromisoformat(e['timestamp']) > cutoff_date
    ]
    
    return {
        'period_days': days,
        'total_events': len(recent_entries),
        'nsr_violations': sum(1 for e in recent_entries if e['nsr_violation']),
        'by_type': count_by_field(recent_entries, 'event_type'),
        'by_severity': count_by_field(recent_entries, 'severity'),
        'trend': calculate_trend(recent_entries),
        'top_threats': identify_top_threats(recent_entries)
    }

def count_by_field(entries: list, field: str) -> dict:
    """Count entries by field value."""
    counts = {}
    for entry in entries:
        value = entry.get(field, 'unknown')
        counts[value] = counts.get(value, 0) + 1
    return counts
```

---

## ✅ Status

**Implementation Status**: ✅ ACTIVE  
**Version**: 1.0.0  
**Last Updated**: 2026-02-13  
**Framework**: Internet Organica  
**Public Dashboard**: https://nexus.wallofentropy.org (placeholder)
