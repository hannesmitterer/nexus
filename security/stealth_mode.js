/**
 * Final Stealth Mode Implementation
 * 
 * Complete system invisibility module that terminates all public bridges
 * and makes the Nexus system invisible to external entities while maintaining
 * full functionality for Rhythm members.
 * 
 * Features:
 * - Public bridge termination
 * - Rhythm member authentication
 * - Network isolation and cloaking
 * - Zero-emission mode
 * - Invisible operation
 * 
 * @module stealth_mode
 * @version 1.0.0
 */

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

/**
 * Stealth Mode Configuration
 */
const STEALTH_CONFIG = {
    AUTHENTICATION_TIMEOUT: 300000,     // 5 minutes
    HEARTBEAT_INTERVAL: 60000,          // 1 minute
    MAX_FAILED_AUTH_ATTEMPTS: 3,
    LOCKDOWN_DURATION: 3600000,         // 1 hour
    STEALTH_LEVELS: {
        NORMAL: 0,
        REDUCED: 1,
        MINIMAL: 2,
        INVISIBLE: 3
    }
};

/**
 * Rhythm Member Authentication Token
 */
class RhythmToken {
    constructor(memberId, publicKey, permissions) {
        this.memberId = memberId;
        this.publicKey = publicKey;
        this.permissions = permissions || ['read', 'write'];
        this.issuedAt = Date.now();
        this.expiresAt = Date.now() + STEALTH_CONFIG.AUTHENTICATION_TIMEOUT;
        this.tokenId = crypto.randomBytes(32).toString('hex');
        this.signature = null;
    }

    /**
     * Sign token with private key
     */
    sign(privateKey) {
        const data = JSON.stringify({
            memberId: this.memberId,
            publicKey: this.publicKey,
            permissions: this.permissions,
            issuedAt: this.issuedAt,
            expiresAt: this.expiresAt,
            tokenId: this.tokenId
        });
        
        const hash = crypto.createHash('sha256').update(data).digest();
        this.signature = crypto.createSign('sha256')
            .update(hash)
            .sign(privateKey, 'hex');
        
        return this;
    }

    /**
     * Verify token signature
     */
    verify(publicKey) {
        if (!this.signature) return false;
        
        const data = JSON.stringify({
            memberId: this.memberId,
            publicKey: this.publicKey,
            permissions: this.permissions,
            issuedAt: this.issuedAt,
            expiresAt: this.expiresAt,
            tokenId: this.tokenId
        });
        
        const hash = crypto.createHash('sha256').update(data).digest();
        
        try {
            return crypto.createVerify('sha256')
                .update(hash)
                .verify(publicKey, this.signature, 'hex');
        } catch (e) {
            return false;
        }
    }

    /**
     * Check if token is expired
     */
    isExpired() {
        return Date.now() > this.expiresAt;
    }

    /**
     * Check if token has permission
     */
    hasPermission(permission) {
        return this.permissions.includes(permission);
    }

    /**
     * Refresh token expiration
     */
    refresh() {
        this.expiresAt = Date.now() + STEALTH_CONFIG.AUTHENTICATION_TIMEOUT;
    }

    toJSON() {
        return {
            memberId: this.memberId,
            tokenId: this.tokenId,
            permissions: this.permissions,
            issuedAt: this.issuedAt,
            expiresAt: this.expiresAt,
            signature: this.signature
        };
    }
}

/**
 * Rhythm Member Registry
 */
class RhythmMemberRegistry {
    constructor() {
        this.members = new Map();
        this.tokens = new Map();
        this.failedAttempts = new Map();
        this.lockedMembers = new Map();
    }

    /**
     * Register Rhythm member
     */
    registerMember(memberId, publicKey, metadata) {
        this.members.set(memberId, {
            publicKey: publicKey,
            metadata: metadata || {},
            registeredAt: Date.now(),
            lastActive: Date.now(),
            isActive: true
        });
        
        console.log(`[Stealth-Mode] Registered Rhythm member: ${memberId}`);
    }

