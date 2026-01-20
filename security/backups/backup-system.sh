#!/bin/bash
# Nexus Distributed Backup System
# Implements automated encrypted backups using IPFS and GnuPG

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "${SCRIPT_DIR}")")"
BACKUP_DIR="${BACKUP_DIR:-/var/lib/nexus/backups}"
IPFS_REPO="${IPFS_REPO:-/var/lib/nexus/ipfs}"
GPG_RECIPIENT="${GPG_RECIPIENT:-nexus@backup.local}"
BACKUP_MANIFEST="${BACKUP_DIR}/backup-manifest.json"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Initialize backup environment
init_backup_env() {
    log_info "Initializing backup environment..."
    
    mkdir -p "${BACKUP_DIR}"
    mkdir -p "${IPFS_REPO}"
    
    # Initialize IPFS if not already initialized
    if [ ! -d "${IPFS_REPO}/config" ]; then
        log_info "Initializing IPFS repository..."
        IPFS_PATH="${IPFS_REPO}" ipfs init
    fi
    
    # Check if GPG key exists
    if ! gpg --list-keys "${GPG_RECIPIENT}" > /dev/null 2>&1; then
        log_warn "GPG key for ${GPG_RECIPIENT} not found"
        log_info "Generating new GPG key..."
        generate_gpg_key
    fi
}

# Generate GPG key for backups
generate_gpg_key() {
    cat > /tmp/gpg-gen-key.conf << EOF
%echo Generating Nexus Backup GPG key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Nexus Backup System
Name-Email: ${GPG_RECIPIENT}
Expire-Date: 0
%no-protection
%commit
%echo Done
EOF
    
    gpg --batch --gen-key /tmp/gpg-gen-key.conf
    rm -f /tmp/gpg-gen-key.conf
    
    log_info "✓ GPG key generated successfully"
}

# Create backup archive
create_backup_archive() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="nexus-backup-${timestamp}"
    local archive_path="${BACKUP_DIR}/${backup_name}.tar.gz"
    
    log_info "Creating backup archive: ${backup_name}..."
    
    # Create list of directories to backup
    local backup_items=(
        "contracts"
        "dashboard"
        "scripts"
        "docs"
        "kosymbiosis"
        "*.md"
        "*.json"
    )
    
    # Create archive
    cd "${PROJECT_ROOT}"
    tar -czf "${archive_path}" \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='*.pyc' \
        --exclude='__pycache__' \
        "${backup_items[@]}" 2>/dev/null || true
    
    if [ ! -f "${archive_path}" ]; then
        log_error "Failed to create backup archive"
        return 1
    fi
    
    log_info "✓ Backup archive created: ${archive_path}"
    echo "${archive_path}"
}

# Encrypt backup with GnuPG
encrypt_backup() {
    local archive_path="$1"
    local encrypted_path="${archive_path}.gpg"
    
    log_info "Encrypting backup with GnuPG..."
    
    gpg --encrypt \
        --recipient "${GPG_RECIPIENT}" \
        --output "${encrypted_path}" \
        --trust-model always \
        "${archive_path}"
    
    if [ ! -f "${encrypted_path}" ]; then
        log_error "Failed to encrypt backup"
        return 1
    fi
    
    # Create checksum
    sha256sum "${encrypted_path}" > "${encrypted_path}.sha256"
    
    log_info "✓ Backup encrypted successfully"
    echo "${encrypted_path}"
}

# Upload to IPFS
upload_to_ipfs() {
    local file_path="$1"
    
    log_info "Uploading to IPFS..."
    
    # Start IPFS daemon if not running
    if ! pgrep -x "ipfs" > /dev/null; then
        log_info "Starting IPFS daemon..."
        IPFS_PATH="${IPFS_REPO}" ipfs daemon --init &
        sleep 5
    fi
    
    # Add file to IPFS
    local ipfs_hash=$(IPFS_PATH="${IPFS_REPO}" ipfs add -Q "${file_path}")
    
    if [ -z "${ipfs_hash}" ]; then
        log_error "Failed to upload to IPFS"
        return 1
    fi
    
    log_info "✓ Uploaded to IPFS with hash: ${ipfs_hash}"
    
    # Pin the file
    IPFS_PATH="${IPFS_REPO}" ipfs pin add "${ipfs_hash}"
    
    echo "${ipfs_hash}"
}

