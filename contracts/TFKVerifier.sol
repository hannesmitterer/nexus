// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TFKVerifier - Trust-Finalizable-Key Verifier for Phase II
 * @notice Manages model retraining proposals with IPFS CID verification
 * @dev Part of Euystacio Framework Phase II - Operative Harmony
 */
contract TFKVerifier {
    // ============ State Variables ============
    
    struct ModelProposal {
        bytes32 ipfsCID;           // IPFS Content Identifier (hash)
        address proposer;          // Address that submitted the proposal
        uint256 timestamp;         // When proposal was created
        uint256 votesFor;          // Number of votes in favor
        uint256 votesAgainst;      // Number of votes against
        bool executed;             // Whether proposal has been executed
        bool passed;               // Whether proposal achieved consensus
        string description;        // Human-readable description
        mapping(address => bool) hasVoted;  // Track who has voted
    }
    
    struct ModelVersion {
        bytes32 ipfsCID;
        uint256 timestamp;
        uint256 proposalId;
        bool isActive;
    }
    
    // Current active model version
    bytes32 public currentModelCID;
    uint256 public currentModelVersion;
    
    // Proposal management
    uint256 public proposalCount;
    mapping(uint256 => ModelProposal) public proposals;
    
    // Model version history
    mapping(uint256 => ModelVersion) public modelVersions;
    
    // Authorized EFA (Euystacio Field Agent) DIDs
    mapping(address => bool) public authorizedEFAs;
    uint256 public efaCount;
    
    // Governance parameters
    uint256 public votingPeriod = 48 hours;
    uint256 public consensusThreshold = 67; // 67% required for passage
    uint256 public quorumPercentage = 50; // 50% quorum required
    address public ggcMultisig;
    
    // Automated retraining triggers
    uint256 public treThreshold = 20; // TRE < 0.20% triggers auto-proposal
    bool public autoRetrainEnabled = true;
    
    // ============ Events ============
    
    event ModelProposalCreated(
        uint256 indexed proposalId,
        bytes32 indexed ipfsCID,
        address indexed proposer,
        string description
    );
    
    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 votesFor,
        uint256 votesAgainst
    );
    
    event ProposalExecuted(
        uint256 indexed proposalId,
        bytes32 indexed ipfsCID,
        bool passed,
        uint256 newVersion
    );
    
    event ModelVersionActivated(
        uint256 indexed version,
        bytes32 indexed ipfsCID,
        uint256 timestamp
    );
    
    event CIDAnchoredOnChain(
        bytes32 indexed ipfsCID,
        string artifactType,
        address indexed anchor,
        uint256 timestamp
    );
    
    event EFAAuthorized(address indexed efa, bool authorized);
    
    event AutoRetrainTriggered(
        uint256 indexed proposalId,
        uint256 treValue,
        string reason
    );
    
    event QuorumPercentageUpdated(uint256 oldQuorum, uint256 newQuorum);
    event AutoRetrainEnabledUpdated(bool enabled);
    
    // ============ Modifiers ============
    
    modifier onlyGGC() {
        require(msg.sender == ggcMultisig, "Only GGC multisig");
        _;
    }
    
    modifier onlyAuthorizedEFA() {
        require(authorizedEFAs[msg.sender], "Only authorized EFA");
        _;
    }
    
    modifier proposalExists(uint256 proposalId) {
        require(proposalId < proposalCount, "Proposal does not exist");
        _;
    }
    
    modifier votingActive(uint256 proposalId) {
        ModelProposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Proposal already executed");
        require(
            block.timestamp < proposal.timestamp + votingPeriod,
            "Voting period ended"
        );
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _ggcMultisig, bytes32 _initialModelCID) {
        require(_ggcMultisig != address(0), "Invalid GGC address");
        ggcMultisig = _ggcMultisig;
        currentModelCID = _initialModelCID;
        currentModelVersion = 0;
        
        // Initialize first model version
        modelVersions[0] = ModelVersion({
            ipfsCID: _initialModelCID,
            timestamp: block.timestamp,
            proposalId: 0,
            isActive: true
        });
        
        emit ModelVersionActivated(0, _initialModelCID, block.timestamp);
    }
    
    // ============ Core Functions ============
    
    /**
     * @notice Propose a new model retraining with IPFS CID
     * @param ipfsCID The IPFS content identifier for the new model
     * @param description Human-readable description of the update
     * @return proposalId The ID of the created proposal
     */
    function propose_model_retrain(
        bytes32 ipfsCID,
        string calldata description
    ) external onlyAuthorizedEFA returns (uint256) {
        require(ipfsCID != bytes32(0), "Invalid CID");
        require(ipfsCID != currentModelCID, "CID already active");
        
        uint256 proposalId = proposalCount++;
        ModelProposal storage proposal = proposals[proposalId];
        
        proposal.ipfsCID = ipfsCID;
        proposal.proposer = msg.sender;
        proposal.timestamp = block.timestamp;
        proposal.description = description;
        proposal.executed = false;
        proposal.passed = false;
        
        emit ModelProposalCreated(proposalId, ipfsCID, msg.sender, description);
        emit CIDAnchoredOnChain(ipfsCID, "MODEL_PROPOSAL", msg.sender, block.timestamp);
        
        return proposalId;
    }
    
    /**
     * @notice Vote on a model retraining proposal
     * @param proposalId The proposal to vote on
     * @param support True to vote in favor, false to vote against
     */
    function vote(
        uint256 proposalId,
        bool support
    ) external onlyAuthorizedEFA proposalExists(proposalId) votingActive(proposalId) {
        ModelProposal storage proposal = proposals[proposalId];
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        proposal.hasVoted[msg.sender] = true;
        
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        
        emit VoteCast(proposalId, msg.sender, support, proposal.votesFor, proposal.votesAgainst);
    }
    
    /**
     * @notice Execute a proposal after voting period ends
     * @param proposalId The proposal to execute
     */
    function executeProposal(
        uint256 proposalId
    ) external proposalExists(proposalId) {
        ModelProposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "Already executed");
        require(
            block.timestamp >= proposal.timestamp + votingPeriod,
            "Voting period not ended"
        );
        
        proposal.executed = true;
        
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (efaCount * quorumPercentage) / 100;
        
        require(totalVotes >= quorum, "Quorum not reached");
        
        // Check if consensus threshold met (67%)
        uint256 approvalPercentage = (proposal.votesFor * 100) / totalVotes;
        
        if (approvalPercentage >= consensusThreshold) {
            proposal.passed = true;
            
            // Deactivate old version
            modelVersions[currentModelVersion].isActive = false;
            
            // Activate new version
            currentModelVersion++;
            currentModelCID = proposal.ipfsCID;
            
            modelVersions[currentModelVersion] = ModelVersion({
                ipfsCID: proposal.ipfsCID,
                timestamp: block.timestamp,
                proposalId: proposalId,
                isActive: true
            });
            
            emit ModelVersionActivated(currentModelVersion, proposal.ipfsCID, block.timestamp);
        }
        
        emit ProposalExecuted(proposalId, proposal.ipfsCID, proposal.passed, currentModelVersion);
    }
    
    /**
     * @notice Automated retraining trigger based on TRE metric
     * @param treValue Current TRE value (in basis points, e.g., 20 = 0.20%)
     * @param newModelCID IPFS CID of the retrained model
     * @param description Reason for automated retraining
     */
    function triggerAutoRetrain(
        uint256 treValue,
        bytes32 newModelCID,
        string calldata description
    ) external onlyAuthorizedEFA returns (uint256) {
        require(autoRetrainEnabled, "Auto-retrain disabled");
        require(treValue < treThreshold, "TRE above threshold");
        require(newModelCID != bytes32(0), "Invalid CID");
        
        uint256 proposalId = propose_model_retrain(newModelCID, description);
        
        emit AutoRetrainTriggered(proposalId, treValue, description);
        
        return proposalId;
    }
    
    /**
     * @notice Anchor arbitrary CID on-chain for immutability
     * @param ipfsCID The IPFS content identifier
     * @param artifactType Type of artifact (e.g., "SEP_BUNDLE", "AUDIT_REPORT")
     */
    function anchorCID(
        bytes32 ipfsCID,
        string calldata artifactType
    ) external onlyAuthorizedEFA {
        require(ipfsCID != bytes32(0), "Invalid CID");
        
        emit CIDAnchoredOnChain(ipfsCID, artifactType, msg.sender, block.timestamp);
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Get proposal details
     * @param proposalId The proposal ID
     * @return ipfsCID, proposer, timestamp, votesFor, votesAgainst, executed, passed
     */
    function getProposal(uint256 proposalId)
        external
        view
        proposalExists(proposalId)
        returns (
            bytes32 ipfsCID,
            address proposer,
            uint256 timestamp,
            uint256 votesFor,
            uint256 votesAgainst,
            bool executed,
            bool passed,
            string memory description
        )
    {
        ModelProposal storage proposal = proposals[proposalId];
        return (
            proposal.ipfsCID,
            proposal.proposer,
            proposal.timestamp,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed,
            proposal.passed,
            proposal.description
        );
    }
    
    /**
     * @notice Check if address has voted on proposal
     * @param proposalId The proposal ID
     * @param voter The voter address
     * @return hasVoted True if already voted
     */
    function hasVoted(uint256 proposalId, address voter)
        external
        view
        proposalExists(proposalId)
        returns (bool)
    {
        return proposals[proposalId].hasVoted[voter];
    }
    
    /**
     * @notice Get current model version details
     * @return version, ipfsCID, timestamp
     */
    function getCurrentModel()
        external
        view
        returns (uint256 version, bytes32 ipfsCID, uint256 timestamp)
    {
        ModelVersion storage current = modelVersions[currentModelVersion];
        return (currentModelVersion, current.ipfsCID, current.timestamp);
    }
    
    /**
     * @notice Get model version history
     * @param version The version number
     * @return ipfsCID, timestamp, proposalId, isActive
     */
    function getModelVersion(uint256 version)
        external
        view
        returns (bytes32 ipfsCID, uint256 timestamp, uint256 proposalId, bool isActive)
    {
        ModelVersion storage mv = modelVersions[version];
        return (mv.ipfsCID, mv.timestamp, mv.proposalId, mv.isActive);
    }
    
    // ============ Governance Functions ============
    
    /**
     * @notice Authorize an EFA DID for voting
     * @param efa The EFA address to authorize
     */
    function authorizeEFA(address efa) external onlyGGC {
        require(efa != address(0), "Invalid address");
        require(!authorizedEFAs[efa], "Already authorized");
        
        authorizedEFAs[efa] = true;
        efaCount++;
        
        emit EFAAuthorized(efa, true);
    }
    
    /**
     * @notice Revoke EFA authorization
     * @param efa The EFA address to revoke
     */
    function revokeEFA(address efa) external onlyGGC {
        require(authorizedEFAs[efa], "Not authorized");
        
        authorizedEFAs[efa] = false;
        efaCount--;
        
        emit EFAAuthorized(efa, false);
    }
    
    /**
     * @notice Update voting period
     * @param newPeriod New voting period in seconds
     */
    function setVotingPeriod(uint256 newPeriod) external onlyGGC {
        require(newPeriod >= 24 hours && newPeriod <= 7 days, "Invalid period");
        votingPeriod = newPeriod;
    }
    
    /**
     * @notice Update consensus threshold
     * @param newThreshold New threshold percentage (e.g., 67 for 67%)
     */
    function setConsensusThreshold(uint256 newThreshold) external onlyGGC {
        require(newThreshold >= 51 && newThreshold <= 100, "Invalid threshold");
        consensusThreshold = newThreshold;
    }
    
    /**
     * @notice Update TRE threshold for auto-retraining
     * @param newThreshold New TRE threshold in basis points
     */
    function setTREThreshold(uint256 newThreshold) external onlyGGC {
        require(newThreshold > 0 && newThreshold <= 100, "Invalid threshold");
        treThreshold = newThreshold;
    }
    
    /**
     * @notice Enable/disable auto-retraining
     * @param enabled True to enable, false to disable
     */
    function setAutoRetrainEnabled(bool enabled) external onlyGGC {
        autoRetrainEnabled = enabled;
        emit AutoRetrainEnabledUpdated(enabled);
    }
    
    /**
     * @notice Update quorum percentage
     * @param newQuorum New quorum percentage (e.g., 50 for 50%)
     */
    function setQuorumPercentage(uint256 newQuorum) external onlyGGC {
        require(newQuorum >= 25 && newQuorum <= 100, "Invalid quorum");
        uint256 oldQuorum = quorumPercentage;
        quorumPercentage = newQuorum;
        emit QuorumPercentageUpdated(oldQuorum, newQuorum);
    }
    
    /**
     * @notice Update GGC multisig address
     * @param newGGC New GGC multisig address
     */
    function updateGGCMultisig(address newGGC) external onlyGGC {
        require(newGGC != address(0), "Invalid address");
        ggcMultisig = newGGC;
    }
}