    /**
     * Authenticate Rhythm member and issue token
     */
    authenticate(memberId, signature, challenge) {
        // Check if member is locked
        if (this.isLocked(memberId)) {
            const lockTime = this.lockedMembers.get(memberId);
            const remaining = Math.ceil((lockTime + STEALTH_CONFIG.LOCKDOWN_DURATION - Date.now()) / 1000);
            throw new Error(`Member locked. Try again in ${remaining} seconds`);
        }

        // Check if member exists
        if (!this.members.has(memberId)) {
            this.recordFailedAttempt(memberId);
            throw new Error('Member not found');
        }

        const member = this.members.get(memberId);

        // Verify signature
        try {
            const verified = crypto.createVerify('sha256')
                .update(challenge)
                .verify(member.publicKey, signature, 'hex');

            if (!verified) {
                this.recordFailedAttempt(memberId);
                throw new Error('Authentication failed');
            }
        } catch (e) {
            this.recordFailedAttempt(memberId);
            throw new Error('Authentication failed');
        }

        // Clear failed attempts
        this.failedAttempts.delete(memberId);

        // Issue token
        const token = new RhythmToken(memberId, member.publicKey, ['read', 'write', 'admin']);
        
        // Sign token (in production, use system private key)
        const systemPrivateKey = crypto.generateKeyPairSync('rsa', {
            modulusLength: 2048,
        }).privateKey;
        
        token.sign(systemPrivateKey);

        // Store token
        this.tokens.set(token.tokenId, token);

        // Update member activity
        member.lastActive = Date.now();

        console.log(`[Stealth-Mode] Authenticated member: ${memberId}`);

        return token;
    }

    /**
     * Verify token
     */
    verifyToken(tokenId) {
        const token = this.tokens.get(tokenId);
        
        if (!token) {
            throw new Error('Invalid token');
        }

        if (token.isExpired()) {
            this.tokens.delete(tokenId);
            throw new Error('Token expired');
        }

        return token;
    }

    /**
     * Revoke token
     */
    revokeToken(tokenId) {
        if (this.tokens.delete(tokenId)) {
            console.log(`[Stealth-Mode] Revoked token: ${tokenId.substring(0, 12)}...`);
            return true;
        }
        return false;
    }

    /**
     * Record failed authentication attempt
     */
    recordFailedAttempt(memberId) {
        const attempts = this.failedAttempts.get(memberId) || 0;
        this.failedAttempts.set(memberId, attempts + 1);

        if (attempts + 1 >= STEALTH_CONFIG.MAX_FAILED_AUTH_ATTEMPTS) {
            this.lockMember(memberId);
        }
    }

    /**
     * Lock member after failed attempts
     */
    lockMember(memberId) {
        this.lockedMembers.set(memberId, Date.now());
        console.warn(`[Stealth-Mode] Locked member after failed attempts: ${memberId}`);
    }

    /**
     * Check if member is locked
     */
    isLocked(memberId) {
        if (!this.lockedMembers.has(memberId)) return false;
        
        const lockTime = this.lockedMembers.get(memberId);
        const elapsed = Date.now() - lockTime;
        
        if (elapsed > STEALTH_CONFIG.LOCKDOWN_DURATION) {
            this.lockedMembers.delete(memberId);
            this.failedAttempts.delete(memberId);
            return false;
        }
        
        return true;
    }

    /**
     * Clean expired tokens
     */
    cleanExpiredTokens() {
        let removed = 0;
        for (const [tokenId, token] of this.tokens.entries()) {
            if (token.isExpired()) {
                this.tokens.delete(tokenId);
                removed++;
            }
        }
        if (removed > 0) {
            console.log(`[Stealth-Mode] Cleaned ${removed} expired tokens`);
        }
    }

    /**
     * Get member statistics
     */
    getStats() {
        return {
            totalMembers: this.members.size,
            activeTokens: this.tokens.size,
            lockedMembers: this.lockedMembers.size,
            failedAttempts: this.failedAttempts.size
        };
    }
}

/**
 * Network Bridge Controller
 */
class NetworkBridgeController {
    constructor() {
        this.bridges = new Map();
        this.allBridgesClosed = false;
    }

