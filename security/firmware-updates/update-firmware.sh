#!/bin/bash
# Nexus Secure Firmware Update Script
# Implements secure firmware updates with checksum verification and cryptographic signatures

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_DIR="${UPDATE_DIR:-/var/lib/nexus/updates}"
BACKUP_DIR="${BACKUP_DIR:-/var/lib/nexus/backups}"
GPG_KEYRING="${GPG_KEYRING:-/etc/nexus/trusted-keys.gpg}"
UPDATE_MANIFEST="${UPDATE_MANIFEST:-update-manifest.json}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Initialize directories
init_directories() {
    log_info "Initializing update directories..."
    mkdir -p "${UPDATE_DIR}"
    mkdir -p "${BACKUP_DIR}"
    mkdir -p "$(dirname "${GPG_KEYRING}")"
}

# Verify GPG signature
verify_signature() {
    local file="$1"
    local signature="$2"
    
    log_info "Verifying GPG signature for ${file}..."
    
    if [ ! -f "${signature}" ]; then
        log_error "Signature file not found: ${signature}"
        return 1
    fi
    
    if ! gpg --verify "${signature}" "${file}" 2>&1 | grep -q "Good signature"; then
        log_error "GPG signature verification failed!"
        return 1
    fi
    
    log_info "✓ GPG signature verified successfully"
    return 0
}

# Verify checksum
verify_checksum() {
    local file="$1"
    local expected_checksum="$2"
    
    log_info "Verifying checksum for ${file}..."
    
    local actual_checksum=$(sha256sum "${file}" | awk '{print $1}')
    
    if [ "${actual_checksum}" != "${expected_checksum}" ]; then
        log_error "Checksum mismatch!"
        log_error "Expected: ${expected_checksum}"
        log_error "Actual:   ${actual_checksum}"
        return 1
    fi
    
    log_info "✓ Checksum verified successfully"
    return 0
}

# Parse update manifest
parse_manifest() {
    local manifest_file="$1"
    
    if [ ! -f "${manifest_file}" ]; then
        log_error "Manifest file not found: ${manifest_file}"
        return 1
    fi
    
    log_info "Parsing update manifest..."
    
    # Validate JSON structure
    if ! jq empty "${manifest_file}" 2>/dev/null; then
        log_error "Invalid JSON in manifest file"
        return 1
    fi
    
    log_info "✓ Manifest parsed successfully"
    return 0
}

# Create backup before update
create_backup() {
    local component="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="${component}_${timestamp}.tar.gz"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    log_info "Creating backup: ${backup_name}..."
    
    # Determine what to backup based on component
    case "${component}" in
        "contracts")
            tar -czf "${backup_path}" -C "$(dirname "${SCRIPT_DIR}")" contracts/
            ;;
        "dashboard")
            tar -czf "${backup_path}" -C "$(dirname "${SCRIPT_DIR}")" dashboard/
            ;;
        "scripts")
            tar -czf "${backup_path}" -C "$(dirname "${SCRIPT_DIR}")" scripts/
            ;;
        *)
            log_error "Unknown component: ${component}"
            return 1
            ;;
    esac
    
    # Create checksum for backup
    sha256sum "${backup_path}" > "${backup_path}.sha256"
    
    log_info "✓ Backup created: ${backup_path}"
    echo "${backup_path}"
}

# Rollback to previous version
rollback() {
    local backup_file="$1"
    
    log_warn "Rolling back to previous version..."
    
    if [ ! -f "${backup_file}" ]; then
        log_error "Backup file not found: ${backup_file}"
        return 1
    fi
    
    # Verify backup checksum
    if ! sha256sum -c "${backup_file}.sha256" > /dev/null 2>&1; then
        log_error "Backup checksum verification failed!"
        return 1
    fi
    
    # Extract backup
    tar -xzf "${backup_file}" -C "$(dirname "${SCRIPT_DIR}")"
    
    log_info "✓ Rollback completed successfully"
    return 0
}

# Apply update
apply_update() {
    local update_file="$1"
    local component="$2"
    local backup_file="$3"
    
    log_info "Applying update for component: ${component}..."
    
    # Extract update
    if ! tar -xzf "${update_file}" -C "$(dirname "${SCRIPT_DIR}")"; then
        log_error "Failed to extract update!"
        log_warn "Attempting rollback..."
        rollback "${backup_file}"
        return 1
    fi
    
    log_info "✓ Update applied successfully"
    return 0
}

