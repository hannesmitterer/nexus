# KOSYMBIOSIS Project - File Index

## Purpose
This index provides a quick reference to all files in the KOSYMBIOSIS archive, their purpose, and their relationships.

## Core Documentation

### README.md
- **Purpose:** Main entry point for the archive
- **Contains:** Overview, verification instructions, IPFS/GitHub info
- **Audience:** General users, auditors, verifiers
- **Status:** Complete with checksum and timestamp

### KOSYMBIOSIS_DECLARATION.md
- **Purpose:** Official project mandate and ethical alignment
- **Contains:** NSR/OLF compliance, principles, commitments
- **Audience:** Stakeholders, governance bodies, auditors
- **Status:** Final and sealed

### KOSYMBIOSIS_METADATA.json
- **Purpose:** Machine-readable technical specifications
- **Contains:** Project config, protocols, metrics, distribution info
- **Audience:** Automated tools, technical integrators
- **Status:** Complete, ready for parsing

### KOSYMBIOSIS_FINAL_LOG.txt
- **Purpose:** Execution timeline and event history
- **Contains:** Chronological record of all project milestones
- **Audience:** Auditors, historians, compliance teams
- **Status:** Final log, no further entries

### ARCHIVAL_PROCESS.md
- **Purpose:** Complete guide to the archival process
- **Contains:** Step-by-step workflow, status tracking, checklists
- **Audience:** Co-creators, maintainers, future archivists
- **Status:** Living document (current status: awaiting signatures)

## Distribution Guides

### IPFS_DISTRIBUTION.md
- **Purpose:** Instructions for IPFS upload and verification
- **Contains:** Multiple upload methods, verification steps, troubleshooting
- **Audience:** Co-creators performing IPFS upload
- **Dependencies:** Archive must be created first

### GITHUB_RELEASE.md
- **Purpose:** Instructions for GitHub release creation
- **Contains:** Release configuration, methods, verification steps
- **Audience:** Co-creators with repository access
- **Dependencies:** Archive, checksum, signatures

## Scripts

### scripts/create_archive.sh
- **Purpose:** Automated archive creation
- **Input:** Project files from repository
- **Output:** kosymbiosis-archive.zip, checksum.sha256
- **Status:** Tested and working
- **Usage:** `bash scripts/create_archive.sh`

### scripts/verify_archive.sh
- **Purpose:** Archive integrity verification
- **Input:** kosymbiosis-archive.zip, checksum.sha256, signatures (optional)
- **Output:** Verification report
- **Status:** Tested and working
- **Usage:** `bash scripts/verify_archive.sh [archive-file]`

## Signatures

### signatures/SIGNATURE_INSTRUCTIONS.md
- **Purpose:** GPG signature creation and verification guide
- **Contains:** Commands, workflows, troubleshooting
- **Audience:** Co-creators, verifiers
- **Status:** Complete

### signatures/*.sig.placeholder
- **Purpose:** Placeholders for actual signature files
- **Status:** Awaiting replacement by actual GPG signatures
- **Note:** Actual .sig files are excluded from git (see .gitignore)

## Generated Files

### kosymbiosis-archive.zip
- **Purpose:** The sealed archive containing all project artifacts
- **Size:** ~50 KB
- **Contents:** 39 files (protocols, contracts, docs, data)
- **Checksum:** 5b0a84e35b910d834b4d6e013a228a151873663ada978518070e621355948cb0
- **Status:** Generated and verified
- **Note:** Excluded from git (see .gitignore)

### checksum.sha256
- **Purpose:** SHA-256 checksum for archive verification
- **Format:** `[hash] [filename]`
- **Status:** Generated with archive
- **Verification:** `sha256sum -c checksum.sha256`

## Artifacts Directory

The `artifacts/` directory is created during archive creation and contains:

### Protocol Files
- SAIN-Protocol-V1.0.md
- Sentinel_MANIFESTO.md
- ACTUS_RESONANTIAE_CUSTOS_SENTIMENTO.json
- HARMONIC_CONFIRMATION_CUSTOS_SENTIMENTO.json
- CUSTOS_SENTIMENTO.md

