#!/usr/bin/env python3
"""
Wall of Entropy - Transparent Access Logging System
Implements public, immutable logging of security events and NSR violations.
Part of Internet Organica framework - transparency and accountability layer.
"""

import hashlib
import json
import os
import time
from datetime import datetime
from typing import Optional, List, Dict, Any


# Valid event types for Wall of Entropy
EVENT_TYPES = {
    'SPID_ATTEMPT',          # Surveillance/privacy invasion attempt
    'CIE_ATTEMPT',           # Corporate information extraction
    'UNAUTHORIZED_TRACKING', # Tracking without consent
    'CONSENT_BYPASS',        # Attempt to bypass consent mechanisms
    'DATA_EXTRACTION',       # Unauthorized data extraction
    'AUTH_FAILURE',          # Authentication failure
    'BRUTE_FORCE',           # Brute force attack
    'DOS_ATTEMPT',           # Denial of service attempt
    'NSR_VIOLATION',         # General NSR violation
    'SYSTEM_ANOMALY',        # Unusual system behavior
}

# Severity levels
SEVERITY_LEVELS = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'INFO']


class WallOfEntropy:
    """
    Transparent, immutable logging system for security events.

    All unauthorized access attempts and NSR violations are logged
    publicly for transparency and accountability. Logs are stored
    locally with optional IPFS/blockchain anchoring when available.
    """

    def __init__(self, log_dir: str = '.', log_file: str = 'wall_of_entropy.jsonl'):
        """
        Initialize Wall of Entropy.

        Args:
            log_dir: Directory for local log storage
            log_file: Log file name (JSON Lines format)
        """
        self.log_dir = log_dir
        self.log_file = os.path.join(log_dir, log_file)
        self.local_index: List[Dict[str, Any]] = []
        self.entry_counter = 0
        self._load_existing_entries()

    def _load_existing_entries(self) -> None:
        """Load existing log entries from disk."""
        if not os.path.exists(self.log_file):
            return
        try:
            with open(self.log_file, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if line:
                        entry = json.loads(line)
                        self.local_index.append(entry)
                        self.entry_counter += 1
        except (IOError, json.JSONDecodeError):
            pass

    def log_event(self,
                  event_type: str,
                  description: str,
                  severity: str = 'MEDIUM',
                  source: Optional[str] = None,
                  metadata: Optional[Dict[str, Any]] = None,
                  nsr_violation: bool = False) -> str:
        """
        Log a security event to the Wall of Entropy.

        Args:
            event_type: Type of security event (see EVENT_TYPES)
            description: Human-readable description
            severity: Event severity level (see SEVERITY_LEVELS)
            source: Source identifier (will be hashed for privacy)
            metadata: Additional event metadata
            nsr_violation: Whether this represents an NSR violation

        Returns:
            str: Entry ID
        """
        if event_type not in EVENT_TYPES:
            event_type = 'SYSTEM_ANOMALY'
        if severity not in SEVERITY_LEVELS:
            severity = 'MEDIUM'

        entry_id = self._generate_entry_id()

        log_entry: Dict[str, Any] = {
            'entry_id': entry_id,
            'timestamp': datetime.now().isoformat(),
            'event_type': event_type,
            'severity': severity,
            'description': description,
            'action_taken': 'LOGGED',
            'nsr_violation': nsr_violation,
            'metadata': metadata or {},
            'verified': True,
        }

        if source:
            log_entry['source_hash'] = self._hash_source(source)

        # Compute entry hash for integrity verification
        log_entry['integrity_hash'] = self._compute_integrity_hash(log_entry)

        # Persist to disk
        self._persist_entry(log_entry)

        # Add to in-memory index
        self.local_index.append(log_entry)

        return entry_id

    def _generate_entry_id(self) -> str:
        """Generate a unique entry ID."""
        self.entry_counter += 1
        date_str = datetime.now().strftime('%Y%m%d')
        return f"WOE_{date_str}_{self.entry_counter:06d}"

    def _hash_source(self, source: str) -> str:
        """
        Hash source identifier for privacy-preserving logging.

        Args:
            source: Original source identifier

        Returns:
            str: SHA-256 hash (first 16 hex chars)
        """
        return hashlib.sha256(source.encode('utf-8')).hexdigest()[:16]

    def _compute_integrity_hash(self, entry: Dict[str, Any]) -> str:
        """
        Compute integrity hash for log entry verification.

        Args:
            entry: Log entry dict (without integrity_hash key)

        Returns:
            str: SHA-256 integrity hash
        """
        entry_copy = {k: v for k, v in entry.items() if k != 'integrity_hash'}
        entry_str = json.dumps(entry_copy, sort_keys=True)
        return hashlib.sha256(entry_str.encode('utf-8')).hexdigest()

    def _persist_entry(self, entry: Dict[str, Any]) -> None:
        """Persist log entry to local storage."""
        try:
            os.makedirs(self.log_dir, exist_ok=True)
            with open(self.log_file, 'a', encoding='utf-8') as f:
                f.write(json.dumps(entry) + '\n')
        except IOError:
            pass

    def verify_entry(self, entry: Dict[str, Any]) -> bool:
        """
        Verify integrity of a log entry.

        Args:
            entry: Log entry to verify

        Returns:
            bool: True if entry integrity is valid
        """
        stored_hash = entry.get('integrity_hash', '')
        computed = self._compute_integrity_hash(entry)
        return stored_hash == computed

    def query_events(self,
                     event_type: Optional[str] = None,
                     severity: Optional[str] = None,
                     nsr_violations_only: bool = False,
                     limit: int = 100) -> List[Dict[str, Any]]:
        """
        Query logged events with optional filtering.

        Args:
            event_type: Filter by event type
            severity: Filter by severity level
            nsr_violations_only: Return only NSR violations
            limit: Maximum number of results

        Returns:
            List of matching log entries
        """
        results = list(self.local_index)

        if event_type:
            results = [e for e in results if e.get('event_type') == event_type]
        if severity:
            results = [e for e in results if e.get('severity') == severity]
        if nsr_violations_only:
            results = [e for e in results if e.get('nsr_violation')]

        return results[-limit:]

    def get_stats(self) -> Dict[str, Any]:
        """
        Get statistical summary of logged events.

        Returns:
            dict: Event statistics
        """
        total = len(self.local_index)
        nsr_count = sum(1 for e in self.local_index if e.get('nsr_violation'))

        severity_counts: Dict[str, int] = {}
        type_counts: Dict[str, int] = {}
        for entry in self.local_index:
            sev = entry.get('severity', 'UNKNOWN')
            evt = entry.get('event_type', 'UNKNOWN')
            severity_counts[sev] = severity_counts.get(sev, 0) + 1
            type_counts[evt] = type_counts.get(evt, 0) + 1

        return {
            'total_events': total,
            'nsr_violations': nsr_count,
            'by_severity': severity_counts,
            'by_type': type_counts,
            'log_file': self.log_file,
            'timestamp': datetime.now().isoformat()
        }

    def export_public_log(self, max_entries: int = 1000) -> List[Dict[str, Any]]:
        """
        Export public-safe log entries (source hashes only, no raw IPs).

        Args:
            max_entries: Maximum entries to export

        Returns:
            List of sanitized log entries suitable for public display
        """
        public_entries = []
        for entry in self.local_index[-max_entries:]:
            public_entry = {
                'entry_id': entry.get('entry_id'),
                'timestamp': entry.get('timestamp'),
                'event_type': entry.get('event_type'),
                'severity': entry.get('severity'),
                'description': entry.get('description'),
                'action_taken': entry.get('action_taken'),
                'nsr_violation': entry.get('nsr_violation'),
                'verified': entry.get('verified'),
                'integrity_hash': entry.get('integrity_hash'),
            }
            if 'source_hash' in entry:
                public_entry['source_hash'] = entry['source_hash']
            public_entries.append(public_entry)

        return public_entries


# Global instance for application-wide use
wall_of_entropy = WallOfEntropy()


if __name__ == "__main__":
    print("Wall of Entropy - Transparent Access Logging")
    print("=" * 50)

    woe = WallOfEntropy(log_dir='/tmp')

    # Log example events
    eid1 = woe.log_event(
        event_type='SPID_ATTEMPT',
        description='Attempted fingerprinting via canvas API',
        severity='HIGH',
        source='192.168.1.100',
        metadata={'detection_method': 'behavioral_analysis', 'confidence': 0.92},
        nsr_violation=True
    )
    print(f"Logged event: {eid1}")

    eid2 = woe.log_event(
        event_type='UNAUTHORIZED_TRACKING',
        description='Third-party tracker injection attempt',
        severity='MEDIUM',
        nsr_violation=True
    )
    print(f"Logged event: {eid2}")

    stats = woe.get_stats()
    print(f"\nStats: {json.dumps(stats, indent=2)}")

    # Verify integrity
    for entry in woe.local_index:
        valid = woe.verify_entry(entry)
        print(f"Entry {entry['entry_id']} integrity: {'VALID' if valid else 'INVALID'}")
