# Peacobond IPFS Distribution System

## Overview

The Peacobond Distribution System is an automated solution for distributing critical aid information securely across a network of IPFS nodes. This system ensures reliable, persistent delivery and storage of Peacobond aid files, eliminating reliance on public IPFS gateways and prioritizing node-to-node security.

## Features

### 1. Automated File Distribution
- **Immutable Content Addressing**: Adds files to IPFS and retrieves their immutable Content Identifier (CID)
- **Network Distribution**: Distributes CID to all IPFS nodes listed in the configuration
- **Content Persistence**: Ensures content reaches targeted nodes for long-term availability
- **DHT Announcement**: Announces content availability across the IPFS Distributed Hash Table

### 2. Robust Configuration
- **Configurable File Input**: Specify which file to distribute (default: `peacobond_contract.json`)
- **Flexible Peer Management**: Manage target nodes via `peers.txt` configuration file
- **Comprehensive Logging**: All distribution activity logged to `distribution.log` for auditing and debugging
- **Environment Variables**: Override defaults using environment variables

### 3. Validation & Verification
- **Connection Validation**: Verifies successful connection to each target IPFS node
- **Distribution Validation**: Checks that distributed CID is accessible via the DHT
- **Detailed Reporting**: Provides summary statistics on distribution success/failure

## System Requirements

### Prerequisites
- **IPFS Daemon**: IPFS must be installed and the daemon must be running
  ```bash
  ipfs daemon
  ```
- **Bash Shell**: Compatible with bash 4.0 or higher
- **Network Access**: Ability to connect to target IPFS nodes

### File Requirements
- `peacobond_contract.json` - The file to be distributed (or specify your own)
- `peers.txt` - Configuration file with target peer multi-addresses

## Installation

1. **Ensure IPFS is installed**
   ```bash
   # Check IPFS installation
   ipfs --version
   
   # If not installed, download from https://ipfs.io
   ```

2. **Start IPFS daemon**
   ```bash
   ipfs daemon &
   ```

3. **Make script executable**
   ```bash
   chmod +x peacobond_distribute.sh
   ```

## Configuration

### peers.txt Format

The `peers.txt` file should contain one peer multi-address per line. Comments (lines starting with `#`) and empty lines are ignored.

**Format Examples:**
```
# IPv4 address
/ip4/192.168.1.100/tcp/4001/p2p/QmPeerID1

# IPv6 address
/ip6/2001:db8::1/tcp/4001/p2p/QmPeerID2

# DNS address
/dns4/ipfs-node.example.org/tcp/4001/p2p/QmPeerID3

# DNS multi-address
/dnsaddr/bootstrap.libp2p.io/p2p/QmBootstrapNodeID
```

**Getting Peer IDs:**
- To get your local peer ID: `ipfs id`
- To get a remote peer's multi-address: `ipfs swarm peers`
- Peers must be reachable on the network

### Environment Variables

You can override default configuration using environment variables:

```bash
# Change the file to distribute
export PEACOBOND_FILE="my_custom_file.json"

# Change the peers configuration file
export PEERS_FILE="my_peers.txt"

# Change the log file location
export LOG_FILE="my_distribution.log"

# Run the script
./peacobond_distribute.sh
```

## Usage

### Basic Usage

1. **Prepare your Peacobond file** (default: `peacobond_contract.json`)
   ```bash
   # File already exists with example data
   cat peacobond_contract.json
   ```

2. **Configure target peers** in `peers.txt`
   ```bash
   # Edit peers.txt to add your target IPFS nodes
   nano peers.txt
   ```

3. **Run the distribution script**
   ```bash
   ./peacobond_distribute.sh
   ```

### Advanced Usage

**Distribute a different file:**
```bash
PEACOBOND_FILE="emergency_aid_2024.json" ./peacobond_distribute.sh
```

**Use a different peers configuration:**
```bash
PEERS_FILE="priority_nodes.txt" ./peacobond_distribute.sh
```