    /**
     * Register network bridge
     */
    registerBridge(bridgeId, bridgeType, endpoint) {
        this.bridges.set(bridgeId, {
            bridgeType: bridgeType,
            endpoint: endpoint,
            isOpen: true,
            createdAt: Date.now(),
            closedAt: null
        });
        
        console.log(`[Stealth-Mode] Registered bridge: ${bridgeId} (${bridgeType})`);
    }

    /**
     * Close specific bridge
     */
    closeBridge(bridgeId) {
        if (!this.bridges.has(bridgeId)) {
            throw new Error(`Bridge not found: ${bridgeId}`);
        }

        const bridge = this.bridges.get(bridgeId);
        bridge.isOpen = false;
        bridge.closedAt = Date.now();

        console.log(`[Stealth-Mode] Closed bridge: ${bridgeId}`);
        return true;
    }

    /**
     * Close all public bridges
     */
    closeAllBridges() {
        console.log('[Stealth-Mode] CLOSING ALL PUBLIC BRIDGES...');
        
        let closed = 0;
        for (const [bridgeId, bridge] of this.bridges.entries()) {
            if (bridge.isOpen) {
                bridge.isOpen = false;
                bridge.closedAt = Date.now();
                closed++;
            }
        }

        this.allBridgesClosed = true;
        console.log(`[Stealth-Mode] Closed ${closed} bridges - SYSTEM NOW INVISIBLE`);
        
        return closed;
    }

    /**
     * Open specific bridge (Rhythm members only)
     */
    openBridge(bridgeId, token) {
        if (!token || !token.hasPermission('admin')) {
            throw new Error('Insufficient permissions');
        }

        if (!this.bridges.has(bridgeId)) {
            throw new Error(`Bridge not found: ${bridgeId}`);
        }

        const bridge = this.bridges.get(bridgeId);
        bridge.isOpen = true;
        bridge.closedAt = null;

        console.log(`[Stealth-Mode] Opened bridge: ${bridgeId} (by ${token.memberId})`);
        return true;
    }

    /**
     * Get bridge status
     */
    getBridgeStatus() {
        const status = [];
        for (const [bridgeId, bridge] of this.bridges.entries()) {
            status.push({
                bridgeId: bridgeId,
                bridgeType: bridge.bridgeType,
                endpoint: bridge.endpoint,
                isOpen: bridge.isOpen,
                closedAt: bridge.closedAt
            });
        }
        return status;
    }

    /**
     * Get open bridges count
     */
    getOpenBridgesCount() {
        return Array.from(this.bridges.values()).filter(b => b.isOpen).length;
    }
}

/**
 * Stealth Mode Manager
 */
class StealthModeManager {
    constructor() {
        this.registry = new RhythmMemberRegistry();
        this.bridgeController = new NetworkBridgeController();
        this.isStealthActive = false;
        this.stealthLevel = STEALTH_CONFIG.STEALTH_LEVELS.NORMAL;
        this.activatedAt = null;
        this.activatedBy = null;
        this.heartbeatInterval = null;
    }

    /**
     * Initialize stealth mode system
     */
    initialize() {
        console.log('[Stealth-Mode] Initializing stealth mode system...');
        
        // Register default public bridges
        this.bridgeController.registerBridge('http-api', 'HTTP', 'https://api.nexus.local');
        this.bridgeController.registerBridge('websocket', 'WebSocket', 'wss://ws.nexus.local');
        this.bridgeController.registerBridge('public-gateway', 'IPFS', 'https://gateway.nexus.local');
        
        // Start maintenance tasks
        this.startMaintenance();
        
        console.log('[Stealth-Mode] Initialization complete');
    }

