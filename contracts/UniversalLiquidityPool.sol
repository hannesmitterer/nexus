// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Universal Liquidity Pool (ULP)
 * @notice Core financial engine of Protocol SAIN (Phase III)
 * @dev Advanced Automated Market Maker (AMM) contract for Polygon Mainnet
 * 
 * This contract implements the Universal Liquidity Pool with:
 * - SAIN Token / Stablecoin pair management
 * - Dynamic stabilization fees
 * - Price floor protection with burning/buyback mechanisms
 * - TRE (Truthfulness, Restoration, Ethics) pledge system
 * - GGC Multisig governance for critical parameter updates
 */
contract UniversalLiquidityPool {
    
    // ============ State Variables ============
    
    /// @notice SAIN Token address in the liquidity pair
    address public sainToken;
    
    /// @notice Stablecoin address (e.g., USDC) in the liquidity pair
    address public stablecoin;
    
    /// @notice Current stabilization fee (in basis points: 1 = 0.01%)
    /// @dev Range: 5-10 basis points (0.05% - 0.1%)
    uint256 public stabilizationFee;
    
    /// @notice Minimum price floor for SAIN token (10 stablecoin units with 18 decimals)
    /// @dev Constant value: 10 × 10^18
    uint256 public constant MIN_PRICE_FLOOR = 10 * 10**18;
    
    /// @notice TRE pledge rate applied to yields (in basis points: 1 = 0.01%)
    /// @dev Fixed at 0.3% = 30 basis points
    uint256 public trePledgeRate;
    
    /// @notice GGC Multisig wallet address (7/9 authorization required)
    address public ggcMultisig;
    
    /// @notice Required number of confirmations for GGC Multisig operations
    uint256 public constant REQUIRED_CONFIRMATIONS = 7;
    
    /// @notice Total number of GGC Multisig signers
    uint256 public constant TOTAL_SIGNERS = 9;
    
    /// @notice Total liquidity in the pool (SAIN tokens)
    uint256 public totalSainLiquidity;
    
    /// @notice Total liquidity in the pool (Stablecoin)
    uint256 public totalStablecoinLiquidity;
    
    /// @notice Total TRE funds collected for GGC Restitution Fund
    uint256 public totalTreFunds;
    
    /// @notice Flag to track if buyback mechanism is active
    bool public buybackActive;
    
    // ============ Events ============
    
    /// @notice Emitted when liquidity is added to the pool
    event LiquidityAdded(
        address indexed provider,
        uint256 sainAmount,
        uint256 stablecoinAmount,
        uint256 timestamp
    );
    
    /// @notice Emitted when liquidity is removed from the pool
    event LiquidityRemoved(
        address indexed provider,
        uint256 sainAmount,
        uint256 stablecoinAmount,
        uint256 feeCollected,
        uint256 timestamp
    );
    
    /// @notice Emitted when a swap occurs
    event Swap(
        address indexed trader,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 timestamp
    );
    
    /// @notice Emitted when stabilization fee is updated
    event StabilizationFeeUpdated(
        uint256 oldFee,
        uint256 newFee,
        address indexed updatedBy,
        uint256 timestamp
    );
    
    /// @notice Emitted when TRE pledge rate is updated
    event TrePledgeRateUpdated(
        uint256 oldRate,
        uint256 newRate,
        address indexed updatedBy,
        uint256 timestamp
    );
    
    /// @notice Emitted when governance weights are updated
    event GovernanceWeightsUpdated(
        uint256 stabilizationFee,
        uint256 trePledgeRate,
        address indexed updatedBy,
        uint256 timestamp
    );
    
    /// @notice Emitted when price falls below floor and buyback is triggered
    event BuybackTriggered(
        uint256 currentPrice,
        uint256 priceFloor,
        uint256 amountBought,
        uint256 timestamp
    );
    
    /// @notice Emitted when tokens are burned to defend price floor
    event TokensBurned(
        uint256 amount,
        uint256 currentPrice,
        address indexed burner,
        uint256 timestamp
    );
    
    /// @notice Emitted when TRE funds are transferred to GGC
    event TreFundsTransferred(
        uint256 amount,
        address indexed recipient,
        uint256 timestamp
    );
    
    /// @notice Emitted when GGC Multisig address is updated
    event GgcMultisigUpdated(
        address indexed oldMultisig,
        address indexed newMultisig,
        uint256 timestamp
    );
    
    // ============ Modifiers ============
    
    /// @notice Restricts function access to GGC Multisig only
    modifier onlyGgcMultisig() {
        require(msg.sender == ggcMultisig, "ULP: Only GGC Multisig authorized");
        _;
    }
    
    /// @notice Validates that stabilization fee is within allowed range
    modifier validStabilizationFee(uint256 _fee) {
        require(_fee >= 5 && _fee <= 10, "ULP: Fee must be between 0.05% and 0.1%");
        _;
    }
    
    /// @notice Validates that TRE pledge rate is non-zero
    modifier validTrePledgeRate(uint256 _rate) {
        require(_rate > 0, "ULP: TRE pledge rate must be positive");
        _;
    }
    
    // ============ Constructor ============
    
    /**
     * @notice Initializes the Universal Liquidity Pool
     * @param _sainToken Address of the SAIN token contract
     * @param _stablecoin Address of the stablecoin contract (e.g., USDC)
     * @param _ggcMultisig Address of the GGC Multisig wallet (7/9)
     */
    constructor(
        address _sainToken,
        address _stablecoin,
        address _ggcMultisig
    ) {
        require(_sainToken != address(0), "ULP: Invalid SAIN token address");
        require(_stablecoin != address(0), "ULP: Invalid stablecoin address");
        require(_ggcMultisig != address(0), "ULP: Invalid GGC Multisig address");
        
        sainToken = _sainToken;
        stablecoin = _stablecoin;
        ggcMultisig = _ggcMultisig;
        
        // Initialize with default values
        stabilizationFee = 5; // 0.05% (5 basis points)
        trePledgeRate = 30;   // 0.3% (30 basis points)
        buybackActive = false;
    }
    
    // ============ Core AMM Functions ============
    
    /**
     * @notice Adds liquidity to the pool
     * @param sainAmount Amount of SAIN tokens to add
     * @param stablecoinAmount Amount of stablecoins to add
     * @dev Transfers tokens from msg.sender to this contract
     */
    function addLiquidity(uint256 sainAmount, uint256 stablecoinAmount) external {
        require(sainAmount > 0, "ULP: SAIN amount must be positive");
        require(stablecoinAmount > 0, "ULP: Stablecoin amount must be positive");
        
        // Update pool liquidity
        totalSainLiquidity += sainAmount;
        totalStablecoinLiquidity += stablecoinAmount;
        
        // Note: In production, this would use ERC20 transferFrom
        // For now, we emit the event for traceability
        
        emit LiquidityAdded(
            msg.sender,
            sainAmount,
            stablecoinAmount,
            block.timestamp
        );
    }
    
    /**
     * @notice Removes liquidity from the pool with stabilization fee
     * @param sainAmount Amount of SAIN tokens to remove
     * @param stablecoinAmount Amount of stablecoins to remove
     * @dev Applies stabilization fee to withdrawals
     */
    function removeLiquidity(uint256 sainAmount, uint256 stablecoinAmount) external {
        require(sainAmount > 0, "ULP: SAIN amount must be positive");
        require(stablecoinAmount > 0, "ULP: Stablecoin amount must be positive");
        require(sainAmount <= totalSainLiquidity, "ULP: Insufficient SAIN liquidity");
        require(stablecoinAmount <= totalStablecoinLiquidity, "ULP: Insufficient stablecoin liquidity");
        
        // Calculate stabilization fee
        uint256 feeAmount = (stablecoinAmount * stabilizationFee) / 10000;
        uint256 amountAfterFee = stablecoinAmount - feeAmount;
        
        // Update pool liquidity
        totalSainLiquidity -= sainAmount;
        totalStablecoinLiquidity -= stablecoinAmount;
        
        // Note: In production, this would use ERC20 transfer
        
        emit LiquidityRemoved(
            msg.sender,
            sainAmount,
            amountAfterFee,
            feeAmount,
            block.timestamp
        );
    }
    
    /**
     * @notice Swaps tokens in the pool
     * @param tokenIn Address of input token
     * @param amountIn Amount of input token
     * @param minAmountOut Minimum acceptable output amount (slippage protection)
     * @return amountOut Amount of output token received
     */
    function swap(
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut
    ) external returns (uint256 amountOut) {
        require(amountIn > 0, "ULP: Amount must be positive");
        require(
            tokenIn == sainToken || tokenIn == stablecoin,
            "ULP: Invalid token"
        );
        
        address tokenOut = tokenIn == sainToken ? stablecoin : sainToken;
        
        // Simplified AMM calculation (constant product formula)
        // In production, this would use a more sophisticated pricing mechanism
        if (tokenIn == sainToken) {
            amountOut = (amountIn * totalStablecoinLiquidity) / (totalSainLiquidity + amountIn);
            require(amountOut >= minAmountOut, "ULP: Insufficient output amount");
            totalSainLiquidity += amountIn;
            totalStablecoinLiquidity -= amountOut;
        } else {
            amountOut = (amountIn * totalSainLiquidity) / (totalStablecoinLiquidity + amountIn);
            require(amountOut >= minAmountOut, "ULP: Insufficient output amount");
            totalStablecoinLiquidity += amountIn;
            totalSainLiquidity -= amountOut;
        }
        
        // Calculate and collect TRE pledge
        uint256 trePledge = (amountOut * trePledgeRate) / 10000;
        totalTreFunds += trePledge;
        
        emit Swap(
            msg.sender,
            tokenIn,
            tokenOut,
            amountIn,
            amountOut,
            block.timestamp
        );
        
        return amountOut;
    }
    
    // ============ Price Floor Protection ============
    
    /**
     * @notice Gets the current SAIN token price in stablecoin
     * @return Current price (stablecoin per SAIN with 18 decimals)
     */
    function getCurrentPrice() public view returns (uint256) {
        if (totalSainLiquidity == 0) return 0;
        return (totalStablecoinLiquidity * 10**18) / totalSainLiquidity;
    }
    
    /**
     * @notice Checks if price is below minimum floor
     * @return True if price is below MIN_PRICE_FLOOR
     */
    function isPriceBelowFloor() public view returns (bool) {
        return getCurrentPrice() < MIN_PRICE_FLOOR;
    }
    
    /**
     * @notice Triggers buyback mechanism when price falls below floor
     * @param stablecoinAmount Amount of stablecoin to use for buyback
     * @dev Only callable by GGC Multisig; activates when price < MIN_PRICE_FLOOR
     */
    function triggerBuyback(uint256 stablecoinAmount) external onlyGgcMultisig {
        require(isPriceBelowFloor(), "ULP: Price is above floor");
        require(stablecoinAmount > 0, "ULP: Amount must be positive");
        require(stablecoinAmount <= totalStablecoinLiquidity, "ULP: Insufficient liquidity");
        
        uint256 currentPrice = getCurrentPrice();
        uint256 amountBought = (stablecoinAmount * 10**18) / currentPrice;
        
        // Update liquidity pools
        totalStablecoinLiquidity -= stablecoinAmount;
        totalSainLiquidity += amountBought;
        
        buybackActive = true;
        
        emit BuybackTriggered(
            currentPrice,
            MIN_PRICE_FLOOR,
            amountBought,
            block.timestamp
        );
    }
    
    /**
     * @notice Burns SAIN tokens to defend price floor
     * @param amount Amount of SAIN tokens to burn
     * @dev Only callable by GGC Multisig; used when price < MIN_PRICE_FLOOR
     */
    function burnTokens(uint256 amount) external onlyGgcMultisig {
        require(isPriceBelowFloor(), "ULP: Price is above floor");
        require(amount > 0, "ULP: Amount must be positive");
        require(amount <= totalSainLiquidity, "ULP: Insufficient liquidity");
        
        uint256 currentPrice = getCurrentPrice();
        
        // Reduce SAIN liquidity (simulates burning)
        totalSainLiquidity -= amount;
        
        emit TokensBurned(
            amount,
            currentPrice,
            msg.sender,
            block.timestamp
        );
    }
    
    // ============ Governance Functions ============
    
    /**
     * @notice Updates governance weights (stabilization fee and TRE pledge rate)
     * @param newStabilizationFee New stabilization fee (basis points)
     * @param newTrePledgeRate New TRE pledge rate (basis points)
     * @dev Only callable by GGC Multisig (7/9 authorization required)
     */
    function setGovernanceWeights(
        uint256 newStabilizationFee,
        uint256 newTrePledgeRate
    ) 
        external 
        onlyGgcMultisig
        validStabilizationFee(newStabilizationFee)
        validTrePledgeRate(newTrePledgeRate)
    {
        uint256 oldStabilizationFee = stabilizationFee;
        uint256 oldTrePledgeRate = trePledgeRate;
        
        stabilizationFee = newStabilizationFee;
        trePledgeRate = newTrePledgeRate;
        
        emit GovernanceWeightsUpdated(
            newStabilizationFee,
            newTrePledgeRate,
            msg.sender,
            block.timestamp
        );
        
        emit StabilizationFeeUpdated(
            oldStabilizationFee,
            newStabilizationFee,
            msg.sender,
            block.timestamp
        );
        
        emit TrePledgeRateUpdated(
            oldTrePledgeRate,
            newTrePledgeRate,
            msg.sender,
            block.timestamp
        );
    }
    
    /**
     * @notice Updates the stabilization fee
     * @param newFee New fee value (basis points: 5-10)
     * @dev Only callable by GGC Multisig; used by AIC to defend floor price
     */
    function setStabilizationFee(uint256 newFee) 
        external 
        onlyGgcMultisig
        validStabilizationFee(newFee)
    {
        uint256 oldFee = stabilizationFee;
        stabilizationFee = newFee;
        
        emit StabilizationFeeUpdated(
            oldFee,
            newFee,
            msg.sender,
            block.timestamp
        );
    }
    
    /**
     * @notice Updates the TRE pledge rate
     * @param newRate New rate value (basis points)
     * @dev Only callable by GGC Multisig
     */
    function setTrePledgeRate(uint256 newRate)
        external
        onlyGgcMultisig
        validTrePledgeRate(newRate)
    {
        uint256 oldRate = trePledgeRate;
        trePledgeRate = newRate;
        
        emit TrePledgeRateUpdated(
            oldRate,
            newRate,
            msg.sender,
            block.timestamp
        );
    }
    
    /**
     * @notice Updates the GGC Multisig address
     * @param newMultisig New GGC Multisig wallet address
     * @dev Only callable by current GGC Multisig
     */
    function setGgcMultisig(address newMultisig) external onlyGgcMultisig {
        require(newMultisig != address(0), "ULP: Invalid address");
        
        address oldMultisig = ggcMultisig;
        ggcMultisig = newMultisig;
        
        emit GgcMultisigUpdated(
            oldMultisig,
            newMultisig,
            block.timestamp
        );
    }
    
    // ============ TRE Fund Management ============
    
    /**
     * @notice Transfers accumulated TRE funds to GGC Restitution Fund
     * @param recipient Address to receive TRE funds
     * @param amount Amount of TRE funds to transfer
     * @dev Only callable by GGC Multisig
     */
    function transferTreFunds(address recipient, uint256 amount) 
        external 
        onlyGgcMultisig 
    {
        require(recipient != address(0), "ULP: Invalid recipient");
        require(amount > 0, "ULP: Amount must be positive");
        require(amount <= totalTreFunds, "ULP: Insufficient TRE funds");
        
        totalTreFunds -= amount;
        
        // Note: In production, this would use ERC20 transfer
        
        emit TreFundsTransferred(
            amount,
            recipient,
            block.timestamp
        );
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Gets the current liquidity pair configuration
     * @return sainTokenAddr SAIN token address
     * @return stablecoinAddr Stablecoin address
     */
    function getUlpPair() external view returns (
        address sainTokenAddr,
        address stablecoinAddr
    ) {
        return (sainToken, stablecoin);
    }
    
    /**
     * @notice Gets current pool parameters
     * @return currentStabilizationFee Current stabilization fee
     * @return currentTrePledgeRate Current TRE pledge rate
     * @return minPriceFloor Minimum price floor constant
     * @return currentPrice Current SAIN token price
     */
    function getPoolParameters() external view returns (
        uint256 currentStabilizationFee,
        uint256 currentTrePledgeRate,
        uint256 minPriceFloor,
        uint256 currentPrice
    ) {
        return (
            stabilizationFee,
            trePledgeRate,
            MIN_PRICE_FLOOR,
            getCurrentPrice()
        );
    }
    
    /**
     * @notice Gets pool liquidity information
     * @return sainLiq Total SAIN token liquidity
     * @return stablecoinLiq Total stablecoin liquidity
     * @return treFunds Total TRE funds collected
     */
    function getPoolLiquidity() external view returns (
        uint256 sainLiq,
        uint256 stablecoinLiq,
        uint256 treFunds
    ) {
        return (
            totalSainLiquidity,
            totalStablecoinLiquidity,
            totalTreFunds
        );
    }
    
    /**
     * @notice Gets governance configuration
     * @return multisig GGC Multisig address
     * @return requiredConfirmations Required confirmations (7)
     * @return totalSignersCount Total signers (9)
     */
    function getGovernanceConfig() external view returns (
        address multisig,
        uint256 requiredConfirmations,
        uint256 totalSignersCount
    ) {
        return (
            ggcMultisig,
            REQUIRED_CONFIRMATIONS,
            TOTAL_SIGNERS
        );
    }
}
