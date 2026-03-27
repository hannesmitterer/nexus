/**
 * Nexus Security Integration Example
 * 
 * This example shows how to integrate the quantum-safe security system
 * with the existing Nexus dashboard and smart contracts.
 */

const { getNexusSecuritySystem } = require('../security/nexus_security');
const crypto = require('crypto');

/**
 * Example: Integrate with Nexus Dashboard
 */
async function integrateWithDashboard() {
    console.log('=== Dashboard Integration Example ===\n');

    const security = getNexusSecuritySystem();
    await security.initialize();
    await security.start();

    // Get real-time security status for dashboard
    const status = security.getSystemStatus();
    
    // Format for dashboard display
    const dashboardData = {
        security: {
            quantumShield: {
                status: 'ACTIVE',
                keyRotations: status.components.quantumShield.rotationCount
            },
            stealthMode: {
                status: status.components.stealthMode.isActive ? 'ACTIVE' : 'STANDBY'
            }
        }
    };

    console.log('Dashboard Data:', JSON.stringify(dashboardData, null, 2));
    
    security.stop();
    return dashboardData;
}

// Run if executed directly
if (require.main === module) {
    integrateWithDashboard().catch(console.error);
}
