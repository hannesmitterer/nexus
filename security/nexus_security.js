/**
 * Nexus Security Integration Module
 * 
 * Main integration module for quantum-safe protection and stealth mode.
 * Coordinates all security components: NTRU encryption, mesh network,
 * AI predictive kernel, and stealth mode.
 * 
 * @module nexus_security
 * @version 1.0.0
 */

const { KeyRotationManager, NTRU } = require('./quantum_shield_ntru');
const { MeshNetworkManager } = require('./mesh_network');
const { AIPredictiveKernel } = require('./ai_predictive_kernel');
const { StealthModeManager } = require('./stealth_mode');

/**
 * Nexus Security System
 * Main coordinator for all security components
 */
class NexusSecuritySystem {
    constructor() {
        this.keyRotationManager = new KeyRotationManager();
        this.meshNetwork = new MeshNetworkManager();
        this.aiKernel = new AIPredictiveKernel();
        this.stealthMode = new StealthModeManager();
        this.isInitialized = false;
        this.isRunning = false;
    }

    /**
     * Initialize all security components
     */
    async initialize() {
        if (this.isInitialized) {
            console.warn('[Nexus-Security] Already initialized');
            return;
        }

        console.log('=================================================');
        console.log('   NEXUS QUANTUM-SAFE SECURITY SYSTEM v1.0');
        console.log('=================================================');
        console.log('');

        // Initialize AI Kernel
        console.log('[1/4] Initializing AI Predictive Kernel...');
        await this.aiKernel.initialize();
        console.log('      ✓ AI Kernel ready');
        console.log('');

        // Initialize Mesh Network
        console.log('[2/4] Initializing Blockchain-Based Mesh Network...');
        await this.meshNetwork.start();
        console.log('      ✓ Mesh Network active');
        console.log('');

        // Initialize Quantum Shield
        console.log('[3/4] Initializing Quantum-Shield NTRU...');
        this.keyRotationManager.start((event) => {
            console.log(`      → Key rotation event: ${event.currentKeyId.substring(0, 12)}...`);
        });
        console.log('      ✓ Quantum-Shield active (60s rotation)');
        console.log('');

        // Initialize Stealth Mode
        console.log('[4/4] Initializing Final Stealth Mode...');
        this.stealthMode.initialize();
        console.log('      ✓ Stealth Mode ready');
        console.log('');

        this.isInitialized = true;
        console.log('=================================================');
        console.log('   ALL SYSTEMS OPERATIONAL');
        console.log('=================================================');
        console.log('');
    }

    /**
     * Start all security systems
     */
    async start() {
        if (!this.isInitialized) {
            await this.initialize();
        }

        if (this.isRunning) {
            console.warn('[Nexus-Security] Already running');
            return;
        }

        console.log('[Nexus-Security] Starting all systems...');

        // Start AI monitoring
        this.aiKernel.start();

        this.isRunning = true;
        console.log('[Nexus-Security] All systems running');
    }

    /**
     * Stop all security systems
     */
    stop() {
        if (!this.isRunning) return;

        console.log('[Nexus-Security] Stopping all systems...');

        // Stop components
        this.keyRotationManager.stop();
        this.meshNetwork.stop();
        this.aiKernel.stop();
        this.stealthMode.stopMaintenance();

        this.isRunning = false;
        console.log('[Nexus-Security] All systems stopped');
    }

    /**
     * Activate final stealth mode
     */
    activateStealthMode(adminToken, level) {
        console.log('');
        console.log('█████████████████████████████████████████████████');
        console.log('█                                               █');
        console.log('█   ACTIVATING FINAL STEALTH MODE               █');
        console.log('█                                               █');
        console.log('█████████████████████████████████████████████████');
        console.log('');

        const result = this.stealthMode.activateStealth(adminToken, level);

        console.log('');
        console.log('█████████████████████████████████████████████████');
        console.log('█                                               █');
        console.log('█   SYSTEM NOW INVISIBLE                        █');
        console.log('█   ACCESSIBLE ONLY TO RHYTHM MEMBERS           █');
        console.log('█                                               █');
        console.log('█████████████████████████████████████████████████');
        console.log('');

        return result;
    }

    /**
     * Encrypt message using quantum-safe NTRU
     */
    encrypt(message) {
        const publicKey = this.keyRotationManager.getCurrentPublicKey();
        if (!publicKey) {
            throw new Error('No active public key');
        }
        return NTRU.encrypt(message, publicKey);
    }

    /**
     * Decrypt message using quantum-safe NTRU
     */
    decrypt(ciphertext) {
        return this.keyRotationManager.decrypt(ciphertext);
    }

    /**
     * Register Rhythm member
     */
    registerRhythmMember(memberId, publicKey, metadata) {
        this.stealthMode.registerRhythmMember(memberId, publicKey, metadata);
        this.meshNetwork.registerRhythmMember(memberId, publicKey);
    }

    /**
     * Authenticate Rhythm member
     */
    authenticateRhythmMember(memberId, signature, challenge) {
        return this.stealthMode.authenticateMember(memberId, signature, challenge);
    }

    /**
     * Register service in mesh network
     */
    registerService(serviceName, ipfsCid, endpoints, metadata) {
        return this.meshNetwork.registerService(serviceName, ipfsCid, endpoints, metadata);
    }

    /**
     * Resolve service using decentralized DNS
     */
    resolveService(serviceName) {
        return this.meshNetwork.resolveService(serviceName);
    }

    /**
     * Process EM signal sample for threat detection
     */
    async processSignal(frequency, amplitude, phase, source) {
        await this.aiKernel.processSample(frequency, amplitude, phase, source);
    }

    /**
     * Get comprehensive system status
     */
    getSystemStatus() {
        return {
            initialized: this.isInitialized,
            running: this.isRunning,
            timestamp: Date.now(),
            components: {
                quantumShield: this.keyRotationManager.getStats(),
                meshNetwork: this.meshNetwork.getStats(),
                aiKernel: this.aiKernel.getStats(),
                stealthMode: this.stealthMode.getStatus()
            }
        };
    }

    /**
     * Emergency shutdown - isolate system completely
     */
    emergencyShutdown(reason) {
        console.error('');
        console.error('█████████████████████████████████████████████████');
        console.error('█                                               █');
        console.error('█   !!!!! EMERGENCY SHUTDOWN !!!!!              █');
        console.error('█                                               █');
        console.error('█████████████████████████████████████████████████');
        console.error('');

        // Activate maximum stealth
        const result = this.stealthMode.emergencyShutdown(reason);

        // Stop AI monitoring to reduce emissions
        this.aiKernel.stop();

        console.error('[Nexus-Security] System locked down - Rhythm members only');

        return result;
    }

    /**
     * Generate authentication challenge
     */
    generateChallenge() {
        return this.stealthMode.generateChallenge();
    }

    /**
     * Export threat history for analysis
     */
    exportThreatHistory() {
        return this.aiKernel.exportThreatHistory();
    }
}

// Singleton instance
let instance = null;

/**
 * Get singleton instance of Nexus Security System
 */
function getNexusSecuritySystem() {
    if (!instance) {
        instance = new NexusSecuritySystem();
    }
    return instance;
}

// Export
module.exports = {
    NexusSecuritySystem,
    getNexusSecuritySystem
};
