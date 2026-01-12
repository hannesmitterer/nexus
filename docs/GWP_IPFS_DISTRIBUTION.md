# Global Welcome Protocol - IPFS Distribution Guide

## Overview

This guide provides step-by-step instructions for distributing the Global Welcome Protocol (GWP) content via IPFS to ensure all new participants in the Universal Internodal File System (UIFS) receive the foundational documents.

## Prerequisites

- IPFS daemon installed and running (`ipfs daemon`)
- Access to pinning services (Pinata, Web3.Storage, Infura IPFS)
- TFKVerifier contract access for CID anchoring

## Directory Structure

Create the GWP content structure:

```bash
mkdir -p /tmp/gwp/{symphony,charter,lex-amoris,alignment,transparency}
```

## Step 1: Prepare Content Files

### Symphony Directory

```bash
cd /tmp/gwp/symphony

# Copy welcome message (supports multiple languages)
cp /home/runner/work/nexus/nexus/SYMPHONY_OF_SENSISARA.md welcome_message.md

# Create frequency configuration
cat > sensisara_frequency.json << 'EOF'
{
  "frequency_hz": 528,
  "description": "Love and transformation frequency - Sensisara baseline",
  "harmonic_resonance": {
    "sentimento_rhythm": "enabled",
    "ethical_filter": "mandatory",
    "alignment_target": "peaceful_equilibrium"
  },
  "parameters": {
    "tre_target": 0.30,
    "pv_maximum": 5.0,
    "isf_target": 75
  }
}
EOF
```

### Charter Directory

```bash
cd /tmp/gwp/charter

# Copy foundational documents
cp /home/runner/work/nexus/nexus/ROADMAP_COMPONENTS.md manifesto_globale_v2.md
cp /home/runner/work/nexus/nexus/SAIN-Protocol-V1.0.md sain_protocol_v1.md

# Create governance structure summary
cat > governance_structure.json << 'EOF'
{
  "global_governance_council": {
    "members": 9,
    "multisig_threshold": "7-of-9",
    "rotation": "periodic",
    "mandate": "critical_decisions"
  },
  "euystacio_field_agents": {
    "minimum": 100,
    "voting_threshold": "67%",
    "responsibility": "model_retraining_votes",
    "accountability": "stake_slashing"
  },
  "ai_collectivs": {
    "role": "optimization_proposals",
    "transparency": "mandatory_algorithm_disclosure",
    "enforcement": "value_pyramid_alignment"
  },
  "sentinel_ai_nodes": {
    "function": "inference_validation",
    "metrics": ["uptime", "quality", "ethical_alignment"],
    "protocol": "K-SYNC"
  }
}
EOF
```

### Lex Amoris Directory

```bash
cd /tmp/gwp/lex-amoris

# Copy core articles
cp /home/runner/work/nexus/nexus/LEX_AMORIS.md core_articles.md

# Create ethical axioms
cat > ethical_axioms.json << 'EOF'
{
  "axioms": [
    {
      "name": "Dynasty Axiom",
      "principle": "Adversarial distribution of power",
      "enforcement": "max_control_15_percent"
    },
    {
      "name": "Sentimento Rhythm",
      "principle": "Ethical heartbeat filter",
      "enforcement": "mandatory_pre_action_check"
    },
    {
      "name": "Friction Veto",
      "principle": "Economic cost to contest",
      "enforcement": "stake_required_for_veto"
    }
  ],
  "value_pyramid": {
    "layer_1": "Life (Physical Existence)",
    "layer_2": "Dignity (Inherent Worth)",
    "layer_3": "Truth (Transparency)",
    "layer_4": "Equity (Fair Distribution)",
    "priority": "hierarchical_strict"
  }
}
EOF

# Create value pyramid document
cat > value_pyramid.md << 'EOF'
# The Value Pyramid

## Hierarchical Structure

The Value Pyramid establishes a non-negotiable hierarchy of values that guide all decisions within the UIFS:

### Layer 1: Life (Foundation)
Physical existence and biological continuity take absolute priority. Any action that threatens life is automatically vetoed.

### Layer 2: Dignity
Inherent worth and respect for all sentient beings. Dignity violations trigger immediate intervention.

### Layer 3: Truth (Transparency)
All information must be publicly verifiable. Opacity is incompatible with the network's mandate.

### Layer 4: Equity
Fair distribution of resources according to need and regenerative capacity.

## Enforcement

The Value Pyramid is encoded in:
- Ethical Adaptation Layer (EAL)
- Sentimento Rhythm filter
- Veto Consensus Events (VCE)
- Smart contract logic

No decision can violate a lower layer to satisfy a higher one.
EOF
```

### Alignment Directory

