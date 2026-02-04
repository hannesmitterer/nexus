#!/usr/bin/env python3
"""
Geo-Zone Filter for Suspicious Activity Isolation
Implements geographic filtering and activity monitoring
Part of Scenario C: Globale Angriffe und Koordination defense
"""

import time
import json
from typing import Dict, List, Any, Tuple, Optional
from dataclasses import dataclass, asdict
from enum import Enum


class ThreatLevel(Enum):
    """Threat levels for geo-zones"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


@dataclass
class GeoLocation:
    """Represents a geographic location"""
    latitude: float
    longitude: float
    country: str
    region: str
    city: Optional[str] = None


@dataclass
class ActivityEvent:
    """Represents a network activity event"""
    event_id: str
    ip_address: str
    location: GeoLocation
    activity_type: str
    timestamp: float
    metadata: Dict[str, Any]


@dataclass
class GeoZone:
    """Represents a geographic zone with security settings"""
    zone_id: str
    name: str
    countries: List[str]
    threat_level: ThreatLevel
    allowed_activities: List[str]
    blocked_activities: List[str]
    rate_limit: int  # requests per minute
    enabled: bool = True


class GeoZoneFilter:
    """
    Geographic filtering system for isolating suspicious activities
    """
    
    def __init__(self):
        """Initialize geo-zone filter"""
        self.zones: Dict[str, GeoZone] = {}
        self.blocked_ips: set = set()
        self.activity_log: List[ActivityEvent] = []
        self.threat_zones: Dict[str, ThreatLevel] = {}
        self._initialize_default_zones()
    
    def _initialize_default_zones(self):
        """Initialize default security zones"""
        # Trusted zone
        self.add_zone(GeoZone(
            zone_id="trusted",
            name="Trusted Zone",
            countries=["CH", "DE", "AT", "LI"],  # Switzerland, Germany, Austria, Liechtenstein
            threat_level=ThreatLevel.LOW,
            allowed_activities=["all"],
            blocked_activities=[],
            rate_limit=1000
        ))
        
        # Standard zone
        self.add_zone(GeoZone(
            zone_id="standard",
            name="Standard Zone",
            countries=["US", "GB", "FR", "IT", "ES", "NL", "BE", "SE", "NO", "DK"],
            threat_level=ThreatLevel.LOW,
            allowed_activities=["read", "write", "transact"],
            blocked_activities=["admin"],
            rate_limit=500
        ))
        
        # Restricted zone
        self.add_zone(GeoZone(
            zone_id="restricted",
            name="Restricted Zone",
            countries=["CN", "RU", "KP", "IR"],
            threat_level=ThreatLevel.HIGH,
            allowed_activities=["read"],
            blocked_activities=["write", "transact", "admin"],
            rate_limit=100
        ))
    
    def add_zone(self, zone: GeoZone):
        """
        Add or update a geo-zone
        
        Args:
            zone: GeoZone configuration
        """
        self.zones[zone.zone_id] = zone
        
        # Update threat level mapping
        for country in zone.countries:
            self.threat_zones[country] = zone.threat_level
    
    def filter_activity(self, event: ActivityEvent) -> Dict[str, Any]:
        """
        Filter activity based on geo-zone rules
        
        Args:
            event: Activity event to filter
            
        Returns:
            Filtering decision
        """
        result = {
            "event_id": event.event_id,
            "ip_address": event.ip_address,
            "timestamp": time.time()
        }
        
        # Check if IP is blocked
        if event.ip_address in self.blocked_ips:
            result["action"] = "BLOCK"
            result["reason"] = "ip_blacklisted"
            return result
        
        # Find applicable zone
        zone = self._find_zone_for_country(event.location.country)
        
        if not zone:
            result["action"] = "BLOCK"
            result["reason"] = "unknown_zone"
            result["recommendation"] = "Add country to a geo-zone"
            return result
        
        if not zone.enabled:
            result["action"] = "BLOCK"
            result["reason"] = "zone_disabled"
            return result
        
        # Check activity against zone rules
        if event.activity_type in zone.blocked_activities:
            result["action"] = "BLOCK"
            result["reason"] = "activity_blocked_in_zone"
            result["zone"] = zone.name
            
            # Escalate threat if multiple blocks from same location
            self._escalate_threat(event.location.country)
            
            return result
        
        if "all" not in zone.allowed_activities and event.activity_type not in zone.allowed_activities:
            result["action"] = "BLOCK"
            result["reason"] = "activity_not_allowed"
            result["zone"] = zone.name
            return result
        
        # Check rate limiting
        rate_check = self._check_rate_limit(event.ip_address, zone.rate_limit)
        if not rate_check["allowed"]:
            result["action"] = "THROTTLE"
            result["reason"] = "rate_limit_exceeded"
            result["retry_after"] = rate_check["retry_after"]
            return result
        
        # Activity allowed
        result["action"] = "ALLOW"
        result["zone"] = zone.name
        result["threat_level"] = zone.threat_level.value
        
        # Log activity
        self.activity_log.append(event)
        if len(self.activity_log) > 10000:
            self.activity_log = self.activity_log[-10000:]
        
        return result
    
    def detect_suspicious_patterns(self, window_minutes: int = 60) -> Dict[str, Any]:
        """
        Detect suspicious activity patterns across geo-zones
        
        Args:
            window_minutes: Time window for analysis
            
        Returns:
            Suspicious pattern detection results
        """
        cutoff_time = time.time() - (window_minutes * 60)
        recent_events = [e for e in self.activity_log if e.timestamp >= cutoff_time]
        
        if not recent_events:
            return {"status": "no_recent_activity"}
        
        # Analyze patterns
        country_activity = {}
        ip_activity = {}
        activity_types = {}
        
        for event in recent_events:
            country = event.location.country
            country_activity[country] = country_activity.get(country, 0) + 1
            
            ip_activity[event.ip_address] = ip_activity.get(event.ip_address, 0) + 1
            
            activity_types[event.activity_type] = activity_types.get(event.activity_type, 0) + 1
        
        # Detect anomalies
        suspicious_patterns = []
        
        # Pattern 1: High activity from high-threat zones
        for country, count in country_activity.items():
            threat_level = self.threat_zones.get(country, ThreatLevel.MEDIUM)
            if threat_level == ThreatLevel.HIGH and count > 50:
                suspicious_patterns.append({
                    "type": "high_threat_zone_activity",
                    "country": country,
                    "event_count": count,
                    "severity": "HIGH"
                })
        
        # Pattern 2: Single IP with excessive activity
        for ip, count in ip_activity.items():
            if count > 100:
                suspicious_patterns.append({
                    "type": "excessive_ip_activity",
                    "ip_address": ip,
                    "event_count": count,
                    "severity": "MEDIUM"
                })
        
        # Pattern 3: Coordinated attack from multiple zones
        if len(country_activity) > 10 and sum(country_activity.values()) > 200:
            suspicious_patterns.append({
                "type": "coordinated_multi_zone_attack",
                "affected_zones": len(country_activity),
                "total_events": sum(country_activity.values()),
                "severity": "CRITICAL"
            })
        
        return {
            "analysis_window_minutes": window_minutes,
            "total_events": len(recent_events),
            "unique_countries": len(country_activity),
            "unique_ips": len(ip_activity),
            "suspicious_patterns": suspicious_patterns,
            "threat_assessment": "CRITICAL" if any(p["severity"] == "CRITICAL" for p in suspicious_patterns) else "ELEVATED" if suspicious_patterns else "NORMAL",
            "timestamp": time.time()
        }
    
    def isolate_zone(self, zone_id: str, reason: str) -> Dict[str, Any]:
        """
        Isolate a geo-zone by blocking all activities
        
        Args:
            zone_id: Zone to isolate
            reason: Reason for isolation
            
        Returns:
            Isolation result
        """
        if zone_id not in self.zones:
            return {"status": "error", "message": "Zone not found"}
        
        zone = self.zones[zone_id]
        zone.enabled = False
        zone.threat_level = ThreatLevel.CRITICAL
        
        return {
            "status": "isolated",
            "zone_id": zone_id,
            "zone_name": zone.name,
            "affected_countries": zone.countries,
            "reason": reason,
            "timestamp": time.time()
        }
    
    def restore_zone(self, zone_id: str) -> Dict[str, Any]:
        """
        Restore an isolated zone
        
        Args:
            zone_id: Zone to restore
            
        Returns:
            Restoration result
        """
        if zone_id not in self.zones:
            return {"status": "error", "message": "Zone not found"}
        
        zone = self.zones[zone_id]
        zone.enabled = True
        
        return {
            "status": "restored",
            "zone_id": zone_id,
            "zone_name": zone.name,
            "timestamp": time.time()
        }
    
    def block_ip(self, ip_address: str, reason: str) -> Dict[str, Any]:
        """
        Block an IP address
        
        Args:
            ip_address: IP to block
            reason: Reason for blocking
            
        Returns:
            Block result
        """
        self.blocked_ips.add(ip_address)
        
        return {
            "status": "blocked",
            "ip_address": ip_address,
            "reason": reason,
            "timestamp": time.time()
        }
    
    def _find_zone_for_country(self, country: str) -> Optional[GeoZone]:
        """Find geo-zone for a country"""
        for zone in self.zones.values():
            if country in zone.countries:
                return zone
        return None
    
    def _check_rate_limit(self, ip_address: str, limit: int) -> Dict[str, Any]:
        """Check if IP has exceeded rate limit"""
        # Get activity in last minute
        cutoff = time.time() - 60
        recent = [e for e in self.activity_log if e.ip_address == ip_address and e.timestamp >= cutoff]
        
        count = len(recent)
        allowed = count < limit
        
        return {
            "allowed": allowed,
            "current_count": count,
            "limit": limit,
            "retry_after": 60 if not allowed else 0
        }
    
    def _escalate_threat(self, country: str):
        """Escalate threat level for a country"""
        if country in self.threat_zones:
            current = self.threat_zones[country]
            if current == ThreatLevel.LOW:
                self.threat_zones[country] = ThreatLevel.MEDIUM
            elif current == ThreatLevel.MEDIUM:
                self.threat_zones[country] = ThreatLevel.HIGH
            elif current == ThreatLevel.HIGH:
                self.threat_zones[country] = ThreatLevel.CRITICAL
    
    def get_zone_statistics(self) -> Dict[str, Any]:
        """Get statistics for all zones"""
        stats = {}
        
        for zone_id, zone in self.zones.items():
            zone_events = [e for e in self.activity_log if e.location.country in zone.countries]
            
            stats[zone_id] = {
                "name": zone.name,
                "enabled": zone.enabled,
                "threat_level": zone.threat_level.value,
                "countries": zone.countries,
                "total_events": len(zone_events),
                "rate_limit": zone.rate_limit
            }
        
        return {
            "zones": stats,
            "total_blocked_ips": len(self.blocked_ips),
            "total_events_logged": len(self.activity_log),
            "timestamp": time.time()
        }


if __name__ == "__main__":
    # Example usage
    geofilter = GeoZoneFilter()
    
    # Test event from trusted zone
    event1 = ActivityEvent(
        event_id="evt_001",
        ip_address="192.168.1.1",
        location=GeoLocation(47.3769, 8.5417, "CH", "Zurich", "Zurich"),
        activity_type="transact",
        timestamp=time.time(),
        metadata={"amount": 100}
    )
    
    result1 = geofilter.filter_activity(event1)
    print(f"Event 1: {result1['action']} - {result1.get('zone', 'N/A')}")
    
    # Test event from restricted zone
    event2 = ActivityEvent(
        event_id="evt_002",
        ip_address="203.0.113.1",
        location=GeoLocation(39.9042, 116.4074, "CN", "Beijing", "Beijing"),
        activity_type="write",
        timestamp=time.time(),
        metadata={}
    )
    
    result2 = geofilter.filter_activity(event2)
    print(f"Event 2: {result2['action']} - {result2.get('reason', 'N/A')}")
    
    # Get statistics
    stats = geofilter.get_zone_statistics()
    print(f"\nZone Statistics: {json.dumps(stats, indent=2)}")
