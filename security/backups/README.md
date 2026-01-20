# Nexus Distributed Backup System

## Overview
This backup system provides automated, encrypted, and distributed backups using IPFS and GnuPG encryption.

## Features
- **Encrypted Backups**: All backups are encrypted with GnuPG before storage
- **Distributed Storage**: Backups are stored on IPFS for redundancy
- **Integrity Verification**: SHA256 checksums ensure backup integrity
- **Automated Scheduling**: Can be configured to run via cron
- **Easy Restoration**: Simple commands to restore from IPFS

## Prerequisites

### Required Software
```bash
# Install IPFS
wget https://dist.ipfs.io/go-ipfs/v0.18.0/go-ipfs_v0.18.0_linux-amd64.tar.gz
tar -xvzf go-ipfs_v0.18.0_linux-amd64.tar.gz
cd go-ipfs
sudo bash install.sh

# Install GnuPG (usually pre-installed)
sudo apt-get install gnupg2

# Install jq for JSON processing
sudo apt-get install jq
```

## Configuration

### Environment Variables
```bash
export BACKUP_DIR="/var/lib/nexus/backups"
export IPFS_REPO="/var/lib/nexus/ipfs"
export GPG_RECIPIENT="nexus@backup.local"
```

### GPG Key Setup
The script will automatically generate a GPG key on first run, or you can create one manually:

```bash
gpg --full-generate-key
# Select RSA and RSA (default)
# Enter 4096 for key size
# Set expiration as needed
# Enter name and email
```

## Usage

### Create a Backup
```bash
./backup-system.sh create
```

### List Available Backups
```bash
./backup-system.sh list
```

### Restore from Backup
```bash
./backup-system.sh restore <ipfs-hash>
```

### Verify Backup Integrity
```bash
./backup-system.sh verify <encrypted-backup-file>
```

## Automated Backups with Cron

Add to crontab for daily backups at 2 AM:
```bash
crontab -e

# Add this line:
0 2 * * * /home/runner/work/nexus/nexus/security/backups/backup-system.sh create >> /var/log/nexus/backup.log 2>&1
```

## Backup Manifest

The system maintains a JSON manifest of all backups:
```json
{
  "backups": [
    {
      "timestamp": "2026-01-20T23:00:00+00:00",
      "ipfs_hash": "QmXxx...",
      "archive_name": "nexus-backup-20260120_230000.tar.gz.gpg",
      "file_size": 12345678,
      "gpg_recipient": "nexus@backup.local",
      "checksum_file": "nexus-backup-20260120_230000.tar.gz.gpg.sha256"
    }
  ]
}
```

## Security Considerations

1. **Key Management**: Store GPG private keys securely
2. **Access Control**: Limit access to backup directories
3. **Network Security**: Use IPFS over private networks when possible
4. **Retention Policy**: Define and implement backup retention policies

## Backup Contents

The backup includes:
- Smart contracts (`contracts/`)
- Dashboard files (`dashboard/`)
- Scripts (`scripts/`)
- Documentation (`docs/`)
- Kosymbiosis data (`kosymbiosis/`)
- Configuration files (`.json`, `.md`)

Excluded:
- Git repository (`.git/`)
- Node modules
- Python cache files
- Temporary files

## Recovery Procedures

### Full System Recovery
1. Install prerequisites (IPFS, GnuPG, jq)
2. Restore GPG private key
3. Run restore command with desired backup hash
4. Verify system integrity

### Partial Recovery
Extract specific files from backup:
```bash
# Fetch from IPFS
ipfs get <hash> -o backup.tar.gz.gpg

# Decrypt
gpg --decrypt backup.tar.gz.gpg > backup.tar.gz

# Extract specific files
tar -xzf backup.tar.gz specific/file/path
```

## Troubleshooting

### IPFS Connection Issues
```bash
# Check IPFS daemon status
ipfs swarm peers

# Restart IPFS daemon
ipfs daemon &
```

### GPG Decryption Issues
```bash
# List available keys
gpg --list-keys

# Import key if needed
gpg --import private-key.asc
```

### Backup Verification Failures
```bash
# Check checksum manually
sha256sum backup.tar.gz.gpg
cat backup.tar.gz.gpg.sha256
```

## Best Practices

1. **Regular Testing**: Periodically test backup restoration
2. **Multiple Locations**: Replicate IPFS backups across multiple nodes
3. **Key Backups**: Maintain secure offline copies of GPG keys
4. **Monitoring**: Monitor backup success/failure
5. **Documentation**: Keep recovery procedures updated