# Update backup manifest
update_manifest() {
    local timestamp="$1"
    local ipfs_hash="$2"
    local archive_path="$3"
    local file_size="$4"
    
    log_info "Updating backup manifest..."
    
    # Create manifest entry
    local manifest_entry=$(cat <<EOF
{
  "timestamp": "${timestamp}",
  "ipfs_hash": "${ipfs_hash}",
  "archive_name": "$(basename "${archive_path}")",
  "file_size": ${file_size},
  "gpg_recipient": "${GPG_RECIPIENT}",
  "checksum_file": "$(basename "${archive_path}").sha256"
}
EOF
)
    
    # Initialize manifest if it doesn't exist
    if [ ! -f "${BACKUP_MANIFEST}" ]; then
        echo '{"backups": []}' > "${BACKUP_MANIFEST}"
    fi
    
    # Add entry to manifest
    local temp_manifest=$(mktemp)
    jq ".backups += [${manifest_entry}]" "${BACKUP_MANIFEST}" > "${temp_manifest}"
    mv "${temp_manifest}" "${BACKUP_MANIFEST}"
    
    log_info "✓ Manifest updated"
}

# Perform full backup
perform_backup() {
    log_info "=== Starting Nexus Distributed Backup ==="
    
    local timestamp=$(date -Iseconds)
    
    # Initialize environment
    init_backup_env
    
    # Create backup archive
    local archive_path=$(create_backup_archive)
    if [ -z "${archive_path}" ]; then
        log_error "Backup creation failed"
        return 1
    fi
    
    # Encrypt backup
    local encrypted_path=$(encrypt_backup "${archive_path}")
    if [ -z "${encrypted_path}" ]; then
        log_error "Encryption failed"
        return 1
    fi
    
    # Get file size (portable across platforms)
    local file_size
    file_size=$(wc -c < "${encrypted_path}")
    
    # Upload to IPFS
    local ipfs_hash=$(upload_to_ipfs "${encrypted_path}")
    if [ -z "${ipfs_hash}" ]; then
        log_error "IPFS upload failed"
        return 1
    fi
    
    # Update manifest
    update_manifest "${timestamp}" "${ipfs_hash}" "${encrypted_path}" "${file_size}"
    
    # Clean up unencrypted archive
    rm -f "${archive_path}"
    
    log_info "=== Backup Completed Successfully ==="
    log_info "Backup Details:"
    log_info "  IPFS Hash: ${ipfs_hash}"
    log_info "  Encrypted File: ${encrypted_path}"
    log_info "  Size: $(numfmt --to=iec ${file_size} 2>/dev/null || echo "${file_size} bytes")"
    log_info ""
    log_info "To retrieve this backup:"
    log_info "  ipfs get ${ipfs_hash}"
    log_info "To decrypt:"
    log_info "  gpg --decrypt ${encrypted_path}.gpg"
}

# Restore from backup
restore_backup() {
    local ipfs_hash="$1"
    
    log_info "=== Restoring from Backup ==="
    log_info "IPFS Hash: ${ipfs_hash}"
    
    # Fetch from IPFS
    log_info "Fetching from IPFS..."
    local temp_file=$(mktemp)
    IPFS_PATH="${IPFS_REPO}" ipfs get "${ipfs_hash}" -o "${temp_file}"
    
    # Decrypt
    log_info "Decrypting backup..."
    local decrypted_file=$(mktemp)
    gpg --decrypt --output "${decrypted_file}" "${temp_file}"
    
    # Extract
    log_info "Extracting backup..."
    tar -xzf "${decrypted_file}" -C "${PROJECT_ROOT}"
    
    # Clean up
    rm -f "${temp_file}" "${decrypted_file}"
    
    log_info "✓ Backup restored successfully"
}

# List available backups
list_backups() {
    log_info "=== Available Backups ==="
    
    if [ ! -f "${BACKUP_MANIFEST}" ]; then
        log_warn "No backups found"
        return
    fi
    
    jq -r '.backups[] | "\(.timestamp) - \(.ipfs_hash) - \(.archive_name) (\(.file_size) bytes)"' "${BACKUP_MANIFEST}"
}

# Verify backup integrity
verify_backup() {
    local encrypted_file="$1"
    
    log_info "Verifying backup integrity..."
    
    # Verify checksum
    if ! sha256sum -c "${encrypted_file}.sha256" > /dev/null 2>&1; then
        log_error "Checksum verification failed!"
        return 1
    fi
    
    log_info "✓ Backup integrity verified"
}

# Main
main() {
    case "${1:-}" in
        "create"|"backup")
            perform_backup
            ;;
        "restore")
            if [ -z "${2:-}" ]; then
                log_error "Usage: $0 restore <ipfs-hash>"
                exit 1
            fi
            restore_backup "$2"
            ;;
        "list")
            list_backups
            ;;
        "verify")
            if [ -z "${2:-}" ]; then
                log_error "Usage: $0 verify <encrypted-file>"
                exit 1
            fi
            verify_backup "$2"
            ;;
        *)
            echo "Nexus Distributed Backup System"
            echo "Usage: $0 {create|restore|list|verify} [args]"
            echo ""
            echo "Commands:"
            echo "  create               - Create new encrypted backup and upload to IPFS"
            echo "  restore <ipfs-hash>  - Restore backup from IPFS"
            echo "  list                 - List available backups"
            echo "  verify <file>        - Verify backup integrity"
            exit 1
            ;;
    esac
}

main "$@"
