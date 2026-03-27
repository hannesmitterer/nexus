# 🏛️ S-ROI Sovereign Protocol

**Smart Contract:** `contracts/SROISovereign.sol`  
**Documentation:** `docs/SROI_Sovereign_Protocol.md`  
**Integration Example:** `scripts/sroi_integration_example.js`

## 📋 Overview

The S-ROI (Sovereign Return on Investment) Sovereign Protocol is a comprehensive state machine implementation designed to manage protocol lifecycle with advanced logging, validation, and notification capabilities. It integrates seamlessly with the Euystacio/SAIN ecosystem.

## ✨ Key Features

### 1. 📊 Complete Logging System
- **Immutable Audit Trail**: Every state transition is permanently recorded
- **Comprehensive Context**: Logs include from/to state, timestamp, triggeredBy, reason
- **Unique Hashes**: Each transition has a cryptographic hash for verification
- **Full History Access**: Query any historical transition

### 2. ✅ State Transition Validation
- **8 Protocol States**: INITIALIZED, ACTIVE, VALIDATION, THRESHOLD_BREACH, PAUSED, EMERGENCY, RECOVERED, TERMINATED
- **Strict Validation Rules**: Invalid transitions are automatically rejected
- **Predefined Transitions**: Valid state paths are hardcoded for security
- **Failed Attempt Logging**: Invalid transition attempts are logged for audit

### 3. 🔔 Automatic Notifications
- **7 Notification Types**: STATE_CHANGE, THRESHOLD_BREACH, CRITICAL_STATE, VALIDATION_FAILED, EMERGENCY_TRIGGERED, RECOVERY_INITIATED, SYSTEM_ALERT
- **5-Level Severity**: From informational (1) to critical (5)
- **Automatic Escalation**: Multiple threshold breaches trigger critical state
- **Critical Flagging**: High-severity notifications are flagged separately

### 4. 🧩 Modular Architecture
- **Individual State Functions**: Each state transition has a dedicated function
- **Clean Separation**: Threshold management, notifications, and state logic are modular
- **Reusable Components**: Functions can be called independently
- **Clear Intent**: Function names clearly indicate their purpose

## 🚀 Quick Start

### Deployment

```solidity
// Deploy the contract
SROISovereign protocol = new SROISovereign(governanceAddress);

// Authorize operators
protocol.authorizeOperator(operatorAddress);

// Activate the protocol
protocol.activate();
```

### Configuration

```solidity
// Set up thresholds
protocol.setThreshold("MAX_DAILY_OPERATIONS", 10000, true);
protocol.setThreshold("MAX_ERROR_RATE", 5, true);
protocol.setThreshold("MAX_EMERGENCY_COUNT", 3, true);
```

### Monitoring

```javascript
// Listen for state changes
protocol.on('StateTransitioned', (fromState, toState, triggeredBy, timestamp, reason) => {
    console.log(`State: ${fromState} → ${toState}`);
    console.log(`Reason: ${reason}`);
});

// Listen for critical notifications
protocol.on('NotificationCreated', (id, type, state, severity, message) => {
    if (severity >= 4) {
        alert(`CRITICAL: ${message}`);
    }
});

// Listen for threshold breaches
protocol.on('ThresholdBreached', (key, currentValue, thresholdValue, breachCount) => {
    console.warn(`Threshold ${key} breached: ${currentValue} > ${thresholdValue}`);
});
```

## 📖 Documentation

For detailed documentation, see:
- **Full Documentation**: [docs/SROI_Sovereign_Protocol.md](docs/SROI_Sovereign_Protocol.md)
- **Integration Example**: [scripts/sroi_integration_example.js](scripts/sroi_integration_example.js)

## 🔄 State Machine

```
INITIALIZED
    ↓
ACTIVE ←→ VALIDATION
    ↓         ↓
PAUSED ←→ THRESHOLD_BREACH
    ↓         ↓
EMERGENCY → RECOVERED → ACTIVE
    ↓         ↓
TERMINATED (final)
```