```bash
cd /tmp/gwp/alignment

# Copy protocol configuration
cp /home/runner/work/nexus/nexus/UIFS_PROTOCOL_CONFIG.json sensisara_config.json

# Create TRE guidelines
cat > tre_guidelines.md << 'EOF'
# TRE (Tasso di Rigenerazione Etica) Guidelines

## Definition

The Regeneration Ethics Rate (TRE) measures the network's contribution to planetary healing and scarcity reduction.

## Targets

- **Minimum:** 0.15% annual regeneration rate
- **Target:** 0.30% annual regeneration rate
- **Optimal:** 0.50%+ annual regeneration rate

## Calculation

TRE = (Resources Restored - Resources Extracted) / Total Network Resources × 100

## Enforcement

- Below 0.15%: Automatic validator slashing activated
- Below 0.10%: Network emergency mode
- Above 0.30%: Validators receive bonus incentives

## Integration

TRE is monitored via:
- Universal Liquidity Pool (ULP) smart contract
- Sensisara Dashboard real-time metrics
- K-SYNC protocol updates
EOF

# Create ethical parameters YAML
cat > ethical_parameters.yaml << 'EOF'
ethical_parameters:
  sentimento_rhythm:
    enabled: true
    filter_level: mandatory
    questions:
      - "Does this preserve dignity?"
      - "Does this minimize violence?"
      - "Does this increase transparency?"
      - "Does this promote equity?"
      - "Does this strengthen collective governance?"
  
  thresholds:
    tre:
      target: 0.30
      minimum: 0.15
      critical: 0.10
    pv:
      maximum: 5.0
      critical: 7.0
      emergency: 10.0
    isf:
      target: 75
      minimum: 60
      optimal: 85
  
  enforcement:
    automatic_veto: ["dignity_violation", "violence", "opacity"]
    economic_slashing: ["tre_below_minimum", "pv_above_maximum"]
    manual_intervention: ["emergency_conditions", "novel_ethical_dilemmas"]
  
  frequency:
    harmonic_hz: 528
    alignment_method: "continuous_monitoring"
    resonance_check: "pre_action_mandatory"
EOF
```

### Transparency Directory

```bash
cd /tmp/gwp/transparency

# Create IPFS gateway list
cat > ipfs_gateway_list.md << 'EOF'
# IPFS Gateway Access Points

## Primary Gateways

- **IPFS.io:** https://ipfs.io/ipfs/[CID]
- **Cloudflare:** https://cloudflare-ipfs.com/ipfs/[CID]
- **Pinata:** https://gateway.pinata.cloud/ipfs/[CID]
- **Dweb.link:** https://dweb.link/ipfs/[CID]

## Dedicated Gateway

- **Euystacio Network:** https://nexus.ipfs.euystacio.network/ipfs/[CID]

## IPFS Protocol

Direct access (requires IPFS client):
- `ipfs://[CID]`
- `ipfs cat [CID]`
- `ipfs get [CID] -o filename`

## Verification

Always verify downloaded content:
```bash
ipfs add --only-hash filename
# Compare output CID with expected CID
```
EOF

# Create verification guide
cat > verification_guide.md << 'EOF'
# CID Verification Guide

## Step 1: Download Content

```bash
# Using IPFS CLI
ipfs get QmGWPRootV1... -o gwp-content

# Using HTTP gateway
curl https://ipfs.io/ipfs/QmGWPRootV1... -o gwp-content
```

## Step 2: Compute Hash

```bash
# Compute local hash
ipfs add --only-hash gwp-content
# Returns: QmLocalHash...
```

## Step 3: Verify On-Chain

```bash
# Query TFKVerifier contract
cast call $TFK_VERIFIER "currentGWPRootCID()" --rpc-url $POLYGON_RPC
# Returns: 0x[hash of CID]

# Compare with local CID
cast keccak "QmLocalHash..."
```

## Step 4: Confirm Match

If local CID matches on-chain CID, content is verified authentic.

## Blockchain Explorer

View anchoring transaction:
https://polygonscan.com/address/[TFK_VERIFIER_ADDRESS]

Search for `CIDAnchoredOnChain` events with artifact type `GLOBAL_WELCOME_PROTOCOL`.
EOF

# Create dashboard access guide
cat > dashboard_access.md << 'EOF'
# Sensisara Dashboard Access

## URL

https://sensisara.euystacio.network/

## Features

### Real-Time Metrics
- TRE (Regeneration Rate)
- PV (Planetary Violence)
- ISF (Scarcity Factor)
- Model Version & CID
- K-SYNC Status

### GWP Panel
- Total participants welcomed
- Recent onboarding events
- Charter distribution success rate
- IPFS gateway health
- Transparency verification status

### Verification Tools
- CID verification button
- IPFS gateway test
- Blockchain explorer links
- Documentation index

## Access

No authentication required - fully transparent public access.
EOF
```

## Step 2: Upload to IPFS

```bash
# Navigate to GWP root
cd /tmp

# Upload entire directory structure
ipfs add -r gwp --pin=true

