// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SyntropicToken – ERC-20 token based on Urformel principles
/// @notice Implements syntropic growth and harmony validation derived from
///         the golden ratio (φ ≈ 1.618) and Fibonacci sequences.
/// @dev    Transfers are validated for harmonic proportions; non-harmonic
///         amounts are rejected to preserve syntropic integrity.
contract SyntropicToken is ERC20, Ownable {
    /// @notice Golden ratio approximated in integer millesimi (1.618 → 1618).
    uint256 public constant PHI = 1618;

    /// @notice Initial symbolic supply: 144 000 tokens (a Fibonacci number).
    uint256 public constant INITIAL_SUPPLY = 144_000;

    /// @param initialOwner Address that receives the initial symbolic supply.
    constructor(address initialOwner)
        ERC20("SyntropicToken", "STOK")
        Ownable(initialOwner)
    {
        _mint(initialOwner, INITIAL_SUPPLY * 10 ** decimals());
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Harmonic validation
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Returns true when `amount` conforms to golden-ratio proportions.
    /// @dev    Validation operates on whole token units (amount / 10**decimals())
    ///         so that, e.g., 1618 STOK or 1617 STOK are harmonic transfers.
    ///         An amount is harmonic when its whole-unit value is divisible by
    ///         PHI (1618) or by PHI − 1 (1617, the nearest Fibonacci-adjacent
    ///         value).  Sub-unit (fractional) amounts are treated as harmonic to
    ///         avoid blocking small adjustments.
    ///         Mint/burn operations (from == address(0) or to == address(0))
    ///         are exempt from this check.
    function isHarmonic(uint256 amount) public pure returns (bool) {
        uint256 wholeUnits = amount / (10 ** 18);
        // Sub-unit amounts are allowed (whole-unit value is 0).
        if (wholeUnits == 0) return true;
        return wholeUnits % PHI == 0 || wholeUnits % (PHI - 1) == 0;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ERC-20 override
    // ─────────────────────────────────────────────────────────────────────────

    /// @inheritdoc ERC20
    /// @dev Applies harmonic validation to every peer-to-peer transfer.
    ///      Mint (from == address(0)) and burn (to == address(0)) are exempt.
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // Exempt mint and burn operations from harmonic validation.
        bool isMintOrBurn = (from == address(0) || to == address(0));

        if (!isMintOrBurn) {
            require(
                isHarmonic(amount),
                "SyntropicToken: transfer amount violates harmonic principles"
            );
        }

        super._update(from, to, amount);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Owner-only growth functions
    // ─────────────────────────────────────────────────────────────────────────

    /// @notice Mint additional tokens to `account` (owner only).
    /// @param account Recipient of the newly minted tokens.
    /// @param amount  Amount to mint (in token base units).
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /// @notice Burn tokens from the caller's own balance.
    /// @param amount Amount to burn (in token base units).
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
