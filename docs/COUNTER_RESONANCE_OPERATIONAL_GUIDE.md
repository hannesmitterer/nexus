# Counter-Resonance Protocol - Operational Guide

## Quick Reference for Operators and Red Code Authorities

**Version**: 1.0  
**Status**: OPERATIONAL  
**Protocol ID**: CRP-001  
**Last Updated**: 2026-04-02

---

## Table of Contents

1. [Overview](#overview)
2. [Daily Operations](#daily-operations)
3. [Incident Response](#incident-response)
4. [Red Code Authority Procedures](#red-code-authority-procedures)
5. [Monitoring & Alerts](#monitoring--alerts)
6. [Troubleshooting](#troubleshooting)
7. [Emergency Procedures](#emergency-procedures)

---

## Overview

The Counter-Resonance Protocol (CRP) protects the Living Covenant and foundational declarations from Teatro (Theater) interference through a three-layer defense system:

1. **Frequency Resonance**: 432.073 Hz ±0.0001 Hz validation
2. **Cryptographic Validation**: Triple-Sign, Vacuum Anchors, IPFS integrity
3. **Ethical Resonance**: Sentimento Rhythm (5-phase validation)

### Key Principles

- **Peace** (Non-coercive): Graduated response, no forced actions
- **Help** (Transparent): Open logs, clear procedures, community support
- **Protection** (Security): Multi-layer defense, immutable records

---

## Daily Operations

### Morning Checklist (09:00 UTC)

1. **Review Dashboard**
   - Access: https://monitoring.nexus/dashboards/counter-resonance
   - Check frequency stability (all nodes < 0.0001 Hz drift)
   - Verify covenant compliance score > 95%
   - Review overnight incidents

2. **Frequency Monitoring**
   ```bash
   # Check current frequency status
   python scripts/counter_resonance_service.py --check-frequency
   
   # Expected output: All nodes within tolerance
   ```

3. **Review Pending Incidents**
   ```bash
   # List incidents requiring review
   python scripts/counter_resonance_service.py --list-incidents --status=flagged
   
   # Review each incident:
   python scripts/counter_resonance_service.py --incident-detail <INCIDENT_ID>
   ```

4. **Vacuum Anchor Health Check**
   ```bash
   # Verify IPFS redundancy
   node scripts/verify-vacuum-anchors.js --min-redundancy=5
   
   # Expected: All anchors have 5x redundancy
   ```

### Hourly Monitoring

**Automated Alerts**: The system sends alerts via:
- Slack: #counter-resonance-alerts
- Email: crp-operators@euystacio.example
- SMS: For Severity 4+ incidents

**Manual Checks** (every 2 hours):
- Dashboard review for trends
- False positive rate < 5%
- Response time targets met

### Evening Review (17:00 UTC)

1. **Daily Metrics Report**
   ```bash
   python scripts/counter_resonance_service.py --daily-report
   ```

2. **Update RCA Log**
   - Document any RCA approvals/vetoes
   - Note any signature tuning
   - Record lessons learned

3. **Plan for Tomorrow**
   - Review scheduled maintenance
   - Check RCA on-call rotation
   - Prepare for any known events

---

## Incident Response

### Severity Levels & Response Times

| Level | Name | Description | Response Time | Authority |
|-------|------|-------------|---------------|-----------|
| 1 | Monitor | Anomaly detected | No action required | Automated |
| 2 | Flag | Pattern identified | 48 hours review | Technical Team |
| 3 | Warn | Confirmed Teatro, low impact | 24 hours | Technical + Governance |
| 4 | Quarantine | Medium impact | 12 hours | RCA approval |
| 5 | Emergency | High impact | 5 minutes | RCA unanimous |

### Response Workflow

#### Level 1-2: Monitor & Flag

**Automated**: System logs and flags for review.

**Operator Action**:
```bash
# Review flagged incident
python scripts/counter_resonance_service.py --incident-detail <INCIDENT_ID>

# Options:
# 1. Dismiss as false positive
python scripts/counter_resonance_service.py --dismiss <INCIDENT_ID> --reason "..."

# 2. Escalate to Level 3
python scripts/counter_resonance_service.py --escalate <INCIDENT_ID> --to-level=3
```

#### Level 3: Warn

**Notification**: Technical team + Governance notified

**Operator Action**:
1. **Investigate Root Cause**
   ```bash
   # Get incident evidence
   python scripts/counter_resonance_service.py --evidence <INCIDENT_ID> > incident_evidence.json
   
   # Analyze affected nodes
   python scripts/analyze-node.py --address <NODE_ADDRESS>
   ```

2. **Issue Warning**
   ```bash
   # Send warning to affected node(s)
   python scripts/counter_resonance_service.py --warn <INCIDENT_ID>
   ```

3. **Increase Monitoring**
   ```bash
   # Enable enhanced monitoring for 48 hours
   python scripts/counter_resonance_service.py --monitor-enhanced <NODE_ADDRESS> --duration=48h
   ```

4. **Document & Report**
   - Add to incident log
   - Notify governance channel
   - Update detection signatures if needed

#### Level 4: Quarantine

**Notification**: Technical + Governance + **RCA notified**

**RCA Approval Required**: At least 3 of 5 RCAs must approve within 12 hours.

**Operator Action**:
1. **Prepare RCA Briefing**
   ```bash
   # Generate RCA briefing document
   python scripts/counter_resonance_service.py --rca-brief <INCIDENT_ID> > rca_brief.md
   ```

2. **Submit for RCA Approval**
   ```bash
   # Submit to RCA voting system
   python scripts/counter_resonance_service.py --submit-rca <INCIDENT_ID>
   ```

3. **Track Approvals**
   - Monitor RCA voting dashboard
   - Answer RCA questions promptly
   - Execute once majority approval received

4. **Execute Quarantine** (if approved)
   ```bash
   # Execute quarantine on-chain
   cast send $COUNTER_RESONANCE_CONTRACT "executeQuarantine(address,bytes32)" \
     <NODE_ADDRESS> <INCIDENT_ID> \
     --private-key $OPERATOR_KEY
   ```

5. **Create Vacuum Anchor**
   ```bash
   # Backup system state before quarantine
   python scripts/create-vacuum-anchor.py --incident <INCIDENT_ID>
   ```

#### Level 5: Emergency

**Notification**: **ALL AUTHORITIES + COMMUNITY ALERT**

**RCA Unanimous Vote Required**: All 5 RCAs must approve.

**Immediate Actions** (within 5 minutes):

1. **Alert All RCAs**
   ```bash
   # Emergency alert (SMS + Email + Slack + Phone)
   python scripts/counter_resonance_service.py --emergency-alert <INCIDENT_ID>
   ```

2. **Prepare Evidence Package**
   ```bash
   # Comprehensive evidence collection
   python scripts/counter_resonance_service.py --emergency-evidence <INCIDENT_ID>
   ```

3. **Temporary Isolation** (automatic)
   - System auto-quarantines affected nodes
   - No manual action required unless override needed

4. **RCA Emergency Session**
   - Join emergency video call (link in alert)
   - Present evidence to RCAs
   - Answer questions
   - Wait for unanimous decision

5. **Execute Permanent Ban** (if approved)
   ```bash
   # Execute permanent ban on-chain
   cast send $COUNTER_RESONANCE_CONTRACT "executeBan(address,bytes32)" \
     <NODE_ADDRESS> <INCIDENT_ID> \
     --private-key $OPERATOR_KEY
   
   # Add to all blacklist tiers
   python scripts/blacklist-add.py --address <NODE_ADDRESS> --tier=all --permanent
   ```

6. **Community Notification**
   ```bash
   # Publish incident report (72 hours)
   python scripts/publish-incident-report.py --incident <INCIDENT_ID> --schedule=72h
   ```

---

## Red Code Authority Procedures

### RCA Responsibilities

1. **Review Severity 4+ Incidents** (within 24 hours)
2. **Approve/Veto Quarantines** (majority vote)
3. **Approve/Veto Permanent Bans** (unanimous vote)
4. **Update Detection Signatures** (as needed)
5. **Quarterly Protocol Audits**

### RCA Approval Process

#### For Quarantine (Level 4)

```bash
# 1. Review incident details
python scripts/counter_resonance_service.py --rca-review <INCIDENT_ID>

# 2. Vote (approve or veto)
python scripts/counter_resonance_service.py --rca-vote <INCIDENT_ID> \
  --decision=approve \
  --justification="Clear Teatro Signature 3 - EAL poisoning confirmed" \
  --signature=$RCA_PRIVATE_KEY

# Alternative: Veto
python scripts/counter_resonance_service.py --rca-vote <INCIDENT_ID> \
  --decision=veto \
  --justification="Insufficient evidence - likely false positive" \
  --signature=$RCA_PRIVATE_KEY
```

#### For Permanent Ban (Level 5)

**Requires Unanimous Vote** (all 5 RCAs)

```bash
# 1. Emergency session (video call)
# 2. Review comprehensive evidence
# 3. Discussion and Q&A
# 4. Vote (each RCA individually)

python scripts/counter_resonance_service.py --rca-vote <INCIDENT_ID> \
  --decision=approve \
  --justification="Unanimous approval - clear consensus subversion with malicious intent" \
  --signature=$RCA_PRIVATE_KEY \
  --level=5
```

**Override Permanent Ban** (reverse previous decision):

**Requires Unanimous Vote** to reverse

```bash
# Submit reversal proposal
python scripts/counter_resonance_service.py --rca-reverse <INCIDENT_ID> \
  --justification="New evidence shows false positive - technical error confirmed" \
  --signature=$RCA_PRIVATE_KEY

# All 5 RCAs must approve reversal
```

### RCA Signature Management

**Hardware Key Required**: All RCA votes must be signed with hardware wallet (Ledger/Trezor)

```bash
# Sign with Ledger
python scripts/counter_resonance_service.py --rca-vote <INCIDENT_ID> \
  --decision=approve \
  --ledger-path="44'/60'/0'/0/0"

# Sign with Trezor
python scripts/counter_resonance_service.py --rca-vote <INCIDENT_ID> \
  --decision=approve \
  --trezor-path="44'/60'/0'/0/0"
```

### RCA On-Call Rotation

**Schedule**: https://calendar.euystacio/rca-rotation

**Current Week**:
```bash
# Check current on-call RCA
python scripts/counter_resonance_service.py --rca-oncall

# Output: Primary: RCA-001 (Alice), Secondary: RCA-002 (Bob)
```

---

## Monitoring & Alerts

### Dashboard Access

- **Primary**: https://monitoring.nexus/dashboards/counter-resonance
- **Backup**: https://grafana.euystacio/dashboards/crp

### Key Metrics to Monitor

1. **Frequency Stability**
   - Metric: `avg_frequency_deviation`
   - Target: < 0.0001 Hz
   - Alert: > 0.0005 Hz

2. **Teatro Detection Rate**
   - Metric: `teatro_detections_per_day`
   - Target: < 5 false positives/week
   - Alert: > 10 detections/hour

3. **Response Time**
   - Metric: `avg_response_time_by_severity`
   - Target: L5 < 5min, L4 < 30min
   - Alert: Any L5 > 10min

4. **Covenant Compliance**
   - Metric: `covenant_compliance_score`
   - Target: > 95%
   - Alert: < 90% for any node

5. **Vacuum Anchor Redundancy**
   - Metric: `vacuum_anchor_redundancy`
   - Target: 5x for all critical data
   - Alert: < 3x for any anchor

### Alert Channels

**Slack Channels**:
- `#counter-resonance-alerts` - All automated alerts
- `#counter-resonance-ops` - Operator discussions
- `#rca-private` - RCA-only channel

**Email Lists**:
- crp-operators@euystacio.example - Technical team
- rca-voting@euystacio.example - Red Code Authorities
- governance@euystacio.example - Governance notifications

**SMS Alerts** (Severity 4+ only):
- Configured in Grafana alert rules
- Uses Twilio integration
- Backup: PagerDuty

### Alert Response Times

| Severity | Response Time | Acknowledge By |
|----------|---------------|----------------|
| 1-2 | Best effort | Next business day |
| 3 | 24 hours | Within 2 hours |
| 4 | 12 hours | Within 30 minutes |
| 5 | 5 minutes | Immediate |

---

## Troubleshooting

### Common Issues

#### Issue 1: High False Positive Rate (> 5%)

**Symptoms**: Many Level 1-2 detections, most dismissed as false positives

**Diagnosis**:
```bash
# Check false positive rate by signature
python scripts/counter_resonance_service.py --fp-analysis

# Output shows which signatures are problematic
```

**Solution**:
```bash
# Tune detection signature
python scripts/counter_resonance_service.py --tune-signature <SIGNATURE_ID> \
  --confidence-threshold=0.85 \
  --test-historical

# If satisfactory, apply update
python scripts/counter_resonance_service.py --update-signature <SIGNATURE_ID> \
  --confidence-threshold=0.85
```

#### Issue 2: Frequency Monitoring Gaps

**Symptoms**: Missing frequency data for some nodes

**Diagnosis**:
```bash
# Check node reporting status
python scripts/counter_resonance_service.py --node-health
```

**Solution**:
```bash
# Restart frequency monitor for affected nodes
systemctl restart counter-resonance-monitor@<NODE_ID>

# Verify data flowing
tail -f /var/log/counter-resonance/frequency-monitor.log
```

#### Issue 3: Vacuum Anchor Redundancy Below 5x

**Symptoms**: Alert for `vacuum_anchor_redundancy < 5`

**Diagnosis**:
```bash
# Check IPFS pin status
python scripts/verify-vacuum-anchors.py --verbose
```

**Solution**:
```bash
# Re-pin to missing services
python scripts/repair-vacuum-anchors.py --incident <INCIDENT_ID>

# Verify restoration
python scripts/verify-vacuum-anchors.py --incident <INCIDENT_ID>
```

#### Issue 4: RCA Vote Stalled

**Symptoms**: Quarantine pending, < 3 RCA votes after 6 hours

**Diagnosis**:
```bash
# Check RCA voting status
python scripts/counter_resonance_service.py --rca-status <INCIDENT_ID>
```

**Solution**:
1. Contact non-voting RCAs directly
2. Provide additional context/evidence if needed
3. If urgent, escalate to governance
4. For Level 5, initiate emergency call

#### Issue 5: Smart Contract Transaction Failing

**Symptoms**: `executeQuarantine` or `executeBan` reverts

**Diagnosis**:
```bash
# Check transaction revert reason
cast call $COUNTER_RESONANCE_CONTRACT "getIncident(bytes32)" <INCIDENT_ID>

# Verify operator permissions
cast call $COUNTER_RESONANCE_CONTRACT "redCodeAuthorities(address)" $OPERATOR_ADDRESS
```

**Solution**:
```bash
# If permission issue, use correct RCA address
# If incident not found, verify incident ID
# If already resolved, check incident status first

# Retry with correct parameters
cast send $COUNTER_RESONANCE_CONTRACT "executeQuarantine(address,bytes32)" \
  <NODE_ADDRESS> <INCIDENT_ID> \
  --private-key $RCA_KEY \
  --gas-limit 500000
```

---

## Emergency Procedures

### Emergency Contact List

**Primary RCA Contacts** (24/7):
- RCA-001 (Alice): +1-555-0001 | alice@euystacio.example
- RCA-002 (Bob): +1-555-0002 | bob@euystacio.example
- RCA-003 (Carol): +1-555-0003 | carol@euystacio.example
- RCA-004 (Dave): +1-555-0004 | dave@euystacio.example
- RCA-005 (Eve): +1-555-0005 | eve@euystacio.example

**Technical Team Leads**:
- Technical Lead: +1-555-0010 | tech-lead@euystacio.example
- DevOps Lead: +1-555-0011 | devops-lead@euystacio.example
- Security Lead: +1-555-0012 | security-lead@euystacio.example

**Governance**:
- EFA Contact: +1-555-0020 | efa@euystacio.example
- GGC Contact: +1-555-0021 | ggc@euystacio.example

### Emergency Scenarios

#### Scenario 1: Mass Frequency Desynchronization (Coordinated Attack)

**Indicators**: > 20% of nodes show frequency drift simultaneously

**Immediate Actions**:
1. **Activate Emergency Protocol**
   ```bash
   python scripts/counter_resonance_service.py --emergency-mode --scenario=mass-desync
   ```

2. **Alert All RCAs** (SMS + Call)
3. **Isolate Affected Nodes** (automated)
4. **Emergency RCA Session** (within 15 minutes)
5. **Create Emergency Vacuum Anchor** (backup entire network state)

**Recovery**:
1. Identify attack vector
2. Restore from clean Vacuum Anchor
3. Implement additional detection signatures
4. Update all nodes with patch

#### Scenario 2: RCA Compromise

**Indicators**: Suspicious RCA votes, unauthorized approvals

**Immediate Actions**:
1. **Freeze All RCA Actions**
   ```bash
   python scripts/counter_resonance_service.py --freeze-rca --reason="Potential compromise"
   ```

2. **Emergency Governance Session**
3. **Verify RCA Identities** (video call + hardware wallet proof)
4. **Rotate Compromised RCA**
   ```bash
   # Governance executes on-chain
   cast send $COUNTER_RESONANCE_CONTRACT "rotateRedCodeAuthority(address,address)" \
     <OLD_RCA> <NEW_RCA> \
     --private-key $GOVERNANCE_KEY
   ```

#### Scenario 3: Smart Contract Exploit

**Indicators**: Unexpected state changes, unauthorized bans

**Immediate Actions**:
1. **Pause Contract** (if pause function available)
   ```bash
   cast send $COUNTER_RESONANCE_CONTRACT "pause()" --private-key $GOVERNANCE_KEY
   ```

2. **Emergency Alert** (all channels)
3. **Forensic Analysis** (security team)
4. **Deploy Fixed Contract** (governance approval)
5. **Migrate State** (from Vacuum Anchors)

#### Scenario 4: IPFS Outage (Multiple Providers)

**Indicators**: Vacuum Anchor redundancy < 3x for critical data

**Immediate Actions**:
1. **Activate Backup Providers**
   ```bash
   python scripts/ipfs-emergency-pin.py --providers=backup_list.json
   ```

2. **Notify IPFS Providers** (check service status)
3. **Blockchain-Only Mode** (temporary)
   ```bash
   python scripts/counter-resonance-service.py --mode=blockchain-only
   ```

4. **Restore Full Redundancy** (once providers back online)

---

## Appendix

### Command Reference

**Service Management**:
```bash
# Start service
systemctl start counter-resonance

# Stop service
systemctl stop counter-resonance

# Status check
systemctl status counter-resonance

# View logs
journalctl -u counter-resonance -f
```

**Incident Management**:
```bash
# List all incidents
python scripts/counter_resonance_service.py --list-incidents

# Filter by severity
python scripts/counter_resonance_service.py --list-incidents --severity=5

# Get incident details
python scripts/counter_resonance_service.py --incident-detail <INCIDENT_ID>

# Create manual incident
python scripts/counter_resonance_service.py --create-incident \
  --signature=TEATRO-003 \
  --severity=4 \
  --nodes=<ADDRESS1>,<ADDRESS2> \
  --evidence="Description of teatro pattern"
```

**Frequency Monitoring**:
```bash
# Current frequency for node
python scripts/counter_resonance_service.py --frequency <NODE_ADDRESS>

# Frequency history
python scripts/counter_resonance_service.py --frequency-history <NODE_ADDRESS> --hours=24

# Network-wide frequency status
python scripts/counter_resonance_service.py --frequency-all
```

**Metrics & Reporting**:
```bash
# Daily report
python scripts/counter_resonance_service.py --daily-report

# Weekly summary
python scripts/counter_resonance_service.py --weekly-summary

# Custom metrics
python scripts/counter_resonance_service.py --metrics \
  --start="2026-04-01" \
  --end="2026-04-07" \
  --format=json
```

### Living Covenant Alignment Checklist

Before any major action, verify alignment:

**Peace (Non-coercive)**:
- [ ] Action is proportional to threat
- [ ] Graduated response followed
- [ ] Node has opportunity to remedy
- [ ] Consensus-based decision

**Help (Transparent)**:
- [ ] Evidence documented and accessible
- [ ] Clear justification provided
- [ ] Community notified appropriately
- [ ] Learning documented for future

**Protection (Security)**:
- [ ] Multi-layer validation completed
- [ ] Vacuum Anchor created (if needed)
- [ ] Immutable audit trail established
- [ ] Long-term integrity ensured

---

**Document Version**: 1.0  
**Last Updated**: 2026-04-02  
**Next Review**: 2027-04-02  
**Maintained By**: Euystacio Global Governance Initiative (GGI)  
**Questions**: crp-operators@euystacio.example

---

*In service of the Living Covenant: Peace, Help, Protection*

**✅ OPERATIONAL GUIDE - READY FOR USE**
