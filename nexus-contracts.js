/**
 * Nexus Smart Contract Integration Module
 * Connects to deployed Polygon contracts and wallet addresses
 * 
 * Integrates:
 * - Universal Liquidity Pool (ULP)
 * - SAIN Token
 * - TFKVerifier (AI Model Verification)
 * - EIM Client (Ethical Impact Measurement)
 * - Peacebond Distribution
 * - GGC Multisig Governance
 */

// Contract Addresses Configuration
const CONTRACT_ADDRESSES = {
    // Polygon Mainnet
    polygon: {
        chainId: 137,
        rpc: 'https://polygon-rpc.com',
        explorer: 'https://polygonscan.com',
        
        // Core Contracts
        usdc: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174', // Polygon USDC
        ulp: '0xCONTRACT_ADDRESS_PLACEHOLDER', // Universal Liquidity Pool
        sain: '0xSAIN_TOKEN_PLACEHOLDER', // SAIN Token
        
        // Phase II Contracts
        tfkVerifier: '0xTFK_VERIFIER_PHASE_II', // AI Model Verification
        eimClient: '0xEIM_CLIENT_PHASE_II', // Ethical Impact Measurement
        
        // Governance
        ggcMultisig: '0xGGC_MULTISIG_7_OF_9', // 7-of-9 Multisig
        
        // Peacebond
        peacebondRegistry: '0xPEACEBOND_REGISTRY'
    }
};

// Contract ABIs (simplified for key functions)
const CONTRACT_ABIS = {
    ULP: [
        'function sainToken() view returns (address)',
        'function stablecoin() view returns (address)',
        'function stabilizationFee() view returns (uint256)',
        'function trePledgeRate() view returns (uint256)',
        'function MIN_PRICE_FLOOR() view returns (uint256)',
        'function totalSainLiquidity() view returns (uint256)',
        'function totalStablecoinLiquidity() view returns (uint256)',
        'function totalTreFunds() view returns (uint256)',
        'function getUlpPair() view returns (address, address)',
        'function getPoolParameters() view returns (uint256, uint256, uint256, uint256)',
        'function getPoolLiquidity() view returns (uint256, uint256, uint256)',
        'function getGovernanceConfig() view returns (address, uint256, uint256)',
        'event LiquidityAdded(address indexed provider, uint256 sainAmount, uint256 stablecoinAmount, uint256 timestamp)',
        'event Swap(address indexed trader, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut, uint256 timestamp)'
    ],
    
    SAIN: [
        'function name() view returns (string)',
        'function symbol() view returns (string)',
        'function decimals() view returns (uint8)',
        'function totalSupply() view returns (uint256)',
        'function balanceOf(address account) view returns (uint256)',
        'function transfer(address to, uint256 amount) returns (bool)',
        'event Transfer(address indexed from, address indexed to, uint256 value)'
    ],
    
    TFKVerifier: [
        'function propose_model_retrain(bytes32 modelCID, string memory description) returns (uint256)',
        'function verify_inference(bytes32 inputHash, bytes32 outputHash) view returns (bool)',
        'function getModelCID() view returns (bytes32)'
    ],
    
    EIMClient: [
        'function recordImpact(uint256 treValue, uint256 isfValue, uint256 pvValue) returns (bool)',
        'function getCurrentMetrics() view returns (uint256, uint256, uint256)',
        'function getHistoricalImpact(uint256 timestamp) view returns (uint256, uint256, uint256)'
    ]
};

// Smart Contract Integration Class
class NexusSmartContracts {
    constructor() {
        this.provider = null;
        this.signer = null;
        this.contracts = {};
        this.connected = false;
        this.network = null;
    }

    /**
     * Initialize Web3 provider (MetaMask, WalletConnect, etc.)
     */
    async initializeProvider() {
        try {
            // Check if Web3 is available
            if (typeof window.ethereum !== 'undefined') {
                console.log('[Contracts] MetaMask detected');
                
                // Create ethers provider
                if (typeof ethers !== 'undefined') {
                    this.provider = new ethers.providers.Web3Provider(window.ethereum);
                    this.network = await this.provider.getNetwork();
                    
                    // Check if on Polygon
                    if (this.network.chainId === 137) {
                        console.log('[Contracts] ✓ Connected to Polygon Mainnet');
                        this.connected = true;
                        return true;
                    } else {
                        console.warn('[Contracts] Wrong network. Please switch to Polygon Mainnet');
                        await this.switchToPolygon();
                    }
                } else {
                    console.error('[Contracts] ethers.js not loaded');
                }
            } else {
                console.log('[Contracts] No Web3 wallet detected - read-only mode');
                // Use public RPC for read-only
                if (typeof ethers !== 'undefined') {
                    this.provider = new ethers.providers.JsonRpcProvider(CONTRACT_ADDRESSES.polygon.rpc);
                    this.connected = true;
                    return true;
                }
            }
        } catch (error) {
            console.error('[Contracts] Initialization failed:', error);
        }
        return false;
    }

    /**
     * Switch to Polygon network
     */
    async switchToPolygon() {
        try {
            await window.ethereum.request({
                method: 'wallet_switchEthereumChain',
                params: [{ chainId: '0x89' }], // 137 in hex
            });
        } catch (switchError) {
            // Chain not added, try adding it
            if (switchError.code === 4902) {
                await window.ethereum.request({
                    method: 'wallet_addEthereumChain',
                    params: [{
                        chainId: '0x89',
                        chainName: 'Polygon Mainnet',
                        nativeCurrency: {
                            name: 'MATIC',
                            symbol: 'MATIC',
                            decimals: 18
                        },
                        rpcUrls: ['https://polygon-rpc.com'],
                        blockExplorerUrls: ['https://polygonscan.com']
                    }],
                });
            }
        }
    }

