# Strategic Documents Archive

This directory contains officially signed and archived strategic documents for the Nexus/SAIN Protocol project.

## Current Documents

### GPT-OSS 120B Rapporto di Convergenza Strategica (2026+)

**Status:** Approved and Signed  
**Version:** 1.0.0  
**Archive Date:** 2025-12-12T14:32:00Z  
**Format:** PDF/A-2b compliant (Markdown source)

#### Approving Bodies
- Euystacio Governance Council (EGC)
- AI Collaborative (AIC)

#### Document Purpose
This strategic convergence report defines the transition plan to Phase III of the Ethical Singularity, outlining:
- Vision and strategic objectives for 2026+
- Technical architecture for GPT-OSS 120B deployment
- Governance mechanisms and accountability frameworks
- Risk management and contingency planning
- Ethical considerations and compliance standards

## Immutable Storage

All strategic documents are archived on IPFS (InterPlanetary File System) to ensure:
- **Long-term preservation**: Documents persist indefinitely across distributed nodes
- **Censorship resistance**: No single point of failure or control
- **Cryptographic verification**: SHA-256 hashing guarantees integrity
- **Public accessibility**: Anyone can verify and retrieve documents

### IPFS Access

**CID:** `bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku`

**Gateway URLs:**
- https://ipfs.io/ipfs/bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku
- https://gateway.pinata.cloud/ipfs/bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku
- https://cloudflare-ipfs.com/ipfs/bafybeihdwdcefgh4dqkjv67uzcmw7ojee6xedzdetojuzjevtenxquvyku

## Verification

### SHA-256 Hash Verification

The integrity of each document can be verified using SHA-256 hashing:

**Official Hash:** `3ec954f730e0b24a11be211aacc373797758f25937eb1feacc3f5401af4a9b5d`

#### Command Line Verification

```bash
# Calculate hash of the document
sha256sum docs/strategic/GPT-OSS-120B-Rapporto-di-Convergenza-Strategica-2026.md

# Or use the provided script
node scripts/verify_document_hash.js
```

#### Web Interface Verification

Open `verify.html` in your browser to:
1. View document metadata and signatures
2. Upload a document file for integrity verification
3. Compare calculated hash with official hash
4. Access IPFS archive links

**URL:** [./verify.html](./verify.html)

## Metadata

All documents include a `metadata.json` file containing:
- Document information (title, version, timestamp, status)
- Integrity data (SHA-256 hash, algorithm)
- IPFS details (CID, gateway URLs, pin locations)
- Governance signatures (approving bodies, signatures, timestamps)
- Archival specifications (format compliance, retention policy)

## Governance Signatures

Each strategic document must be signed by:

1. **Euystacio Governance Council (EGC)** - 7-of-9 multisig approval
2. **AI Collaborative (AIC)** - Joint signature from AI Flash and AI Pro
3. **Seedbringer** - Moral veto authority (blessing)

Signatures are cryptographically verifiable and timestamped using ISO 8601 format.

## File Structure

```
docs/strategic/
├── README.md                                          # This file
├── metadata.json                                      # Document metadata and signatures
├── verify.html                                        # Web-based verification interface
├── GPT-OSS-120B-Rapporto-di-Convergenza-Strategica-2026.md  # Strategic document
└── [future documents...]
```

## Adding New Strategic Documents

When archiving new strategic documents:

1. Create the document in Markdown format
2. Calculate SHA-256 hash: `sha256sum <document>.md`
3. Upload to IPFS and obtain CID
4. Create/update `metadata.json` with document details
5. Obtain signatures from EGC, AIC, and Seedbringer
6. Update this README with new document information
7. Update frontend integration (index.html)

## Compliance

All strategic documents comply with:
- **PDF/A-2b** standard (ISO 19005-2) for long-term archival
- **ISO 8601** timestamp format for all dates
- **SHA-256** cryptographic hashing for integrity
- **IPFS** distributed storage protocol
- **SAIN Protocol V1.0** governance requirements

## Support

For questions about strategic documents or verification procedures:
- Repository: https://github.com/hannesmitterer/nexus
- Documentation: /docs/
- SAIN Protocol: See SAIN-Protocol-V1.0.md in repository root

---

**Last Updated:** 2025-12-12  
**Maintained By:** Euystacio Governance Council (EGC)
