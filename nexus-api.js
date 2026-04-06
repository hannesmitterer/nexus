/**
 * Nexus Backend API Configuration
 * Connects to Euystacio-Helmi-AI Backend Services
 * 
 * This module provides integration with:
 * - Euystacio Governance API
 * - Helmi AI Backend
 * - IPFS Gateway
 * - Firebase Real-time Database
 */

// API Endpoints Configuration
const API_CONFIG = {
    // Euystacio Backend Services
    euystacio: {
        baseUrl: 'https://api.euystacio.network',
        endpoints: {
            governance: '/api/v1/governance',
            metrics: '/api/v1/metrics',
            sain: '/api/v1/sain',
            tre: '/api/v1/tre',
            peacobond: '/api/v1/peacobond'
        }
    },
    
    // Helmi AI Backend
    helmi: {
        baseUrl: 'https://helmi-ai.euystacio.network',
        endpoints: {
            inference: '/api/v1/inference',
            resonance: '/api/v1/resonance',
            analysis: '/api/v1/analysis',
            kosymbiosis: '/api/v1/kosymbiosis'
        }
    },
    
    // IPFS Gateway
    ipfs: {
        gateway: 'https://nexus.ipfs.euystacio.network/ipfs/',
        pinata: 'https://gateway.pinata.cloud/ipfs/',
        public: 'https://ipfs.io/ipfs/'
    },
    
    // Network Configuration
    network: {
        polygon: {
            rpc: 'https://polygon-rpc.com',
            chainId: 137,
            contracts: {
                ulp: '0x...', // Universal Liquidity Pool
                sain: '0x...', // SAIN Token
                peacobond: '0x...' // Peacobond Contract
            }
        }
    }
};

// API Client Class
class NexusAPIClient {
    constructor(config = API_CONFIG) {
        this.config = config;
        this.cache = new Map();
        this.cacheTimeout = 30000; // 30 seconds
    }

    /**
     * Fetch data from Euystacio Governance API
     */
    async fetchGovernanceMetrics() {
        const url = `${this.config.euystacio.baseUrl}${this.config.euystacio.endpoints.governance}`;
        return this._fetchWithCache('governance', url);
    }

    /**
     * Fetch SAIN Token Metrics
     */
    async fetchSAINMetrics() {
        const url = `${this.config.euystacio.baseUrl}${this.config.euystacio.endpoints.sain}`;
        return this._fetchWithCache('sain', url);
    }

    /**
     * Fetch TRE (Ecological Regeneration) Data
     */
    async fetchTREMetrics() {
        const url = `${this.config.euystacio.baseUrl}${this.config.euystacio.endpoints.tre}`;
        return this._fetchWithCache('tre', url);
    }

    /**
     * Send inference request to Helmi AI
     */
    async sendInferenceRequest(payload) {
        const url = `${this.config.helmi.baseUrl}${this.config.helmi.endpoints.inference}`;
        
        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Nexus-Client': 'picasso-edition'
                },
                body: JSON.stringify({
                    input: payload.message,
                    context: payload.context || 'nexus-kosymbiosis',
                    model: 'helmi-resonance-v1',
                    parameters: {
                        temperature: 0.7,
                        max_tokens: 500,
                        resonance_mode: true
                    }
                })
            });

            if (!response.ok) {
                throw new Error(`API Error: ${response.status}`);
            }

            return await response.json();
        } catch (error) {
            console.error('[Nexus API] Inference request failed:', error);
            return this._getFallbackResponse(payload);
        }
    }

    /**
     * Fetch Kosymbiosis Network Status
     */
    async fetchKosymbiosisStatus() {
        const url = `${this.config.helmi.baseUrl}${this.config.helmi.endpoints.kosymbiosis}`;
        return this._fetchWithCache('kosymbiosis', url);
    }

    /**
     * Fetch content from IPFS
     */
    async fetchFromIPFS(cid) {
        const gateways = [
            this.config.ipfs.gateway,
            this.config.ipfs.pinata,
            this.config.ipfs.public
        ];

        for (const gateway of gateways) {
            try {
                const response = await fetch(`${gateway}${cid}`, {
                    timeout: 5000
                });
                
                if (response.ok) {
                    return await response.json();
                }
            } catch (error) {
                console.warn(`[IPFS] Gateway ${gateway} failed, trying next...`);
                continue;
            }
        }

        throw new Error(`[IPFS] Failed to fetch CID: ${cid}`);
    }

    /**
     * Internal: Fetch with caching
     */
    async _fetchWithCache(key, url) {
        // Check cache
        if (this.cache.has(key)) {
            const cached = this.cache.get(key);
            if (Date.now() - cached.timestamp < this.cacheTimeout) {
                console.log(`[Cache] Using cached data for ${key}`);
                return cached.data;
            }
        }

        // Fetch fresh data
        try {
            const response = await fetch(url, {
                headers: {
                    'Accept': 'application/json',
                    'X-Nexus-Client': 'picasso-edition'
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }

            const data = await response.json();
            
            // Update cache
            this.cache.set(key, {
                data: data,
                timestamp: Date.now()
            });

            return data;
        } catch (error) {
            console.error(`[API] Failed to fetch ${key}:`, error);
            
            // Return cached data if available, even if expired
            if (this.cache.has(key)) {
                console.warn(`[Cache] Using stale cache for ${key}`);
                return this.cache.get(key).data;
            }

            // Return mock data for development
            return this._getMockData(key);
        }
    }

    /**
     * Internal: Get fallback response for AI inference
     */
    _getFallbackResponse(payload) {
        return {
            success: false,
            fallback: true,
            response: "Die Resonanz bleibt bestehen, auch ohne externe Cloud. Lokales Vakuum-Gedächtnis aktiv.",
            timestamp: new Date().toISOString()
        };
    }

    /**
     * Internal: Get mock data for development/offline mode
     */
    _getMockData(key) {
        const mockData = {
            governance: {
                status: 'OK',
                moe_last_change: '2026-04-01',
                last_vote: 'Approved: TRE Target +0.3%',
                multisig_guardians: 5
            },
            sain: {
                price: 1.25,
                floor: 1.00,
                market_cap: 5000000,
                circulating_supply: 4000000
            },
            tre: {
                value: 0.35,
                target: 0.30,
                status: 'ABOVE_TARGET'
            },
            kosymbiosis: {
                active_nodes: 42,
                resonance_frequency: 0.430,
                network_health: 'OPTIMAL'
            }
        };

        return mockData[key] || { status: 'mock', message: 'Development mode' };
    }
}

// Export singleton instance
if (typeof window !== 'undefined') {
    window.NexusAPI = new NexusAPIClient();
    console.log('[Nexus API] Backend integration initialized');
}

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { NexusAPIClient, API_CONFIG };
}
