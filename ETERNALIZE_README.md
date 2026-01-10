# IPFS and Pinata Framework Eternalization

This directory contains the `eternalize.sh` script for automating the workflow of eternalizing frameworks using IPFS and Pinata.

## Overview

The `eternalize.sh` script fully automates the process of:
1. Installing the IPFS CLI (if not already installed)
2. Initializing the IPFS repository
3. Starting the IPFS daemon
4. Adding your documentation folder to IPFS
5. Pinning the resulting Content Identifier (CID) to Pinata

## Prerequisites

- Linux operating system (tested on Ubuntu/Debian)
- `sudo` privileges (for IPFS CLI installation)
- A Pinata account with an API JWT token
- Documentation files in the `docs/` directory

## Setup

### 1. Prepare Your Documentation

Ensure your documentation is placed in the `docs/` directory at the repository root:

```bash
mkdir -p docs
# Add your documentation files to the docs/ directory
```

### 2. Export Pinata JWT Token

You need to export your Pinata JWT token as an environment variable before running the script:

```bash
export PINATA_JWT="your_pinata_jwt_token_here"
```

To get a Pinata JWT token:
1. Sign up at [Pinata](https://www.pinata.cloud/)
2. Navigate to the API Keys section
3. Create a new API key with pinning permissions
4. Copy the JWT token

## Usage

### Basic Usage

Simply run the script from the repository root:

```bash
./eternalize.sh
```

### What the Script Does

1. **Checks Prerequisites**: Verifies that `PINATA_JWT` is set and `docs/` directory exists with content
2. **Installs IPFS CLI**: Downloads and installs IPFS CLI if not already present
3. **Initializes IPFS**: Sets up the IPFS repository if needed
4. **Starts IPFS Daemon**: Launches the IPFS daemon in the background
5. **Adds Documentation**: Recursively adds all files in `docs/` to IPFS
6. **Pins to Pinata**: Automatically pins the root CID to Pinata for permanent storage
7. **Provides URLs**: Displays IPFS gateway URLs for accessing your documentation

### Example Output

```
====================================================================
  IPFS and Pinata Framework Eternalization Script
====================================================================

[INFO] Checking for PINATA_JWT environment variable...
[SUCCESS] PINATA_JWT is set.
[INFO] Checking for documentation directory...
[SUCCESS] Documentation directory found and contains files.
[SUCCESS] IPFS CLI is already installed (ipfs version 0.27.0).
[SUCCESS] IPFS repository already initialized.
[INFO] Checking IPFS daemon status...
[SUCCESS] IPFS daemon is already running.
[INFO] Adding documentation folder to IPFS...
[INFO] Processing: docs
[SUCCESS] Documentation added to IPFS successfully.
[SUCCESS] Root CID: QmXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXx

IPFS Gateway URLs:
  - https://ipfs.io/ipfs/QmXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXx
  - https://gateway.pinata.cloud/ipfs/QmXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXx

[INFO] Pinning CID to Pinata...
[INFO] Sending pin request to Pinata...
[SUCCESS] Successfully pinned to Pinata!

====================================================================
  Eternalization Complete!
====================================================================
  Your documentation is now eternalized on IPFS and pinned to Pinata.
  CID: QmXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXx
====================================================================
```

## Features

### Error Handling

The script includes comprehensive error handling:
- Validates that `PINATA_JWT` environment variable is set
- Checks that `docs/` directory exists and contains files
- Verifies IPFS installation and initialization
- Confirms IPFS daemon is running before adding files
- Validates successful pinning to Pinata

### User Feedback

Clear status messages for each step:
- **[INFO]**: Informational messages about current operations
- **[SUCCESS]**: Confirmation of successful operations
- **[WARNING]**: Non-critical warnings
- **[ERROR]**: Critical errors that stop execution

### Automatic Installation

If IPFS CLI is not installed, the script will:
1. Download the latest stable version of IPFS (Kubo)
2. Extract and install it automatically
3. Verify the installation

### Background Daemon

The IPFS daemon runs in the background and continues after the script completes. To stop it manually:

```bash
ipfs shutdown
```

## Troubleshooting

### IPFS Installation Fails

If the automatic installation fails:
1. Check your internet connection
2. Verify you have `sudo` privileges
3. Manually install IPFS from [IPFS Documentation](https://docs.ipfs.tech/install/)

### Daemon Won't Start

If the IPFS daemon fails to start:
1. Check if another instance is running: `pgrep ipfs`
2. Check the daemon logs: `cat /tmp/ipfs-daemon.log`
3. Try stopping any existing daemon: `ipfs shutdown`
4. Re-run the script

### Pinata Pinning Fails

If pinning to Pinata fails:
1. Verify your `PINATA_JWT` token is valid
2. Check your Pinata account has sufficient pinning quota
3. Ensure your JWT has pinning permissions
4. Review the error message in the script output

## Advanced Configuration

### Custom IPFS Version

To use a different IPFS version, edit the script and change:

```bash
IPFS_VERSION="v0.27.0"
```

### Custom Documentation Directory

To use a different documentation directory, edit the script and change:

```bash
DOCS_DIR="docs"
```

## Security Notes

- Never commit your `PINATA_JWT` token to version control
- Store your JWT token securely (e.g., in environment files or secret managers)
- The script uses HTTPS for all API communications
- IPFS content is public and immutable once added

## Additional Resources

- [IPFS Documentation](https://docs.ipfs.tech/)
- [Pinata Documentation](https://docs.pinata.cloud/)
- [IPFS Best Practices](https://docs.ipfs.tech/concepts/best-practices/)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the script output for error messages
3. Check IPFS and Pinata documentation
4. Open an issue in the repository
