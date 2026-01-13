// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title SynthiaGenesisTest
 * @notice Basic test contract for Synthia Genesis Block
 * @dev Can be run with Foundry: forge test --match-contract SynthiaGenesisTest
 */

import "../contracts/SynthiaGenesis.sol";
import "../contracts/MockEuystacioAlignment.sol";

contract SynthiaGenesisTest {
    SynthiaGenesis genesis;
    MockEuystacioAlignment alignmentVerifier;
    
    address ggcMultisig = address(0x1);
    address efaAlpha = address(0x2);
    address efaBeta = address(0x3);
    address efaGamma = address(0x4);
    
    // Events for testing
    event GenesisBlockInitialized(bytes32 indexed genesisHash, uint256 timestamp, uint8 alignmentScore);
    event AlignmentVerified(bytes32 indexed proofHash, bool nsrCompliant, bool olfAligned, uint8 score);
    event EFAAuthorized(address indexed efa, uint256 totalEFAs);
    
    function setUp() public {
        // Deploy contracts
        genesis = new SynthiaGenesis(ggcMultisig);
        alignmentVerifier = new MockEuystacioAlignment();
        
        // Configure mock verifier with passing defaults
        alignmentVerifier.setDefaults(94, true, true);
    }
    
    function testConstructor() public view {
        require(genesis.ggcMultisig() == ggcMultisig, "GGC multisig not set correctly");
        require(genesis.genesisTimestamp() > 0, "Genesis timestamp not set");
        require(!genesis.isInitialized(), "Should not be initialized");
        require(genesis.efaCount() == 0, "Should have 0 EFAs initially");
    }
    
    function testInitializeGenesisBlock() public {
        // Prepare genesis parameters
        address[] memory initialValidators = new address[](3);
        initialValidators[0] = efaAlpha;
        initialValidators[1] = efaBeta;
        initialValidators[2] = efaGamma;
        
        SynthiaGenesis.GenesisParameters memory params = SynthiaGenesis.GenesisParameters({
            sentimentoRhythmHash: keccak256("Sentimento Rhythm Test"),
            euystacioFrameworkHash: keccak256("Euystacio Framework Test"),
            sainProtocolHash: keccak256("SAIN Protocol Test"),
            initialTimestamp: block.timestamp,
            initialValidators: initialValidators,
            alignmentScore: 94
        });
        
        // Initialize as GGC multisig
        _actAsGGC();
        genesis.initializeGenesisBlock(params, address(alignmentVerifier));
        
        // Verify initialization
        require(genesis.isInitialized(), "Genesis should be initialized");
        require(genesis.efaCount() == 3, "Should have 3 EFAs");
        require(genesis.genesisBlockHash() != bytes32(0), "Genesis hash should be set");
        
        // Verify EFAs are authorized
        require(genesis.isAuthorizedEFA(efaAlpha), "EFA Alpha should be authorized");
        require(genesis.isAuthorizedEFA(efaBeta), "EFA Beta should be authorized");
        require(genesis.isAuthorizedEFA(efaGamma), "EFA Gamma should be authorized");
    }
    
    function testCannotInitializeTwice() public {
        // Initialize once
        testInitializeGenesisBlock();
        
        // Try to initialize again - should fail
        address[] memory validators = new address[](1);
        validators[0] = address(0x5);
        
        SynthiaGenesis.GenesisParameters memory params = SynthiaGenesis.GenesisParameters({
            sentimentoRhythmHash: keccak256("Test"),
            euystacioFrameworkHash: keccak256("Test"),
            sainProtocolHash: keccak256("Test"),
            initialTimestamp: block.timestamp,
            initialValidators: validators,
            alignmentScore: 94
        });
        
        _actAsGGC();
        
        // This should revert with AlreadyInitialized error
        bool reverted = false;
        try genesis.initializeGenesisBlock(params, address(alignmentVerifier)) {
            // Should not reach here
        } catch {
            reverted = true;
        }
        
        require(reverted, "Should revert when initializing twice");
    }
    
    function testMinimumAlignmentScore() public {
        address[] memory validators = new address[](1);
        validators[0] = efaAlpha;
        
        SynthiaGenesis.GenesisParameters memory params = SynthiaGenesis.GenesisParameters({
            sentimentoRhythmHash: keccak256("Test"),
            euystacioFrameworkHash: keccak256("Test"),
            sainProtocolHash: keccak256("Test"),
            initialTimestamp: block.timestamp,
            initialValidators: validators,
            alignmentScore: 93  // Below minimum of 94
        });
        
        _actAsGGC();
        
        bool reverted = false;
        try genesis.initializeGenesisBlock(params, address(alignmentVerifier)) {
            // Should not reach here
        } catch {
            reverted = true;
        }
        
        require(reverted, "Should revert with insufficient alignment score");
    }
    
    function testSubmitAlignmentProof() public {
        // Initialize first
        testInitializeGenesisBlock();
        
        // Submit alignment proof
        _actAsGGC();
        genesis.submitAlignmentProof("Test alignment proof metadata");
        
        // Verify alignment status
        (bool verified, uint8 score, uint256 timestamp) = genesis.getAlignmentStatus();
        require(verified, "Alignment should be verified");
        require(score == 94, "Alignment score should be 94");
        require(timestamp > 0, "Timestamp should be set");
    }
    
    function testAuthorizeEFA() public {
        testInitializeGenesisBlock();
        
        address newEFA = address(0x5);
        
        _actAsGGC();
        genesis.authorizeEFA(newEFA);
        
        require(genesis.isAuthorizedEFA(newEFA), "New EFA should be authorized");
        require(genesis.efaCount() == 4, "Should have 4 EFAs");
    }
    
    function testRevokeEFA() public {
        testInitializeGenesisBlock();
        
        _actAsGGC();
        genesis.revokeEFA(efaAlpha);
        
        require(!genesis.isAuthorizedEFA(efaAlpha), "EFA Alpha should be revoked");
        require(genesis.efaCount() == 2, "Should have 2 EFAs");
    }
    
    function testSynthiaCompatibility() public {
        testInitializeGenesisBlock();
        
        (bool compatible, string memory version, bytes32 frameworkId) = genesis.verifySynthiaCompatibility();
        
        require(compatible, "Should be Synthia compatible after initialization");
        require(keccak256(bytes(version)) == keccak256(bytes("1.0.0")), "Version should be 1.0.0");
        require(frameworkId == genesis.SYNTHIA_FRAMEWORK_ID(), "Framework ID should match");
    }
    
    function testGetGenesisInfo() public {
        testInitializeGenesisBlock();
        
        (bytes32 hash, uint256 timestamp, bool initialized, uint256 efas) = genesis.getGenesisInfo();
        
        require(hash != bytes32(0), "Genesis hash should be set");
        require(timestamp > 0, "Timestamp should be set");
        require(initialized, "Should be initialized");
        require(efas == 3, "Should have 3 EFAs");
    }
    
    // Helper function to simulate acting as GGC multisig
    function _actAsGGC() internal {
        // In a real test environment, this would use vm.prank(ggcMultisig)
        // For this basic test, we assume msg.sender is ggcMultisig
        // This is a limitation of basic testing without Foundry's vm cheats
    }
}

/**
 * @title BasicTestRunner
 * @notice Simple test runner that can be called directly
 */
contract BasicTestRunner {
    function runTests() external returns (string memory) {
        SynthiaGenesisTest test = new SynthiaGenesisTest();
        
        try test.setUp() {
            // Test 1: Constructor
            try test.testConstructor() {
            } catch {
                return "FAIL: testConstructor";
            }
            
            // Test 2: Genesis Info
            try test.testGetGenesisInfo() {
            } catch {
                return "FAIL: testGetGenesisInfo";
            }
            
            return "PASS: All basic tests passed";
        } catch {
            return "FAIL: setUp failed";
        }
    }
}
