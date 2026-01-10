# KOSYMBIOSIS IPFS Distribution Guide

## Overview

This guide provides instructions for distributing the KOSYMBIOSIS final archive via IPFS (InterPlanetary File System), ensuring censorship-resistant, redundant, and long-term accessible storage.

## What is IPFS?

IPFS is a peer-to-peer distributed file system that seeks to connect all computing devices with the same system of files. Key benefits:

- **Content-Addressed**: Files identified by cryptographic hash (CID), not location
- **Distributed**: No central server; files stored across multiple nodes
- **Immutable**: Content cannot be changed without changing the CID
- **Persistent**: Pinned content remains available as long as at least one node hosts it

## Prerequisites

### Install IPFS

#### Option 1: IPFS Desktop (Recommended for beginners)

1. Download from: https://docs.ipfs.tech/install/ipfs-desktop/
2. Install for your operating system
3. Launch IPFS Desktop

#### Option 2: IPFS Command Line

**Linux/macOS**:
```bash
wget https://dist.ipfs.tech/kubo/v0.27.0/kubo_v0.27.0_linux-amd64.tar.gz
tar -xvzf kubo_v0.27.0_linux-amd64.tar.gz
cd kubo
sudo bash install.sh
ipfs --version
```

**Initialize IPFS**:
```bash
ipfs init
ipfs daemon
```

## Upload Process

### Step 1: Prepare Archive

Ensure you have:
```
kosymbiosis-final-archive.zip
checksum.sha256
kosymbiosis.sig
kosymbiosis-co1.sig
kosymbiosis-co2.sig
```

### Step 2: Upload to IPFS

#### Using IPFS Desktop

1. Open IPFS Desktop
2. Navigate to "Files" tab
3. Click "Import"
4. Select `kosymbiosis-final-archive.zip`
5. Wait for upload to complete
6. Copy the CID (Content Identifier)

#### Using Command Line

```bash
# Upload archive
ipfs add kosymbiosis-final-archive.zip

# Output example:
# added QmX... kosymbiosis-final-archive.zip
# 20.00 KiB / 20.00 KiB [===================] 100.00%
```

The alphanumeric string (e.g., `QmX...`) is your **IPFS CID**.

### Step 3: Pin the Content

Pinning ensures the content remains available:

```bash
# Pin locally
ipfs pin add [YOUR_CID]

# Verify pin
ipfs pin ls | grep [YOUR_CID]
```

### Step 4: Test Retrieval

Verify the upload worked:

```bash
# Retrieve via CLI
ipfs get [YOUR_CID] -o test-download.zip

# Verify checksum matches
sha256sum test-download.zip
# Should match: 64e038c00860ea31edf23b78f21c8c28ee0d48cf9f35f3869313c7616b9fef6b
```

## Public IPFS Pinning Services

For enhanced availability, use pinning services to ensure your content remains accessible even if your node goes offline.

### Recommended Services

#### 1. Pinata (pinata.cloud)

**Free Tier**: Up to 1 GB

**Setup**:
1. Create account at https://pinata.cloud
2. Get API keys from account settings
3. Upload via web interface or API

**Web Upload**:
1. Log in to Pinata
2. Click "Upload" → "File"
3. Select `kosymbiosis-final-archive.zip`
4. Note the CID provided

#### 2. Web3.Storage (web3.storage)

**Free Tier**: Unlimited storage (as of 2024)

**Setup**:
```bash
# Install w3 CLI
npm install -g @web3-storage/w3cli

# Create account and login
w3 login

# Upload
w3 up kosymbiosis-final-archive.zip
```

#### 3. NFT.Storage (nft.storage)

**Free Tier**: Unlimited (focused on NFT metadata but accepts any files)

**Upload**:
1. Create account at https://nft.storage
2. Use web interface to upload
3. Record the CID

### Multiple Pinning for Redundancy

**Best Practice**: Pin to at least 3 different services:

```
✓ Local IPFS node
✓ Pinata
✓ Web3.Storage
```

This ensures availability even if one service has issues.

## Accessing via IPFS Gateways

Once uploaded, the archive is accessible through IPFS gateways:

### Public Gateways

Replace `[YOUR_CID]` with your actual CID:

```
https://ipfs.io/ipfs/[YOUR_CID]
https://cloudflare-ipfs.com/ipfs/[YOUR_CID]
https://gateway.pinata.cloud/ipfs/[YOUR_CID]
https://dweb.link/ipfs/[YOUR_CID]
https://w3s.link/ipfs/[YOUR_CID]
```

### Testing Gateway Access

```bash
# Download via gateway
curl -o test-gateway.zip https://ipfs.io/ipfs/[YOUR_CID]

# Verify checksum
sha256sum test-gateway.zip
```

## Update Documentation with CID