**Custom log file:**
```bash
LOG_FILE="logs/distribution_$(date +%Y%m%d).log" ./peacobond_distribute.sh
```

## Script Workflow

The distribution process follows these steps:

### 1. Pre-flight Checks
- Verifies IPFS daemon is running
- Confirms `peacobond_contract.json` exists
- Validates `peers.txt` exists and is not empty

### 2. Local File Addition
- Adds the Peacobond file to local IPFS node
- Pins the content locally to prevent garbage collection
- Retrieves and displays the CID

### 3. Peer Distribution
- Reads peer addresses from `peers.txt`
- Connects to each peer using `ipfs swarm connect`
- Announces CID to the DHT network
- Provides informational messages about remote pinning

### 4. Validation
- Waits for DHT propagation (5 seconds)
- Validates CID accessibility via each peer
- Reports validation summary

### 5. Completion
- Displays distribution summary
- Provides access URLs
- Logs all activity to `distribution.log`

## Output & Logging

### Console Output

The script provides color-coded console output:
- **Blue [INFO]**: Informational messages
- **Green [SUCCESS]**: Successful operations
- **Yellow [WARNING]**: Non-critical issues
- **Red [ERROR]**: Critical errors

### Log File

All activities are logged to `distribution.log` (or custom location) with timestamps:

```
2024-12-07 10:30:00 - [INFO] Starting distribution process
2024-12-07 10:30:01 - [SUCCESS] IPFS daemon is running
2024-12-07 10:30:02 - [SUCCESS] File added to IPFS with CID: QmXxx...
2024-12-07 10:30:05 - [SUCCESS] Connected to peer: /ip4/...
...
```

## Use Cases

### Scenario 1: Emergency Aid Distribution
**Problem**: Distribute critical aid information to IPFS nodes in conflict zones
**Solution**: 
1. Populate `peacobond_contract.json` with aid package details
2. Configure `peers.txt` with nodes in target regions
3. Run distribution script
4. Aid information is immutably stored and accessible

**Result**: Long-term storage and secure accessibility of vital aid information

### Scenario 2: Multi-Region Coordination
**Problem**: Coordinate aid distribution across multiple geographical regions
**Solution**:
1. Create region-specific peer configurations
2. Run distribution for each region
3. Validate cross-region accessibility

**Result**: Globally coordinated, locally accessible aid information

### Scenario 3: Disaster Recovery
**Problem**: Ensure aid data survives infrastructure failures
**Solution**:
1. Distribute to redundant nodes across multiple networks
2. Each node independently pins the content
3. Content remains accessible if any single node fails

**Result**: Resilient, fault-tolerant aid information system

## Troubleshooting

### IPFS Daemon Not Running
**Error**: `IPFS daemon is not running`
**Solution**:
```bash
ipfs daemon &
# Wait a few seconds for daemon to start
./peacobond_distribute.sh
```

### File Not Found
**Error**: `File not found: peacobond_contract.json`
**Solution**:
```bash
# Create or specify the file
echo '{"contract": "data"}' > peacobond_contract.json
# Or use a different file
PEACOBOND_FILE="my_file.json" ./peacobond_distribute.sh
```

### Empty Peers File
**Error**: `Peers file is empty`
**Solution**:
```bash
# Add at least one peer address to peers.txt
echo "/dnsaddr/bootstrap.libp2p.io/p2p/QmNnooDu7bfjPFoTZYxMNLWUQJyrVwtbZg5gBMjTezGAJN" >> peers.txt
```

### Connection Failures
**Warning**: `Failed to connect to peer`
**Possible Causes**:
- Peer is offline or unreachable
- Network firewall blocking connection
- Incorrect peer multi-address format
- Peer ID mismatch

**Solutions**:
- Verify peer is online: `ipfs ping <peer-id>`
- Check network connectivity
- Verify multi-address format is correct
- Update peer information if peer ID changed

