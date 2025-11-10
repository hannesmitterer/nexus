# Universal Liquidity Pool (ULP) Smart Contract

## Overview
The Universal Liquidity Pool (ULP) is the core financial engine of Protocol SAIN (Phase III). This advanced Automated Market Maker (AMM) contract is designed for deployment on Polygon Mainnet with full auditability and ethical/financial constraints encoded in the contract logic.

## Contract Specifications

### Core Variables and Functions

| Variable/Function | Technical Detail | Ethical/Financial Function |
|------------------|------------------|---------------------------|
| **ULP_PAIR** | Pair: SAIN Token / Stablecoin (e.g., USDC) | Establishes fundamental liquidity for PeaceBonds |
| **STABILIZATION_FEE** | Variable (0.05% - 0.1%) | Tax applied to withdrawals. Modified by AIC to defend floor price |
| **MIN_PRICE_FLOOR** | Constant (10×10^18 in Stablecoin) | Activates burning/buyback mechanisms if price drops below floor |
| **TRE_PLEDGE_RATE** | Variable: 0.3% of Yield | Fixed percentage allocated to GGC Restitution Fund |
| **setGovernanceWeights()** | Only GGC Multisig (7/9) authorized | Updates critical variables (stabilization fee, minimum ethical TRE) |

## Key Features

### 1. Liquidity Pool Management
- **addLiquidity()**: Add SAIN tokens and stablecoins to the pool
- **removeLiquidity()**: Remove liquidity with stabilization fee applied
- **swap()**: Execute token swaps with automatic TRE pledge collection

### 2. Price Floor Protection Mechanisms
- **getCurrentPrice()**: Get current SAIN token price in stablecoin
- **isPriceBelowFloor()**: Check if price is below MIN_PRICE_FLOOR
- **triggerBuyback()**: Activate buyback when price falls below floor
- **burnTokens()**: Burn SAIN tokens to defend price floor

### 3. Governance Functions (GGC Multisig Only)
- **setGovernanceWeights()**: Update both stabilization fee and TRE pledge rate
- **setStabilizationFee()**: Update stabilization fee (0.05%-0.1% range)
- **setTrePledgeRate()**: Update TRE pledge rate
- **setGgcMultisig()**: Update GGC Multisig address

### 4. TRE Fund Management
- **transferTreFunds()**: Transfer accumulated TRE funds to GGC Restitution Fund
- Automatic collection of 0.3% of yields for ethical restitution

## Financial Safety Mechanisms

### Stabilization Fee
- Range: 0.05% - 0.1% (5-10 basis points)
- Applied to all liquidity withdrawals
- Dynamically adjustable by GGC Multisig to defend price floor
- Helps prevent rapid liquidity drains

### Price Floor Defense
When SAIN token price falls below MIN_PRICE_FLOOR (10 stablecoin units):
1. **Buyback Mechanism**: GGC Multisig can trigger automatic buybacks using pool stablecoin reserves
2. **Token Burning**: GGC Multisig can burn SAIN tokens to reduce supply and support price

### TRE Pledge System
- 0.3% (30 basis points) of all swap yields automatically allocated to TRE funds
- Supports the GGC Restitution Fund for ethical commitments
- Fully transparent and traceable through events

## Governance and Authorization

### GGC Multisig (7/9)
All critical parameter updates require authorization from the GGC Multisig wallet:
- 7 out of 9 signatures required for operations
- Controls stabilization fee adjustments
- Controls TRE pledge rate updates
- Authorizes price floor defense mechanisms
- Can transfer TRE funds to Restitution Fund

### Access Control
- `onlyGgcMultisig` modifier restricts sensitive functions
- Prevents unauthorized parameter changes
- Ensures ethical oversight of financial operations

## Traceability and Auditability