### Smart Contracts
- UniversalLiquidityPool.sol
- Validator_and_Collateral_Enforcement_VCE.sol
- contracts/ULP.sol
- contracts/ulp_parameters.canonical.json

### Documentation
- ULP_DEPLOYMENT_GUIDE.md
- ULP_ACCEPTANCE_CRITERIA.md
- ULP_README.md
- AIC_Manuale_Operativo_Finale.md
- Rapporto_di_Allineamento_Zero.txt

### Dashboard and Data
- dashboard/ (complete web interface)
  - index.html, app.js, styles.css
  - locale/ (EN, IT, ES translations)
  - data/ (state.json, onchain.json, history.json)

## Configuration Files

### .gitignore
- **Purpose:** Exclude generated files from version control
- **Excludes:** Archive, actual signatures, temp files
- **Keeps:** Placeholders, documentation, scripts
- **Status:** Active

## File Relationships

```
Archive Creation Flow:
└─ create_archive.sh
   ├─ Reads: All project files
   ├─ Creates: kosymbiosis-archive.zip
   └─ Generates: checksum.sha256

Signature Flow:
└─ SIGNATURE_INSTRUCTIONS.md
   ├─ Input: kosymbiosis-archive.zip
   └─ Output: *.sig files (3 total)

Verification Flow:
└─ verify_archive.sh
   ├─ Reads: kosymbiosis-archive.zip
   ├─ Reads: checksum.sha256
   ├─ Reads: signatures/*.sig (optional)
   └─ Reports: Verification status

Distribution Flow:
├─ IPFS_DISTRIBUTION.md
│  ├─ Input: kosymbiosis-archive.zip
│  └─ Output: IPFS CID
└─ GITHUB_RELEASE.md
   ├─ Input: Archive, checksum, signatures
   └─ Output: Public GitHub release
```

## Reading Order

### For First-Time Users:
1. README.md - Get overview
2. KOSYMBIOSIS_DECLARATION.md - Understand the project
3. verify_archive.sh - Verify your download
4. ARCHIVAL_PROCESS.md - See complete status

### For Co-Creators:
1. ARCHIVAL_PROCESS.md - Current status
2. SIGNATURE_INSTRUCTIONS.md - Create your signature
3. IPFS_DISTRIBUTION.md - Upload to IPFS
4. GITHUB_RELEASE.md - Create release

### For Developers/Integrators:
1. KOSYMBIOSIS_METADATA.json - Technical specs
2. KOSYMBIOSIS_FINAL_LOG.txt - Event history
3. artifacts/ - Source materials
4. scripts/ - Automation tools

### For Auditors:
1. KOSYMBIOSIS_DECLARATION.md - Ethical claims
2. KOSYMBIOSIS_FINAL_LOG.txt - Timeline verification
3. verify_archive.sh - Integrity check
4. KOSYMBIOSIS_METADATA.json - Technical validation

## File Integrity

All files in this directory contribute to the immutable archive:

- **Documentation:** Human-readable, comprehensive
- **Scripts:** Executable, tested, reproducible
- **Metadata:** Machine-readable, versioned
- **Archive:** Sealed, checksummed, signed
- **Guides:** Step-by-step, complete

## Maintenance

### Current State (2026-01-07)
- ✓ All documentation complete
- ✓ Archive generated and verified
- ⏳ Awaiting GPG signatures
- ⏳ Awaiting IPFS upload
- ⏳ Awaiting GitHub release

### Future Updates
Once signatures and distribution are complete:
- Update README.md with IPFS CID
- Update README.md with GitHub release URL
- Update KOSYMBIOSIS_METADATA.json with distribution info
- Create IPFS_CID.txt with the CID
- Mark ARCHIVAL_PROCESS.md as complete

### Immutability Note
After signing and distribution, no files should be modified. Any changes would invalidate signatures and checksums.

---

**Last Updated:** 2026-01-07T00:55:00Z  
**Total Files:** 15 in repository, 39 in archive  
**Status:** Archive ready for signature collection
