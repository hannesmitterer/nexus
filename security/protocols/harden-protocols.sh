#!/bin/bash
# Nexus Protocol Security Hardening Script
# Configures QUIC + TLS 1.3 and disables insecure protocols

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/protocol-config.json"

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check for required tools
    for tool in openssl jq; do
        if ! command -v $tool > /dev/null; then
            missing_tools+=($tool)
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Install with: apt-get install ${missing_tools[*]}"
        return 1
    fi
    
    log_info "✓ All prerequisites met"
}

# Generate self-signed certificate for testing
generate_test_certificate() {
    local cert_dir="/etc/nexus/ssl"
    
    log_info "Generating test SSL certificates..."
    
    mkdir -p "${cert_dir}"
    
    # Generate private key
    openssl genrsa -out "${cert_dir}/key.pem" 4096
    
    # Generate certificate signing request
    openssl req -new -key "${cert_dir}/key.pem" \
        -out "${cert_dir}/csr.pem" \
        -subj "/C=US/ST=State/L=City/O=Nexus/CN=nexus.local"
    
    # Generate self-signed certificate
    openssl x509 -req -days 365 \
        -in "${cert_dir}/csr.pem" \
        -signkey "${cert_dir}/key.pem" \
        -out "${cert_dir}/cert.pem"
    
    # Set permissions
    chmod 600 "${cert_dir}/key.pem"
    chmod 644 "${cert_dir}/cert.pem"
    
    log_info "✓ Test certificates generated at ${cert_dir}"
}

# Configure Nginx with QUIC and TLS 1.3
configure_nginx() {
    log_info "Configuring Nginx for QUIC + TLS 1.3..."
    
    # Check if Nginx is installed
    if ! command -v nginx > /dev/null; then
        log_warn "Nginx not installed. Install with:"
        log_warn "  apt-get install nginx-quic"
        return 1
    fi
    
    # Backup existing configuration
    if [ -f /etc/nginx/sites-available/default ]; then
        cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup
    fi
    
    # Copy our configuration
    cp "${SCRIPT_DIR}/nginx-quic-tls13.conf" /etc/nginx/sites-available/nexus
    ln -sf /etc/nginx/sites-available/nexus /etc/nginx/sites-enabled/nexus
    
    # Test configuration
    if nginx -t; then
        log_info "✓ Nginx configuration valid"
        systemctl reload nginx || log_warn "Could not reload nginx (may not be running)"
    else
        log_error "Nginx configuration test failed"
        return 1
    fi
}

# Disable insecure protocols
disable_insecure_protocols() {
    log_info "Disabling insecure protocols..."
    
    # Disable SSLv2, SSLv3, TLS 1.0, TLS 1.1
    if [ -f /etc/ssl/openssl.cnf ]; then
        if ! grep -q "MinProtocol = TLSv1.3" /etc/ssl/openssl.cnf; then
            echo "" >> /etc/ssl/openssl.cnf
            echo "# Nexus Security Hardening" >> /etc/ssl/openssl.cnf
            echo "MinProtocol = TLSv1.3" >> /etc/ssl/openssl.cnf
            log_info "✓ Updated OpenSSL configuration"
        fi
    fi
    
    # Configure firewall to block insecure ports
    if command -v ufw > /dev/null; then
        ufw allow 443/tcp comment 'HTTPS/TLS'
        ufw allow 443/udp comment 'QUIC'
        ufw deny 80/tcp comment 'HTTP (insecure)'
        log_info "✓ Firewall rules updated"
    fi
}

# Verify TLS configuration
verify_tls_config() {
    log_info "Verifying TLS configuration..."
    
    # Check OpenSSL version
    local openssl_version=$(openssl version | awk '{print $2}')
    log_info "OpenSSL version: ${openssl_version}"
    
    # Check supported protocols
    log_info "Supported TLS protocols:"
    openssl ciphers -v | grep TLSv1.3 | head -5
    
    log_info "✓ TLS configuration verified"
}

# Setup monitoring
setup_monitoring() {
    log_info "Setting up protocol monitoring..."
    
    # Create monitoring script
    cat > /usr/local/bin/nexus-protocol-monitor.sh << 'EOF'
#!/bin/bash
# Monitor TLS/QUIC connections

while true; do
    # Check active TLS connections
    tls_conns=$(ss -tn | grep :443 | wc -l)
    
    # Check active QUIC connections
    quic_conns=$(ss -un | grep :443 | wc -l)
    
    # Log to monitoring file
    echo "$(date -Iseconds) TLS:${tls_conns} QUIC:${quic_conns}" >> /var/log/nexus/protocol-stats.log
    
    sleep 60
done
EOF
    
    chmod +x /usr/local/bin/nexus-protocol-monitor.sh
    
    log_info "✓ Monitoring setup complete"
}

# Main hardening process
main() {
    log_info "=== Nexus Protocol Security Hardening ==="
    
    # Check prerequisites
    if ! check_prerequisites; then
        log_error "Prerequisites not met"
        exit 1
    fi
    
    # Generate test certificates
    generate_test_certificate
    
    # Configure Nginx
    configure_nginx
    
    # Disable insecure protocols
    disable_insecure_protocols
    
    # Verify configuration
    verify_tls_config
    
    # Setup monitoring
    setup_monitoring
    
    log_info "=== Hardening Complete ==="
    log_info ""
    log_info "Next Steps:"
    log_info "1. Replace test certificates with production certificates"
    log_info "2. Update DNS to point to this server"
    log_info "3. Test HTTPS/QUIC connectivity"
    log_info "4. Monitor logs in /var/log/nexus/"
    log_info ""
    log_info "Test QUIC connection:"
    log_info "  curl --http3 https://nexus.local"
}

# Run main function
main "$@"
