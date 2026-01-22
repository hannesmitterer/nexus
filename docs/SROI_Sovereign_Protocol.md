# 🏛️ S-ROI Sovereign Protocol Documentation

**Version:** 1.0  
**Status:** Operational  
**Contract:** `SROISovereign.sol`  
**Framework:** Euystacio / SAIN Protocol Integration

---

## 📋 Overview

The S-ROI (Sovereign Return on Investment) Sovereign Protocol implements a comprehensive state machine for managing protocol lifecycle with advanced logging, validation, and notification systems. It ensures transparent, auditable, and secure state transitions with automatic alerting for critical conditions.

### Core Features

1. **Complete Logging System** - Every state transition and operation is logged with full context
2. **State Transition Validation** - Strict validation rules prevent invalid state changes
3. **Automatic Notifications** - Real-time alerts for critical states and threshold breaches
4. **Modular Architecture** - Each state has dedicated functions for clarity and reusability

---

## 🔄 Protocol States

The protocol operates in distinct states, each representing a phase in the S-ROI lifecycle:

### State Definitions

| State | Description | Purpose |
|-------|-------------|---------|
| **INITIALIZED** | Initial deployment state | Starting point after contract deployment |
| **ACTIVE** | Normal operational state | Protocol is fully operational |
| **VALIDATION** | Under audit/validation | Protocol is being validated or audited |
| **THRESHOLD_BREACH** | Critical threshold exceeded | One or more thresholds have been breached |
| **PAUSED** | Temporarily paused | Operations temporarily halted |
| **EMERGENCY** | Emergency state | Critical issue requiring immediate intervention |
| **RECOVERED** | Post-emergency recovery | System has recovered from emergency |
| **TERMINATED** | Final state (irreversible) | Protocol permanently terminated |

### State Transition Diagram

```
INITIALIZED
    ↓
ACTIVE ←→ VALIDATION
    ↓         ↓
PAUSED ←→ THRESHOLD_BREACH
    ↓         ↓
EMERGENCY → RECOVERED → ACTIVE
    ↓         ↓
TERMINATED
```

---

## 🔐 State Transition Rules

The protocol enforces strict validation for all state transitions:

### Valid Transitions

**From INITIALIZED:**
- → ACTIVE (activation)
- → PAUSED (initial pause)

**From ACTIVE:**
- → VALIDATION (enter audit)
- → PAUSED (pause operations)
- → EMERGENCY (critical issue)
- → THRESHOLD_BREACH (threshold exceeded)
- → TERMINATED (shutdown)

**From VALIDATION:**
- → ACTIVE (validation passed)
- → PAUSED (pause during validation)
- → EMERGENCY (critical issue found)

**From THRESHOLD_BREACH:**
- → ACTIVE (threshold resolved)
- → EMERGENCY (escalation)
- → PAUSED (temporary halt)

**From PAUSED:**
- → ACTIVE (resume)
- → EMERGENCY (critical issue)
- → TERMINATED (shutdown while paused)

**From EMERGENCY:**
- → RECOVERED (recovery initiated)
- → TERMINATED (emergency shutdown)

**From RECOVERED:**
- → ACTIVE (full recovery)
- → VALIDATION (post-recovery audit)
- → TERMINATED (shutdown after recovery)

**TERMINATED:**
- No transitions (final state)

---

## 📊 Logging System

### Complete State Transition Logging

Every state transition creates a permanent, immutable record:

```solidity
struct StateTransition {
    ProtocolState fromState;    // Previous state
    ProtocolState toState;      // New state
    uint256 timestamp;          // When transition occurred
    address triggeredBy;        // Who triggered it
    string reason;              // Why it happened
    bytes32 transitionHash;     // Unique hash for verification
}
```

### Events Emitted

1. **StateTransitioned** - Complete transition details
2. **TransitionValidationFailed** - Failed transition attempts
3. **OperationExecuted** - All operations with success/failure status
4. **ThresholdBreached** - Threshold violations
5. **NotificationCreated** - All system notifications
6. **CriticalStateEntered** - Entry into critical states
7. **EmergencyActivated** - Emergency activations
8. **SystemRecovered** - Recovery completions

### Audit Trail Access

```solidity
// Get total number of transitions
uint256 count = protocol.getStateHistoryLength();

// Get specific transition details
(fromState, toState, timestamp, triggeredBy, reason, hash) = 
    protocol.getStateTransition(index);

// Get protocol statistics
(state, transitions, notifications, operations, failures, emergencies) = 
    protocol.getProtocolStats();
```