# Verify update installation
verify_installation() {
    local component="$1"
    local expected_version="$2"
    
    log_info "Verifying installation for ${component}..."
    
    # Component-specific verification
    case "${component}" in
        "contracts")
            # Check if contract files exist
            if [ ! -d "$(dirname "${SCRIPT_DIR}")/contracts" ]; then
                log_error "Contracts directory not found after update!"
                return 1
            fi
            ;;
        "dashboard")
            # Check if dashboard files exist
            if [ ! -f "$(dirname "${SCRIPT_DIR}")/dashboard/index.html" ]; then
                log_error "Dashboard index.html not found after update!"
                return 1
            fi
            ;;
    esac
    
    log_info "✓ Installation verified successfully"
    return 0
}

# Main update process
perform_update() {
    local manifest_path="$1"
    
    log_info "=== Starting Nexus Firmware Update ==="
    
    # Initialize
    init_directories
    
    # Parse manifest
    if ! parse_manifest "${manifest_path}"; then
        log_error "Failed to parse manifest"
        return 1
    fi
    
    # Read manifest data
    local version=$(jq -r '.version' "${manifest_path}")
    local component=$(jq -r '.component' "${manifest_path}")
    local checksum=$(jq -r '.checksum' "${manifest_path}")
    local update_file=$(jq -r '.update_file' "${manifest_path}")
    local signature_file=$(jq -r '.signature_file' "${manifest_path}")
    
    log_info "Update Details:"
    log_info "  Version: ${version}"
    log_info "  Component: ${component}"
    log_info "  Update File: ${update_file}"
    
    # Verify signature
    if ! verify_signature "${update_file}" "${signature_file}"; then
        log_error "Signature verification failed!"
        return 1
    fi
    
    # Verify checksum
    if ! verify_checksum "${update_file}" "${checksum}"; then
        log_error "Checksum verification failed!"
        return 1
    fi
    
    # Create backup
    local backup_file=$(create_backup "${component}")
    if [ $? -ne 0 ]; then
        log_error "Failed to create backup!"
        return 1
    fi
    
    # Apply update
    if ! apply_update "${update_file}" "${component}" "${backup_file}"; then
        log_error "Update failed!"
        return 1
    fi
    
    # Verify installation
    if ! verify_installation "${component}" "${version}"; then
        log_error "Installation verification failed!"
        log_warn "Attempting rollback..."
        rollback "${backup_file}"
        return 1
    fi
    
    log_info "=== Update Completed Successfully ==="
    log_info "Backup saved to: ${backup_file}"
    
    return 0
}

# Check for available updates
check_updates() {
    local update_server="${UPDATE_SERVER:-https://updates.nexus.local}"
    
    log_info "Checking for available updates..."
    
    # Fetch update manifest from server
    if command -v curl > /dev/null; then
        curl -sSL "${update_server}/latest-manifest.json" -o "${UPDATE_DIR}/latest-manifest.json"
    elif command -v wget > /dev/null; then
        wget -q "${update_server}/latest-manifest.json" -O "${UPDATE_DIR}/latest-manifest.json"
    else
        log_error "Neither curl nor wget found!"
        return 1
    fi
    
    if [ -f "${UPDATE_DIR}/latest-manifest.json" ]; then
        local latest_version=$(jq -r '.version' "${UPDATE_DIR}/latest-manifest.json")
        log_info "Latest version available: ${latest_version}"
    fi
}

# Main
main() {
    case "${1:-}" in
        "check")
            check_updates
            ;;
        "apply")
            if [ -z "${2:-}" ]; then
                log_error "Usage: $0 apply <manifest-file>"
                exit 1
            fi
            perform_update "$2"
            ;;
        "rollback")
            if [ -z "${2:-}" ]; then
                log_error "Usage: $0 rollback <backup-file>"
                exit 1
            fi
            rollback "$2"
            ;;
        *)
            echo "Usage: $0 {check|apply|rollback} [args]"
            echo ""
            echo "Commands:"
            echo "  check                    - Check for available updates"
            echo "  apply <manifest-file>    - Apply update from manifest"
            echo "  rollback <backup-file>   - Rollback to previous version"
            exit 1
            ;;
    esac
}

main "$@"
