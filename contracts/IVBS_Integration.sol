// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IVBS_RedCodeVeto.sol";
import "./IVBS_TripleSignValidation.sol";
import "./IVBS_VacuumAnchor.sol";

/**
 * @title IVBS_Integration - Integration Layer for IVBS with TFKVerifier
 * @notice Extends TFKVerifier functionality with IVBS governance and backup capabilities
 * @dev Part of Internodal Vacuum Backup System (IVBS) - Phase II Enhancement
 */
contract IVBS_Integration {
    // ============ State Variables ============
    
    // Core IVBS contracts
    IVBS_RedCodeVeto public redCodeVeto;
    IVBS_TripleSignValidation public tripleSignValidation;
    IVBS_VacuumAnchor public vacuumAnchor;
    
    // TFKVerifier reference (existing contract)
    address public tfkVerifier;
    
    // Governance
    address public ggcMultisig;
    
    // Proposal to IVBS mapping
    mapping(uint256 => uint256) public proposalToTripleSignRequest;
    mapping(uint256 => uint256) public proposalToVacuumAnchor;
    mapping(uint256 => bool) public proposalRequiresRedCodeApproval;
    
    // ============ Events ============
    
    event IVBSProposalCreated(
        uint256 indexed tfkProposalId,
        uint256 indexed tripleSignRequestId,
        bool requiresRedCodeApproval
    );
    
    event VacuumAnchorCreatedForProposal(
        uint256 indexed tfkProposalId,
        uint256 indexed anchorId,
        bytes32 ipfsCID
    );
    
    event ProposalApprovedWithIVBS(
        uint256 indexed tfkProposalId,
        uint256 tripleSignRequestId,
        uint256 vacuumAnchorId
    );
    
    event RedCodeVetoDetected(
        uint256 indexed tfkProposalId,
        address indexed rcaAddress,
        string reason
    );
    
    // ============ Modifiers ============
    
    modifier onlyGGC() {
        require(msg.sender == ggcMultisig, "Only GGC multisig can execute");
        _;
    }
    
    modifier onlyTFKVerifier() {
        require(msg.sender == tfkVerifier, "Only TFKVerifier can execute");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(
        address _redCodeVeto,
        address _tripleSignValidation,
        address _vacuumAnchor,
        address _tfkVerifier,
        address _ggcMultisig
    ) {
        require(_redCodeVeto != address(0), "Invalid RedCodeVeto address");
        require(_tripleSignValidation != address(0), "Invalid TripleSign address");
        require(_vacuumAnchor != address(0), "Invalid VacuumAnchor address");
        require(_tfkVerifier != address(0), "Invalid TFKVerifier address");
        require(_ggcMultisig != address(0), "Invalid GGC address");
        
        redCodeVeto = IVBS_RedCodeVeto(_redCodeVeto);
        tripleSignValidation = IVBS_TripleSignValidation(_tripleSignValidation);
        vacuumAnchor = IVBS_VacuumAnchor(_vacuumAnchor);
        tfkVerifier = _tfkVerifier;
        ggcMultisig = _ggcMultisig;
    }
    
    // ============ Proposal Creation with IVBS ============
    
    /**
     * @notice Create a TFKVerifier proposal with IVBS integration
     * @param tfkProposalId ID of the TFKVerifier proposal
     * @param ipfsCID IPFS CID of the model/data
     * @param requiresRedCodeApproval Whether this proposal needs Red Code approval
     * @return tripleSignRequestId The created Triple-Sign request ID
     */
    function createIVBSProposal(
        uint256 tfkProposalId,
        bytes32 ipfsCID,
        bool requiresRedCodeApproval
    ) external returns (uint256) {
        require(
            proposalToTripleSignRequest[tfkProposalId] == 0,
            "IVBS proposal already exists"
        );
        
        // Create Triple-Sign validation request
        bytes32 dataHash = keccak256(abi.encodePacked(ipfsCID, tfkProposalId));
        uint256 tripleSignRequestId = tripleSignValidation.createTripleSignRequest(
            dataHash,
            "TFK_PROPOSAL"
        );
        
        // Store mapping
        proposalToTripleSignRequest[tfkProposalId] = tripleSignRequestId;
        proposalRequiresRedCodeApproval[tfkProposalId] = requiresRedCodeApproval;
        
        emit IVBSProposalCreated(tfkProposalId, tripleSignRequestId, requiresRedCodeApproval);
        
        return tripleSignRequestId;
    }
    
    // ============ Validation Submission ============
    
    /**
     * @notice Submit technical validation for a proposal
     * @param tfkProposalId TFKVerifier proposal ID
     * @param approved Whether validation passed
     * @param reason Reason for approval/rejection
     * @param signature Technical validator signature
     */
    function submitTechnicalValidation(
        uint256 tfkProposalId,
        bool approved,
        string calldata reason,
        bytes calldata signature
    ) external {
        uint256 tripleSignRequestId = proposalToTripleSignRequest[tfkProposalId];
        require(tripleSignRequestId != 0, "IVBS proposal does not exist");
        
        tripleSignValidation.submitTechnicalValidation(
            tripleSignRequestId,
            approved,
            reason,
            signature
        );
    }
    
    /**
     * @notice Submit governance validation for a proposal
     * @param tfkProposalId TFKVerifier proposal ID
     * @param approved Whether validation passed
     * @param signatures Array of governance signatures
     * @param reason Reason for approval/rejection
     */
    function submitGovernanceValidation(
        uint256 tfkProposalId,
        bool approved,
        bytes[] calldata signatures,
        string calldata reason
    ) external onlyGGC {
        uint256 tripleSignRequestId = proposalToTripleSignRequest[tfkProposalId];
        require(tripleSignRequestId != 0, "IVBS proposal does not exist");
        
        tripleSignValidation.submitGovernanceValidation(
            tripleSignRequestId,
            approved,
            signatures,
            reason
        );
    }
    
    /**
     * @notice Submit ethical validation for a proposal
     * @param tfkProposalId TFKVerifier proposal ID
     * @param approved Whether validation passed
     * @param signatures Array of RCA signatures
     * @param reason Reason for approval/rejection
     */
    function submitEthicalValidation(
        uint256 tfkProposalId,
        bool approved,
        bytes[] calldata signatures,
        string calldata reason
    ) external {
        uint256 tripleSignRequestId = proposalToTripleSignRequest[tfkProposalId];
        require(tripleSignRequestId != 0, "IVBS proposal does not exist");
        
        // Verify caller is RCA if required
        if (proposalRequiresRedCodeApproval[tfkProposalId]) {
            require(
                redCodeVeto.isActiveRCA(msg.sender) || msg.sender == ggcMultisig,
                "Only RCA or GGC can submit ethical validation"
            );
        }
        
        tripleSignValidation.submitEthicalValidation(
            tripleSignRequestId,
            approved,
            signatures,
            reason
        );
    }
    
    // ============ Red Code Veto Integration ============
    
    /**
     * @notice Submit Red Code Veto for a proposal
     * @param tfkProposalId TFKVerifier proposal ID
     * @param reason Reason for veto
     * @param signature RCA signature
     */
    function submitRedCodeVetoForProposal(
        uint256 tfkProposalId,
        string calldata reason,
        bytes calldata signature
    ) external {
        require(
            proposalRequiresRedCodeApproval[tfkProposalId],
            "Proposal does not require Red Code approval"
        );
        
        // Submit veto to Red Code contract
        redCodeVeto.submitRedCodeVeto(tfkProposalId, reason, signature);
        
        emit RedCodeVetoDetected(tfkProposalId, msg.sender, reason);
    }
    
    /**
     * @notice Check if proposal has been vetoed
     * @param tfkProposalId TFKVerifier proposal ID
     * @return bool True if vetoed
     */
    function isProposalVetoed(uint256 tfkProposalId) external view returns (bool) {
        if (!proposalRequiresRedCodeApproval[tfkProposalId]) {
            return false;
        }
        return redCodeVeto.isProposalVetoed(tfkProposalId);
    }
    
    // ============ Vacuum Anchor Integration ============
    
    /**
     * @notice Create Vacuum Anchor after Triple-Sign approval
     * @param tfkProposalId TFKVerifier proposal ID
     * @param ipfsCID IPFS CID to anchor
     * @param description Anchor description
     * @param contentHash SHA-256 hash of content
     * @param sizeBytes Size of content
     * @return anchorId The created anchor ID
     */
    function createVacuumAnchorForProposal(
        uint256 tfkProposalId,
        bytes32 ipfsCID,
        string calldata description,
        bytes32 contentHash,
        uint256 sizeBytes
    ) external returns (uint256) {
        uint256 tripleSignRequestId = proposalToTripleSignRequest[tfkProposalId];
        require(tripleSignRequestId != 0, "IVBS proposal does not exist");
        
        // Verify Triple-Sign approval
        require(
            tripleSignValidation.verifyTripleSignApproval(tripleSignRequestId),
            "Triple-Sign approval required"
        );
        
        // Create Vacuum Anchor
        uint256 anchorId = vacuumAnchor.createVacuumAnchor(
            ipfsCID,
            IVBS_VacuumAnchor.AnchorType.MODEL,
            tripleSignRequestId,
            description,
            contentHash,
            sizeBytes
        );
        
        proposalToVacuumAnchor[tfkProposalId] = anchorId;
        
        emit VacuumAnchorCreatedForProposal(tfkProposalId, anchorId, ipfsCID);
        
        return anchorId;
    }
    
    // ============ Verification Functions ============
    
    /**
     * @notice Verify if proposal has complete IVBS approval
     * @param tfkProposalId TFKVerifier proposal ID
     * @return bool True if fully approved
     */
    function verifyProposalIVBSApproval(uint256 tfkProposalId) 
        external 
        view 
        returns (bool) 
    {
        uint256 tripleSignRequestId = proposalToTripleSignRequest[tfkProposalId];
        if (tripleSignRequestId == 0) {
            return false;
        }
        
        // Check for Red Code veto if required
        if (proposalRequiresRedCodeApproval[tfkProposalId]) {
            if (redCodeVeto.isProposalVetoed(tfkProposalId)) {
                return false;
            }
        }
        
        // Check Triple-Sign approval
        return tripleSignValidation.verifyTripleSignApproval(tripleSignRequestId);
    }
    
    /**
     * @notice Get IVBS details for a proposal
     * @param tfkProposalId TFKVerifier proposal ID
     */
    function getProposalIVBSDetails(uint256 tfkProposalId)
        external
        view
        returns (
            uint256 tripleSignRequestId,
            uint256 vacuumAnchorId,
            bool requiresRedCodeApproval,
            bool isVetoed,
            bool isApproved
        )
    {
        tripleSignRequestId = proposalToTripleSignRequest[tfkProposalId];
        vacuumAnchorId = proposalToVacuumAnchor[tfkProposalId];
        requiresRedCodeApproval = proposalRequiresRedCodeApproval[tfkProposalId];
        
        if (requiresRedCodeApproval) {
            isVetoed = redCodeVeto.isProposalVetoed(tfkProposalId);
        }
        
        if (tripleSignRequestId != 0) {
            isApproved = tripleSignValidation.verifyTripleSignApproval(tripleSignRequestId);
        }
    }
    
    // ============ Administrative Functions ============
    
    /**
     * @notice Update TFKVerifier address
     * @param newTFKVerifier New TFKVerifier address
     */
    function updateTFKVerifier(address newTFKVerifier) external onlyGGC {
        require(newTFKVerifier != address(0), "Invalid address");
        tfkVerifier = newTFKVerifier;
    }
    
    /**
     * @notice Update GGC multisig address
     * @param newGGC New GGC address
     */
    function updateGGCMultisig(address newGGC) external onlyGGC {
        require(newGGC != address(0), "Invalid address");
        ggcMultisig = newGGC;
    }
}