---

## 🎯 Threshold Management

### Threshold Configuration

Thresholds monitor critical metrics and trigger alerts when breached:

```solidity
// Configure a threshold
protocol.setThreshold(
    "MAX_OPERATIONS_PER_HOUR",  // Threshold key
    1000,                        // Threshold value
    true                         // Enabled
);

// Check value against threshold
bool breached = protocol.checkThreshold("MAX_OPERATIONS_PER_HOUR", currentValue);
```

### Threshold Structure

```solidity
struct Threshold {
    uint256 value;           // Threshold limit
    bool enabled;            // Whether threshold is active
    uint256 breachCount;     // Number of times breached
    uint256 lastBreachTime;  // Last breach timestamp
}
```

### Automatic Escalation

- **First breach:** Warning notification (severity 4)
- **Second breach:** Another warning notification
- **Third breach:** Automatic transition to THRESHOLD_BREACH state
- **Critical notification** generated with severity 5

### Threshold Querying

```solidity
// Get threshold details
(value, enabled, breachCount, lastBreachTime) = 
    protocol.getThreshold("MAX_OPERATIONS_PER_HOUR");

// Get all configured thresholds
string[] memory keys = protocol.getAllThresholdKeys();
```

---

## 🔔 Notification System

### Notification Types

1. **STATE_CHANGE** - State transitions
2. **THRESHOLD_BREACH** - Threshold violations
3. **CRITICAL_STATE** - Entry into critical states
4. **VALIDATION_FAILED** - Failed validations
5. **EMERGENCY_TRIGGERED** - Emergency activations
6. **RECOVERY_INITIATED** - Recovery processes
7. **SYSTEM_ALERT** - General system alerts

### Severity Levels

- **1-2:** Informational
- **3:** Warning
- **4:** High priority
- **5:** Critical (requires immediate attention)

### Notification Structure

```solidity
struct Notification {
    uint256 id;                      // Unique identifier
    NotificationType notificationType; // Type of notification
    ProtocolState relatedState;      // Associated state
    string message;                  // Human-readable message
    uint256 timestamp;               // When created
    uint256 severity;                // 1-5 severity level
    bool acknowledged;               // Acknowledgment status
}
```

### Accessing Notifications

```solidity
// Get notification details
(type, state, message, timestamp, severity, acknowledged) = 
    protocol.getNotification(notificationId);

// Acknowledge a notification
protocol.acknowledgeNotification(notificationId);

// Check if notification is critical
bool isCritical = protocol.criticalNotifications(notificationId);
```

---

## 🛠️ Core Functions

### State Transition Functions (Modularized)

Each state transition has a dedicated function:

#### Activation
```solidity
function activate() external onlyAuthorized
```
Transitions from INITIALIZED to ACTIVE state.

#### Validation
```solidity
function enterValidation() external onlyAuthorized
function completeValidation(bool passed) external onlyAuthorized
```
Enter and complete validation phase.

#### Pause/Resume
```solidity
function pause() external onlyAuthorized
function resume() external onlyAuthorized
```
Pause and resume protocol operations.

#### Emergency Management
```solidity
function triggerEmergency(string calldata reason) external onlyAuthorized
function recoverFromEmergency() external onlyGovernance
function returnToActive() external onlyGovernance
```
Handle emergency situations with recovery path.

#### Termination
```solidity
function terminate(string calldata reason) external onlyGovernance
```
Permanently terminate the protocol (irreversible).

---

## 👥 Access Control

### Roles

1. **Governance** - Full control, can execute all functions
2. **Authorized Operators** - Can trigger state transitions (except termination)
3. **Public** - Read-only access to all data

### Authorization Management

```solidity
// Authorize an operator
function authorizeOperator(address operator) external onlyGovernance

// Revoke authorization
function revokeOperator(address operator) external onlyGovernance

// Update governance address
function updateGovernance(address newGovernance) external onlyGovernance
```

---

## 📈 Usage Examples

### Example 1: Normal Operation Flow

```solidity
// 1. Deploy contract
SROISovereign protocol = new SROISovereign(governanceAddress);

// 2. Authorize operators
protocol.authorizeOperator(operatorAddress);

// 3. Activate protocol
protocol.activate();

// 4. Configure thresholds
protocol.setThreshold("MAX_DAILY_OPERATIONS", 10000, true);
protocol.setThreshold("MAX_FAILURE_RATE", 5, true); // 5%

// 5. Monitor operations
bool breached = protocol.checkThreshold("MAX_DAILY_OPERATIONS", currentOps);

// 6. Enter validation when needed
protocol.enterValidation();
protocol.completeValidation(true);
```

