// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IVBS_RedCodeVeto - Red Code Veto Mechanism for Critical Decision Governance
 * @notice Implements veto-based consensus for system-critical operations
 * @dev Part of Internodal Vacuum Backup System (IVBS) - Phase II Enhancement
 */
contract IVBS_RedCodeVeto {
    // ============ State Variables ============
    
    struct RedCodeAuthority {
        address authorityAddress;
        string name;
        string jurisdiction;
        uint256 appointmentDate;
        uint256 termEndDate;
        bool isActive;
    }
    
    struct VetoRecord {
        uint256 proposalId;
        address rcaAddress;
        string reason;
        bytes signature;
        uint256 timestamp;
        bool isActive;
    }
    
    // Red Code Authorities registry
    mapping(address => RedCodeAuthority) public redCodeAuthorities;
    address[] public rcaAddresses;
    uint256 public activeRCACount;
    
    // Veto records by proposal
    mapping(uint256 => VetoRecord[]) public proposalVetoes;
    mapping(uint256 => bool) public proposalVetoed;
    
    // Governance
    address public ggcMultisig;
    uint256 public constant MIN_RCA_COUNT = 5;
    uint256 public constant RCA_TERM_DURATION = 365 days;
    
    // ============ Events ============
    
    event RCAAppointed(
        address indexed rcaAddress,
        string name,
        string jurisdiction,
        uint256 termEndDate
    );
    
    event RCARemoved(
        address indexed rcaAddress,
        string reason
    );
    
    event RedCodeVetoSubmitted(
        uint256 indexed proposalId,
        address indexed rcaAddress,
        string reason,
        uint256 timestamp
    );
    
    event VetoAuditTriggered(
        uint256 indexed proposalId,
        uint256 vetoCount
    );
    
    event ProposalBlocked(
        uint256 indexed proposalId,
        string reason
    );
    
    // ============ Modifiers ============
    
    modifier onlyGGC() {
        require(msg.sender == ggcMultisig, "Only GGC multisig can execute");
        _;
    }
    
    modifier onlyActiveRCA() {
        require(
            redCodeAuthorities[msg.sender].isActive,
            "Caller is not an active Red Code Authority"
        );
        require(
            block.timestamp < redCodeAuthorities[msg.sender].termEndDate,
            "RCA term has expired"
        );
        _;
    }
    
    modifier proposalNotVetoed(uint256 proposalId) {
        require(!proposalVetoed[proposalId], "Proposal has been vetoed");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _ggcMultisig) {
        require(_ggcMultisig != address(0), "Invalid GGC address");
        ggcMultisig = _ggcMultisig;
    }
    
    // ============ RCA Management Functions ============
    
    /**
     * @notice Appoint a new Red Code Authority
     * @param rcaAddress Address of the RCA
     * @param name Name of the RCA
     * @param jurisdiction Geographic/organizational jurisdiction
     */
    function appointRCA(
        address rcaAddress,
        string calldata name,
        string calldata jurisdiction
    ) external onlyGGC {
        require(rcaAddress != address(0), "Invalid RCA address");
        require(!redCodeAuthorities[rcaAddress].isActive, "RCA already active");
        
        uint256 termEndDate = block.timestamp + RCA_TERM_DURATION;
        
        redCodeAuthorities[rcaAddress] = RedCodeAuthority({
            authorityAddress: rcaAddress,
            name: name,
            jurisdiction: jurisdiction,
            appointmentDate: block.timestamp,
            termEndDate: termEndDate,
            isActive: true
        });
        
        rcaAddresses.push(rcaAddress);
        activeRCACount++;
        
        emit RCAAppointed(rcaAddress, name, jurisdiction, termEndDate);
    }
    
    /**
     * @notice Remove a Red Code Authority
     * @param rcaAddress Address of the RCA to remove
     * @param reason Reason for removal
     */
    function removeRCA(address rcaAddress, string calldata reason) 
        external 
        onlyGGC 
    {
        require(redCodeAuthorities[rcaAddress].isActive, "RCA not active");
        require(
            activeRCACount > MIN_RCA_COUNT,
            "Cannot remove: minimum RCA count required"
        );
        
        redCodeAuthorities[rcaAddress].isActive = false;
        activeRCACount--;
        
        emit RCARemoved(rcaAddress, reason);
    }
    
    /**
     * @notice Renew RCA term
     * @param rcaAddress Address of the RCA
     */
    function renewRCATerm(address rcaAddress) external onlyGGC {
        require(redCodeAuthorities[rcaAddress].isActive, "RCA not active");
        
        redCodeAuthorities[rcaAddress].termEndDate = 
            block.timestamp + RCA_TERM_DURATION;
    }
    
    // ============ Veto Functions ============
    
    /**
     * @notice Submit a Red Code Veto for a proposal
     * @param proposalId ID of the proposal to veto
     * @param reason Detailed reason for the veto
     * @param signature RCA's cryptographic signature
     */
    function submitRedCodeVeto(
        uint256 proposalId,
        string calldata reason,
        bytes calldata signature
    ) external onlyActiveRCA {
        require(!proposalVetoed[proposalId], "Proposal already vetoed");
        require(bytes(reason).length > 0, "Veto reason required");
        
        // Verify signature corresponds to the RCA
        bytes32 messageHash = keccak256(
            abi.encodePacked(proposalId, reason, msg.sender)
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        require(
            recoverSigner(ethSignedMessageHash, signature) == msg.sender,
            "Invalid signature"
        );
        
        // Record the veto
        VetoRecord memory veto = VetoRecord({
            proposalId: proposalId,
            rcaAddress: msg.sender,
            reason: reason,
            signature: signature,
            timestamp: block.timestamp,
            isActive: true
        });
        
        proposalVetoes[proposalId].push(veto);
        proposalVetoed[proposalId] = true;
        
        emit RedCodeVetoSubmitted(proposalId, msg.sender, reason, block.timestamp);
        emit VetoAuditTriggered(proposalId, proposalVetoes[proposalId].length);
        emit ProposalBlocked(proposalId, reason);
    }
    
    /**
     * @notice Check if a proposal has been vetoed
     * @param proposalId ID of the proposal
     * @return bool True if vetoed
     */
    function isProposalVetoed(uint256 proposalId) external view returns (bool) {
        return proposalVetoed[proposalId];
    }
    
    /**
     * @notice Get all vetoes for a proposal
     * @param proposalId ID of the proposal
     * @return Array of veto records
     */
    function getProposalVetoes(uint256 proposalId) 
        external 
        view 
        returns (VetoRecord[] memory) 
    {
        return proposalVetoes[proposalId];
    }
    
    /**
     * @notice Get count of active RCAs
     * @return uint256 Number of active RCAs
     */
    function getActiveRCACount() external view returns (uint256) {
        return activeRCACount;
    }
    
    /**
     * @notice Get all RCA addresses
     * @return Array of RCA addresses
     */
    function getAllRCAs() external view returns (address[] memory) {
        return rcaAddresses;
    }
    
    /**
     * @notice Check if address is an active RCA
     * @param rcaAddress Address to check
     * @return bool True if active RCA
     */
    function isActiveRCA(address rcaAddress) external view returns (bool) {
        return redCodeAuthorities[rcaAddress].isActive && 
               block.timestamp < redCodeAuthorities[rcaAddress].termEndDate;
    }
    
    // ============ Emergency Functions ============
    
    /**
     * @notice Emergency RCA rotation (GGC only)
     * @param oldRCA Address of RCA to replace
     * @param newRCA Address of new RCA
     * @param name Name of new RCA
     * @param jurisdiction Jurisdiction of new RCA
     */
    function emergencyRCARotation(
        address oldRCA,
        address newRCA,
        string calldata name,
        string calldata jurisdiction
    ) external onlyGGC {
        require(redCodeAuthorities[oldRCA].isActive, "Old RCA not active");
        require(!redCodeAuthorities[newRCA].isActive, "New RCA already active");
        
        // Deactivate old RCA
        redCodeAuthorities[oldRCA].isActive = false;
        
        // Activate new RCA
        uint256 termEndDate = block.timestamp + RCA_TERM_DURATION;
        redCodeAuthorities[newRCA] = RedCodeAuthority({
            authorityAddress: newRCA,
            name: name,
            jurisdiction: jurisdiction,
            appointmentDate: block.timestamp,
            termEndDate: termEndDate,
            isActive: true
        });
        
        rcaAddresses.push(newRCA);
        
        emit RCARemoved(oldRCA, "Emergency rotation");
        emit RCAAppointed(newRCA, name, jurisdiction, termEndDate);
    }
    
    // ============ Helper Functions ============
    
    function getEthSignedMessageHash(bytes32 messageHash)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
    }
    
    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        require(signature.length == 65, "Invalid signature length");
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        return ecrecover(ethSignedMessageHash, v, r, s);
    }
}