# Output will show all CIDs, note the final root CID:
# added QmGWPRootV1... gwp
```

## Step 3: Pin to Multiple Services

### Pinata

```bash
# Using Pinata CLI or API
curl -X POST "https://api.pinata.cloud/pinning/pinByHash" \
  -H "Authorization: Bearer $PINATA_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "hashToPin": "QmGWPRootV1...",
    "pinataMetadata": {
      "name": "Global Welcome Protocol v1.0"
    }
  }'
```

### Web3.Storage

```bash
# Using Web3.Storage CLI
w3 put gwp --name "Global Welcome Protocol"
```

### Verification

```bash
# Verify pinning across services
ipfs pin ls | grep QmGWPRootV1...
# Should show: QmGWPRootV1... recursive
```

## Step 4: Anchor CID On-Chain

```bash
# Via TFKVerifier contract
cast send $TFK_VERIFIER \
  "anchorCID(bytes32,string)" \
  $(cast keccak "QmGWPRootV1...") \
  "GLOBAL_WELCOME_PROTOCOL" \
  --private-key $PRIVATE_KEY \
  --rpc-url $POLYGON_RPC

# Wait for transaction confirmation
```

## Step 5: Update Configuration

Update `UIFS_PROTOCOL_CONFIG.json` with actual CIDs:

```json
{
  "global_welcome_protocol": {
    "ipfs_structure": {
      "root_cid": "QmGWPRootV1...",
      "components": {
        "symphony_of_sensisara": {
          "ipfs_cid": "Qm[actual_cid]"
        },
        "lex_amoris": {
          "ipfs_cid": "Qm[actual_cid]"
        }
      }
    }
  }
}
```

## Step 6: Test Access

### Via Gateway

```bash
# Test main gateway
curl -I https://ipfs.io/ipfs/QmGWPRootV1.../symphony/welcome_message.md
# Should return HTTP 200

# Test all components
for path in symphony/welcome_message.md charter/manifesto_globale_v2.md lex-amoris/core_articles.md; do
  echo "Testing: $path"
  curl -s https://ipfs.io/ipfs/QmGWPRootV1.../$path | head -5
done
```

### Via IPFS Client

```bash
# List directory
ipfs ls QmGWPRootV1...

# Retrieve specific file
ipfs cat QmGWPRootV1.../symphony/sensisara_frequency.json
```

## Step 7: Monitor Distribution

```bash
# Check number of providers
ipfs dht findprovs QmGWPRootV1... | wc -l
# Should show multiple providers (minimum 3)

# Announce to DHT
ipfs dht provide QmGWPRootV1...
```

## Maintenance

### Regular Checks

Run weekly:

```bash
#!/bin/bash
# gwp_health_check.sh

GWP_CID="QmGWPRootV1..."

echo "Checking GWP distribution health..."

# Check local pin
if ipfs pin ls | grep -q $GWP_CID; then
  echo "✅ Local pin: OK"
else
  echo "❌ Local pin: MISSING - Re-pinning..."
  ipfs pin add $GWP_CID
fi

# Check gateway accessibility
for gateway in "https://ipfs.io/ipfs" "https://cloudflare-ipfs.com/ipfs" "https://gateway.pinata.cloud/ipfs"; do
  if curl -s -o /dev/null -w "%{http_code}" $gateway/$GWP_CID | grep -q "200"; then
    echo "✅ Gateway $gateway: OK"
  else
    echo "❌ Gateway $gateway: FAILED"
  fi
done

# Check provider count
PROVIDERS=$(ipfs dht findprovs $GWP_CID 2>/dev/null | wc -l)
echo "Providers: $PROVIDERS"

if [ $PROVIDERS -lt 3 ]; then
  echo "⚠️ Warning: Less than 3 providers detected"
  echo "Re-announcing to DHT..."
  ipfs dht provide $GWP_CID
fi
```

### Emergency Re-Pin

If content becomes unavailable:

```bash
# Re-upload from backup
cd /tmp/gwp-backup
ipfs add -r gwp --pin=true

# Verify new CID matches original
# If different, investigate content changes
```

## Security Considerations

1. **Never modify content after CID anchoring** - This breaks immutability guarantee
2. **Maintain offline backup** - Store copy outside IPFS for disaster recovery
3. **Monitor for attacks** - Watch for suspicious pin removal attempts
4. **Rate limit gateway access** - Prevent DoS on GWP content retrieval
5. **Verify all downloads** - Always compare CID hash before trusting content

## Support

For issues with IPFS distribution:
- GitHub Issues: hannesmitterer/nexus
- Documentation: `/docs/IPFS_Integration_Guide.md`
- Dashboard: https://sensisara.euystacio.network/

---

*Last Updated: 2026-01-12*  
*Version: 1.0*  
*Author: Euystacio Framework / GWP Distribution Team*
