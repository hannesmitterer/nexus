# GitHub Release Creation Guide

## Overview
This guide explains how to create a GitHub release for the KOSYMBIOSIS archive, ensuring immutability and public accessibility.

## Prerequisites
- GitHub account with access to the `hannesmitterer/nexus` repository
- Git and GitHub CLI (`gh`) installed, OR access to GitHub web interface
- Complete archive package:
  - `kosymbiosis-archive.zip`
  - `checksum.sha256`
  - `signatures/kosymbiosis.sig`
  - `signatures/kosymbiosis-co1.sig`
  - `signatures/kosymbiosis-co2.sig`

## Method 1: GitHub Web Interface (Recommended)

### Step 1: Navigate to Releases
1. Go to https://github.com/hannesmitterer/nexus
2. Click on "Releases" in the right sidebar
3. Click "Draft a new release"

### Step 2: Create Release Tag
- **Tag version:** `kosymbiosis-v1.0-final`
- **Target:** Select the appropriate branch (e.g., `main` or `copilot/finalize-kosymbiosis-archive-again`)
- **Release title:** `KOSYMBIOSIS v1.0 - Final Archive`

### Step 3: Write Release Notes
Copy and paste the following template:

```markdown
# KOSYMBIOSIS v1.0 - Final Archive

## Overview
This release contains the final, immutable archive of the KOSYMBIOSIS project within the Euystacio framework. The archive includes all project artifacts, documentation, and verification materials.

## Ethical Alignment
- **NSR (Non-Slavery Rule):** Compliant - Decentralized governance with adversarial checks
- **OLF (Optimal Life Function):** Aligned - Ecological regeneration and scarcity reduction

## Archive Contents
- Complete protocol specifications (SAIN, Custos Sentimento, ULP)
- Smart contracts with ethical enforcement
- Governance documentation and decision records
- Dashboard and transparency systems
- Multi-language support (EN, IT, ES)

## Verification

### SHA-256 Checksum
Download `checksum.sha256` and verify:
```bash
sha256sum -c checksum.sha256
```

### Triple-Signature Verification
This archive is signed by three independent co-creators. Verify all signatures:
```bash
gpg --verify kosymbiosis.sig kosymbiosis-archive.zip
gpg --verify kosymbiosis-co1.sig kosymbiosis-archive.zip
gpg --verify kosymbiosis-co2.sig kosymbiosis-archive.zip
```

## IPFS Distribution
For redundancy, the archive is also available on IPFS:
- **CID:** `[INSERT_CID_HERE]`
- **Gateway:** https://ipfs.io/ipfs/[INSERT_CID_HERE]

## Files Included
- `kosymbiosis-archive.zip` - Complete project archive
- `checksum.sha256` - SHA-256 checksum for verification
- `kosymbiosis.sig` - Primary co-creator signature
- `kosymbiosis-co1.sig` - Co-creator 1 signature
- `kosymbiosis-co2.sig` - Co-creator 2 signature

## Immutability Guarantee
This archive represents the final state of the KOSYMBIOSIS project:
- ✓ Cryptographic integrity (SHA-256)
- ✓ Multi-party verification (3 signatures)
- ✓ Distributed storage (IPFS + GitHub)
- ✓ Tamper-evident versioning (Git)

## Quick Start
```bash
# Download the archive
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0-final/kosymbiosis-archive.zip

# Download checksum
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0-final/checksum.sha256

# Verify
sha256sum -c checksum.sha256
```

## Documentation
See the [KOSYMBIOSIS README](https://github.com/hannesmitterer/nexus/tree/main/kosymbiosis/README.md) for complete documentation.

## Contact
- **Email:** governance@euystacio.example
- **Issues:** https://github.com/hannesmitterer/nexus/issues
- **Protocol:** See SAIN-Protocol-V1.0.md

---

**Status:** SEALED AND FINAL  
**Framework:** Euystacio GGI  
**Date:** 2026-01-07
```

