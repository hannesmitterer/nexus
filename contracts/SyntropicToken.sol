// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SyntropicToken – ERC-20 token based on Urformel (primordial formula) principles
/// @notice Implements harmonic validation derived from the golden ratio (PHI) and Fibonacci growth.
///         Every transfer is validated against syntropic proportions; dissonant amounts are rejected.
/// @dev Compatible with Optimism L2 and IPFS Mosaic architecture.
contract SyntropicToken is ERC20, Ownable {
    /// @notice Golden ratio approximated in thousandths (1.618 → 1618).
    uint256 public constant PHI = 1618;

    /// @notice Fibonacci sequence used for Mosaic node connection validation.
    uint256[] public fibonacciSequence;

    /// @dev O(1) lookup for Fibonacci membership.
    mapping(uint256 => bool) private _isFibonacciValue;

    /// @notice Emitted when a Mosaic node is registered on-chain.
    event MosaicNodeRegistered(uint256 indexed nodeId, string ipfsCid, uint256 frequency);

    /// @notice Emitted when a harmonic transfer is validated.
    event HarmonicTransfer(address indexed from, address indexed to, uint256 amount);

    /// @dev Maps Mosaic node IDs to their IPFS CID for on-chain reference.
    mapping(uint256 => string) public mosaicNodes;

    /// @dev Constructor initialises token supply and Fibonacci base sequence.
    constructor() ERC20("SyntropicToken", "STOK") Ownable(msg.sender) {
        // 144 000 units – symbolic initial supply aligned with sacred geometry.
        _mint(msg.sender, 144_000 * 10 ** decimals());

        // Seed first ten Fibonacci numbers for Mosaic node connection validation.
        // Node IDs use distinct Fibonacci values starting from 1, 2, 3, 5, 8 …
        // (the duplicate opening 1 of the classical sequence is omitted for clarity).
        uint256[10] memory fibs = [uint256(1), 2, 3, 5, 8, 13, 21, 34, 55, 89];
        for (uint256 i = 0; i < fibs.length; i++) {
            fibonacciSequence.push(fibs[i]);
            _isFibonacciValue[fibs[i]] = true;
        }
    }

    /// @notice Returns the length of the stored Fibonacci sequence.
    function fibonacciLength() external view returns (uint256) {
        return fibonacciSequence.length;
    }

    /// @notice Registers a Mosaic node with its IPFS CID and resonance frequency.
    /// @param nodeId   Unique Fibonacci-derived identifier for the node.
    /// @param ipfsCid  IPFS content identifier of the Mosaic JSON structure.
    /// @param frequency Resonance frequency in millihertz (e.g. 7830 = 7.83 Hz).
    function registerMosaicNode(
        uint256 nodeId,
        string calldata ipfsCid,
        uint256 frequency
    ) external onlyOwner {
        require(isFibonacci(nodeId), "Node ID must be a Fibonacci number.");
        mosaicNodes[nodeId] = ipfsCid;
        emit MosaicNodeRegistered(nodeId, ipfsCid, frequency);
    }

    /// @notice Validates whether a value is a Fibonacci number stored in the sequence.
    /// @param value The value to check.
    /// @return bool True if the value appears in the Fibonacci sequence.
    function isFibonacci(uint256 value) public view returns (bool) {
        return _isFibonacciValue[value];
    }

    /// @notice Validates whether an amount respects golden-ratio-derived proportions.
    /// @param amount Transfer amount to validate.
    /// @return bool True when the amount is divisible by PHI (1618) or PHI-1 (1617).
    function isHarmonic(uint256 amount) public pure returns (bool) {
        return amount % PHI == 0 || amount % (PHI - 1) == 0;
    }

    /// @dev Hook called before every token transfer; enforces harmonic validation.
    ///      Minting (from == address(0)) and burning (to == address(0)) bypass the check.
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != address(0) && to != address(0)) {
            require(
                isHarmonic(amount),
                "Sintropia Violata: Transfer rejected – amount does not conform to harmonic principles."
            );
            emit HarmonicTransfer(from, to, amount);
        }
        super._update(from, to, amount);
    }
}
