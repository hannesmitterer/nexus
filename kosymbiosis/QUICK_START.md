# KOSYMBIOSIS Quick Start Guide

## Overview

This quick reference guide helps you get started with the KOSYMBIOSIS archive, whether you're verifying its integrity, extracting contents, or understanding the project.

## 🚀 Quick Verification (30 seconds)

```bash
# 1. Clone the repository
git clone https://github.com/hannesmitterer/nexus.git
cd nexus

# 2. Verify checksum
sha256sum -c checksum.sha256
# Expected: kosymbiosis-final-archive.zip: OK

# 3. Extract archive
unzip kosymbiosis-final-archive.zip
cd kosymbiosis/

# 4. Read overview
cat README.md
```

## 📦 What's in the Archive?

The KOSYMBIOSIS archive contains:

```
kosymbiosis/
├── README.md                          # Start here!
├── GITHUB_RELEASE_GUIDE.md           # How to create GitHub release
├── IPFS_DISTRIBUTION_GUIDE.md        # How to distribute via IPFS
├── declarations/                      # Ethical compliance declarations
│   ├── NSR_COMPLIANCE.md             # Non-Slavery Rule adherence
│   ├── OLF_ALIGNMENT.md              # Optimal Life Function alignment
│   └── CO_CREATOR_ATTESTATIONS.md    # Co-creator signatures
├── metadata/                          # Project information
│   ├── project_info.json             # Technical specifications
│   └── contributors.json             # Contributor details
└── logs/                              # Project history
    ├── development_log.md            # Development timeline
    └── ethical_review_log.md         # Ethical review history
```

## 🔐 Verification Steps

### Checksum Verification

```bash
# Verify archive hasn't been tampered with
sha256sum -c checksum.sha256
```

Expected checksum: `69ece107f0cb8564e0ab02d46d64bad2181ee85a01e44910c4eeb38a948b406d`

### Signature Verification (requires GPG)

```bash
# Verify all three co-creator signatures
gpg --verify kosymbiosis.sig kosymbiosis-final-archive.zip
gpg --verify kosymbiosis-co1.sig kosymbiosis-final-archive.zip
gpg --verify kosymbiosis-co2.sig kosymbiosis-final-archive.zip
```

Note: Signature files are placeholders for demonstration. In production, these would be actual GPG signatures from co-creators' private keys.

## 🌐 Distribution Channels

### GitHub
- **Repository**: https://github.com/hannesmitterer/nexus
- **Branch**: `copilot/finalize-kosymbiosis-archive`
- **Archive**: In repository root

### GitHub Release (Recommended for End Users)
- **Tag**: `kosymbiosis-v1.0.0-final` (to be created)
- **URL**: https://github.com/hannesmitterer/nexus/releases
- **Assets**: Archive + checksum + 3 signatures

### IPFS (Distributed Storage)
- **CID**: [To be updated after IPFS upload]
- **Gateways**:
  - `https://ipfs.io/ipfs/[CID]`
  - `https://cloudflare-ipfs.com/ipfs/[CID]`
  - `https://gateway.pinata.cloud/ipfs/[CID]`

## 🎯 Common Tasks

### Create the Archive Yourself

```bash
# Run the archive creation script
bash scripts/create_kosymbiosis_archive.sh

# This creates:
# - kosymbiosis-final-archive.zip
# - checksum.sha256
```

### Upload to IPFS

```bash
# Install IPFS first: https://docs.ipfs.tech/install/

# Upload archive
ipfs add kosymbiosis-final-archive.zip

# Pin for persistence
ipfs pin add [YOUR_CID]

# Access via gateway
open https://ipfs.io/ipfs/[YOUR_CID]
```

See `kosymbiosis/IPFS_DISTRIBUTION_GUIDE.md` for detailed instructions.

### Create GitHub Release

See `kosymbiosis/GITHUB_RELEASE_GUIDE.md` for step-by-step instructions.

## 📚 Key Documents

Start with these files in order:

1. **README.md** (main repo) - Overview and KOSYMBIOSIS section
2. **kosymbiosis/README.md** - Detailed project documentation
3. **kosymbiosis/declarations/NSR_COMPLIANCE.md** - Ethical foundation
4. **kosymbiosis/declarations/OLF_ALIGNMENT.md** - Ethical alignment
5. **kosymbiosis/logs/development_log.md** - Project history

## ✅ Verification Checklist

Before using or citing the archive:

- [ ] Clone repository or download from release
- [ ] Verify SHA-256 checksum matches
- [ ] Extract archive successfully
- [ ] Read main README
- [ ] Review ethical declarations
- [ ] (Optional) Verify GPG signatures
- [ ] (Optional) Check IPFS availability

## 🔍 Understanding the Project