### Step 4: Attach Files
Drag and drop or select the following files in the "Attach binaries" section:
1. `kosymbiosis-archive.zip`
2. `checksum.sha256`
3. `signatures/kosymbiosis.sig`
4. `signatures/kosymbiosis-co1.sig`
5. `signatures/kosymbiosis-co2.sig`

### Step 5: Publish
1. Review all information
2. Check "Set as the latest release" if appropriate
3. Click "Publish release"

## Method 2: GitHub CLI

### Install GitHub CLI
```bash
# On Ubuntu/Debian
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list
sudo apt update
sudo apt install gh

# Login
gh auth login
```

### Create Release
```bash
# Navigate to repository
cd /home/runner/work/nexus/nexus

# Create release with files
gh release create kosymbiosis-v1.0-final \
  kosymbiosis/kosymbiosis-archive.zip \
  kosymbiosis/checksum.sha256 \
  kosymbiosis/signatures/kosymbiosis.sig \
  kosymbiosis/signatures/kosymbiosis-co1.sig \
  kosymbiosis/signatures/kosymbiosis-co2.sig \
  --title "KOSYMBIOSIS v1.0 - Final Archive" \
  --notes-file kosymbiosis/GITHUB_RELEASE_NOTES.md \
  --target main
```

## Method 3: Git Tag + Manual Upload

### Create Git Tag
```bash
git tag -a kosymbiosis-v1.0-final -m "KOSYMBIOSIS v1.0 Final Archive"
git push origin kosymbiosis-v1.0-final
```

### Upload via Web Interface
Follow Method 1, but the tag will already exist.

## Post-Release Checklist

After creating the release:

- [ ] Verify all files are attached and downloadable
- [ ] Test download links
- [ ] Verify checksums of downloaded files
- [ ] Update KOSYMBIOSIS README.md with release URL
- [ ] Update KOSYMBIOSIS_METADATA.json with release information
- [ ] Announce release (if applicable)

## Release URL Structure

After creation, your release will be available at:
```
https://github.com/hannesmitterer/nexus/releases/tag/kosymbiosis-v1.0-final
```

Individual files can be downloaded via:
```
https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0-final/[FILENAME]
```

## Updating Release Notes

If you need to update the release description:
1. Go to the release page
2. Click "Edit release"
3. Update the description
4. Click "Update release"

Note: Attached files cannot be modified after upload (this ensures immutability).

## Verification for Users

Users can verify the release:

```bash
# Download all files
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0-final/kosymbiosis-archive.zip
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0-final/checksum.sha256
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0-final/kosymbiosis.sig
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0-final/kosymbiosis-co1.sig
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0-final/kosymbiosis-co2.sig

# Verify checksum
sha256sum -c checksum.sha256

# Verify signatures
gpg --verify kosymbiosis.sig kosymbiosis-archive.zip
gpg --verify kosymbiosis-co1.sig kosymbiosis-archive.zip
gpg --verify kosymbiosis-co2.sig kosymbiosis-archive.zip
```

## Best Practices

1. **Immutability:** Never delete or modify a published release
2. **Versioning:** Use semantic versioning for any future releases
3. **Documentation:** Include comprehensive release notes
4. **Verification:** Always include checksums and signatures
5. **Redundancy:** Maintain copies on IPFS and other systems

## Troubleshooting

### File upload fails
- Check file size limits (2GB per file for GitHub)
- Ensure stable internet connection
- Try web interface if CLI fails

### Tag already exists
```bash
# Delete local tag
git tag -d kosymbiosis-v1.0-final

# Delete remote tag
git push --delete origin kosymbiosis-v1.0-final

# Recreate
git tag -a kosymbiosis-v1.0-final -m "Message"
git push origin kosymbiosis-v1.0-final
```

### Permission denied
Ensure you have write access to the repository or contact the repository owner.

## Next Steps

After GitHub release:
1. ✓ Verify all downloads work correctly
2. ✓ Update project documentation with release links
3. ✓ Announce completion (if applicable)
4. ✓ Archive local copies securely

## Contact

For GitHub release questions:
- **Email:** governance@euystacio.example
- **Issues:** https://github.com/hannesmitterer/nexus/issues