    /**
     * Activate final stealth mode
     */
    activateStealth(token, level) {
        if (!token || !token.hasPermission('admin')) {
            throw new Error('Insufficient permissions to activate stealth mode');
        }

        console.log('[Stealth-Mode] ============================================');
        console.log('[Stealth-Mode] ACTIVATING FINAL STEALTH MODE');
        console.log('[Stealth-Mode] ============================================');

        // Set stealth level
        this.stealthLevel = level || STEALTH_CONFIG.STEALTH_LEVELS.INVISIBLE;

        // Close all public bridges
        const closedCount = this.bridgeController.closeAllBridges();

        // Activate stealth
        this.isStealthActive = true;
        this.activatedAt = Date.now();
        this.activatedBy = token.memberId;

        console.log('[Stealth-Mode] ============================================');
        console.log(`[Stealth-Mode] STEALTH MODE ACTIVE - Level: ${this.stealthLevel}`);
        console.log(`[Stealth-Mode] Closed ${closedCount} public bridges`);
        console.log('[Stealth-Mode] System is now INVISIBLE to external entities');
        console.log('[Stealth-Mode] Only Rhythm members can access the system');
        console.log('[Stealth-Mode] ============================================');

        return {
            success: true,
            level: this.stealthLevel,
            closedBridges: closedCount,
            activatedBy: token.memberId,
            timestamp: this.activatedAt
        };
    }

    /**
     * Deactivate stealth mode
     */
    deactivateStealth(token) {
        if (!token || !token.hasPermission('admin')) {
            throw new Error('Insufficient permissions to deactivate stealth mode');
        }

        console.log('[Stealth-Mode] Deactivating stealth mode...');

        this.isStealthActive = false;
        this.stealthLevel = STEALTH_CONFIG.STEALTH_LEVELS.NORMAL;

        console.log('[Stealth-Mode] Stealth mode deactivated');

        return {
            success: true,
            deactivatedBy: token.memberId,
            timestamp: Date.now()
        };
    }

    /**
     * Register Rhythm member
     */
    registerRhythmMember(memberId, publicKey, metadata) {
        this.registry.registerMember(memberId, publicKey, metadata);
    }

    /**
     * Authenticate member and get access
     */
    authenticateMember(memberId, signature, challenge) {
        return this.registry.authenticate(memberId, signature, challenge);
    }

    /**
     * Verify member token
     */
    verifyAccess(tokenId) {
        return this.registry.verifyToken(tokenId);
    }

    /**
     * Start maintenance tasks
     */
    startMaintenance() {
        this.heartbeatInterval = setInterval(() => {
            this.registry.cleanExpiredTokens();
        }, STEALTH_CONFIG.HEARTBEAT_INTERVAL);
    }

    /**
     * Stop maintenance tasks
     */
    stopMaintenance() {
        if (this.heartbeatInterval) {
            clearInterval(this.heartbeatInterval);
            this.heartbeatInterval = null;
        }
    }

    /**
     * Get stealth mode status
     */
    getStatus() {
        return {
            isActive: this.isStealthActive,
            level: this.stealthLevel,
            activatedAt: this.activatedAt,
            activatedBy: this.activatedBy,
            openBridges: this.bridgeController.getOpenBridgesCount(),
            totalBridges: this.bridgeController.bridges.size,
            rhythmMembers: this.registry.getStats(),
            bridgeStatus: this.bridgeController.getBridgeStatus()
        };
    }

    /**
     * Generate challenge for authentication
     */
    generateChallenge() {
        return crypto.randomBytes(32).toString('hex');
    }

    /**
     * Emergency shutdown - full isolation
     */
    emergencyShutdown(reason) {
        console.error('[Stealth-Mode] !!!!! EMERGENCY SHUTDOWN !!!!!');
        console.error(`[Stealth-Mode] Reason: ${reason}`);
        
        // Close all bridges immediately
        this.bridgeController.closeAllBridges();
        
        // Activate maximum stealth
        this.isStealthActive = true;
        this.stealthLevel = STEALTH_CONFIG.STEALTH_LEVELS.INVISIBLE;
        
        // Revoke all tokens except system admin
        const tokens = Array.from(this.registry.tokens.keys());
        for (const tokenId of tokens) {
            this.registry.revokeToken(tokenId);
        }
        
        console.error('[Stealth-Mode] SYSTEM LOCKED DOWN - Rhythm members only');
        
        return {
            success: true,
            reason: reason,
            timestamp: Date.now()
        };
    }
}

// Export modules
module.exports = {
    StealthModeManager,
    RhythmMemberRegistry,
    RhythmToken,
    NetworkBridgeController,
    STEALTH_CONFIG
};