## 🎯 Use Cases

### Normal Operations
1. Deploy and activate protocol
2. Configure thresholds
3. Monitor state transitions
4. Handle threshold breaches
5. Periodic validation

### Emergency Response
1. Detect critical issue
2. Trigger emergency state
3. System auto-pauses related operations
4. Governance investigates
5. Recovery initiated
6. Return to active state

### Validation Flow
1. Enter validation state
2. External audit performed
3. Validation completed (pass/fail)
4. Return to active or handle failure

## 🔐 Security Features

- ✅ **Access Control**: Only authorized addresses can trigger transitions
- ✅ **Validation**: All transitions validated before execution
- ✅ **Immutable Logging**: State history cannot be modified
- ✅ **Emergency Procedures**: Quick response for critical issues
- ✅ **Governance Protection**: Critical functions restricted to governance

## 📊 Monitoring & Metrics

### Key Metrics
- Current protocol state
- Total state transitions
- Total notifications
- Failed validations
- Emergency activations
- Threshold breach counts

### Access Functions
```solidity
// Get protocol statistics
(state, transitions, notifications, operations, failures, emergencies) = 
    protocol.getProtocolStats();

// Get state history
(fromState, toState, timestamp, triggeredBy, reason, hash) = 
    protocol.getStateTransition(index);

// Get notification details
(type, state, message, timestamp, severity, acknowledged) = 
    protocol.getNotification(notificationId);

// Get threshold details
(value, enabled, breachCount, lastBreachTime) = 
    protocol.getThreshold("MAX_DAILY_OPERATIONS");
```

## 🔗 Integration

### Euystacio/SAIN Ecosystem Integration

The S-ROI Sovereign Protocol integrates with:

1. **EIMClient** - Automated monitoring of state transitions
2. **TFKVerifier** - State changes can trigger model validation
3. **Sensisara Dashboard** - Real-time visualization of protocol state
4. **VCE System** - Critical states can trigger consensus events

### Integration Example

See `scripts/sroi_integration_example.js` for a complete integration example showing:
- Event listener setup
- Dashboard integration
- Threshold monitoring
- Emergency handling
- EIMClient integration

## 📝 Requirements Fulfilled

This implementation fulfills all requirements from the problem statement:

1. ✅ **Logging Functions**: Complete logging of logical flow and all states
   - StateTransition struct with full context
   - Immutable state history array
   - Comprehensive event emission
   - Unique transition hashes

2. ✅ **Validation System**: Verification of state transition correctness
   - validTransitions mapping
   - Automatic validation before state change
   - Failed attempt logging
   - Revert on invalid transitions

3. ✅ **Automatic Notifications**: Alerts for critical states and thresholds
   - 7 notification types
   - 5-level severity system
   - Automatic threshold monitoring
   - Critical state detection
   - Escalation mechanisms

4. ✅ **Modular Code**: States as individual functions
   - activate()
   - enterValidation() / completeValidation()
   - pause() / resume()
   - triggerEmergency() / recoverFromEmergency()
   - Each state has dedicated logic

## 🛠️ Development

### Prerequisites
- Solidity ^0.8.20
- Node.js and npm (for integration example)
- ethers.js or web3.js (for interaction)

### Testing

```bash
# Compile contract
solc contracts/SROISovereign.sol

# Run integration example
node scripts/sroi_integration_example.js
```

## 📄 License

MIT License - See contract header for details

## 🤝 Contributing

Part of the Euystacio Framework / SAIN Protocol ecosystem.

For issues or improvements, please follow the standard contribution process.

## 📞 Support

- **Technical Issues**: Monitor Sensisara Dashboard for notifications
- **Governance**: Submit proposals to GGC multisig
- **Emergency**: Follow documented emergency procedures
- **Documentation**: See `docs/SROI_Sovereign_Protocol.md`

---

**Status**: Operational  
**Version**: 1.0  
**Last Updated**: 2026-01-22
