# Governance Automation Workflows

This directory contains GitHub Actions workflows that automate governance, monitoring, and compliance processes for the Nexus/Euystacio Framework.

## Overview

The Nexus project implements a decentralized governance framework (Euystacio/SAIN Protocol) with multiple automation pipelines ensuring:

- **Ethical Metrics Monitoring**: Continuous tracking of TRE, PV, and ISF
- **Proposal Management**: Automated validation and tracking of governance proposals
- **Network Synchronization**: K-SYNC protocol monitoring for EAL updates
- **Security Integrity**: Cryptographic verification and compliance checks
- **EFA Compliance**: Validation of Euystacio Field Agent authorization and participation
- **Documentation**: Automated generation of governance reports and audit trails

## Workflows

### 1. Governance Metrics Monitor
**File**: `governance-metrics-monitor.yml`  
**Trigger**: Daily at 00:00 UTC, on state.json changes, manual dispatch  
**Purpose**: Monitor ethical and financial metrics

#### Metrics Tracked
- **TRE (Tasso di Rigenerazione Etica)**: ≥0.30% annual target
- **PV (Planetary Violence)**: <5.0% threshold
- **ISF (Integral Scarcity Factor)**: ≥75 target
- **SAIN Price**: Floor protection at $10.00
- **Fee Split**: 40/30/30 validation (Restitution/Counter-Cyclicity/Burn)

#### Alerts
- ⚠️ TRE below target → Validator slashing may trigger
- 🚨 PV ≥5.0% → Regenerative Priority Session required
- ⚠️ Price ≤$10.55 → Proactive defense should execute

---

### 2. Proposal Lifecycle Automation
**File**: `proposal-lifecycle.yml`  
**Trigger**: Issues with `governance-proposal` label, manual dispatch  
**Purpose**: Automate proposal validation and voting tracking

#### Features
- Format validation (required sections check)
- IPFS CID validation (Qm... format)
- Proposal type classification
- Vote counting from comments (`/vote yes`, `/vote no`)
- Quorum calculation (50% of EFAs)
- Consensus verification (67% approval threshold)
- Voting period tracking (48 hours)

#### Usage
1. Create issue with label `governance-proposal`
2. Include required sections (Type, CID, Description, Rationale, Impact)
3. EFAs vote via comments: `/vote yes` or `/vote no`
4. After 48 hours, workflow checks quorum and consensus

---

### 3. K-SYNC Protocol Monitor
**File**: `ksync-monitor.yml`  
**Trigger**: Every 2 hours, on K-SYNC docs changes, manual dispatch  
**Purpose**: Monitor Ethical Adaptation Layer (EAL) synchronization

#### Monitoring
- **SAN Synchronization**: 12/12 SANs should be synchronized
- **EAL Version**: Current version and IPFS CID
- **Sync Performance**: Target <2 minutes average
- **CID Verification**: Hash validation against IPFS content
- **Rollback Detection**: Automatic rollback if >10% SANs fail

#### Alerts
- 🟡 Yellow: >1% SANs out of sync for >5 minutes
- 🔴 Red: >5% SANs out of sync for >10 minutes

---

### 4. Security and Integrity Checks
**File**: `security-integrity-checks.yml`  
**Trigger**: Daily at 02:00 UTC, on contract/script changes, PRs  
**Purpose**: Verify cryptographic integrity and governance compliance

#### Checks Performed
1. **Checksum Verification**
   - kosymbiosis-final-archive.zip SHA-256 validation
   - GPG triple-signature verification (3 co-creators)

2. **Smart Contract Validation**
   - Solidity linting with solhint
   - ULP parameter validation (price floor, thresholds)
   - PARAMS_ROOT hash verification
   - TFKVerifier governance parameters check

3. **Ethical Compliance**
   - Sentimento Rhythm alignment (Transparency, Provenance, Contestability)
   - Dynasty Axiom compliance (Distributed sovereignty, Friction principle)
   - KOSYMBIOSIS framework (NSR, OLF documentation)

---

### 5. EFA Compliance Monitor
**File**: `efa-compliance.yml`  
**Trigger**: Weekly on Mondays, on `efa-authorization` issues, manual dispatch  
**Purpose**: Monitor Euystacio Field Agent compliance and participation

#### Validations
- **Authorization Requests**: Format and required fields
- **Geographic Diversity**: 6 continents representation
- **DID Uniqueness**: No duplicate decentralized identifiers
- **SAN Ownership**: 1 EFA = maximum 1 SAN
- **VCE Participation**: >80% participation rate target

#### Compliance Metrics
- Total authorized EFAs: 12 current, 100+ target
- Geographic distribution across 5+ continents
- VCE participation rate: 92% average
- No duplicate DIDs or sybil attacks

---

