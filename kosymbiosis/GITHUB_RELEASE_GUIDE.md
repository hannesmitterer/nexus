# KOSYMBIOSIS GitHub Release Guide

## Overview

This guide provides step-by-step instructions for creating the KOSYMBIOSIS final archive GitHub release, ensuring proper distribution and verification of the project artifacts.

## Prerequisites

- Access to the `hannesmitterer/nexus` repository
- Permissions to create releases
- All archive files prepared:
  - `kosymbiosis-final-archive.zip`
  - `checksum.sha256`
  - `kosymbiosis.sig`
  - `kosymbiosis-co1.sig`
  - `kosymbiosis-co2.sig`

## Release Creation Steps

### 1. Navigate to Releases

1. Go to the repository: https://github.com/hannesmitterer/nexus
2. Click on "Releases" in the right sidebar
3. Click "Draft a new release"

### 2. Configure Release Details

**Tag Name**: `kosymbiosis-v1.0.0-final`

**Release Title**: `KOSYMBIOSIS Final Archive v1.0.0`

**Description Template**:

```markdown
# KOSYMBIOSIS Project - Final Archive v1.0.0

## Overview

This release contains the final, immutable archive of the KOSYMBIOSIS project, developed within the Euystacio framework with strict adherence to NSR (Non-Slavery Rule) and OLF (Optimal Life Function) principles.

## Release Contents

This release includes:

- **kosymbiosis-final-archive.zip** - Complete project archive with all documentation, metadata, declarations, and logs
- **checksum.sha256** - SHA-256 checksum for archive verification
- **kosymbiosis.sig** - Primary co-creator GPG signature
- **kosymbiosis-co1.sig** - Co-creator 1 GPG signature
- **kosymbiosis-co2.sig** - Co-creator 2 GPG signature

## Verification

### Checksum Verification

Verify archive integrity:

```bash
sha256sum -c checksum.sha256
```

Expected output:
```
kosymbiosis-final-archive.zip: OK
```

### Signature Verification

Verify all three signatures (requires co-creator public keys):

```bash
gpg --verify kosymbiosis.sig kosymbiosis-final-archive.zip
gpg --verify kosymbiosis-co1.sig kosymbiosis-final-archive.zip
gpg --verify kosymbiosis-co2.sig kosymbiosis-final-archive.zip
```

All three signatures must validate for the archive to be considered authentic.

## Archive Contents

The archive includes:

- **README.md** - Complete project overview and verification instructions
- **declarations/** - NSR compliance, OLF alignment, and co-creator attestations
- **metadata/** - Project information and contributor details
- **logs/** - Development and ethical review logs

## IPFS Distribution

For redundancy, this archive is also available via IPFS:

**IPFS CID**: [To be updated after IPFS upload]

Access via IPFS gateways:
- https://ipfs.io/ipfs/[CID]
- https://cloudflare-ipfs.com/ipfs/[CID]
- https://gateway.pinata.cloud/ipfs/[CID]

## Ethical Foundations

### Non-Slavery Rule (NSR)

The KOSYMBIOSIS project was developed with zero exploitation:
- All participation was voluntary
- Fair attribution for all contributors
- Autonomous decision-making maintained
- Human dignity respected throughout

### Optimal Life Function (OLF)

The project prioritizes:
- Stakeholder well-being maximization
- Ecological balance and sustainability
- Social harmony and collaboration
- Potential realization through knowledge sharing

**OLF Alignment Score**: 94/100

## Immutability Statement

This archive represents the final, sealed state of the KOSYMBIOSIS project as of 2026-01-07. The combination of:

- Cryptographic checksums (SHA-256)
- Triple-signature verification (GPG)
- IPFS distribution (content-addressed storage)
- GitHub release (version control)

Ensures integrity, authenticity, availability, and transparency for long-term preservation.

## License

Released under Euystacio ethical framework principles:
- Free access to knowledge
- Respectful citation of contributors
- Alignment with NSR and OLF in derivative works

## Contact

- **Email**: governance@euystacio.example
- **Repository**: https://github.com/hannesmitterer/nexus
- **Governance**: Euystacio Global Governance Initiative (GGI)

---

**Archive Sealed**: 2026-01-07  
**Framework**: Euystacio v1.0  
**Protocol**: KOSYMBIOSIS-FINAL-001
```

