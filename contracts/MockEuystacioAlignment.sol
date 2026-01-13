// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MockEuystacioAlignment
 * @notice Mock implementation of IEuystacioAlignment for testing Synthia Genesis
 * @dev This is a simplified mock for development/testing - production should use proper verification
 */
contract MockEuystacioAlignment {
    // Storage for mock alignment scores
    mapping(address => bool) public nsrCompliant;
    mapping(bytes32 => uint8) public olfScores;
    mapping(bytes32 => bool) public sentimentoAligned;
    
    // Default values
    uint8 public defaultOLFScore = 94;
    bool public defaultNSRCompliance = true;
    bool public defaultSentimentoAlignment = true;
    
    // Events
    event NSRComplianceSet(address indexed entity, bool compliant);
    event OLFScoreSet(bytes32 indexed genesisHash, uint8 score);
    event SentimentoAlignmentSet(bytes32 indexed operationId, bool aligned);
    
    /**
     * @notice Set NSR compliance status for an entity
     * @param entity Address of the entity
     * @param compliant Compliance status
     */
    function setNSRCompliance(address entity, bool compliant) external {
        nsrCompliant[entity] = compliant;
        emit NSRComplianceSet(entity, compliant);
    }
    
    /**
     * @notice Set OLF alignment score for a genesis hash
     * @param genesisHash Hash of the genesis block
     * @param score Alignment score (0-100)
     */
    function setOLFScore(bytes32 genesisHash, uint8 score) external {
        require(score <= 100, "Score must be 0-100");
        olfScores[genesisHash] = score;
        emit OLFScoreSet(genesisHash, score);
    }
    
    /**
     * @notice Set Sentimento alignment status for an operation
     * @param operationId Operation identifier
     * @param aligned Alignment status
     */
    function setSentimentoAlignment(bytes32 operationId, bool aligned) external {
        sentimentoAligned[operationId] = aligned;
        emit SentimentoAlignmentSet(operationId, aligned);
    }
    
    /**
     * @notice Set default values for testing
     * @param _defaultOLFScore Default OLF score
     * @param _defaultNSRCompliance Default NSR compliance
     * @param _defaultSentimentoAlignment Default Sentimento alignment
     */
    function setDefaults(
        uint8 _defaultOLFScore,
        bool _defaultNSRCompliance,
        bool _defaultSentimentoAlignment
    ) external {
        require(_defaultOLFScore <= 100, "Score must be 0-100");
        defaultOLFScore = _defaultOLFScore;
        defaultNSRCompliance = _defaultNSRCompliance;
        defaultSentimentoAlignment = _defaultSentimentoAlignment;
    }
    
    // IEuystacioAlignment implementation
    
    /**
     * @notice Verify Sentimento alignment for an operation
     * @param operationId Operation identifier
     * @return aligned True if aligned with Sentimento Rhythm
     */
    function verifySentimentoAlignment(bytes32 operationId) 
        external 
        view 
        returns (bool aligned) 
    {
        // Check if specific alignment set, otherwise use default
        if (sentimentoAligned[operationId]) {
            return true;
        }
        return defaultSentimentoAlignment;
    }
    
    /**
     * @notice Validate NSR compliance for an entity
     * @param entity Address of the entity to validate
     * @return compliant True if NSR compliant
     */
    function validateNSRCompliance(address entity) 
        external 
        view 
        returns (bool compliant) 
    {
        // Check if specific compliance set, otherwise use default
        bool hasSpecificValue = nsrCompliant[entity];
        if (hasSpecificValue) {
            return true;
        }
        return defaultNSRCompliance;
    }
    
    /**
     * @notice Check OLF alignment score for a genesis hash
     * @param genesisHash Hash of the genesis block
     * @return score Alignment score (0-100)
     */
    function checkOLFAlignment(bytes32 genesisHash) 
        external 
        view 
        returns (uint8 score) 
    {
        // Check if specific score set, otherwise use default
        uint8 specificScore = olfScores[genesisHash];
        if (specificScore > 0) {
            return specificScore;
        }
        return defaultOLFScore;
    }
}