### 6. Governance Documentation
**File**: `governance-documentation.yml`  
**Trigger**: Weekly on Sundays, on issue closures, state.json updates  
**Purpose**: Generate governance reports and audit trails

#### Generated Reports
1. **Decision Registry**: All closed governance proposals with status
2. **Weekly Summary**: Governance events, proposals, metrics alerts
3. **Audit Trail**: Monthly comprehensive governance audit with:
   - GGC multisig actions
   - Metrics evolution (TRE, PV, financial)
   - Cryptographic verification status
   - Event log from state.json

#### Report Retention
- Governance reports: 365 days
- Audit trails: 365 days
- Metrics reports: 90 days

---

## SAIN Protocol Alignment

All workflows implement requirements from **SAIN-Protocol-V1.0.md**:

### Dynasty Axiom (Adversarial Decentralization)
- ✅ Distributed sovereignty across 100+ EFAs (growing: 12/100)
- ✅ Friction veto mechanism (3 EFA minimum stake)
- ✅ Geographic diversity enforcement
- ✅ 7-of-9 GGC multisig for critical decisions

### Sentimento Rhythm (Ethical Alignment)
- ✅ Transparency: SEP schema validation
- ✅ Provenance: Blockchain anchoring verification
- ✅ Contestability: VCE mechanism automation

### Governance Parameters (TFKVerifier)
- ✅ Voting Period: 48 hours
- ✅ Consensus Threshold: 67%
- ✅ Quorum Requirement: 50%
- ✅ Auto-retrain: TRE <0.20% threshold

---

## Integration with Euystacio Framework

### Value Pyramid Implementation
1. **Apex (Sentimento Rhythm)**: Metrics monitor enforces non-negotiable principles
2. **Foundation (Scriptum Chronicum)**: Audit trails provide traceability
3. **Global Utility (Abundance)**: TRE/ISF tracking ensures equitability
4. **Individual Agency**: EFA compliance protects autonomy

### Competence Layers
1. **GGI (Global Governance Initiative)**: Audit and veto via workflows
2. **AIC (AI Collectivs)**: Metrics automation for real-time adjustment
3. **EFA (Euystacio Field Agents)**: Compliance monitoring and validation

---

## Manual Workflow Triggers

All workflows support manual triggering via GitHub Actions UI:

1. Go to **Actions** tab in GitHub
2. Select desired workflow
3. Click **Run workflow** button
4. Optionally provide input parameters (if supported)

---

## Artifacts and Reports

Workflows generate artifacts accessible via Actions tab:

- **governance-metrics-report**: Daily metrics validation
- **ksync-status-report**: K-SYNC synchronization status
- **security-report**: Comprehensive security validation
- **efa-compliance-report**: Weekly EFA audit
- **governance-reports**: Decision registry and summaries
- **audit-trail**: Monthly governance audit

Retention periods: 30-365 days depending on report type

---

## Local Testing

To test workflow logic locally:

```bash
# Install act (GitHub Actions local runner)
brew install act  # macOS
# or
sudo apt install act  # Ubuntu

# Run specific workflow
act -j monitor-tre-metrics -W .github/workflows/governance-metrics-monitor.yml

# Run with workflow_dispatch event
act workflow_dispatch -W .github/workflows/governance-metrics-monitor.yml
```

---

## Dependencies

Workflows use standard GitHub Actions:

- `actions/checkout@v4`: Repository checkout
- `actions/setup-node@v4`: Node.js setup
- `actions/github-script@v7`: GitHub API automation
- `actions/upload-artifact@v4`: Report archiving

Additional tools:
- `jq`: JSON parsing
- `bc`: Numeric calculations
- `solhint`: Solidity linting (installed via npm)

---

## Extending Workflows

To add new governance automation:

1. Create new `.yml` file in `.github/workflows/`
2. Follow existing patterns for structure
3. Use `jq` to extract data from `dashboard/data/state.json`
4. Generate reports in `reports/` subdirectory
5. Upload artifacts with appropriate retention
6. Update this README with workflow description

---

## Security Considerations

- Workflows run in isolated GitHub-hosted runners
- No secrets required for read-only operations
- Write operations (comments, labels) use `GITHUB_TOKEN`
- All validations are deterministic and verifiable
- Reports are immutable artifacts with SHA-256 hashes

---

## Contact and Governance

- **Repository**: https://github.com/hannesmitterer/nexus
- **Governance Framework**: Euystacio v1.0
- **Protocol**: SAIN (Sentinel AI Network) V1.0
- **Governing Body**: GGC (Global Governance Council) 7-of-9 multisig

---

## License

Released under Euystacio ethical framework principles:
- Free access to knowledge
- Respectful citation of contributors
- Alignment with NSR and OLF in derivative works

---

*Last Updated*: 2026-01-13  
*Version*: 1.0.0  
*Maintained by*: Euystacio Framework / SAIN Protocol Implementation Team