### 3. Upload Release Assets

Attach the following files to the release:

1. `kosymbiosis-final-archive.zip`
2. `checksum.sha256`
3. `kosymbiosis.sig`
4. `kosymbiosis-co1.sig`
5. `kosymbiosis-co2.sig`

### 4. Review and Publish

1. Review all information for accuracy
2. Ensure all five files are attached
3. Click "Publish release"

## Post-Release Tasks

### 1. Verify Release Accessibility

Test download links:
- Navigate to the release page
- Download each asset
- Verify checksums match

### 2. Update Documentation

Update any references to the release:
- Archive README (if IPFS CID becomes available)
- Project documentation
- External references

### 3. Announce Release

Consider announcing through:
- Repository README update
- Project communication channels
- Relevant communities
- Stakeholder notifications

### 4. IPFS Upload (Optional but Recommended)

If IPFS distribution is desired:

```bash
# Upload to IPFS
ipfs add kosymbiosis-final-archive.zip

# Pin for long-term availability
ipfs pin add [IPFS_CID]
```

Then update the release description with the IPFS CID.

## Verification Commands Summary

For end users to verify the release:

```bash
# Download all files
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0.0-final/kosymbiosis-final-archive.zip
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0.0-final/checksum.sha256
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0.0-final/kosymbiosis.sig
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0.0-final/kosymbiosis-co1.sig
wget https://github.com/hannesmitterer/nexus/releases/download/kosymbiosis-v1.0.0-final/kosymbiosis-co2.sig

# Verify checksum
sha256sum -c checksum.sha256

# Verify signatures (requires public keys)
gpg --verify kosymbiosis.sig kosymbiosis-final-archive.zip
gpg --verify kosymbiosis-co1.sig kosymbiosis-final-archive.zip
gpg --verify kosymbiosis-co2.sig kosymbiosis-final-archive.zip

# Extract archive
unzip kosymbiosis-final-archive.zip
cd kosymbiosis/
cat README.md
```

## Troubleshooting

### Checksum Mismatch

If checksum verification fails:
1. Re-download the archive
2. Ensure file wasn't corrupted during transfer
3. Contact repository maintainers if issue persists

### Signature Verification Fails

If GPG signature verification fails:
1. Ensure you have imported the co-creators' public keys
2. Check that the signature file matches the archive file
3. Verify you're using the correct GPG commands
4. Contact governance@euystacio.example for assistance

### Missing Files

If any release assets are missing:
1. Check that you're viewing the correct release
2. Ensure files finished uploading
3. Contact repository administrators

## Archive Integrity Checklist

Before considering the release complete:

- [ ] Archive created and tested
- [ ] Checksum generated and verified
- [ ] All three signature files created
- [ ] Release created with correct tag
- [ ] All five files uploaded as assets
- [ ] Release description complete and accurate
- [ ] Download links tested
- [ ] Verification commands tested
- [ ] Documentation updated with release information
- [ ] Stakeholders notified

## Long-term Maintenance

### Annual Verification

Recommend annual checks:
- Verify release assets still accessible
- Test download and verification process
- Update documentation if GitHub interface changes
- Maintain IPFS pins if applicable

### Contact Updates

If contact information changes:
1. Update repository README
2. Add note to release description
3. Notify community through appropriate channels

---

**Document Version**: 1.0  
**Last Updated**: 2026-01-07  
**Maintainer**: KOSYMBIOSIS Co-Creators  
**Status**: FINAL