### What is KOSYMBIOSIS?

A collaborative ethical AI development project within the Euystacio framework, demonstrating:
- **Non-Slavery Rule (NSR)**: Zero exploitation, voluntary participation
- **Optimal Life Function (OLF)**: Maximizing well-being and sustainability
- **Triple-signature verification**: Consensus-based authentication
- **Distributed archival**: IPFS + GitHub for long-term preservation

### Why Triple Signatures?

Three independent co-creators must sign the archive:
1. **Primary Architect** - Technical design and ethical framework
2. **Implementation Lead** - System development and testing
3. **Governance Specialist** - Documentation and ethical review

All three must agree before the archive is considered authentic.

### Why IPFS?

IPFS (InterPlanetary File System) provides:
- **Content addressing**: Files identified by cryptographic hash
- **Censorship resistance**: No central authority controls access
- **Permanence**: Content persists as long as anyone hosts it
- **Verifiability**: CID guarantees content hasn't changed

## 🆘 Troubleshooting

### Checksum doesn't match

**Problem**: `sha256sum -c checksum.sha256` fails

**Solutions**:
1. Re-download the archive (file may be corrupted)
2. Ensure you're in the correct directory
3. Check for file tampering

### Can't extract archive

**Problem**: `unzip` fails

**Solutions**:
1. Ensure you have `unzip` installed: `apt-get install unzip`
2. Check archive isn't corrupted: `sha256sum -c checksum.sha256`
3. Verify sufficient disk space: `df -h`

### Signature verification fails

**Problem**: `gpg --verify` fails

**Solutions**:
1. Signatures are placeholders in this version (demonstration)
2. In production, you'd need co-creators' public GPG keys
3. Import keys first: `gpg --import [key-file]`

### Archive script fails

**Problem**: `create_kosymbiosis_archive.sh` errors

**Solutions**:
1. Ensure `zip` is installed: `apt-get install zip`
2. Check permissions: `chmod +x scripts/create_kosymbiosis_archive.sh`
3. Verify `kosymbiosis/` directory exists

## 📞 Getting Help

### Documentation
- Main README: `/README.md` → KOSYMBIOSIS section
- Archive README: `/kosymbiosis/README.md`
- IPFS Guide: `/kosymbiosis/IPFS_DISTRIBUTION_GUIDE.md`
- Release Guide: `/kosymbiosis/GITHUB_RELEASE_GUIDE.md`

### Contact
- **Email**: governance@euystacio.example
- **Repository**: https://github.com/hannesmitterer/nexus
- **Governance**: Euystacio Global Governance Initiative (GGI)

### Framework Documentation
- **Euystacio**: See main README
- **SAIN Protocol**: `/SAIN-Protocol-V1.0.md`
- **ULP**: `/ULP_README.md`

## 🎓 For Developers

### Creating Similar Archives

The KOSYMBIOSIS archive can serve as a template for other projects:

1. **Structure**: Organize as `declarations/`, `metadata/`, `logs/`
2. **Ethics**: Document NSR and OLF compliance
3. **Verification**: Use checksums + multiple signatures
4. **Distribution**: Leverage IPFS for redundancy
5. **Documentation**: Comprehensive guides for all processes

### Adapting the Scripts

The archive script (`scripts/create_kosymbiosis_archive.sh`) can be adapted:
- Change `ARCHIVE_DIR` variable
- Modify exclusion patterns in `zip` command
- Add custom verification steps

### Building on KOSYMBIOSIS

If creating derivative works:
- Cite the original project
- Maintain NSR compliance (no exploitation)
- Align with OLF principles (well-being, ecology, harmony)
- Consider similar verification mechanisms

## 📝 License and Usage

### Euystacio Ethical Framework

Released under Euystacio principles:
- ✓ Free access to knowledge
- ✓ Respectful citation required
- ✓ NSR compliance in derivatives
- ✓ OLF alignment encouraged

### Citation

When referencing KOSYMBIOSIS:

```
KOSYMBIOSIS Project (2026). Final Archive v1.0.0. 
Euystacio Framework. https://github.com/hannesmitterer/nexus
```

## 🎉 Quick Start Summary

**Absolute minimum to get started**:

```bash
# 1. Get the files
git clone https://github.com/hannesmitterer/nexus.git
cd nexus

# 2. Verify + extract
sha256sum -c checksum.sha256
unzip kosymbiosis-final-archive.zip

# 3. Read documentation
less kosymbiosis/README.md

# Done! You now have the complete KOSYMBIOSIS archive.
```

---

**Version**: 1.0  
**Last Updated**: 2026-01-07  
**Status**: FINAL  
**Archive Size**: ~26 KB (compressed)  
**Files**: 14 total