### Comprehensive Event Logging
The contract emits detailed events for all operations:
- `LiquidityAdded`: Track liquidity additions
- `LiquidityRemoved`: Track withdrawals with fees
- `Swap`: Track all token swaps
- `StabilizationFeeUpdated`: Track fee changes
- `TrePledgeRateUpdated`: Track TRE rate changes
- `GovernanceWeightsUpdated`: Track governance parameter updates
- `BuybackTriggered`: Track price floor defense buybacks
- `TokensBurned`: Track token burning operations
- `TreFundsTransferred`: Track TRE fund distributions
- `GgcMultisigUpdated`: Track governance address changes

All events include:
- Actor addresses (indexed for efficient querying)
- Amounts and parameters
- Timestamps for chronological tracking

### Public Auditability
- All state variables are public
- View functions provide comprehensive pool status
- Event history creates immutable audit trail
- Contract source will be verified on Polygonscan

## View Functions

### getUlpPair()
Returns the liquidity pair configuration (SAIN token and stablecoin addresses)

### getPoolParameters()
Returns:
- Current stabilization fee
- Current TRE pledge rate
- Minimum price floor
- Current SAIN token price

### getPoolLiquidity()
Returns:
- Total SAIN token liquidity
- Total stablecoin liquidity
- Total TRE funds collected

### getGovernanceConfig()
Returns:
- GGC Multisig address
- Required confirmations (7)
- Total signers (9)

## Deployment Steps

1. **Prepare Addresses**
   - Deploy or identify SAIN token contract address
   - Identify stablecoin contract address (e.g., USDC on Polygon)
   - Set up GGC Multisig wallet (7/9 configuration)

2. **Deploy Contract**
   ```solidity
   constructor(
       address _sainToken,      // SAIN token contract address
       address _stablecoin,     // Stablecoin contract address (USDC)
       address _ggcMultisig     // GGC Multisig wallet address
   )
   ```

3. **Verify on Polygonscan**
   - Submit contract source code
   - Verify constructor parameters
   - Enable public source code view

4. **Initialize Pool**
   - Add initial liquidity via `addLiquidity()`
   - Configure initial stabilization fee if different from default (0.05%)
   - Set TRE pledge rate if different from default (0.3%)

## Security Considerations

### Input Validation
- All critical parameters validated with modifiers
- Stabilization fee constrained to 0.05%-0.1% range
- TRE pledge rate must be positive
- Zero address checks on all address parameters

### Access Control
- GGC Multisig authorization required for all governance functions
- No single point of failure in governance
- Multisig prevents unauthorized parameter changes

### Economic Safeguards
- Price floor protection prevents catastrophic devaluation
- Stabilization fee prevents rapid liquidity drains
- TRE pledge ensures ongoing ethical commitments
- Buyback and burning mechanisms defend token value

## Integration Notes

### ERC20 Token Interface
The current implementation includes event emissions for traceability. In production deployment:
- Integrate with ERC20 `transferFrom()` for liquidity additions
- Integrate with ERC20 `transfer()` for liquidity removals and swaps
- Ensure proper token approvals before contract interactions

### AMM Pricing
The contract uses a simplified constant product formula. For production:
- Consider implementing more sophisticated pricing mechanisms
- Add slippage protection parameters
- Implement oracle price feeds for additional safety

### Upgradability
Current contract is not upgradeable (immutable). For future versions:
- Consider proxy patterns for upgradability
- Maintain governance control through GGC Multisig
- Preserve event history and auditability

## Compliance and Ethics

The ULP contract encodes the following ethical principles:
1. **Transparency**: All operations emit events for public audit
2. **Accountability**: GGC Multisig governance with clear authorization requirements
3. **Restitution**: Automatic TRE pledge collection for ethical commitments
4. **Stability**: Price floor protection and anti-drain mechanisms
5. **Traceability**: Comprehensive event logging with timestamps

## Contract Address (Post-Deployment)
- Network: Polygon Mainnet
- Contract Address: [To be filled after deployment]
- Polygonscan: [Verification link to be added]

## Version History
- v1.0: Initial ULP implementation with all core features

## License
MIT License - Open source and auditable