After successful upload, update these files with your CID:

### 1. Archive README

File: `kosymbiosis/README.md`

Replace:
```markdown
[IPFS_CID_PLACEHOLDER]
```

With:
```markdown
QmYourActualCIDHere
```

### 2. Project Metadata

File: `kosymbiosis/metadata/project_info.json`

Update the `ipfs` section:
```json
"ipfs": {
  "cid": "QmYourActualCIDHere",
  "pin_status": "pinned",
  "pinning_services": ["local", "pinata", "web3.storage"],
  "upload_date": "2026-01-07T00:00:00Z"
}
```

### 3. GitHub Release

Update the release description with IPFS access information.

## Verification Checklist

Before announcing IPFS availability:

- [ ] Archive uploaded to IPFS
- [ ] CID recorded and documented
- [ ] Content pinned locally
- [ ] Content pinned on at least 2 remote services
- [ ] Access tested via at least 3 different gateways
- [ ] Download and checksum verified
- [ ] Documentation updated with CID
- [ ] Gateway links tested and working

## Long-term Maintenance

### Monitoring Availability

Periodically check your content is still accessible:

```bash
# Check pin status locally
ipfs pin ls | grep [YOUR_CID]

# Test gateway access
curl -I https://ipfs.io/ipfs/[YOUR_CID]
```

### Re-pinning

If you lose local pins:

```bash
# Re-pin from network
ipfs pin add [YOUR_CID]
```

### Service Migration

If a pinning service shuts down:
1. Verify content still accessible via other pins
2. Add to new pinning service
3. Update documentation if primary gateway changes

## Troubleshooting

### Upload Fails

**Issue**: `ipfs add` command fails

**Solutions**:
1. Ensure IPFS daemon is running: `ipfs daemon`
2. Check available space: `df -h`
3. Try breaking into smaller pieces if very large
4. Check IPFS logs: `ipfs log tail`

### Content Not Retrievable

**Issue**: Cannot access via gateway

**Solutions**:
1. Wait 5-10 minutes for propagation
2. Try different gateway
3. Verify CID is correct
4. Check if locally pinned: `ipfs pin ls`
5. Ensure at least one pinning service has it

### Slow Gateway Performance

**Issue**: Downloads very slow via gateway

**Solutions**:
1. Try different gateway
2. Use local retrieval: `ipfs get [CID]`
3. Consider dedicated pinning service with CDN

## Advanced: Create IPFS Directory

For enhanced organization, upload all related files as a directory:

```bash
# Create directory structure
mkdir kosymbiosis-ipfs
cp kosymbiosis-final-archive.zip kosymbiosis-ipfs/
cp checksum.sha256 kosymbiosis-ipfs/
cp *.sig kosymbiosis-ipfs/

# Upload directory
ipfs add -r kosymbiosis-ipfs/

# Result will show CID for directory
# Access: https://ipfs.io/ipfs/[DIRECTORY_CID]/kosymbiosis-final-archive.zip
```

## Security Considerations

### What IPFS Does Provide

- ✓ Content integrity (CID verification)
- ✓ Censorship resistance
- ✓ Distributed availability
- ✓ Immutability

### What IPFS Does NOT Provide

- ✗ Encryption (content is public by default)
- ✗ Access control (anyone can download)
- ✗ Automatic persistence (requires pinning)

### For KOSYMBIOSIS

Since the archive is intended for public access and contains no sensitive information, public IPFS distribution is appropriate.

## Example Complete Workflow

```bash
# 1. Start IPFS
ipfs daemon &

# 2. Upload archive
CID=$(ipfs add -Q kosymbiosis-final-archive.zip)
echo "Archive CID: $CID"

# 3. Pin locally
ipfs pin add $CID

# 4. Test retrieval
ipfs get $CID -o test.zip
sha256sum -c checksum.sha256

# 5. Upload to Pinata (via web interface)
# Visit pinata.cloud and upload

# 6. Test gateway access
curl -I https://ipfs.io/ipfs/$CID
curl -I https://cloudflare-ipfs.com/ipfs/$CID

# 7. Update documentation
sed -i "s/\[IPFS_CID_PLACEHOLDER\]/$CID/g" kosymbiosis/README.md

echo "IPFS distribution complete!"
echo "CID: $CID"
echo "Gateway: https://ipfs.io/ipfs/$CID"
```

## Community and Support

For IPFS help:

- **Documentation**: https://docs.ipfs.tech/
- **Forum**: https://discuss.ipfs.tech/
- **Discord**: https://discord.gg/ipfs

For KOSYMBIOSIS-specific questions:
- **Email**: governance@euystacio.example

---

**Document Version**: 1.0  
**Last Updated**: 2026-01-07  
**Status**: FINAL  
**Expected Archive CID**: To be determined upon upload
