# S-ROI Sovereign Protocol

## Overview

The S-ROI (Sovereign Return on Investment) Sovereign Protocol is a modular state management system designed to track resonance values and manage protocol states with improved scalability and edge case handling.

## Features

### 1. State Management
The protocol supports three distinct states:

- **NORMAL**: Default state for resonance values at or above the warning threshold (≥ 0.35 by default)
- **WARNING**: Intermediate state for resonance values near the critical threshold (0.30 < resonance < 0.35 by default)
- **STEALTH**: Critical state for low resonance values (≤ 0.30 by default)

### 2. Logging System
Comprehensive logging functionality tracks:
- State transitions with timestamps and reasons
- Resonance value changes
- Cooldown activation events
- Warning and error conditions

### 3. Cooldown Mechanism
A configurable cooldown period (300 seconds by default) prevents rapid stealth mode reactivation, improving system stability and preventing oscillation between states.

### 4. Modular Architecture
The protocol is organized into separate modules for easy maintenance and testing:
- `protocol.py`: Main protocol implementation
- `states.py`: State enumeration
- `config.py`: Configuration management
- `logger.py`: Logging functionality

## Installation

The protocol is a pure Python implementation with no external dependencies beyond the standard library.

```bash
# No installation required - use directly from the repository
cd /path/to/nexus
python3
```

## Quick Start

### Basic Usage

```python
from s_roi_protocol import SROISovereignProtocol

# Initialize with default configuration
protocol = SROISovereignProtocol()

# Update resonance value
protocol.update_resonance(0.5)  # NORMAL state
protocol.update_resonance(0.32) # WARNING state
protocol.update_resonance(0.25) # STEALTH state

# Get current state
print(f"Current state: {protocol.state}")
print(f"Resonance: {protocol.current_resonance}")
```

### Custom Configuration

```python
from s_roi_protocol import SROISovereignProtocol, ProtocolConfig

# Create custom configuration
config = ProtocolConfig(
    STEALTH_THRESHOLD=0.2,
    WARNING_THRESHOLD=0.4,
    STEALTH_COOLDOWN_SECONDS=600  # 10 minutes
)

# Initialize with custom config
protocol = SROISovereignProtocol(config)
```

### Getting State Information

```python
# Get comprehensive state info
info = protocol.get_state_info()
print(f"State: {info['state']}")
print(f"Resonance: {info['current_resonance']}")
print(f"Cooldown remaining: {info['stealth_cooldown_remaining']}s")
print(f"Can activate stealth: {info['can_activate_stealth']}")
```

### Manual State Control

```python
# Force state transition (bypasses cooldown)
from s_roi_protocol import ProtocolState

protocol.force_state(ProtocolState.STEALTH, reason="Emergency override")
```

## Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `STEALTH_THRESHOLD` | 0.3 | Maximum resonance for STEALTH state (≤ 0.3) |
| `WARNING_THRESHOLD` | 0.35 | Threshold for WARNING state (0.3 < resonance < 0.35) |
| `STEALTH_COOLDOWN_SECONDS` | 300 | Cooldown period for stealth reactivation |
| `LOG_STATE_CHANGES` | True | Enable state change logging |
| `LOG_RESONANCE_VALUES` | True | Enable resonance value logging |

## State Transitions

```
NORMAL (≥ 0.35) ←→ WARNING (0.3 < resonance < 0.35) ←→ STEALTH (≤ 0.3)
                                                          ↓
                                                    [Cooldown: 300s]
```

### Cooldown Behavior

- First stealth activation: No cooldown required
- Subsequent activations: Must wait for cooldown period to expire
- Manual override: `force_state()` bypasses cooldown
- Reset: Use `reset_cooldown()` to clear cooldown timer

## Testing

Run the test suite:

```bash
cd /home/runner/work/nexus/nexus
python3 -m pytest tests/test_s_roi_protocol.py -v
```

Or using unittest:

```bash
python3 -m unittest tests/test_s_roi_protocol.py
```

## API Reference

### SROISovereignProtocol

#### Methods

- `__init__(config=None)`: Initialize protocol with optional configuration
- `update_resonance(value)`: Update resonance value and handle state transitions
- `force_state(state, reason)`: Force transition to specific state (bypasses cooldown)
- `get_state_info()`: Get comprehensive state information dictionary
- `reset_cooldown()`: Reset the stealth mode cooldown timer

#### Properties

- `state`: Current protocol state (ProtocolState enum)
- `current_resonance`: Current resonance value (float)

### ProtocolConfig

Configuration class for protocol parameters. All parameters can be overridden via constructor:

```python
config = ProtocolConfig(
    STEALTH_THRESHOLD=0.2,
    WARNING_THRESHOLD=0.4
)
```

### ProtocolState

Enumeration of protocol states:
- `ProtocolState.NORMAL`
- `ProtocolState.WARNING`
- `ProtocolState.STEALTH`

## Example Scenarios

### Monitoring System Integration

```python
import time
from s_roi_protocol import SROISovereignProtocol

protocol = SROISovereignProtocol()

# Simulated monitoring loop
while True:
    # Get resonance from your system
    resonance = get_system_resonance()
    
    # Update protocol
    protocol.update_resonance(resonance)
    
    # Check state and take action
    if protocol.state == ProtocolState.STEALTH:
        activate_stealth_mode()
    elif protocol.state == ProtocolState.WARNING:
        send_warning_notification()
    
    time.sleep(1)
```

### Emergency Override

```python
# Emergency situation - force stealth immediately
protocol.force_state(
    ProtocolState.STEALTH,
    reason="Security breach detected"
)
```

## Architecture

The protocol follows a modular design pattern:

```
s_roi_protocol/
├── __init__.py       # Package exports
├── protocol.py       # Main protocol logic
├── states.py         # State definitions
├── config.py         # Configuration management
└── logger.py         # Logging functionality
```

## Contributing

When contributing to this protocol:

1. Maintain backward compatibility
2. Add tests for new features
3. Update documentation
4. Follow existing code style

## License

Part of the Nexus GGI framework under the Euystacio / SAIN Protocol.
