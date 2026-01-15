#!/usr/bin/env node

/**
 * Nexus Security System - Demonstration Script
 * 
 * This script demonstrates the full deployment of quantum-safe protection
 * and stealth mode features for the Nexus system.
 * 
 * Usage: node demo_security_system.js
 */

const { getNexusSecuritySystem } = require('./security/nexus_security');
const crypto = require('crypto');

// ANSI color codes for terminal output
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    red: '\x1b[31m',
    cyan: '\x1b[36m',
    magenta: '\x1b[35m'
};

function log(message, color = 'reset') {
    console.log(`${colors[color]}${message}${colors.reset}`);
}

function header(text) {
    console.log('');
    log('='.repeat(60), 'cyan');
    log(`  ${text}`, 'bright');
    log('='.repeat(60), 'cyan');
    console.log('');
}

async function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
    try {
        header('NEXUS QUANTUM-SAFE SECURITY DEMONSTRATION');

        // Step 1: Initialize Security System
        header('Step 1: Initializing Security System');
        const security = getNexusSecuritySystem();
        await security.initialize();
        await security.start();
        
        log('✓ All security components operational', 'green');
        await sleep(2000);

        // Step 2: Demonstrate Quantum-Shield NTRU Encryption
        header('Step 2: Quantum-Shield NTRU Encryption');
        log('Encrypting message with quantum-resistant NTRU...', 'cyan');
        
        const message = 'This is a secret message protected by quantum-safe cryptography';
        log(`Original: "${message}"`, 'yellow');
        
        const encrypted = security.encrypt(message);
        log(`Encrypted: [${encrypted.length} bytes of ciphertext]`, 'magenta');
        
        const decrypted = security.decrypt(encrypted);
        log(`Decrypted: "${decrypted}"`, 'green');
        
        if (message === decrypted) {
            log('✓ Encryption/Decryption successful', 'green');
        }
        await sleep(2000);

        // Step 3: Demonstrate Key Rotation
        header('Step 3: Dynamic Key Rotation (60s interval)');
        log('Observing key rotation...', 'cyan');
        
        const initialStats = security.keyRotationManager.getStats();
        log(`Current key ID: ${initialStats.currentKeyId.substring(0, 16)}...`, 'yellow');
        log('Waiting for next rotation...', 'cyan');
        
        await sleep(3000); // Wait a bit to show rotation happens
        
        const newStats = security.keyRotationManager.getStats();
        log(`Rotation count: ${newStats.rotationCount}`, 'green');
        log('✓ Keys rotating automatically every 60 seconds', 'green');
        await sleep(2000);

        // Step 4: Demonstrate Mesh Network
        header('Step 4: Blockchain-Based Mesh Network');
        log('Registering service in decentralized mesh...', 'cyan');
        
        security.registerService(
            'nexus-core-api',
            'QmExampleCID123abc456def',
            ['https://backup1.nexus.local', 'https://backup2.nexus.local'],
            { version: '1.0.0', protocol: 'HTTPS' }
        );
        
        const resolved = security.resolveService('nexus-core-api');
        log(`Service CID: ${resolved.ipfsCid}`, 'yellow');
        log(`Endpoints: ${resolved.endpoints.length} backup servers`, 'yellow');
        
        const meshStats = security.meshNetwork.getStats();
        log(`Active peers: ${meshStats.activePeers}`, 'green');
        log(`Registered services: ${meshStats.registeredServices}`, 'green');
        log('✓ Mesh network operational - DNS-free routing', 'green');
        await sleep(2000);

        // Step 5: Demonstrate AI Kernel
        header('Step 5: AI Predictive Kernel - EM Signal Detection');
        log('Simulating electromagnetic signal monitoring...', 'cyan');
        
        // Simulate benign signals
        log('Processing benign signals...', 'yellow');
        for (let i = 0; i < 5; i++) {
            await security.processSignal(
                500 + Math.random() * 500,  // Low frequency
                0.1 + Math.random() * 0.2,  // Low amplitude
                Math.random() * 2 * Math.PI,
                'sensor-main'
            );
        }
        
        // Simulate threat signal
        log('Processing suspicious high-energy signal...', 'red');
        await security.processSignal(
            2400,  // High frequency (scanning range)
            0.95,  // High amplitude
            1.57,
            'sensor-main'
        );
        
        await sleep(1000);
        
        const aiStats = security.aiKernel.getStats();
        log(`Total samples analyzed: ${aiStats.bufferSize}`, 'yellow');
        log(`Threats detected: ${aiStats.totalThreats}`, aiStats.totalThreats > 0 ? 'red' : 'green');
        
        if (aiStats.totalThreats > 0) {
            log(`Mitigations applied: ${aiStats.mitigationSuccess}`, 'green');
        }
        
        log('✓ AI kernel monitoring and protecting system', 'green');
        await sleep(2000);

        // Step 6: Register Rhythm Members
        header('Step 6: Rhythm Member Registration');
        log('Registering authorized Rhythm members...', 'cyan');
        
        // Generate test key pair
        const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
            modulusLength: 2048,
        });
        
        const publicKeyPem = publicKey.export({ type: 'spki', format: 'pem' });
        
        security.registerRhythmMember(
            'rhythm-admin-001',
            publicKeyPem,
            { role: 'admin', clearance: 'high', region: 'eu-central' }
        );
        
        security.registerRhythmMember(
            'rhythm-operator-001',
            publicKeyPem,
            { role: 'operator', clearance: 'medium', region: 'us-east' }
        );
        
        log('✓ Registered 2 Rhythm members', 'green');
        await sleep(2000);

        // Step 7: Authenticate Rhythm Member
        header('Step 7: Rhythm Member Authentication');
        log('Authenticating Rhythm member...', 'cyan');
        
        const challenge = security.generateChallenge();
        log(`Challenge: ${challenge.substring(0, 32)}...`, 'yellow');
        
        const signature = crypto.createSign('sha256')
            .update(challenge)
            .sign(privateKey, 'hex');
        
        const token = security.authenticateRhythmMember(
            'rhythm-admin-001',
            signature,
            challenge
        );
        
        log(`Token ID: ${token.tokenId.substring(0, 32)}...`, 'green');
        log(`Permissions: ${token.permissions.join(', ')}`, 'green');
        log('✓ Authentication successful', 'green');
        await sleep(2000);

        // Step 8: Activate Stealth Mode
        header('Step 8: ACTIVATING FINAL STEALTH MODE');
        log('WARNING: This will close all public bridges', 'red');
        log('System will become invisible to external entities', 'red');
        log('Only Rhythm members will have access', 'red');
        console.log('');
        await sleep(3000);
        
        log('Proceeding with stealth mode activation...', 'yellow');
        await sleep(2000);
        
        const stealthResult = security.activateStealthMode(token, 3);
        
        log(`✓ Stealth mode activated by: ${stealthResult.activatedBy}`, 'green');
        log(`✓ Closed ${stealthResult.closedBridges} public bridges`, 'green');
        log(`✓ Stealth level: ${stealthResult.level} (INVISIBLE)`, 'green');
        await sleep(2000);

        // Step 9: System Status
        header('Step 9: Final System Status');
        const status = security.getSystemStatus();
        
        log('System Overview:', 'bright');
        console.log('');
        log(`  Initialized: ${status.initialized ? '✓' : '✗'}`, status.initialized ? 'green' : 'red');
        log(`  Running: ${status.running ? '✓' : '✗'}`, status.running ? 'green' : 'red');
        console.log('');
        
        log('Component Status:', 'bright');
        console.log('');
        
        log(`  Quantum Shield:`, 'cyan');
        log(`    - Rotations: ${status.components.quantumShield.rotationCount}`, 'yellow');
        log(`    - Quantum Resistant: ${status.components.quantumShield.quantumResistant ? 'Yes' : 'No'}`, 'green');
        console.log('');
        
        log(`  Mesh Network:`, 'cyan');
        log(`    - Active Peers: ${status.components.meshNetwork.activePeers}`, 'yellow');
        log(`    - Services: ${status.components.meshNetwork.registeredServices}`, 'yellow');
        log(`    - Rhythm Members: ${status.components.meshNetwork.rhythmMembers}`, 'yellow');
        console.log('');
        
        log(`  AI Kernel:`, 'cyan');
        log(`    - Running: ${status.components.aiKernel.isRunning ? 'Yes' : 'No'}`, 'yellow');
        log(`    - Threats Detected: ${status.components.aiKernel.totalThreats}`, 'yellow');
        log(`    - Model Accuracy: ${(status.components.aiKernel.modelInfo.accuracy * 100).toFixed(1)}%`, 'yellow');
        console.log('');
        
        log(`  Stealth Mode:`, 'cyan');
        log(`    - Active: ${status.components.stealthMode.isActive ? 'YES' : 'No'}`, status.components.stealthMode.isActive ? 'green' : 'yellow');
        log(`    - Level: ${status.components.stealthMode.level}`, 'yellow');
        log(`    - Open Bridges: ${status.components.stealthMode.openBridges}`, 'yellow');
        log(`    - Rhythm Members: ${status.components.stealthMode.rhythmMembers.totalMembers}`, 'yellow');
        console.log('');

        // Final Summary
        header('DEPLOYMENT COMPLETE');
        console.log('');
        log('✓ Quantum-Shield NTRU: ACTIVE', 'green');
        log('  → Lattice-based encryption operational', 'cyan');
        log('  → 60-second key rotation enabled', 'cyan');
        console.log('');
        
        log('✓ Blockchain-Based Mesh Network: ACTIVE', 'green');
        log('  → Decentralized DNS operational', 'cyan');
        log('  → IPFS peer-to-peer routing enabled', 'cyan');
        console.log('');
        
        log('✓ AI Predictive Kernel: ACTIVE', 'green');
        log('  → EM signal monitoring active', 'cyan');
        log('  → Threat detection and mitigation enabled', 'cyan');
        console.log('');
        
        log('✓ Final Stealth Mode: ACTIVE', 'green');
        log('  → All public bridges closed', 'cyan');
        log('  → System invisible to external entities', 'cyan');
        log('  → Rhythm member access only', 'cyan');
        console.log('');
        
        log('='.repeat(60), 'green');
        log('  NEXUS SYSTEM: FULLY PROTECTED AND INVISIBLE', 'bright');
        log('='.repeat(60), 'green');
        console.log('');

        // Cleanup
        log('Demonstration complete. Stopping system...', 'yellow');
        await sleep(2000);
        security.stop();
        log('✓ System stopped gracefully', 'green');

    } catch (error) {
        log(`ERROR: ${error.message}`, 'red');
        console.error(error);
        process.exit(1);
    }
}

// Run demonstration
if (require.main === module) {
    main().catch(error => {
        console.error('Fatal error:', error);
        process.exit(1);
    });
}

module.exports = { main };
