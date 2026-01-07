# KOSYMBIOSIS Quick Start Guide

## For First-Time Users

### What is KOSYMBIOSIS?
KOSYMBIOSIS is the final, immutable archive of an ethical AI governance project within the Euystacio framework. It demonstrates compliance with:
- **NSR (Non-Slavery Rule):** No unchecked control mechanisms
- **OLF (Optimal Life Function):** Life-affirming optimization

### How to Verify the Archive

**Step 1: Download the Archive**
```bash
# From GitHub (once released)
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0-final/kosymbiosis-archive.zip
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0-final/checksum.sha256
```

**Step 2: Verify Checksum**
```bash
sha256sum -c checksum.sha256
# Expected: kosymbiosis-archive.zip: OK
```

**Step 3: Verify Signatures (Optional)**
```bash
# Download signatures
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0-final/kosymbiosis.sig
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0-final/kosymbiosis-co1.sig
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0-final/kosymbiosis-co2.sig

# Verify (requires GPG public keys)
gpg --verify kosymbiosis.sig kosymbiosis-archive.zip
gpg --verify kosymbiosis-co1.sig kosymbiosis-archive.zip
gpg --verify kosymbiosis-co2.sig kosymbiosis-archive.zip
```

**Step 4: Extract and Explore**
```bash
unzip kosymbiosis-archive.zip
cd kosymbiosis/
cat README.md
```

### What's Inside?

- **Protocols:** SAIN, Custos Sentimento, ULP
- **Smart Contracts:** Ethical AI governance mechanisms
- **Documentation:** Complete guides and specifications
- **Dashboard:** Public transparency interface
- **Data:** Historical metrics and governance records

## For Co-Creators

### Create the Archive
```bash
cd kosymbiosis/
bash scripts/create_archive.sh
```

### Sign the Archive
```bash
# See signatures/SIGNATURE_INSTRUCTIONS.md for details
gpg --detach-sign --armor -o signatures/kosymbiosis.sig kosymbiosis-archive.zip
```

### Upload to IPFS
```bash
# See IPFS_DISTRIBUTION.md for multiple methods
ipfs add kosymbiosis-archive.zip
# Save the CID and update documentation
```

### Create GitHub Release
```bash
# See GITHUB_RELEASE.md for detailed instructions
gh release create kosymbiosis-v1.0-final \
  kosymbiosis-archive.zip \
  checksum.sha256 \
  signatures/kosymbiosis.sig \
  signatures/kosymbiosis-co1.sig \
  signatures/kosymbiosis-co2.sig
```

## For Developers

### Regenerate Archive
```bash
cd kosymbiosis/
bash scripts/create_archive.sh
# Creates kosymbiosis-archive.zip and checksum.sha256
```

### Verify Archive Programmatically
```bash
bash scripts/verify_archive.sh kosymbiosis-archive.zip
# Returns exit code 0 on success
```

### Parse Metadata
```bash
cat KOSYMBIOSIS_METADATA.json | jq '.project'
cat KOSYMBIOSIS_METADATA.json | jq '.ethical_alignment'
```

## For Auditors

### Verify Ethical Compliance

**Check NSR Compliance:**
```bash
# 1. Verify distributed sovereignty (triple-signature)
ls -l signatures/*.sig
# Should show 3 signature files

# 2. Verify transparent processes
cat KOSYMBIOSIS_DECLARATION.md | grep -A5 "NSR"

# 3. Verify contestability
bash scripts/verify_archive.sh  # Anyone can run this
```

**Check OLF Alignment:**
```bash
# View metrics
cat KOSYMBIOSIS_METADATA.json | jq '.ethical_alignment.olf_alignment.metrics'

# View commitments
cat KOSYMBIOSIS_DECLARATION.md | grep -A10 "OLF"
```

### Audit the Archive Contents
```bash
# Extract and inspect
unzip -l kosymbiosis-archive.zip

# Check for required files
unzip -l kosymbiosis-archive.zip | grep "SAIN-Protocol"
unzip -l kosymbiosis-archive.zip | grep "UniversalLiquidityPool.sol"
```

### Verify Timeline
```bash
cat KOSYMBIOSIS_FINAL_LOG.txt | grep "PROJECT INITIALIZATION"
cat KOSYMBIOSIS_FINAL_LOG.txt | grep "FINAL SEAL"
```

## Common Tasks

### Update Documentation (Before Signing)
```bash
# Edit any markdown file
vim kosymbiosis/README.md

# Regenerate archive
cd kosymbiosis/
bash scripts/create_archive.sh

# New checksum will be generated
cat checksum.sha256
```

### Check Archive Status
```bash
cat ARCHIVAL_PROCESS.md | grep "Status:"
cat IMPLEMENTATION_SUMMARY.md | grep "Current Status" -A10
```

### View File Index
```bash
cat FILE_INDEX.md
# Shows all files and their purposes
```

## Troubleshooting

### Archive Checksum Doesn't Match
```bash
# Regenerate archive
rm kosymbiosis-archive.zip checksum.sha256
bash scripts/create_archive.sh

# Verify
sha256sum -c checksum.sha256
```

### GPG Signature Verification Fails
```bash
# Import public keys first
gpg --import [public-key-file]

# Try verification again
gpg --verify signatures/kosymbiosis.sig kosymbiosis-archive.zip
```

### Archive Creation Fails
```bash
# Check that all source files exist
ls -l ../SAIN-Protocol-V1.0.md
ls -l ../UniversalLiquidityPool.sol

# Run with verbose output
bash -x scripts/create_archive.sh
```

## Quick Reference

### File Locations
- **Archive:** `kosymbiosis/kosymbiosis-archive.zip` (generated)
- **Checksum:** `kosymbiosis/checksum.sha256` (generated)
- **Main Docs:** `kosymbiosis/README.md`
- **Scripts:** `kosymbiosis/scripts/`
- **Signatures:** `kosymbiosis/signatures/`

### Important Commands
```bash
# Create archive
bash scripts/create_archive.sh

# Verify archive
bash scripts/verify_archive.sh

# Check checksum
sha256sum -c checksum.sha256

# Verify signature
gpg --verify signatures/[file].sig kosymbiosis-archive.zip
```

### Documentation Files
- `README.md` - Start here
- `KOSYMBIOSIS_DECLARATION.md` - Project mandate
- `ARCHIVAL_PROCESS.md` - Complete workflow
- `IMPLEMENTATION_SUMMARY.md` - What was delivered
- `FILE_INDEX.md` - All files explained
- `QUICK_START.md` - This file

## Support

- **Issues:** https://github.com/hannesmitterer/nexus/issues
- **Email:** governance@euystacio.example
- **Documentation:** All files in `kosymbiosis/` directory

## Summary

1. **Download** → 2. **Verify checksum** → 3. **Verify signatures** → 4. **Extract** → 5. **Explore**

That's it! The KOSYMBIOSIS archive is designed to be transparent, verifiable, and accessible to everyone.

---

**Version:** 1.0  
**Last Updated:** 2026-01-07  
**Status:** Ready for use
