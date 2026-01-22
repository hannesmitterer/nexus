"""
State definitions for the S-ROI Sovereign Protocol
"""

from enum import Enum


class ProtocolState(Enum):
    """Protocol state enumeration"""
    NORMAL = "NORMAL"
    WARNING = "WARNING"
    STEALTH = "STEALTH"

    def __str__(self):
        return self.value
