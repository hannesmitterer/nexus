"""
Logging module for the S-ROI Sovereign Protocol
"""

import logging
from datetime import datetime
from typing import Optional


class ProtocolLogger:
    """Logger for tracking protocol state changes and resonance values"""
    
    def __init__(self, name: str = "S-ROI", log_level: int = logging.INFO):
        """
        Initialize the protocol logger
        
        Args:
            name: Logger name
            log_level: Logging level
        """
        self.logger = logging.getLogger(name)
        self.logger.setLevel(log_level)
        
        # Create console handler if not already configured
        if not self.logger.handlers:
            handler = logging.StreamHandler()
            handler.setLevel(log_level)
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            self.logger.addHandler(handler)
    
    def log_state_change(self, old_state: str, new_state: str, 
                        reason: Optional[str] = None):
        """
        Log a state transition
        
        Args:
            old_state: Previous state
            new_state: New state
            reason: Optional reason for the change
        """
        msg = f"State transition: {old_state} -> {new_state}"
        if reason:
            msg += f" (Reason: {reason})"
        self.logger.info(msg)
    
    def log_resonance_value(self, value: float, context: Optional[str] = None):
        """
        Log a resonance value reading
        
        Args:
            value: Resonance value
            context: Optional context information
        """
        msg = f"Current resonance: {value:.4f}"
        if context:
            msg += f" ({context})"
        self.logger.debug(msg)
    
    def log_cooldown_active(self, remaining_seconds: float):
        """
        Log when cooldown is preventing stealth activation
        
        Args:
            remaining_seconds: Seconds remaining in cooldown
        """
        self.logger.warning(
            f"Stealth mode cooldown active. {remaining_seconds:.1f}s remaining"
        )
    
    def log_warning(self, message: str):
        """Log a warning message"""
        self.logger.warning(message)
    
    def log_error(self, message: str):
        """Log an error message"""
        self.logger.error(message)
    
    def log_info(self, message: str):
        """Log an info message"""
        self.logger.info(message)
