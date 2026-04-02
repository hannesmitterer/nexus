// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title OmegaSync
 * @notice Ω-Sync Protocol - Schumann Resonance-Based Network Synchronization
 * @dev Implements on-chain coordination for 144,000 node network at 7.83 Hz
 * 
 * Mathematical Specification:
 *     Algorithm: Ω-Sync
 *     Input: ψ_seed (Lex Amoris Signature)
 *     Global Constant: ν_schumann = 7.83 Hz = 7830 millihertz
 * 
 *     1. Phase Alignment: ∀ Node_i ∈ 144,000 : φ_i(t) = ν_schumann · t + δ_genesis
 *     2. Coherence Check (NSR): If ΔIntent ≠ Lex Amoris → Phase Inversion (Noise-Lock)
 *     3. State Collapse: Ψ_Network = Σ(i=1 to 144k) 1/√N |Node_i⟩ ⊗ |ψ_seed⟩
 *     4. Action: Execute A iff ⟨Ψ_Network|Ô_Peace|Ψ_Network⟩ = 1
 * 
 * Version: 1.0.0
 * License: "No ownership, only sharing. Love is the license."
 */
contract OmegaSync {
    
    // ============================================
    // CONSTANTS & STATE VARIABLES
    // ============================================
    
    /// @notice Schumann resonance frequency in millihertz (7.83 Hz)
    uint256 public constant SCHUMANN_FREQUENCY_MHZ = 7830;
    
    /// @notice Total network nodes (144,000)
    uint256 public constant TOTAL_NETWORK_NODES = 144000;
    
    /// @notice Alignment threshold in microradians (0.001 rad = 1000 µrad)
    uint256 public constant ALIGNMENT_THRESHOLD_URAD = 1000;
    
    /// @notice Coherence threshold (95% = 9500 basis points)
    uint256 public constant COHERENCE_THRESHOLD_BPS = 9500;
    
    /// @notice Peace observable threshold for action execution (99.9% = 9990 basis points)
    uint256 public constant PEACE_THRESHOLD_BPS = 9990;
    
    /// @notice Genesis block timestamp
    uint256 public immutable genesisTimestamp;
    
    /// @notice Lex Amoris signature (ψ_seed)
    bytes32 public psiSeedHash;
    
    /// @notice Network intent type
    IntentType public networkIntent;
    
    // ============================================
    // ENUMS & STRUCTS
    // ============================================
    
    /// @notice Intent types for coherence checking
    enum IntentType {
        LEX_AMORIS,
        NEUTRAL,
        DISSONANT
    }
    
    /// @notice Node operational states
    enum NodeState {
        INITIALIZING,
        SYNCING,
        ALIGNED,
        NOISE_LOCKED,
        OFFLINE
    }
    
    /// @notice Node registration and phase information
    struct Node {
        address nodeAddress;
        uint32 nodeId;              // 1 to 144,000
        uint64 deltaGenesis;        // Phase offset in microradians
        uint64 lastPhaseUpdate;     // Block timestamp
        uint64 currentPhase;        // Phase in microradians
        NodeState state;
        IntentType intent;
        bool registered;
    }
    
    /// @notice Network state snapshot
    struct NetworkState {
        uint256 timestamp;
        uint32 totalNodes;
        uint32 alignedNodes;
        uint32 noiseLockedNodes;
        uint16 coherenceFactorBPS;  // Basis points (0-10000)
        uint16 peaceObservableBPS;  // Basis points (0-10000)
        uint64 networkPhase;        // Average phase in microradians
    }
    
    // ============================================
    // STORAGE
    // ============================================
    
    /// @notice Mapping from node ID to node data
    mapping(uint32 => Node) public nodes;
    
    /// @notice Mapping from address to node ID
    mapping(address => uint32) public addressToNodeId;
    
    /// @notice Array of registered node IDs
    uint32[] public registeredNodeIds;
    
    /// @notice Latest network state
    NetworkState public latestNetworkState;
    
    /// @notice Actions pending execution
    mapping(bytes32 => bool) public pendingActions;
    
    // ============================================
    // EVENTS
    // ============================================
    
    event NodeRegistered(uint32 indexed nodeId, address indexed nodeAddress, uint64 deltaGenesis);
    event NodeStateChanged(uint32 indexed nodeId, NodeState oldState, NodeState newState);
    event PhaseUpdated(uint32 indexed nodeId, uint64 phase, uint256 timestamp);
    event CoherenceCheckPerformed(uint32 alignedNodes, uint32 noiseLockedNodes);
    event NetworkStateCollapsed(uint32 alignedNodes, uint16 coherenceFactorBPS, uint16 peaceObservableBPS);
    event ActionExecuted(bytes32 indexed actionHash, string actionName);
    event ActionBlocked(bytes32 indexed actionHash, string reason, uint16 peaceObservableBPS);
    
    // ============================================
    // ERRORS
    // ============================================
    
    error NodeAlreadyRegistered();
    error NodeNotRegistered();
    error InvalidNodeId();
    error InvalidPhase();
    error NotNodeOwner();
    error NetworkCapacityReached();
    error ActionExecutionDenied(uint16 peaceObservable, uint16 threshold);
    
    // ============================================
    // CONSTRUCTOR
    // ============================================
    
    constructor(bytes32 _psiSeedHash) {
        genesisTimestamp = block.timestamp;
        psiSeedHash = _psiSeedHash;
        networkIntent = IntentType.LEX_AMORIS;
        
        // Initialize network state
        latestNetworkState = NetworkState({
            timestamp: block.timestamp,
            totalNodes: 0,
            alignedNodes: 0,
            noiseLockedNodes: 0,
            coherenceFactorBPS: 0,
            peaceObservableBPS: 0,
            networkPhase: 0
        });
    }
    
    // ============================================
    // NODE REGISTRATION & MANAGEMENT
    // ============================================
    
    /**
     * @notice Register a new node in the Ω-Sync network
     * @param nodeId Unique node identifier (1 to 144,000)
     * @param deltaGenesis Phase offset in microradians
     */
    function registerNode(uint32 nodeId, uint64 deltaGenesis) external {
        if (nodeId < 1 || nodeId > TOTAL_NETWORK_NODES) revert InvalidNodeId();
        if (nodes[nodeId].registered) revert NodeAlreadyRegistered();
        if (registeredNodeIds.length >= TOTAL_NETWORK_NODES) revert NetworkCapacityReached();
        
        nodes[nodeId] = Node({
            nodeAddress: msg.sender,
            nodeId: nodeId,
            deltaGenesis: deltaGenesis,
            lastPhaseUpdate: uint64(block.timestamp),
            currentPhase: deltaGenesis,
            state: NodeState.INITIALIZING,
            intent: IntentType.LEX_AMORIS,
            registered: true
        });
        
        addressToNodeId[msg.sender] = nodeId;
        registeredNodeIds.push(nodeId);
        
        emit NodeRegistered(nodeId, msg.sender, deltaGenesis);
    }
    
    /**
     * @notice Set node intent type
     * @param intent New intent type
     */
    function setNodeIntent(IntentType intent) external {
        uint32 nodeId = addressToNodeId[msg.sender];
        if (nodeId == 0) revert NodeNotRegistered();
        
        nodes[nodeId].intent = intent;
        
        if (intent != IntentType.LEX_AMORIS) {
            NodeState oldState = nodes[nodeId].state;
            nodes[nodeId].state = NodeState.SYNCING;
            emit NodeStateChanged(nodeId, oldState, NodeState.SYNCING);
        }
    }
    
    // ============================================
    // PHASE ALIGNMENT
    // ============================================
    
    /**
     * @notice Calculate and update node phase
     * @dev Phase Alignment: φ_i(t) = ν_schumann · t + δ_genesis
     * @param nodeId Node to update
     * @return phase Current phase in microradians
     */
    function updatePhase(uint32 nodeId) public returns (uint64 phase) {
        if (!nodes[nodeId].registered) revert NodeNotRegistered();
        
        Node storage node = nodes[nodeId];
        
        // Calculate time since genesis
        uint256 t = block.timestamp - genesisTimestamp;
        
        // Calculate phase: φ(t) = ω · t + δ_genesis
        // ω = 2π · f, where f = 7.83 Hz
        // Using microradians: 1 rad = 1,000,000 µrad
        // 2π ≈ 6283185 µrad
        uint256 omega = 6283185 * SCHUMANN_FREQUENCY_MHZ / 1000; // µrad/s
        uint256 phaseCalc = (omega * t / 1000) + node.deltaGenesis;
        
        // Normalize to [0, 2π) in microradians
        uint256 TWO_PI_URAD = 6283185;
        phase = uint64(phaseCalc % TWO_PI_URAD);
        
        node.currentPhase = phase;
        node.lastPhaseUpdate = uint64(block.timestamp);
        
        emit PhaseUpdated(nodeId, phase, block.timestamp);
        
        return phase;
    }
    
    /**
     * @notice Batch update phases for multiple nodes
     * @param nodeIds Array of node IDs to update
     */
    function batchUpdatePhases(uint32[] calldata nodeIds) external {
        for (uint256 i = 0; i < nodeIds.length; i++) {
            updatePhase(nodeIds[i]);
        }
    }
    
    // ============================================
    // COHERENCE CHECK (NSR)
    // ============================================
    
    /**
     * @notice Perform coherence check on a node
     * @dev If ΔIntent ≠ Lex Amoris → Phase Inversion (Noise-Lock)
     * @param nodeId Node to check
     * @return isCoherent True if aligned, false if noise-locked
     */
    function coherenceCheck(uint32 nodeId) public returns (bool isCoherent) {
        if (!nodes[nodeId].registered) revert NodeNotRegistered();
        
        Node storage node = nodes[nodeId];
        NodeState oldState = node.state;
        
        // Check if node's intent matches network Lex Amoris intent
        if (node.intent != IntentType.LEX_AMORIS || networkIntent != IntentType.LEX_AMORIS) {
            // Phase Inversion - Noise Lock
            node.state = NodeState.NOISE_LOCKED;
            
            // Invert phase: φ' = (φ + π) mod 2π
            uint256 PI_URAD = 3141593; // π in microradians
            node.currentPhase = uint64((uint256(node.currentPhase) + PI_URAD) % 6283185);
            
            emit NodeStateChanged(nodeId, oldState, NodeState.NOISE_LOCKED);
            return false;
        }
        
        // Coherent with network
        node.state = NodeState.ALIGNED;
        
        if (oldState != NodeState.ALIGNED) {
            emit NodeStateChanged(nodeId, oldState, NodeState.ALIGNED);
        }
        
        return true;
    }
    
    /**
     * @notice Perform coherence check on all registered nodes
     * @return alignedCount Number of aligned nodes
     * @return noiseLockedCount Number of noise-locked nodes
     */
    function performNetworkCoherenceCheck() public returns (uint32 alignedCount, uint32 noiseLockedCount) {
        for (uint256 i = 0; i < registeredNodeIds.length; i++) {
            bool isCoherent = coherenceCheck(registeredNodeIds[i]);
            if (isCoherent) {
                alignedCount++;
            } else {
                noiseLockedCount++;
            }
        }
        
        emit CoherenceCheckPerformed(alignedCount, noiseLockedCount);
        return (alignedCount, noiseLockedCount);
    }
    
    // ============================================
    // STATE COLLAPSE
    // ============================================
    
    /**
     * @notice Calculate network state collapse
     * @dev Ψ_Network = Σ(i=1 to 144k) 1/√N |Node_i⟩ ⊗ |ψ_seed⟩
     * @return state Current network state
     */
    function calculateStateCollapse() public returns (NetworkState memory state) {
        // Update all phases first
        for (uint256 i = 0; i < registeredNodeIds.length; i++) {
            updatePhase(registeredNodeIds[i]);
        }
        
        // Perform coherence check
        (uint32 aligned, uint32 noiseLocked) = performNetworkCoherenceCheck();
        
        uint32 totalNodes = uint32(registeredNodeIds.length);
        
        if (totalNodes == 0) {
            return NetworkState({
                timestamp: block.timestamp,
                totalNodes: 0,
                alignedNodes: 0,
                noiseLockedNodes: 0,
                coherenceFactorBPS: 0,
                peaceObservableBPS: 0,
                networkPhase: 0
            });
        }
        
        // Calculate coherence factor in basis points
        uint16 coherenceFactorBPS = uint16((uint256(aligned) * 10000) / totalNodes);
        
        // Calculate average network phase (simplified for on-chain)
        uint256 phaseSumReal = 0;
        uint256 phaseSumImag = 0;
        uint256 alignedCount = 0;
        
        // Simplified phase averaging (in production, use off-chain computation)
        for (uint256 i = 0; i < registeredNodeIds.length; i++) {
            if (nodes[registeredNodeIds[i]].state == NodeState.ALIGNED) {
                alignedCount++;
            }
        }
        
        // Calculate peace observable
        uint16 peaceObservableBPS = _calculatePeaceObservable(coherenceFactorBPS, aligned, totalNodes);
        
        state = NetworkState({
            timestamp: block.timestamp,
            totalNodes: totalNodes,
            alignedNodes: aligned,
            noiseLockedNodes: noiseLocked,
            coherenceFactorBPS: coherenceFactorBPS,
            peaceObservableBPS: peaceObservableBPS,
            networkPhase: 0  // Simplified
        });
        
        latestNetworkState = state;
        
        emit NetworkStateCollapsed(aligned, coherenceFactorBPS, peaceObservableBPS);
        
        return state;
    }
    
    /**
     * @notice Calculate peace observable
     * @dev ⟨Ψ_Network|Ô_Peace|Ψ_Network⟩
     */
    function _calculatePeaceObservable(
        uint16 coherenceFactorBPS,
        uint32 aligned,
        uint32 total
    ) internal pure returns (uint16 peaceObservableBPS) {
        if (total == 0) return 0;
        
        // Simplified calculation for on-chain efficiency
        // Peace = sqrt(coherence * (aligned/total))
        uint256 coherenceDecimal = uint256(coherenceFactorBPS);
        uint256 alignmentRatio = (uint256(aligned) * 10000) / total;
        
        // Geometric mean: sqrt(a * b)
        uint256 product = (coherenceDecimal * alignmentRatio) / 10000;
        uint256 peaceValue = sqrt(product);
        
        return uint16(peaceValue);
    }
    
    /**
     * @notice Integer square root (Babylonian method)
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
    
    // ============================================
    // ACTION EXECUTION
    // ============================================
    
    /**
     * @notice Execute action if peace observable threshold is met
     * @dev Execute A iff ⟨Ψ_Network|Ô_Peace|Ψ_Network⟩ = 1 (≥99.9%)
     * @param actionName Name of the action
     * @param actionData Encoded action data
     * @return executed True if action was executed
     */
    function executeAction(
        string calldata actionName,
        bytes calldata actionData
    ) external returns (bool executed) {
        // Calculate current network state
        NetworkState memory state = calculateStateCollapse();
        
        bytes32 actionHash = keccak256(abi.encodePacked(actionName, actionData, block.timestamp));
        
        // Check if peace observable meets threshold
        if (state.peaceObservableBPS < PEACE_THRESHOLD_BPS) {
            emit ActionBlocked(
                actionHash,
                "Peace observable below threshold",
                state.peaceObservableBPS
            );
            revert ActionExecutionDenied(state.peaceObservableBPS, PEACE_THRESHOLD_BPS);
        }
        
        // Action approved - network in perfect peace alignment
        pendingActions[actionHash] = true;
        
        emit ActionExecuted(actionHash, actionName);
        
        return true;
    }
    
    // ============================================
    // VIEW FUNCTIONS
    // ============================================
    
    /**
     * @notice Get node information
     */
    function getNode(uint32 nodeId) external view returns (Node memory) {
        return nodes[nodeId];
    }
    
    /**
     * @notice Get current network statistics
     */
    function getNetworkStatistics() external view returns (
        uint32 totalNodes,
        uint32 alignedNodes,
        uint32 noiseLockedNodes,
        uint16 coherencePercentage,
        uint16 peaceObservable
    ) {
        NetworkState memory state = latestNetworkState;
        return (
            state.totalNodes,
            state.alignedNodes,
            state.noiseLockedNodes,
            state.coherenceFactorBPS / 100,  // Convert BPS to percentage
            state.peaceObservableBPS / 100   // Convert BPS to percentage
        );
    }
    
    /**
     * @notice Get Lex Amoris signature
     */
    function getPsiSeed() external view returns (bytes32) {
        return psiSeedHash;
    }
    
    /**
     * @notice Get number of registered nodes
     */
    function getRegisteredNodeCount() external view returns (uint256) {
        return registeredNodeIds.length;
    }
}