### Example 2: Emergency Response

```solidity
// Detect critical issue
protocol.triggerEmergency("Critical vulnerability detected");

// System automatically:
// - Transitions to EMERGENCY state
// - Creates critical notification (severity 5)
// - Emits EmergencyActivated event
// - Logs complete transition

// After issue resolved
protocol.recoverFromEmergency();
protocol.returnToActive();
```

### Example 3: Threshold Monitoring

```solidity
// Set up threshold monitoring
protocol.setThreshold("ERROR_RATE", 100, true); // Max 100 errors

// During operations
uint256 currentErrors = calculateCurrentErrors();
bool breached = protocol.checkThreshold("ERROR_RATE", currentErrors);

// If breached 3 times, protocol automatically:
// - Transitions to THRESHOLD_BREACH state
// - Creates critical notification
// - Emits ThresholdBreached event
```

---

## 🔍 Integration with Euystacio Framework

### SAIN Protocol Compatibility

The S-ROI Sovereign Protocol integrates seamlessly with existing Euystacio components:

1. **EIMClient Integration** - State transitions can be monitored by EIMClient
2. **TFKVerifier Compatibility** - State changes can trigger model retraining
3. **Dashboard Integration** - All states and notifications visible on Sensisara Dashboard
4. **VCE Triggering** - Critical states can trigger Veto Consensus Events

### Event Subscriptions

External systems can subscribe to protocol events:

```javascript
// Listen for state changes
protocol.on('StateTransitioned', (fromState, toState, triggeredBy, timestamp, reason, hash) => {
    console.log(`State changed: ${fromState} → ${toState}`);
    console.log(`Reason: ${reason}`);
});

// Listen for critical notifications
protocol.on('NotificationCreated', (id, type, state, severity, message, timestamp) => {
    if (severity >= 4) {
        alert(`CRITICAL: ${message}`);
    }
});

// Listen for threshold breaches
protocol.on('ThresholdBreached', (key, currentValue, thresholdValue, breachCount, timestamp) => {
    console.warn(`Threshold ${key} breached: ${currentValue} > ${thresholdValue}`);
});
```

---

## 🔒 Security Considerations

1. **Access Control** - Only authorized addresses can trigger state transitions
2. **Validation** - All transitions validated before execution
3. **Immutable Logging** - State history cannot be modified
4. **Emergency Procedures** - Quick response mechanism for critical issues
5. **Governance Protection** - Critical functions restricted to governance only

---

## 📊 Monitoring & Metrics

### Key Metrics to Monitor

- **Current State** - Protocol's current operational state
- **Transition Count** - Total number of state transitions
- **Notification Count** - Total notifications generated
- **Critical Notifications** - Unacknowledged critical alerts
- **Failed Validations** - Number of failed validation attempts
- **Emergency Activations** - Number of emergency triggers
- **Threshold Breaches** - Per-threshold breach counts

### Health Indicators

- **Green:** ACTIVE state, no critical notifications, no threshold breaches
- **Yellow:** VALIDATION or PAUSED state, some warnings
- **Red:** EMERGENCY, THRESHOLD_BREACH, or TERMINATED state

---

## 🚀 Deployment Checklist

- [ ] Deploy SROISovereign contract with governance address
- [ ] Authorize initial operators
- [ ] Configure critical thresholds
- [ ] Activate protocol
- [ ] Set up event monitoring
- [ ] Integrate with dashboard
- [ ] Test emergency procedures
- [ ] Document operational procedures
- [ ] Train operators on state management

---

## 📝 Change Log

**Version 1.0** (Initial Release)
- Complete state machine implementation
- Comprehensive logging system
- Threshold monitoring and notifications
- Modular state transition functions
- Emergency management procedures
- Full integration with Euystacio framework

---

## 📞 Support & Governance

For operational issues or governance decisions regarding the S-ROI Sovereign Protocol:

1. **Technical Issues:** Monitor dashboard for notifications
2. **Governance Decisions:** Submit proposals to GGC multisig
3. **Emergency Response:** Follow documented emergency procedures
4. **Audit Requests:** Use `enterValidation()` function

---

**Protocol Status:** Operational  
**Last Updated:** 2026-01-22  
**Maintained By:** Euystacio Framework / SAIN Protocol Team
