"""
Main S-ROI Sovereign Protocol implementation
"""

import time
from typing import Optional
from .states import ProtocolState
from .config import ProtocolConfig
from .logger import ProtocolLogger


class SROISovereignProtocol:
    """
    S-ROI Sovereign Protocol
    
    Manages state transitions and resonance tracking with improved
    scalability and edge case handling.
    """
    
    def __init__(self, config: Optional[ProtocolConfig] = None):
        """
        Initialize the S-ROI Sovereign Protocol
        
        Args:
            config: Optional configuration object. If None, uses defaults.
        """
        self.config = config or ProtocolConfig()
        self.logger = ProtocolLogger()
        
        # Initialize state
        self._state = ProtocolState.NORMAL
        self._current_resonance = 0.0
        
        # Cooldown tracking
        self._last_stealth_activation = 0.0
        
        self.logger.log_info("S-ROI Sovereign Protocol initialized")
    
    @property
    def state(self) -> ProtocolState:
        """Get current protocol state"""
        return self._state
    
    @property
    def current_resonance(self) -> float:
        """Get current resonance value"""
        return self._current_resonance
    
    def update_resonance(self, value: float) -> None:
        """
        Update the current resonance value and handle state transitions
        
        Args:
            value: New resonance value
            
        Raises:
            ValueError: If resonance value is negative
        """
        if value < 0:
            raise ValueError("Resonance value cannot be negative")
        
        old_resonance = self._current_resonance
        self._current_resonance = value
        
        if self.config.LOG_RESONANCE_VALUES:
            self.logger.log_resonance_value(value)
        
        # Determine new state based on resonance value
        new_state = self._calculate_state(value)
        
        # Handle state transition
        if new_state != self._state:
            self._transition_to_state(new_state, f"Resonance: {value:.4f}")
    
    def _calculate_state(self, resonance: float) -> ProtocolState:
        """
        Calculate the appropriate state based on resonance value
        
        Args:
            resonance: Current resonance value
            
        Returns:
            Appropriate protocol state
        """
        if resonance <= self.config.STEALTH_THRESHOLD:
            return ProtocolState.STEALTH
        elif resonance <= self.config.WARNING_THRESHOLD:
            return ProtocolState.WARNING
        else:
            return ProtocolState.NORMAL
    
    def _transition_to_state(self, new_state: ProtocolState, 
                            reason: Optional[str] = None) -> None:
        """
        Transition to a new state with logging and cooldown checks
        
        Args:
            new_state: Target state
            reason: Optional reason for transition
        """
        old_state = self._state
        
        # Check stealth cooldown if attempting to enter stealth mode
        if new_state == ProtocolState.STEALTH:
            if not self._check_stealth_cooldown():
                self.logger.log_warning(
                    f"Stealth activation blocked by cooldown. "
                    f"Remaining in {old_state} state."
                )
                return
        
        # Perform state transition
        self._state = new_state
        
        # Record activation time for stealth mode
        if new_state == ProtocolState.STEALTH:
            self._last_stealth_activation = time.time()
        
        # Log the transition
        if self.config.LOG_STATE_CHANGES:
            self.logger.log_state_change(str(old_state), str(new_state), reason)
    
    def _check_stealth_cooldown(self) -> bool:
        """
        Check if stealth mode cooldown has expired
        
        Returns:
            True if stealth mode can be activated, False otherwise
        """
        if self._last_stealth_activation == 0.0:
            # Never activated before
            return True
        
        elapsed = time.time() - self._last_stealth_activation
        remaining = self.config.STEALTH_COOLDOWN_SECONDS - elapsed
        
        if remaining > 0:
            self.logger.log_cooldown_active(remaining)
            return False
        
        return True
    
    def force_state(self, state: ProtocolState, reason: str = "Manual override") -> None:
        """
        Force transition to a specific state (bypasses cooldown)
        
        Args:
            state: Target state
            reason: Reason for forced transition
            
        Note:
            This method should be used carefully as it bypasses safety checks
        """
        old_state = self._state
        self._state = state
        
        # Record activation time for stealth mode
        if state == ProtocolState.STEALTH:
            self._last_stealth_activation = time.time()
        
        self.logger.log_warning(
            f"FORCED state transition: {old_state} -> {state} ({reason})"
        )
    
    def get_state_info(self) -> dict:
        """
        Get comprehensive state information
        
        Returns:
            Dictionary with current state, resonance, and cooldown info
        """
        cooldown_remaining = 0.0
        if self._last_stealth_activation > 0:
            elapsed = time.time() - self._last_stealth_activation
            cooldown_remaining = max(0, self.config.STEALTH_COOLDOWN_SECONDS - elapsed)
        
        return {
            'state': str(self._state),
            'current_resonance': self._current_resonance,
            'stealth_cooldown_remaining': cooldown_remaining,
            'can_activate_stealth': self._check_stealth_cooldown()
        }
    
    def reset_cooldown(self) -> None:
        """Reset the stealth mode cooldown timer"""
        self._last_stealth_activation = 0.0
        self.logger.log_info("Stealth cooldown reset")