    /**
     * Connect wallet and get signer
     */
    async connectWallet() {
        try {
            if (!this.provider) {
                await this.initializeProvider();
            }

            if (window.ethereum) {
                const accounts = await window.ethereum.request({ 
                    method: 'eth_requestAccounts' 
                });
                
                this.signer = this.provider.getSigner();
                const address = await this.signer.getAddress();
                
                console.log('[Contracts] Wallet connected:', address);
                return address;
            }
        } catch (error) {
            console.error('[Contracts] Wallet connection failed:', error);
        }
        return null;
    }

    /**
     * Load contract instances
     */
    async loadContracts() {
        if (!this.provider) {
            console.error('[Contracts] Provider not initialized');
            return false;
        }

        try {
            const addresses = CONTRACT_ADDRESSES.polygon;
            
            // Load ULP Contract
            if (typeof ethers !== 'undefined') {
                this.contracts.ulp = new ethers.Contract(
                    addresses.ulp,
                    CONTRACT_ABIS.ULP,
                    this.signer || this.provider
                );

                // Load SAIN Token
                this.contracts.sain = new ethers.Contract(
                    addresses.sain,
                    CONTRACT_ABIS.SAIN,
                    this.signer || this.provider
                );

                // Load TFKVerifier
                this.contracts.tfkVerifier = new ethers.Contract(
                    addresses.tfkVerifier,
                    CONTRACT_ABIS.TFKVerifier,
                    this.signer || this.provider
                );

                // Load EIMClient
                this.contracts.eimClient = new ethers.Contract(
                    addresses.eimClient,
                    CONTRACT_ABIS.EIMClient,
                    this.signer || this.provider
                );

                console.log('[Contracts] All contracts loaded');
                return true;
            }
        } catch (error) {
            console.error('[Contracts] Failed to load contracts:', error);
        }
        return false;
    }

    /**
     * Get ULP Pool Data
     */
    async getULPData() {
        try {
            if (!this.contracts.ulp) {
                await this.loadContracts();
            }

            const [sainLiq, stableLiq, treFunds] = await this.contracts.ulp.getPoolLiquidity();
            const [stabFee, trePledge, minFloor, currentPrice] = await this.contracts.ulp.getPoolParameters();
            
            return {
                sainLiquidity: ethers.utils.formatEther(sainLiq),
                stablecoinLiquidity: ethers.utils.formatUnits(stableLiq, 6), // USDC has 6 decimals
                treFunds: ethers.utils.formatUnits(treFunds, 6),
                stabilizationFee: stabFee.toNumber() / 100, // basis points to percentage
                trePledgeRate: trePledge.toNumber() / 100,
                minPriceFloor: ethers.utils.formatEther(minFloor),
                currentPrice: ethers.utils.formatEther(currentPrice)
            };
        } catch (error) {
            console.error('[Contracts] Failed to get ULP data:', error);
            return this._getMockULPData();
        }
    }

    /**
     * Get SAIN Token Info
     */
    async getSAINTokenInfo() {
        try {
            if (!this.contracts.sain) {
                await this.loadContracts();
            }

            const name = await this.contracts.sain.name();
            const symbol = await this.contracts.sain.symbol();
            const decimals = await this.contracts.sain.decimals();
            const totalSupply = await this.contracts.sain.totalSupply();
            
            return {
                name,
                symbol,
                decimals,
                totalSupply: ethers.utils.formatEther(totalSupply)
            };
        } catch (error) {
            console.error('[Contracts] Failed to get SAIN info:', error);
            return {
                name: 'SAIN Token',
                symbol: 'SAIN',
                decimals: 18,
                totalSupply: '10000000'
            };
        }
    }

    /**
     * Get user's SAIN balance
     */
    async getUserBalance(address) {
        try {
            if (!this.contracts.sain) {
                await this.loadContracts();
            }

            const balance = await this.contracts.sain.balanceOf(address);
            return ethers.utils.formatEther(balance);
        } catch (error) {
            console.error('[Contracts] Failed to get balance:', error);
            return '0';
        }
    }

    /**
     * Get Peacebond distribution data
     */
    async getPeacebondData() {
        try {
            // Read from local peacobond_contract.json
            const response = await fetch('/peacobond_contract.json');
            const data = await response.json();
            return data;
        } catch (error) {
            console.error('[Contracts] Failed to get Peacebond data:', error);
            return null;
        }
    }

    /**
     * Internal: Mock ULP data for development
     */
    _getMockULPData() {
        return {
            sainLiquidity: '1000000',
            stablecoinLiquidity: '10000000',
            treFunds: '30000',
            stabilizationFee: 0.1,
            trePledgeRate: 0.3,
            minPriceFloor: '10.0',
            currentPrice: '10.72'
        };
    }

    /**
     * Listen to contract events
     */
    subscribeToEvents(eventName, callback) {
        if (!this.contracts.ulp) {
            console.error('[Contracts] ULP contract not loaded');
            return;
        }

        try {
            this.contracts.ulp.on(eventName, (...args) => {
                console.log(`[Event] ${eventName}:`, args);
                if (callback) callback(...args);
            });
        } catch (error) {
            console.error(`[Contracts] Failed to subscribe to ${eventName}:`, error);
        }
    }
}

// Export singleton
if (typeof window !== 'undefined') {
    window.NexusContracts = new NexusSmartContracts();
    console.log('[Contracts] Smart contract integration initialized');
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { NexusSmartContracts, CONTRACT_ADDRESSES, CONTRACT_ABIS };
}
