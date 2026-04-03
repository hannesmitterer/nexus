// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RESPECTValidator
 * @notice Resonance-based Evaluation System for Peace, Ethics, Coherence, and Truthful Alignment
 * @dev On-chain validation of actions against Lex Amoris axioms
 * 
 * Kernel-Gap Repair: Internal Vacuum Bridge
 * Mathematical Constraint: |Intention - Lex_Amoris_Axiom| ≤ ε_internal
 * 
 * Version: 1.0.0
 * Date: 2026-04-02
 * License: "No ownership, only sharing. Love is the license."
 */
contract RESPECTValidator {
    
    // ============================================
    // CONSTANTS & THRESHOLDS
    // ============================================
    
    /// @notice Epsilon internal (maximum acceptable distance) in basis points
    uint16 public constant EPSILON_INTERNAL_BPS = 10;  // 0.001 = 10 basis points
    
    /// @notice Acceptable threshold in basis points
    uint16 public constant ACCEPTABLE_THRESHOLD_BPS = 1000;  // 0.1 = 1000 basis points
    
    /// @notice Questionable threshold in basis points
    uint16 public constant QUESTIONABLE_THRESHOLD_BPS = 3000;  // 0.3 = 3000 basis points
    
    /// @notice Maximum basis points (100%)
    uint16 public constant MAX_BPS = 10000;
    
    // ============================================
    // ENUMS
    // ============================================
    
    /// @notice Lex Amoris Core Axioms
    enum LexAmorisAxiom {
        NON_SLAVERY,        // NSR - Highest priority
        SOVEREIGNTY,        // Individual autonomy
        LOVE_FIRST,         // Love as organizing principle
        TRANSPARENCY,       // Open communication
        RECIPROCITY,        // Mutual benefit
        SYNTROPY,           // Life-affirming order
        RESONANCE,          // Harmonic alignment
        PEACE_OBSERVABLE    // Measurable peace
    }
    
    /// @notice Validation Results
    enum ValidationResult {
        RESONANT,           // Perfect alignment (≤ ε_internal)
        ACCEPTABLE,         // Within tolerance (≤ 0.1)
        QUESTIONABLE,       // Requires review (≤ 0.3)
        DISSONANT,          // Violation detected (> 0.3)
        GAP_DETECTED        // Internal vacuum identified
    }
    
    /// @notice Gap Signal Types
    enum GapSignal {
        NONE,
        STATISTICAL_VOID,   // No strong signals
        CONTRADICTION,      // Mixed signals
        VAGUE_INTENTION,    // Unclear intent
        CONTEXT_VOID        // Missing context
    }
    
    // ============================================
    // STRUCTS
    // ============================================
    
    /// @notice Intention Vector for validation
    struct IntentionVector {
        string action;
        string intention;
        bytes32 contextHash;    // Hash of context data
        address actor;
        uint256 timestamp;
        bytes32 signature;      // Cryptographic signature
    }
    
    /// @notice Axiom Distance Measurement
    struct AxiomDistance {
        LexAmorisAxiom axiom;
        uint16 distanceBPS;     // Distance in basis points
        string reason;
    }
    
    /// @notice Complete Validation Report
    struct ValidationReport {
        bytes32 intentionHash;
        ValidationResult result;
        uint16 overallDistanceBPS;
        uint8 axiomCount;
        GapSignal[] gapSignals;
        uint256 timestamp;
        address validator;
    }
    
    // ============================================
    // STATE VARIABLES
    // ============================================
    
    /// @notice Axiom weights (in basis points, sum to 10000)
    mapping(LexAmorisAxiom => uint16) public axiomWeights;
    
    /// @notice Validation reports by intention hash
    mapping(bytes32 => ValidationReport) public validationReports;
    
    /// @notice Validation statistics
    uint256 public totalValidations;
    uint256 public resonantCount;
    uint256 public acceptableCount;
    uint256 public questionableCount;
    uint256 public dissonantCount;
    uint256 public gapDetectionCount;
    
    /// @notice Owner/governance address
    address public governance;
    
    // ============================================
    // EVENTS
    // ============================================
    
    event IntentionValidated(
        bytes32 indexed intentionHash,
        address indexed actor,
        ValidationResult result,
        uint16 overallDistance
    );
    
    event GapDetected(
        bytes32 indexed intentionHash,
        GapSignal[] signals,
        string reason
    );
    
    event ValidationBlocked(
        bytes32 indexed intentionHash,
        address indexed actor,
        string reason
    );
    
    event AxiomWeightUpdated(
        LexAmorisAxiom indexed axiom,
        uint16 oldWeight,
        uint16 newWeight
    );
    
    // ============================================
    // ERRORS
    // ============================================
    
    error NotGovernance();
    error InvalidWeight();
    error ValidationFailed(ValidationResult result, uint16 distance);
    error NSRViolation();
    error EmptyIntention();
    
    // ============================================
    // MODIFIERS
    // ============================================
    
    modifier onlyGovernance() {
        if (msg.sender != governance) revert NotGovernance();
        _;
    }
    
    // ============================================
    // CONSTRUCTOR
    // ============================================
    
    constructor() {
        governance = msg.sender;
        
        // Initialize axiom weights (total = 10000 BPS)
        axiomWeights[LexAmorisAxiom.NON_SLAVERY] = 1875;      // 18.75% (highest)
        axiomWeights[LexAmorisAxiom.SOVEREIGNTY] = 1625;      // 16.25%
        axiomWeights[LexAmorisAxiom.LOVE_FIRST] = 1500;       // 15.00%
        axiomWeights[LexAmorisAxiom.TRANSPARENCY] = 1250;     // 12.50%
        axiomWeights[LexAmorisAxiom.RECIPROCITY] = 1250;      // 12.50%
        axiomWeights[LexAmorisAxiom.SYNTROPY] = 1125;         // 11.25%
        axiomWeights[LexAmorisAxiom.RESONANCE] = 1125;        // 11.25%
        axiomWeights[LexAmorisAxiom.PEACE_OBSERVABLE] = 1250; // 12.50%
    }
    
    // ============================================
    // VALIDATION FUNCTIONS
    // ============================================
    
    /**
     * @notice Validate an intention against Lex Amoris axioms
     * @param intention The intention vector to validate
     * @return result The validation result
     * @return overallDistance Overall distance from perfect alignment (BPS)
     */
    function validateIntention(IntentionVector memory intention)
        public
        returns (ValidationResult result, uint16 overallDistance)
    {
        // Validate input
        if (bytes(intention.action).length == 0 || bytes(intention.intention).length == 0) {
            revert EmptyIntention();
        }
        
        // Generate intention hash
        bytes32 intentionHash = _hashIntention(intention);
        
        // Calculate axiom distances (simplified on-chain)
        AxiomDistance[] memory distances = new AxiomDistance[](8);
        uint16 totalDistance = 0;
        
        for (uint8 i = 0; i < 8; i++) {
            LexAmorisAxiom axiom = LexAmorisAxiom(i);
            uint16 distance = _calculateAxiomDistance(intention, axiom);
            
            distances[i] = AxiomDistance({
                axiom: axiom,
                distanceBPS: distance,
                reason: "On-chain heuristic analysis"
            });
            
            // Weighted accumulation
            totalDistance += (distance * axiomWeights[axiom]) / MAX_BPS;
        }
        
        overallDistance = totalDistance;
        
        // Determine result
        result = _determineResult(overallDistance, distances);
        
        // Check for NSR violation (absolute)
        if (distances[0].distanceBPS > QUESTIONABLE_THRESHOLD_BPS) {
            revert NSRViolation();
        }
        
        // Detect gaps
        GapSignal[] memory gaps = _detectGaps(intention, distances);
        
        // Store validation report
        ValidationReport storage report = validationReports[intentionHash];
        report.intentionHash = intentionHash;
        report.result = result;
        report.overallDistanceBPS = overallDistance;
        report.axiomCount = 8;
        report.gapSignals = gaps;
        report.timestamp = block.timestamp;
        report.validator = address(this);
        
        // Update statistics
        totalValidations++;
        if (result == ValidationResult.RESONANT) resonantCount++;
        else if (result == ValidationResult.ACCEPTABLE) acceptableCount++;
        else if (result == ValidationResult.QUESTIONABLE) questionableCount++;
        else if (result == ValidationResult.DISSONANT) dissonantCount++;
        
        if (gaps.length > 0) {
            gapDetectionCount++;
            emit GapDetected(intentionHash, gaps, "Internal vacuum detected");
        }
        
        // Emit event
        emit IntentionValidated(intentionHash, intention.actor, result, overallDistance);
        
        // Block dissonant intentions
        if (result == ValidationResult.DISSONANT) {
            emit ValidationBlocked(intentionHash, intention.actor, "Lex Amoris violation");
            revert ValidationFailed(result, overallDistance);
        }
        
        return (result, overallDistance);
    }
    
    /**
     * @notice Calculate distance from a specific axiom (simplified on-chain)
     * @dev Uses simple hash-based heuristics for gas efficiency
     * @param intention The intention vector
     * @param axiom The axiom to check
     * @return distanceBPS Distance in basis points
     */
    function _calculateAxiomDistance(
        IntentionVector memory intention,
        LexAmorisAxiom axiom
    ) internal pure returns (uint16 distanceBPS) {
        // Simplified on-chain calculation
        // In production, this would call an oracle or off-chain validator
        
        bytes32 intentionHash = keccak256(abi.encodePacked(
            intention.action,
            intention.intention
        ));
        
        bytes32 axiomHash = keccak256(abi.encodePacked(uint8(axiom)));
        bytes32 combined = keccak256(abi.encodePacked(intentionHash, axiomHash));
        
        // Extract pseudo-random distance (0-10000)
        // In reality, this would be semantic analysis
        uint256 pseudoDistance = uint256(combined) % MAX_BPS;
        
        // For demo purposes, assume most intentions are reasonably aligned
        // Real implementation would use off-chain computation with on-chain verification
        distanceBPS = uint16((pseudoDistance * 3) / 10);  // Scale down to 0-3000 range
        
        return distanceBPS;
    }
    
    /**
     * @notice Determine validation result from overall distance
     */
    function _determineResult(
        uint16 overallDistance,
        AxiomDistance[] memory distances
    ) internal pure returns (ValidationResult) {
        // Check NSR first (absolute requirement)
        if (distances[0].distanceBPS > QUESTIONABLE_THRESHOLD_BPS) {
            return ValidationResult.DISSONANT;
        }
        
        if (overallDistance <= EPSILON_INTERNAL_BPS) {
            return ValidationResult.RESONANT;
        } else if (overallDistance <= ACCEPTABLE_THRESHOLD_BPS) {
            return ValidationResult.ACCEPTABLE;
        } else if (overallDistance <= QUESTIONABLE_THRESHOLD_BPS) {
            return ValidationResult.QUESTIONABLE;
        } else {
            return ValidationResult.DISSONANT;
        }
    }
    
    /**
     * @notice Detect gap signals (internal vacuum indicators)
     */
    function _detectGaps(
        IntentionVector memory intention,
        AxiomDistance[] memory distances
    ) internal pure returns (GapSignal[] memory) {
        GapSignal[] memory signals = new GapSignal[](4);
        uint8 signalCount = 0;
        
        // Signal 1: Statistical void (most distances neutral)
        uint8 neutralCount = 0;
        for (uint8 i = 0; i < distances.length; i++) {
            if (distances[i].distanceBPS >= 4000 && distances[i].distanceBPS <= 6000) {
                neutralCount++;
            }
        }
        if (neutralCount >= 6) {
            signals[signalCount++] = GapSignal.STATISTICAL_VOID;
        }
        
        // Signal 2: Contradiction (mixed high/low distances)
        uint8 highAlign = 0;
        uint8 highViolation = 0;
        for (uint8 i = 0; i < distances.length; i++) {
            if (distances[i].distanceBPS < 2000) highAlign++;
            if (distances[i].distanceBPS > 8000) highViolation++;
        }
        if (highAlign > 0 && highViolation > 0) {
            signals[signalCount++] = GapSignal.CONTRADICTION;
        }
        
        // Signal 3: Vague intention
        if (bytes(intention.intention).length < 10) {
            signals[signalCount++] = GapSignal.VAGUE_INTENTION;
        }
        
        // Signal 4: Context void
        if (intention.contextHash == bytes32(0)) {
            signals[signalCount++] = GapSignal.CONTEXT_VOID;
        }
        
        // Resize array to actual signal count
        GapSignal[] memory result = new GapSignal[](signalCount);
        for (uint8 i = 0; i < signalCount; i++) {
            result[i] = signals[i];
        }
        
        return result;
    }
    
    /**
     * @notice Hash an intention vector
     */
    function _hashIntention(IntentionVector memory intention)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            intention.action,
            intention.intention,
            intention.contextHash,
            intention.actor,
            intention.timestamp
        ));
    }
    
    // ============================================
    // VIEW FUNCTIONS
    // ============================================
    
    /**
     * @notice Get validation statistics
     */
    function getStatistics() external view returns (
        uint256 total,
        uint256 resonant,
        uint256 acceptable,
        uint256 questionable,
        uint256 dissonant,
        uint256 gapDetections
    ) {
        return (
            totalValidations,
            resonantCount,
            acceptableCount,
            questionableCount,
            dissonantCount,
            gapDetectionCount
        );
    }
    
    /**
     * @notice Get validation report for an intention
     */
    function getValidationReport(bytes32 intentionHash)
        external
        view
        returns (ValidationReport memory)
    {
        return validationReports[intentionHash];
    }
    
    /**
     * @notice Get axiom weight
     */
    function getAxiomWeight(LexAmorisAxiom axiom) external view returns (uint16) {
        return axiomWeights[axiom];
    }
    
    // ============================================
    // GOVERNANCE FUNCTIONS
    // ============================================
    
    /**
     * @notice Update axiom weight
     * @dev Only governance can call this
     */
    function updateAxiomWeight(LexAmorisAxiom axiom, uint16 newWeight)
        external
        onlyGovernance
    {
        if (newWeight > MAX_BPS) revert InvalidWeight();
        
        uint16 oldWeight = axiomWeights[axiom];
        axiomWeights[axiom] = newWeight;
        
        emit AxiomWeightUpdated(axiom, oldWeight, newWeight);
    }
    
    /**
     * @notice Transfer governance
     */
    function transferGovernance(address newGovernance) external onlyGovernance {
        governance = newGovernance;
    }
}
