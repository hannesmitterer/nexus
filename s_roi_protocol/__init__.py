"""
S-ROI Sovereign Protocol
========================

This module implements the S-ROI (Sovereign Return on Investment) protocol
for managing states and resonance tracking with improved scalability.
"""

from .protocol import SROISovereignProtocol
from .states import ProtocolState
from .config import ProtocolConfig

__all__ = ['SROISovereignProtocol', 'ProtocolState', 'ProtocolConfig']
__version__ = '1.0.0'
