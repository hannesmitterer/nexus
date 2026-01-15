// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title BlacklistManager - Permanent Blacklist for EUYSTACIO Framework
 * @notice Manages permanent blacklist for blocking suspicious nodes and entities
 * @dev Implements three-tier blacklist system (Addresses, CIDs, DIDs) with MISP integration
 */

contract BlacklistManager {
    // ============ State Variables ============
    
    struct BlacklistEntry {
        uint256 timestamp;          // When entity was blacklisted
        string reason;              // Reason for blacklisting
        bytes32 evidenceHash;       // Hash of evidence (SEP or MISP indicator)
        bool isPermanent;           // Whether this is a permanent ban
        address reporter;           // Who reported this entity
    }
    
    struct MISPTrigger {
        string indicatorType;       // Type of threat indicator
        uint256 severityLevel;      // 1-5 severity scale
        bytes32 threatHash;         // Hash of threat intelligence data
        uint256 timestamp;          // When trigger was activated
    }
    
    // Three main blacklist components as per requirements
    // Component 1: Blacklisted node addresses (SAN nodes, malicious addresses)
    mapping(address => BlacklistEntry) public blacklistedAddresses;
    
    // Component 2: Blacklisted IPFS CIDs (malicious model versions, data)
    mapping(bytes32 => BlacklistEntry) public blacklistedCIDs;
    
    // Component 3: Blacklisted DIDs (Decentralized Identifiers for EFAs)
    mapping(bytes32 => BlacklistEntry) public blacklistedDIDs;
    
    // MISP (Malware Information Sharing Platform) policy triggers
    mapping(bytes32 => MISPTrigger) public mispTriggers;
    mapping(bytes32 => bool) public activeMISPIndicators;
    
    // Counters
    uint256 public totalBlacklistedAddresses;
    uint256 public totalBlacklistedCIDs;
    uint256 public totalBlacklistedDIDs;
    uint256 public totalMISPTriggers;
    
    // Governance
    address public ggcMultisig;
    mapping(address => bool) public authorizedReporters; // EFAs and monitors
    
    // ============ Events ============
    
    event AddressBlacklisted(
        address indexed entity,
        string reason,
        bytes32 evidenceHash,
        bool permanent,
        address indexed reporter,
        uint256 timestamp
    );
    
    event CIDBlacklisted(
        bytes32 indexed cid,
        string reason,
        bytes32 evidenceHash,
        bool permanent,
        address indexed reporter,
        uint256 timestamp
    );
    
    event DIDBlacklisted(
        bytes32 indexed did,
        string reason,
        bytes32 evidenceHash,
        bool permanent,
        address indexed reporter,
        uint256 timestamp
    );
    
    event MISPTriggerActivated(
        bytes32 indexed triggerKey,
        string indicatorType,
        uint256 severityLevel,
        bytes32 threatHash,
        uint256 timestamp
    );
    
    event BlacklistRemoved(
        bytes32 indexed entityHash,
        string entityType,
        address indexed remover,
        uint256 timestamp
    );
    
    event ReporterAuthorized(address indexed reporter, bool authorized);
    
    // ============ Modifiers ============
    
    modifier onlyGGC() {
        require(msg.sender == ggcMultisig, "Only GGC multisig");
        _;
    }
    
    modifier onlyAuthorizedReporter() {
        require(authorizedReporters[msg.sender], "Only authorized reporter");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _ggcMultisig) {
        require(_ggcMultisig != address(0), "Invalid GGC address");
        ggcMultisig = _ggcMultisig;
    }
    
    // ============ Blacklist Management Functions ============
    
    /**
     * @notice Add an address to permanent blacklist
     * @param entity Address to blacklist (SAN node, malicious actor)
     * @param reason Description of why entity is blacklisted
     * @param evidenceHash Hash of evidence (SEP ID or investigation report)
     * @param isPermanent Whether this is a permanent ban
     */
    function blacklistAddress(
        address entity,
        string calldata reason,
        bytes32 evidenceHash,
        bool isPermanent
    ) external onlyAuthorizedReporter {
        require(entity != address(0), "Invalid address");
        require(entity != ggcMultisig, "Cannot blacklist GGC");
        require(blacklistedAddresses[entity].timestamp == 0, "Already blacklisted");
        
        blacklistedAddresses[entity] = BlacklistEntry({
            timestamp: block.timestamp,
            reason: reason,
            evidenceHash: evidenceHash,
            isPermanent: isPermanent,
            reporter: msg.sender
        });
        
        totalBlacklistedAddresses++;
        
        emit AddressBlacklisted(
            entity,
            reason,
            evidenceHash,
            isPermanent,
            msg.sender,
            block.timestamp
        );
    }
    
    /**
     * @notice Add an IPFS CID to permanent blacklist
     * @param cid IPFS CID hash to blacklist (malicious model, data)
     * @param reason Description of why CID is blacklisted
     * @param evidenceHash Hash of evidence
     * @param isPermanent Whether this is a permanent ban
     */
    function blacklistCID(
        bytes32 cid,
        string calldata reason,
        bytes32 evidenceHash,
        bool isPermanent
    ) external onlyAuthorizedReporter {
        require(cid != bytes32(0), "Invalid CID");
        require(blacklistedCIDs[cid].timestamp == 0, "Already blacklisted");
        
        blacklistedCIDs[cid] = BlacklistEntry({
            timestamp: block.timestamp,
            reason: reason,
            evidenceHash: evidenceHash,
            isPermanent: isPermanent,
            reporter: msg.sender
        });
        
        totalBlacklistedCIDs++;
        
        emit CIDBlacklisted(
            cid,
            reason,
            evidenceHash,
            isPermanent,
            msg.sender,
            block.timestamp
        );
    }
    
    /**
     * @notice Add a DID to permanent blacklist
     * @param did Decentralized Identifier hash to blacklist
     * @param reason Description of why DID is blacklisted
     * @param evidenceHash Hash of evidence
     * @param isPermanent Whether this is a permanent ban
     */
    function blacklistDID(
        bytes32 did,
        string calldata reason,
        bytes32 evidenceHash,
        bool isPermanent
    ) external onlyAuthorizedReporter {
        require(did != bytes32(0), "Invalid DID");
        require(blacklistedDIDs[did].timestamp == 0, "Already blacklisted");
        
        blacklistedDIDs[did] = BlacklistEntry({
            timestamp: block.timestamp,
            reason: reason,
            evidenceHash: evidenceHash,
            isPermanent: isPermanent,
            reporter: msg.sender
        });
        
        totalBlacklistedDIDs++;
        
        emit DIDBlacklisted(
            did,
            reason,
            evidenceHash,
            isPermanent,
            msg.sender,
            block.timestamp
        );
    }
    
    /**
     * @notice Batch blacklist multiple addresses (for efficiency)
     * @param entities Array of addresses to blacklist
     * @param reason Common reason for all entities
     * @param evidenceHash Hash of evidence
     * @param isPermanent Whether these are permanent bans
     */
    function batchBlacklistAddresses(
        address[] calldata entities,
        string calldata reason,
        bytes32 evidenceHash,
        bool isPermanent
    ) external onlyGGC {
        for (uint256 i = 0; i < entities.length; i++) {
            address entity = entities[i];
            require(entity != address(0), "Invalid address");
            require(entity != ggcMultisig, "Cannot blacklist GGC");
            
            if (blacklistedAddresses[entity].timestamp == 0) {
                blacklistedAddresses[entity] = BlacklistEntry({
                    timestamp: block.timestamp,
                    reason: reason,
                    evidenceHash: evidenceHash,
                    isPermanent: isPermanent,
                    reporter: msg.sender
                });
                
                totalBlacklistedAddresses++;
                
                emit AddressBlacklisted(
                    entity,
                    reason,
                    evidenceHash,
                    isPermanent,
                    msg.sender,
                    block.timestamp
                );
            }
        }
    }
    
    // ============ MISP Integration Functions ============
    
    /**
     * @notice Activate MISP policy trigger for threat intelligence
     * @param indicatorType Type of threat (e.g., "MALICIOUS_NODE", "COMPROMISED_MODEL")
     * @param severityLevel Severity from 1 (low) to 5 (critical)
     * @param threatHash Hash of threat intelligence data
     * @param entityToBlacklist Optional address to immediately blacklist
     */
    function activateMISPTrigger(
        string calldata indicatorType,
        uint256 severityLevel,
        bytes32 threatHash,
        address entityToBlacklist
    ) external onlyAuthorizedReporter {
        require(severityLevel >= 1 && severityLevel <= 5, "Invalid severity");
        require(threatHash != bytes32(0), "Invalid threat hash");
        
        bytes32 triggerKey = keccak256(
            abi.encodePacked(indicatorType, threatHash, block.timestamp)
        );
        
        mispTriggers[triggerKey] = MISPTrigger({
            indicatorType: indicatorType,
            severityLevel: severityLevel,
            threatHash: threatHash,
            timestamp: block.timestamp
        });
        
        activeMISPIndicators[threatHash] = true;
        totalMISPTriggers++;
        
        emit MISPTriggerActivated(
            triggerKey,
            indicatorType,
            severityLevel,
            threatHash,
            block.timestamp
        );
        
        // Auto-blacklist if address provided and severity is high (4-5)
        if (entityToBlacklist != address(0) && severityLevel >= 4) {
            if (blacklistedAddresses[entityToBlacklist].timestamp == 0) {
                blacklistedAddresses[entityToBlacklist] = BlacklistEntry({
                    timestamp: block.timestamp,
                    reason: string(abi.encodePacked("MISP Trigger: ", indicatorType)),
                    evidenceHash: threatHash,
                    isPermanent: true,
                    reporter: msg.sender
                });
                
                totalBlacklistedAddresses++;
                
                emit AddressBlacklisted(
                    entityToBlacklist,
                    string(abi.encodePacked("MISP Trigger: ", indicatorType)),
                    threatHash,
                    true,
                    msg.sender,
                    block.timestamp
                );
            }
        }
    }
    
    // ============ Query Functions ============
    
    /**
     * @notice Check if an address is blacklisted
     * @param entity Address to check
     * @return isBlacklisted True if address is blacklisted
     * @return isPermanent True if blacklist is permanent
     */
    function isAddressBlacklisted(address entity) 
        external 
        view 
        returns (bool isBlacklisted, bool isPermanent) 
    {
        BlacklistEntry storage entry = blacklistedAddresses[entity];
        isBlacklisted = entry.timestamp != 0;
        isPermanent = entry.isPermanent;
    }
    
    /**
     * @notice Check if a CID is blacklisted
     * @param cid CID to check
     * @return isBlacklisted True if CID is blacklisted
     * @return isPermanent True if blacklist is permanent
     */
    function isCIDBlacklisted(bytes32 cid) 
        external 
        view 
        returns (bool isBlacklisted, bool isPermanent) 
    {
        BlacklistEntry storage entry = blacklistedCIDs[cid];
        isBlacklisted = entry.timestamp != 0;
        isPermanent = entry.isPermanent;
    }
    
    /**
     * @notice Check if a DID is blacklisted
     * @param did DID to check
     * @return isBlacklisted True if DID is blacklisted
     * @return isPermanent True if blacklist is permanent
     */
    function isDIDBlacklisted(bytes32 did) 
        external 
        view 
        returns (bool isBlacklisted, bool isPermanent) 
    {
        BlacklistEntry storage entry = blacklistedDIDs[did];
        isBlacklisted = entry.timestamp != 0;
        isPermanent = entry.isPermanent;
    }
    
    /**
     * @notice Check if any entity type is blacklisted (convenience function)
     * @param entityAddress Address to check
     * @param entityCID CID to check
     * @param entityDID DID to check
     * @return isBlacklisted True if any of the provided entities is blacklisted
     */
    function isAnyBlacklisted(
        address entityAddress,
        bytes32 entityCID,
        bytes32 entityDID
    ) external view returns (bool isBlacklisted) {
        if (entityAddress != address(0) && blacklistedAddresses[entityAddress].timestamp != 0) {
            return true;
        }
        if (entityCID != bytes32(0) && blacklistedCIDs[entityCID].timestamp != 0) {
            return true;
        }
        if (entityDID != bytes32(0) && blacklistedDIDs[entityDID].timestamp != 0) {
            return true;
        }
        return false;
    }
    
    /**
     * @notice Get blacklist entry details for an address
     * @param entity Address to query
     * @return entry Full blacklist entry
     */
    function getBlacklistEntry(address entity) 
        external 
        view 
        returns (BlacklistEntry memory entry) 
    {
        return blacklistedAddresses[entity];
    }
    
    /**
     * @notice Get MISP trigger details
     * @param triggerKey MISP trigger identifier
     * @return trigger Full MISP trigger data
     */
    function getMISPTrigger(bytes32 triggerKey) 
        external 
        view 
        returns (MISPTrigger memory trigger) 
    {
        return mispTriggers[triggerKey];
    }
    
    /**
     * @notice Get blacklist statistics
     * @return addresses Total blacklisted addresses
     * @return cids Total blacklisted CIDs
     * @return dids Total blacklisted DIDs
     * @return mispCount Total MISP triggers
     */
    function getBlacklistStats() 
        external 
        view 
        returns (
            uint256 addresses,
            uint256 cids,
            uint256 dids,
            uint256 mispCount
        ) 
    {
        return (
            totalBlacklistedAddresses,
            totalBlacklistedCIDs,
            totalBlacklistedDIDs,
            totalMISPTriggers
        );
    }
    
    // ============ Governance Functions ============
    
    /**
     * @notice Remove an address from blacklist (only non-permanent)
     * @param entity Address to remove
     */
    function removeAddressFromBlacklist(address entity) external onlyGGC {
        BlacklistEntry storage entry = blacklistedAddresses[entity];
        require(entry.timestamp != 0, "Not blacklisted");
        require(!entry.isPermanent, "Cannot remove permanent blacklist");
        
        delete blacklistedAddresses[entity];
        totalBlacklistedAddresses--;
        
        emit BlacklistRemoved(
            bytes32(uint256(uint160(entity))),
            "ADDRESS",
            msg.sender,
            block.timestamp
        );
    }
    
    /**
     * @notice Remove a CID from blacklist (only non-permanent)
     * @param cid CID to remove
     */
    function removeCIDFromBlacklist(bytes32 cid) external onlyGGC {
        BlacklistEntry storage entry = blacklistedCIDs[cid];
        require(entry.timestamp != 0, "Not blacklisted");
        require(!entry.isPermanent, "Cannot remove permanent blacklist");
        
        delete blacklistedCIDs[cid];
        totalBlacklistedCIDs--;
        
        emit BlacklistRemoved(cid, "CID", msg.sender, block.timestamp);
    }
    
    /**
     * @notice Remove a DID from blacklist (only non-permanent)
     * @param did DID to remove
     */
    function removeDIDFromBlacklist(bytes32 did) external onlyGGC {
        BlacklistEntry storage entry = blacklistedDIDs[did];
        require(entry.timestamp != 0, "Not blacklisted");
        require(!entry.isPermanent, "Cannot remove permanent blacklist");
        
        delete blacklistedDIDs[did];
        totalBlacklistedDIDs--;
        
        emit BlacklistRemoved(did, "DID", msg.sender, block.timestamp);
    }
    
    /**
     * @notice Authorize a reporter (EFA or monitor)
     * @param reporter Address to authorize
     */
    function authorizeReporter(address reporter) external onlyGGC {
        require(reporter != address(0), "Invalid address");
        authorizedReporters[reporter] = true;
        emit ReporterAuthorized(reporter, true);
    }
    
    /**
     * @notice Revoke reporter authorization
     * @param reporter Address to revoke
     */
    function revokeReporter(address reporter) external onlyGGC {
        authorizedReporters[reporter] = false;
        emit ReporterAuthorized(reporter, false);
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
