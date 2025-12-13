#!/usr/bin/env node

/**
 * Document Hash Verification Script
 * Verifies the integrity of strategic documents using SHA-256 hashing
 */

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// Configuration
const DOCS_DIR = path.join(__dirname, '..', 'docs', 'strategic');
const METADATA_FILE = path.join(DOCS_DIR, 'metadata.json');
const DOCUMENT_FILE = path.join(DOCS_DIR, 'GPT-OSS-120B-Rapporto-di-Convergenza-Strategica-2026.md');

/**
 * Calculate SHA-256 hash of a file
 * @param {string} filePath - Path to the file
 * @returns {Promise<string>} Promise that resolves to SHA-256 hash in hexadecimal format
 */
function calculateHash(filePath) {
  return new Promise((resolve, reject) => {
    const hash = crypto.createHash('sha256');
    const stream = fs.createReadStream(filePath);

    stream.on('data', (data) => {
      hash.update(data);
    });

    stream.on('end', () => {
      resolve(hash.digest('hex'));
    });

    stream.on('error', (err) => {
      reject(err);
    });
  });
}

/**
 * Verify document integrity against metadata
 */
async function verifyDocument() {
  try {
    console.log('═══════════════════════════════════════════════════════════');
    console.log('  Document Integrity Verification - SHA-256');
    console.log('═══════════════════════════════════════════════════════════\n');

    // Read metadata
    const metadata = JSON.parse(fs.readFileSync(METADATA_FILE, 'utf8'));
    const expectedHash = metadata.integrity.sha256;

    console.log('Document:', metadata.document.title);
    console.log('Version:', metadata.document.version);
    console.log('Timestamp:', metadata.document.timestamp);
    console.log('IPFS CID:', metadata.ipfs.cid);
    console.log('\n───────────────────────────────────────────────────────────\n');

    // Calculate actual hash
    console.log('Calculating SHA-256 hash of document...');
    const actualHash = await calculateHash(DOCUMENT_FILE);

    console.log('\nExpected Hash (from metadata):');
    console.log('  ', expectedHash);
    console.log('\nCalculated Hash (from document):');
    console.log('  ', actualHash);
    console.log('\n───────────────────────────────────────────────────────────\n');

    // Verify
    if (actualHash === expectedHash) {
      console.log('✓ VERIFICATION SUCCESSFUL');
      console.log('  Document integrity confirmed - hashes match!');
      console.log('\n  The document has not been tampered with and matches');
      console.log('  the officially signed version archived on IPFS.');
      console.log('\n═══════════════════════════════════════════════════════════\n');
      return true;
    } else {
      console.log('✗ VERIFICATION FAILED');
      console.log('  Document integrity compromised - hashes DO NOT match!');
      console.log('\n  WARNING: The document may have been modified or corrupted.');
      console.log('  Please retrieve the official version from IPFS.');
      console.log('\n═══════════════════════════════════════════════════════════\n');
      return false;
    }
  } catch (error) {
    console.error('\n✗ ERROR during verification:');
    // Log sanitized error message (avoid exposing sensitive paths/details in production)
    console.error('  ', error.code || error.message || 'Unknown error');
    console.log('\n═══════════════════════════════════════════════════════════\n');
    return false;
  }
}

/**
 * Display IPFS retrieval information
 */
function displayIPFSInfo() {
  const metadata = JSON.parse(fs.readFileSync(METADATA_FILE, 'utf8'));
  
  console.log('\n📦 IPFS Archive Information');
  console.log('───────────────────────────────────────────────────────────\n');
  console.log('CID:', metadata.ipfs.cid);
  console.log('\nGateway URLs:');
  metadata.ipfs.gateway_urls.forEach((url, index) => {
    console.log(`  ${index + 1}. ${url}`);
  });
  console.log('\nPinned Locations:');
  metadata.ipfs.pin_locations.forEach((location, index) => {
    console.log(`  ${index + 1}. ${location}`);
  });
  console.log('\n───────────────────────────────────────────────────────────\n');
}

// Main execution
if (require.main === module) {
  verifyDocument()
    .then((verified) => {
      if (verified) {
        displayIPFSInfo();
      }
      process.exit(verified ? 0 : 1);
    })
    .catch((error) => {
      console.error('Fatal error:', error);
      process.exit(1);
    });
}

module.exports = { calculateHash, verifyDocument };
