# IPFS Distribution Guide

## Overview
This guide explains how to upload the KOSYMBIOSIS archive to IPFS (InterPlanetary File System) for permanent, decentralized storage.

## Prerequisites
- IPFS daemon installed and running, OR
- Access to an IPFS pinning service (Pinata, Infura, Web3.Storage)

## Method 1: Local IPFS Node

### Install IPFS
```bash
# Download and install IPFS (see https://docs.ipfs.tech/install/ and https://dist.ipfs.tech/#kubo for the latest version)
# Example for Linux AMD64 - replace with the latest version from the releases page
KUBO_VERSION="v0.30.0"  # Check https://dist.ipfs.tech/#kubo for the latest version
wget "https://dist.ipfs.tech/kubo/${KUBO_VERSION}/kubo_${KUBO_VERSION}_linux-amd64.tar.gz"
tar -xvzf "kubo_${KUBO_VERSION}_linux-amd64.tar.gz"
cd kubo
sudo bash install.sh
```

### Initialize and Start IPFS
```bash
ipfs init
ipfs daemon &
```

### Add Archive to IPFS
```bash
ipfs add kosymbiosis-archive.zip
```

### Expected Output
```
added QmXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX kosymbiosis-archive.zip
```

The output hash (starting with `Qm` or `bafy`) is your **Content Identifier (CID)**.

### Pin the Content
```bash
ipfs pin add QmXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

## Method 2: Pinata (Recommended for Long-term Storage)

### Sign Up
1. Visit https://pinata.cloud
2. Create a free account
3. Get your API keys from the dashboard

### Upload via Web Interface
1. Log in to Pinata
2. Click "Upload" → "File"
3. Select `kosymbiosis-archive.zip`
4. Add metadata:
   - Name: "KOSYMBIOSIS Archive v1.0"
   - Description: "Final immutable archive of the KOSYMBIOSIS project"
5. Click "Upload"

### Upload via CLI
```bash
curl -X POST "https://api.pinata.cloud/pinning/pinFileToIPFS" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "file=@kosymbiosis-archive.zip" \
  -F "pinataMetadata={\"name\":\"KOSYMBIOSIS Archive v1.0\"}"
```

### Pin Additional Files
Also upload:
- `checksum.sha256`
- `signatures/kosymbiosis.sig`
- `signatures/kosymbiosis-co1.sig`
- `signatures/kosymbiosis-co2.sig`

## Method 3: Web3.Storage

### Sign Up
1. Visit https://web3.storage
2. Create account with email or GitHub
3. Get API token

### Upload via CLI
```bash
npm install -g @web3-storage/w3cli
w3 login
w3 up kosymbiosis-archive.zip
```

## Method 4: Infura IPFS

### Setup
1. Sign up at https://infura.io
2. Create an IPFS project
3. Get your project ID and secret

### Upload
```bash
curl -X POST \
  -F "file=@kosymbiosis-archive.zip" \
  -u "PROJECT_ID:PROJECT_SECRET" \
  "https://ipfs.infura.io:5001/api/v0/add"
```

## Verification

### Access via Gateway
Test accessibility through multiple gateways:

```bash
# IPFS.io gateway
curl https://ipfs.io/ipfs/[YOUR_CID] -I

# Cloudflare gateway
curl https://cloudflare-ipfs.com/ipfs/[YOUR_CID] -I

# Pinata gateway
curl https://gateway.pinata.cloud/ipfs/[YOUR_CID] -I
```

### Verify Content
Download and verify the archive:

```bash
# Download from IPFS
ipfs get [YOUR_CID] -o kosymbiosis-archive-downloaded.zip

# Verify checksum
sha256sum kosymbiosis-archive-downloaded.zip
# Compare with original checksum.sha256
```

## Recording the CID

Once uploaded, update the following files with your CID:

### 1. Update README.md
```bash
sed -i 's/\[TO BE GENERATED UPON UPLOAD\]/[YOUR_CID]/' kosymbiosis/README.md
```

### 2. Update KOSYMBIOSIS_METADATA.json
```json
"distribution": {
  "redundant": {
    "platform": "IPFS",
    "cid": "[YOUR_CID]",
    ...
  }
}
```

### 3. Create CID File
```bash
echo "[YOUR_CID]" > kosymbiosis/IPFS_CID.txt
```

## Multiple Pinning Services (Recommended)

For maximum redundancy, pin the archive to multiple services:

1. **Pinata** - Commercial, reliable, free tier available
2. **Web3.Storage** - Backed by Filecoin, free
3. **Infura** - Enterprise-grade, free tier available
4. **Local IPFS node** - If you can maintain it

## Gateway Links

After uploading, provide these gateway URLs:

- IPFS.io: `https://ipfs.io/ipfs/[CID]`
- Cloudflare: `https://cloudflare-ipfs.com/ipfs/[CID]`
- Pinata: `https://gateway.pinata.cloud/ipfs/[CID]`
- dweb.link: `https://dweb.link/ipfs/[CID]`

## CID Format

IPFS CIDs come in two versions:
- **CIDv0**: Starts with `Qm`, e.g., `QmXXXXXXX...`
- **CIDv1**: Starts with `bafy`, e.g., `bafyXXXXXXX...`

Both are valid. CIDv1 is newer and more flexible.

## Troubleshooting

### Cannot connect to IPFS daemon
```bash
ipfs daemon
# Wait for "Daemon is ready"
```

### File too large for gateway
Use `ipfs get` command instead of browser download

### CID not resolving
Wait 5-10 minutes for DHT propagation, or use direct gateway links

## Next Steps

After IPFS upload:
1. ✓ Record CID in documentation
2. ✓ Test all gateway links
3. ✓ Verify downloaded content matches checksum
4. ✓ Update README with CID information
5. → Proceed to GitHub Release creation

## Contact

For IPFS-related questions:
- Email: governance@euystacio.example
- GitHub: https://github.com/hannesmitterer/nexus/issues
