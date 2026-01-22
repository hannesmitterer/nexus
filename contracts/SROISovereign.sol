// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SROISovereign - S-ROI Sovereign Protocol
 * @notice Implementation of connected logical steps with logging, validation, and notifications
 * @dev Modular state machine with comprehensive monitoring and alerting
 * 
 * Features:
 * 1. Complete logging of logical flow and state changes
 * 2. State transition validation system
 * 3. Automatic notifications for critical states and threshold breaches
 * 4. Modularized code with individual state functions
 */

contract SROISovereign {
    // ============ Type Definitions ============
    
    /**
     * @dev Protocol states - each represents a distinct phase in the S-ROI lifecycle
     */
    enum ProtocolState {
        INITIALIZED,        // Initial state after deployment
        ACTIVE,            // Normal operational state
        VALIDATION,        // Under validation/audit
        THRESHOLD_BREACH,  // Critical threshold exceeded
        PAUSED,           // Temporarily paused
        EMERGENCY,        // Emergency state requiring intervention
        RECOVERED,        // Recovered from emergency
        TERMINATED        // Final state
    }
    
    /**
     * @dev State transition record for full audit trail
     */
    struct StateTransition {
        ProtocolState fromState;
        ProtocolState toState;
        uint256 timestamp;
        address triggeredBy;
        string reason;
        bytes32 transitionHash;
    }
    
    /**
     * @dev Threshold configuration
     */
    struct Threshold {
        uint256 value;
        bool enabled;
        uint256 breachCount;
        uint256 lastBreachTime;
    }
    
    /**
     * @dev Notification record
     */
    struct Notification {
        uint256 id;
        NotificationType notificationType;
        ProtocolState relatedState;
        string message;
        uint256 timestamp;
        uint256 severity; // 1-5, where 5 is critical
        bool acknowledged;
    }
    
    /**
     * @dev Notification types
     */
    enum NotificationType {
        STATE_CHANGE,
        THRESHOLD_BREACH,
        CRITICAL_STATE,
        VALIDATION_FAILED,
        EMERGENCY_TRIGGERED,
        RECOVERY_INITIATED,
        SYSTEM_ALERT
    }
    
    // ============ State Variables ============
    
    // Current protocol state
    ProtocolState public currentState;
    
    // State transition history
    StateTransition[] public stateHistory;
    mapping(uint256 => StateTransition) public transitions;
    uint256 public transitionCount;
    
    // Valid state transitions mapping
    mapping(ProtocolState => mapping(ProtocolState => bool)) public validTransitions;
    
    // Thresholds
    mapping(string => Threshold) public thresholds;
    string[] public thresholdKeys;
    
    // Notifications
    Notification[] public notifications;
    uint256 public notificationCount;
    mapping(uint256 => bool) public criticalNotifications;
    
    // Governance
    address public governance;
    mapping(address => bool) public authorizedOperators;
    
    // Metrics tracking
    uint256 public totalOperations;
    uint256 public failedValidations;
    uint256 public emergencyActivations;
    
    // Emergency pause
    bool public isPaused;
    
    // ============ Events - Complete Logging System ============
    
    /**
     * @dev Emitted for every state transition with full context
     */
    event StateTransitioned(
        ProtocolState indexed fromState,
        ProtocolState indexed toState,
        address indexed triggeredBy,
        uint256 timestamp,
        string reason,
        bytes32 transitionHash
    );
    
    /**
     * @dev Emitted when a state transition validation fails
     */
    event TransitionValidationFailed(
        ProtocolState indexed attemptedFrom,
        ProtocolState indexed attemptedTo,
        address indexed operator,
        uint256 timestamp,
        string reason
    );
    
    /**
     * @dev Emitted when a threshold is breached
     */
    event ThresholdBreached(
        string indexed thresholdKey,
        uint256 currentValue,
        uint256 thresholdValue,
        uint256 indexed breachCount,
        uint256 timestamp
    );
    
    /**
     * @dev Emitted for all notifications
     */
    event NotificationCreated(
        uint256 indexed notificationId,
        NotificationType indexed notificationType,
        ProtocolState indexed relatedState,
        uint256 severity,
        string message,
        uint256 timestamp
    );
    
    /**
     * @dev Emitted when entering critical state
     */
    event CriticalStateEntered(
        ProtocolState indexed state,
        uint256 timestamp,
        string reason
    );
    
    /**
     * @dev Emitted when emergency is triggered
     */
    event EmergencyActivated(
        address indexed triggeredBy,
        uint256 timestamp,
        string reason
    );
    
    /**
     * @dev Emitted when system recovers
     */
    event SystemRecovered(
        ProtocolState indexed previousState,
        address indexed recoveredBy,
        uint256 timestamp
    );
    
    /**
     * @dev Emitted for operation execution
     */
    event OperationExecuted(
        string indexed operationType,
        address indexed executor,
        bool success,
        uint256 timestamp
    );
    
    /**
     * @dev Emitted when threshold is configured
     */
    event ThresholdConfigured(
        string indexed key,
        uint256 value,
        bool enabled,
        uint256 timestamp
    );
    
    // ============ Modifiers ============
    
    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance");
        _;
    }
    
    modifier onlyAuthorized() {
        require(
            msg.sender == governance || authorizedOperators[msg.sender],
            "Not authorized"
        );
        _;
    }
    
    modifier whenNotPaused() {
        require(!isPaused, "System is paused");
        _;
    }
    
    modifier validStateTransition(ProtocolState toState) {
        require(
            _isValidTransition(currentState, toState),
            "Invalid state transition"
        );
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _governance) {
        require(_governance != address(0), "Invalid governance address");
        
        governance = _governance;
        currentState = ProtocolState.INITIALIZED;
        
        // Initialize valid state transitions
        _initializeValidTransitions();
        
        // Log initial state
        _logStateTransition(
            ProtocolState.INITIALIZED,
            ProtocolState.INITIALIZED,
            "Contract deployed"
        );
        
        emit OperationExecuted("DEPLOYMENT", msg.sender, true, block.timestamp);
    }
    
    // ============ Core State Transition Functions (Modularized) ============
    
    /**
     * @notice Activate the protocol from INITIALIZED state
     */
    function activate() external onlyAuthorized validStateTransition(ProtocolState.ACTIVE) {
        _executeStateTransition(ProtocolState.ACTIVE, "Protocol activation");
        _createNotification(
            NotificationType.STATE_CHANGE,
            ProtocolState.ACTIVE,
            "Protocol successfully activated",
            2
        );
    }
    
    /**
     * @notice Enter validation state for auditing
     */
    function enterValidation() external onlyAuthorized validStateTransition(ProtocolState.VALIDATION) {
        _executeStateTransition(ProtocolState.VALIDATION, "Entering validation phase");
        _createNotification(
            NotificationType.STATE_CHANGE,
            ProtocolState.VALIDATION,
            "System entering validation mode",
            3
        );
    }
    
    /**
     * @notice Complete validation and return to active state
     */
    function completeValidation(bool passed) external onlyAuthorized {
        require(currentState == ProtocolState.VALIDATION, "Not in validation state");
        
        if (passed) {
            _executeStateTransition(ProtocolState.ACTIVE, "Validation passed");
            _createNotification(
                NotificationType.STATE_CHANGE,
                ProtocolState.ACTIVE,
                "Validation completed successfully",
                2
            );
        } else {
            failedValidations++;
            _createNotification(
                NotificationType.VALIDATION_FAILED,
                ProtocolState.VALIDATION,
                "Validation failed",
                4
            );
        }
    }
    
    /**
     * @notice Pause the protocol
     */
    function pause() external onlyAuthorized validStateTransition(ProtocolState.PAUSED) {
        isPaused = true;
        _executeStateTransition(ProtocolState.PAUSED, "Protocol paused");
        _createNotification(
            NotificationType.STATE_CHANGE,
            ProtocolState.PAUSED,
            "Protocol paused",
            3
        );
    }
    
    /**
     * @notice Resume from paused state
     */
    function resume() external onlyAuthorized {
        require(currentState == ProtocolState.PAUSED, "Not paused");
        isPaused = false;
        _executeStateTransition(ProtocolState.ACTIVE, "Protocol resumed");
        _createNotification(
            NotificationType.STATE_CHANGE,
            ProtocolState.ACTIVE,
            "Protocol resumed",
            2
        );
    }
    
    /**
     * @notice Trigger emergency state
     */
    function triggerEmergency(string calldata reason) external onlyAuthorized {
        emergencyActivations++;
        _executeStateTransition(ProtocolState.EMERGENCY, reason);
        
        emit EmergencyActivated(msg.sender, block.timestamp, reason);
        emit CriticalStateEntered(ProtocolState.EMERGENCY, block.timestamp, reason);
        
        _createNotification(
            NotificationType.EMERGENCY_TRIGGERED,
            ProtocolState.EMERGENCY,
            string(abi.encodePacked("EMERGENCY: ", reason)),
            5 // Critical severity
        );
    }
    
    /**
     * @notice Recover from emergency state
     */
    function recoverFromEmergency() external onlyGovernance {
        require(currentState == ProtocolState.EMERGENCY, "Not in emergency state");
        
        ProtocolState previousState = currentState;
        _executeStateTransition(ProtocolState.RECOVERED, "Emergency recovery initiated");
        
        emit SystemRecovered(previousState, msg.sender, block.timestamp);
        
        _createNotification(
            NotificationType.RECOVERY_INITIATED,
            ProtocolState.RECOVERED,
            "System recovered from emergency",
            3
        );
    }
    
    /**
     * @notice Return to active state after recovery
     */
    function returnToActive() external onlyGovernance {
        require(currentState == ProtocolState.RECOVERED, "Not in recovered state");
        _executeStateTransition(ProtocolState.ACTIVE, "Returning to active state");
    }
    
    /**
     * @notice Terminate the protocol (irreversible)
     */
    function terminate(string calldata reason) external onlyGovernance {
        _executeStateTransition(ProtocolState.TERMINATED, reason);
        
        emit CriticalStateEntered(ProtocolState.TERMINATED, block.timestamp, reason);
        
        _createNotification(
            NotificationType.SYSTEM_ALERT,
            ProtocolState.TERMINATED,
            string(abi.encodePacked("Protocol terminated: ", reason)),
            5
        );
    }
    
    // ============ Threshold Management & Monitoring ============
    
    /**
     * @notice Configure a threshold
     */
    function setThreshold(
        string calldata key,
        uint256 value,
        bool enabled
    ) external onlyGovernance {
        if (thresholds[key].value == 0) {
            // New threshold
            thresholdKeys.push(key);
        }
        
        thresholds[key] = Threshold({
            value: value,
            enabled: enabled,
            breachCount: thresholds[key].breachCount,
            lastBreachTime: thresholds[key].lastBreachTime
        });
        
        emit ThresholdConfigured(key, value, enabled, block.timestamp);
    }
    
    /**
     * @notice Check a value against a threshold
     */
    function checkThreshold(string calldata key, uint256 currentValue) 
        external 
        onlyAuthorized 
        returns (bool breached) 
    {
        Threshold storage threshold = thresholds[key];
        require(threshold.enabled, "Threshold not enabled");
        
        breached = currentValue > threshold.value;
        
        if (breached) {
            threshold.breachCount++;
            threshold.lastBreachTime = block.timestamp;
            
            emit ThresholdBreached(
                key,
                currentValue,
                threshold.value,
                threshold.breachCount,
                block.timestamp
            );
            
            // Create critical notification
            _createNotification(
                NotificationType.THRESHOLD_BREACH,
                currentState,
                string(abi.encodePacked("Threshold breached: ", key)),
                4
            );
            
            // If multiple breaches, consider entering threshold breach state
            if (threshold.breachCount >= 3) {
                _handleCriticalThresholdBreach(key);
            }
        }
        
        return breached;
    }
    
    /**
     * @notice Handle critical threshold breach
     */
    function _handleCriticalThresholdBreach(string memory key) internal {
        if (currentState == ProtocolState.ACTIVE) {
            _executeStateTransition(
                ProtocolState.THRESHOLD_BREACH,
                string(abi.encodePacked("Critical threshold breach: ", key))
            );
            
            emit CriticalStateEntered(
                ProtocolState.THRESHOLD_BREACH,
                block.timestamp,
                key
            );
            
            _createNotification(
                NotificationType.CRITICAL_STATE,
                ProtocolState.THRESHOLD_BREACH,
                string(abi.encodePacked("CRITICAL: Multiple threshold breaches for ", key)),
                5
            );
        }
    }
    
    // ============ Internal Helper Functions ============
    
    /**
     * @notice Initialize valid state transitions
     */
    function _initializeValidTransitions() internal {
        // From INITIALIZED
        validTransitions[ProtocolState.INITIALIZED][ProtocolState.ACTIVE] = true;
        validTransitions[ProtocolState.INITIALIZED][ProtocolState.PAUSED] = true;
        
        // From ACTIVE
        validTransitions[ProtocolState.ACTIVE][ProtocolState.VALIDATION] = true;
        validTransitions[ProtocolState.ACTIVE][ProtocolState.PAUSED] = true;
        validTransitions[ProtocolState.ACTIVE][ProtocolState.EMERGENCY] = true;
        validTransitions[ProtocolState.ACTIVE][ProtocolState.THRESHOLD_BREACH] = true;
        validTransitions[ProtocolState.ACTIVE][ProtocolState.TERMINATED] = true;
        
        // From VALIDATION
        validTransitions[ProtocolState.VALIDATION][ProtocolState.ACTIVE] = true;
        validTransitions[ProtocolState.VALIDATION][ProtocolState.PAUSED] = true;
        validTransitions[ProtocolState.VALIDATION][ProtocolState.EMERGENCY] = true;
        
        // From THRESHOLD_BREACH
        validTransitions[ProtocolState.THRESHOLD_BREACH][ProtocolState.ACTIVE] = true;
        validTransitions[ProtocolState.THRESHOLD_BREACH][ProtocolState.EMERGENCY] = true;
        validTransitions[ProtocolState.THRESHOLD_BREACH][ProtocolState.PAUSED] = true;
        
        // From PAUSED
        validTransitions[ProtocolState.PAUSED][ProtocolState.ACTIVE] = true;
        validTransitions[ProtocolState.PAUSED][ProtocolState.EMERGENCY] = true;
        validTransitions[ProtocolState.PAUSED][ProtocolState.TERMINATED] = true;
        
        // From EMERGENCY
        validTransitions[ProtocolState.EMERGENCY][ProtocolState.RECOVERED] = true;
        validTransitions[ProtocolState.EMERGENCY][ProtocolState.TERMINATED] = true;
        
        // From RECOVERED
        validTransitions[ProtocolState.RECOVERED][ProtocolState.ACTIVE] = true;
        validTransitions[ProtocolState.RECOVERED][ProtocolState.VALIDATION] = true;
        validTransitions[ProtocolState.RECOVERED][ProtocolState.TERMINATED] = true;
        
        // TERMINATED is final - no transitions out
    }
    
    /**
     * @notice Check if a state transition is valid
     */
    function _isValidTransition(ProtocolState from, ProtocolState to) 
        internal 
        view 
        returns (bool) 
    {
        return validTransitions[from][to];
    }
    
    /**
     * @notice Execute a state transition with full logging
     */
    function _executeStateTransition(ProtocolState toState, string memory reason) internal {
        ProtocolState fromState = currentState;
        
        // Validate transition
        if (!_isValidTransition(fromState, toState)) {
            emit TransitionValidationFailed(
                fromState,
                toState,
                msg.sender,
                block.timestamp,
                "Invalid transition"
            );
            revert("Invalid state transition");
        }
        
        // Update state
        currentState = toState;
        
        // Log transition
        _logStateTransition(fromState, toState, reason);
        
        totalOperations++;
    }
    
    /**
     * @notice Log a state transition with complete audit trail
     */
    function _logStateTransition(
        ProtocolState fromState,
        ProtocolState toState,
        string memory reason
    ) internal {
        bytes32 transitionHash = keccak256(
            abi.encodePacked(
                fromState,
                toState,
                msg.sender,
                block.timestamp,
                reason,
                transitionCount
            )
        );
        
        StateTransition memory transition = StateTransition({
            fromState: fromState,
            toState: toState,
            timestamp: block.timestamp,
            triggeredBy: msg.sender,
            reason: reason,
            transitionHash: transitionHash
        });
        
        stateHistory.push(transition);
        transitions[transitionCount] = transition;
        transitionCount++;
        
        emit StateTransitioned(
            fromState,
            toState,
            msg.sender,
            block.timestamp,
            reason,
            transitionHash
        );
    }
    
    /**
     * @notice Create a notification
     */
    function _createNotification(
        NotificationType notificationType,
        ProtocolState relatedState,
        string memory message,
        uint256 severity
    ) internal {
        uint256 notificationId = notificationCount++;
        
        Notification memory notification = Notification({
            id: notificationId,
            notificationType: notificationType,
            relatedState: relatedState,
            message: message,
            timestamp: block.timestamp,
            severity: severity,
            acknowledged: false
        });
        
        notifications.push(notification);
        
        if (severity >= 4) {
            criticalNotifications[notificationId] = true;
        }
        
        emit NotificationCreated(
            notificationId,
            notificationType,
            relatedState,
            severity,
            message,
            block.timestamp
        );
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get state history length
     */
    function getStateHistoryLength() external view returns (uint256) {
        return stateHistory.length;
    }
    
    /**
     * @notice Get specific state transition
     */
    function getStateTransition(uint256 index) 
        external 
        view 
        returns (
            ProtocolState fromState,
            ProtocolState toState,
            uint256 timestamp,
            address triggeredBy,
            string memory reason,
            bytes32 transitionHash
        ) 
    {
        require(index < stateHistory.length, "Index out of bounds");
        StateTransition storage t = stateHistory[index];
        return (
            t.fromState,
            t.toState,
            t.timestamp,
            t.triggeredBy,
            t.reason,
            t.transitionHash
        );
    }
    
    /**
     * @notice Get notification details
     */
    function getNotification(uint256 notificationId)
        external
        view
        returns (
            NotificationType notificationType,
            ProtocolState relatedState,
            string memory message,
            uint256 timestamp,
            uint256 severity,
            bool acknowledged
        )
    {
        require(notificationId < notifications.length, "Invalid notification ID");
        Notification storage n = notifications[notificationId];
        return (
            n.notificationType,
            n.relatedState,
            n.message,
            n.timestamp,
            n.severity,
            n.acknowledged
        );
    }
    
    /**
     * @notice Get threshold details
     */
    function getThreshold(string calldata key)
        external
        view
        returns (
            uint256 value,
            bool enabled,
            uint256 breachCount,
            uint256 lastBreachTime
        )
    {
        Threshold storage t = thresholds[key];
        return (t.value, t.enabled, t.breachCount, t.lastBreachTime);
    }
    
    /**
     * @notice Get all threshold keys
     */
    function getAllThresholdKeys() external view returns (string[] memory) {
        return thresholdKeys;
    }
    
    /**
     * @notice Get protocol statistics
     */
    function getProtocolStats()
        external
        view
        returns (
            ProtocolState state,
            uint256 totalTransitions,
            uint256 totalNotifications,
            uint256 operations,
            uint256 failures,
            uint256 emergencies
        )
    {
        return (
            currentState,
            transitionCount,
            notificationCount,
            totalOperations,
            failedValidations,
            emergencyActivations
        );
    }
    
    /**
     * @notice Check if transition is valid
     */
    function isValidTransition(ProtocolState from, ProtocolState to)
        external
        view
        returns (bool)
    {
        return validTransitions[from][to];
    }
    
    // ============ Governance Functions ============
    
    /**
     * @notice Authorize an operator
     */
    function authorizeOperator(address operator) external onlyGovernance {
        require(operator != address(0), "Invalid address");
        authorizedOperators[operator] = true;
    }
    
    /**
     * @notice Revoke operator authorization
     */
    function revokeOperator(address operator) external onlyGovernance {
        authorizedOperators[operator] = false;
    }
    
    /**
     * @notice Acknowledge a notification
     */
    function acknowledgeNotification(uint256 notificationId) external onlyAuthorized {
        require(notificationId < notifications.length, "Invalid notification ID");
        notifications[notificationId].acknowledged = true;
    }
    
    /**
     * @notice Update governance address
     */
    function updateGovernance(address newGovernance) external onlyGovernance {
        require(newGovernance != address(0), "Invalid address");
        governance = newGovernance;
    }
}
