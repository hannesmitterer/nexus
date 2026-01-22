"""
Configuration module for the S-ROI Sovereign Protocol
"""


class ProtocolConfig:
    """Configuration class for S-ROI protocol parameters"""
    
    # Resonance thresholds
    STEALTH_THRESHOLD = 0.3  # Stealth if resonance <= 0.3
    WARNING_THRESHOLD = 0.35  # Warning if 0.3 < resonance < 0.35
    # Note: NORMAL state is for resonance >= 0.35
    
    # Cooldown settings
    STEALTH_COOLDOWN_SECONDS = 300  # 5 minutes cooldown for stealth activation
    
    # Logging settings
    LOG_STATE_CHANGES = True
    LOG_RESONANCE_VALUES = True
    
    def __init__(self, **kwargs):
        """
        Initialize configuration with optional overrides
        
        Args:
            **kwargs: Configuration parameters to override
        """
        for key, value in kwargs.items():
            if hasattr(self, key):
                setattr(self, key, value)
            else:
                raise ValueError(f"Unknown configuration parameter: {key}")