### Validation Warnings
**Warning**: `CID not yet provided by peer (may take time to propagate)`
**Explanation**: Normal in distributed systems; DHT propagation takes time
**Action**: Wait a few minutes and content will become available

## Security Considerations

### Data Integrity
- **Content Addressing**: IPFS CIDs are cryptographic hashes of content
- **Immutability**: Once distributed, content cannot be altered without changing CID
- **Verification**: Recipients can verify content integrity by checking CID

### Network Security
- **No Central Point of Failure**: Distributed across multiple nodes
- **Encrypted Transport**: IPFS uses encrypted connections between nodes
- **Authentication**: Peer IDs are cryptographically verified

### Best Practices
1. **Verify Peers**: Only add trusted peers to `peers.txt`
2. **Monitor Logs**: Regularly review `distribution.log` for anomalies
3. **Backup CIDs**: Store distributed CIDs for future reference
4. **Test Distribution**: Validate content accessibility after distribution
5. **Secure the Script**: Restrict execution permissions to authorized users

## Integration with Euystacio Framework

This distribution system aligns with the Euystacio Framework principles:

### Sentimento Rhythm Dimension
- **Ethical Alignment**: Ensures aid information reaches those in need
- **Non-Manipulation**: Content-addressed data prevents tampering
- **Transparency**: All distribution actions are logged and auditable

### AI Collectivs (AIC)
- **Automated Distribution**: Removes manual bottlenecks in aid delivery
- **Optimized Routing**: IPFS DHT finds efficient paths between nodes
- **Real-Time Response**: Immediate distribution upon execution

### Global Governance Initiative (GGI)
- **Decentralized Control**: No single point of control or failure
- **Consensus-Based**: Content verified by cryptographic consensus (CID)
- **Persistent Storage**: Long-term availability through pinning

## Technical Details

### IPFS Commands Used

```bash
# Add file with pinning
ipfs add --pin=true --quieter <file>

# Connect to peer
ipfs swarm connect <peer-multiaddr>

# Announce CID to DHT
ipfs dht provide <cid>

# Find providers for CID
ipfs dht findprovs <cid>

# Get local peer ID
ipfs id
```

### Script Architecture

```
peacobond_distribute.sh
├── Configuration (environment variables)
├── Logging Functions (info, success, warning, error)
├── Validation Functions (daemon, files, peers)
├── IPFS Functions (add, connect, pin, validate)
├── Distribution Functions (distribute, validate)
└── Main Execution (orchestrates all steps)
```

## Future Enhancements

Potential improvements for future versions:

1. **Remote Pinning API**: Direct integration with IPFS pinning services
2. **Multi-File Distribution**: Support for distributing directories
3. **Progress Indicators**: Real-time progress bars for large distributions
4. **Retry Logic**: Automatic retry for failed connections
5. **Parallel Distribution**: Concurrent distribution to multiple peers
6. **Encryption Support**: Optional encryption before distribution
7. **Web Dashboard**: Visual interface for monitoring distributions
8. **Metrics Collection**: Statistics on distribution performance

## Support & Contribution

### Reporting Issues
If you encounter problems:
1. Check `distribution.log` for error details
2. Verify IPFS daemon is running: `ipfs id`
3. Test basic IPFS functionality: `ipfs add <test-file>`

### Contributing
Contributions are welcome! Please ensure:
- Code follows existing style and conventions
- Changes are minimal and focused
- Documentation is updated accordingly

## License

This script is part of the Nexus GGI project and aligns with the Euystacio Framework for global peace and prosperity initiatives.

## References

- [IPFS Documentation](https://docs.ipfs.io/)
- [IPFS Multi-addresses](https://docs.libp2p.io/concepts/addressing/)
- [Nexus Repository](https://github.com/hannesmitterer/nexus)
- [Euystacio Framework](../README.md)
