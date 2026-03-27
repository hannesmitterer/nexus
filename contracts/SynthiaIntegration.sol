// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SynthiaGenesis.sol";

/**
 * @title SynthiaIntegration
 * @notice Integration layer between Synthia Genesis and existing nexus contracts
 * @dev Provides compatibility verification and integration helpers
 */

interface IEIMClient {
    function ggcMultisig() external view returns (address);
    function authorizedEFAs(address efa) external view returns (bool);
}

interface IULP {
    function ggcMultisig() external view returns (address);
}

interface ITFKVerifier {
    function currentModelCID() external view returns (bytes32);
}

contract SynthiaIntegration {
    // ============ State Variables ============
    
    SynthiaGenesis public immutable synthiaGenesis;
    
    // Registered nexus contracts
    address public eimClient;
    address public ulp;
    address public tfkVerifier;
    address public vce;
    
    // Integration status
    bool public isFullyIntegrated;
    
    // ============ Events ============
    
    event ContractRegistered(string indexed contractType, address contractAddress);
    event IntegrationVerified(bool success, string message);
    event AlignmentChecked(address indexed contractAddress, bool aligned);
    
    // ============ Errors ============
    
    error InvalidGenesisContract();
    error NotInitialized();
    error ContractNotRegistered();
    error AlignmentMismatch(string reason);
    
    // ============ Constructor ============
    
    constructor(address _synthiaGenesis) {
        if (_synthiaGenesis == address(0)) revert InvalidGenesisContract();
        synthiaGenesis = SynthiaGenesis(_synthiaGenesis);
    }
    
    // ============ Registration Functions ============
    
    /**
     * @notice Register EIMClient contract
     * @param _eimClient Address of EIMClient contract
     */
    function registerEIMClient(address _eimClient) external {
        require(_eimClient != address(0), "Invalid address");
        eimClient = _eimClient;
        emit ContractRegistered("EIMClient", _eimClient);
        _checkIntegration();
    }
    
    /**
     * @notice Register ULP contract
     * @param _ulp Address of ULP contract
     */
    function registerULP(address _ulp) external {
        require(_ulp != address(0), "Invalid address");
        ulp = _ulp;
        emit ContractRegistered("ULP", _ulp);
        _checkIntegration();
    }
    
    /**
     * @notice Register TFKVerifier contract
     * @param _tfkVerifier Address of TFKVerifier contract
     */
    function registerTFKVerifier(address _tfkVerifier) external {
        require(_tfkVerifier != address(0), "Invalid address");
        tfkVerifier = _tfkVerifier;
        emit ContractRegistered("TFKVerifier", _tfkVerifier);
        _checkIntegration();
    }
    
    /**
     * @notice Register VCE contract
     * @param _vce Address of VCE contract
     */
    function registerVCE(address _vce) external {
        require(_vce != address(0), "Invalid address");
        vce = _vce;
        emit ContractRegistered("VCE", _vce);
        _checkIntegration();
    }
    
    // ============ Verification Functions ============
    
    /**
     * @notice Verify alignment between Synthia Genesis and registered contracts
     * @return aligned True if all contracts are properly aligned
     * @return message Status message
     */
    function verifyIntegration() 
        external 
        view 
        returns (bool aligned, string memory message) 
    {
        // Check Genesis initialization
        if (!synthiaGenesis.isInitialized()) {
            return (false, "Synthia Genesis not initialized");
        }
        
        // Check Synthia compatibility
        (bool compatible, , ) = synthiaGenesis.verifySynthiaCompatibility();
        if (!compatible) {
            return (false, "Synthia compatibility check failed");
        }
        
        // Verify GGC multisig alignment
        address genesisGGC = synthiaGenesis.ggcMultisig();
        
        if (eimClient != address(0)) {
            address eimGGC = IEIMClient(eimClient).ggcMultisig();
            if (eimGGC != genesisGGC) {
                return (false, "EIMClient GGC mismatch");
            }
        }
        
        if (ulp != address(0)) {
            address ulpGGC = IULP(ulp).ggcMultisig();
            if (ulpGGC != genesisGGC) {
                return (false, "ULP GGC mismatch");
            }
        }
        
        // All checks passed
        return (true, "All contracts aligned with Synthia Genesis");
    }
    
    /**
     * @notice Check if a specific EFA is authorized in both Genesis and EIMClient
     * @param efa Address of the EFA to check
     * @return authorized True if authorized in both contracts
     */
    function verifyEFAAlignment(address efa) 
        external 
        view 
        returns (bool authorized) 
    {
        // Check Genesis authorization
        bool genesisAuth = synthiaGenesis.isAuthorizedEFA(efa);
        
        // Check EIMClient authorization (if registered)
        bool eimAuth = true;
        if (eimClient != address(0)) {
            eimAuth = IEIMClient(eimClient).authorizedEFAs(efa);
        }
        
        return genesisAuth && eimAuth;
    }
    
    /**
     * @notice Get comprehensive alignment status
     * @return status Struct containing all alignment information
     */
    function getAlignmentStatus() 
        external 
        view 
        returns (AlignmentStatus memory status) 
    {
        status.genesisInitialized = synthiaGenesis.isInitialized();
        status.genesisBlockHash = synthiaGenesis.genesisBlockHash();
        status.ggcMultisig = synthiaGenesis.ggcMultisig();
        status.efaCount = synthiaGenesis.efaCount();
        
        (bool verified, uint8 score, uint256 timestamp) = synthiaGenesis.getAlignmentStatus();
        status.alignmentVerified = verified;
        status.alignmentScore = score;
        status.alignmentTimestamp = timestamp;
        
        (bool compatible, string memory version, bytes32 frameworkId) = 
            synthiaGenesis.verifySynthiaCompatibility();
        status.synthiaCompatible = compatible;
        status.protocolVersion = version;
        status.frameworkId = frameworkId;
        
        status.eimClientRegistered = eimClient != address(0);
        status.ulpRegistered = ulp != address(0);
        status.tfkVerifierRegistered = tfkVerifier != address(0);
        status.vceRegistered = vce != address(0);
        
        status.fullyIntegrated = isFullyIntegrated;
    }
    
    /**
     * @notice Generate integration report hash
     * @return reportHash Hash of the integration status for verification
     */
    function generateIntegrationReport() 
        external 
        view 
        returns (bytes32 reportHash) 
    {
        return keccak256(
            abi.encodePacked(
                synthiaGenesis.genesisBlockHash(),
                synthiaGenesis.ggcMultisig(),
                synthiaGenesis.efaCount(),
                eimClient,
                ulp,
                tfkVerifier,
                vce,
                block.timestamp
            )
        );
    }
    
    // ============ Internal Functions ============
    
    /**
     * @notice Internal function to check if integration is complete
     */
    function _checkIntegration() internal {
        // Integration is considered complete when key contracts are registered
        // and Genesis is initialized
        bool basicIntegration = synthiaGenesis.isInitialized() &&
                               eimClient != address(0);
        
        if (basicIntegration && !isFullyIntegrated) {
            isFullyIntegrated = true;
            emit IntegrationVerified(true, "Basic integration complete");
        }
    }
    
    // ============ Structs ============
    
    struct AlignmentStatus {
        bool genesisInitialized;
        bytes32 genesisBlockHash;
        address ggcMultisig;
        uint256 efaCount;
        bool alignmentVerified;
        uint8 alignmentScore;
        uint256 alignmentTimestamp;
        bool synthiaCompatible;
        string protocolVersion;
        bytes32 frameworkId;
        bool eimClientRegistered;
        bool ulpRegistered;
        bool tfkVerifierRegistered;
        bool vceRegistered;
        bool fullyIntegrated;
    }
}
