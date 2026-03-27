# Quick Deployment Guide - Nexus Security Features

This guide provides step-by-step instructions to deploy all security and resilience features.

## Prerequisites

Run this script to install all dependencies:

```bash
#!/bin/bash
# Install prerequisites for Nexus security features

# Update package lists
sudo apt-get update

# Install Docker and Docker Compose
sudo apt-get install -y docker.io docker-compose

# Install Python and required packages
sudo apt-get install -y python3 python3-pip
pip3 install pyyaml

# Install GnuPG for encryption
sudo apt-get install -y gnupg2

# Install IPFS
wget https://dist.ipfs.io/go-ipfs/v0.18.0/go-ipfs_v0.18.0_linux-amd64.tar.gz
tar -xvzf go-ipfs_v0.18.0_linux-amd64.tar.gz
cd go-ipfs && sudo bash install.sh && cd ..
rm -rf go-ipfs go-ipfs_v0.18.0_linux-amd64.tar.gz

# Install Nginx with QUIC support (optional - for protocol hardening)
# Note: Standard nginx may not support QUIC, consider nginx-quic or compile from source
sudo apt-get install -y nginx

# Install utilities
sudo apt-get install -y jq curl wget openssl

# Add user to docker group
sudo usermod -aG docker $USER

echo "✓ Prerequisites installed successfully"
echo "⚠️  Log out and back in for docker group changes to take effect"
```

Save as `install-prerequisites.sh` and run:
```bash
chmod +x install-prerequisites.sh
./install-prerequisites.sh
```

## Step 1: Monitoring Dashboard

Deploy the Grafana/Loki monitoring stack:

```bash
# Navigate to monitoring directory
cd monitoring/

# Set admin password (replace with your secure password)
echo "GRAFANA_ADMIN_PASSWORD=YourSecurePassword123!" > .env

# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

Access Grafana at http://localhost:3000
- Username: `admin`
- Password: (the one you set in .env)

## Step 2: Forensic Automation

Setup the forensic log watcher:

```bash
# Create configuration directory
sudo mkdir -p /etc/nexus

# Copy configuration
sudo cp security/forensics/forensics-config.json /etc/nexus/

# Edit configuration if needed
sudo nano /etc/nexus/forensics-config.json

# Create log directory
sudo mkdir -p /var/log/nexus/forensics

# Start log watcher (for testing)
python3 security/forensics/log-watcher.py

# For production, create systemd service
sudo cp security/forensics/log-watcher.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable log-watcher
sudo systemctl start log-watcher
```

Create systemd service file:
```bash
cat > /tmp/log-watcher.service << 'EOF'
[Unit]
Description=Nexus Forensic Log Watcher
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/home/runner/work/nexus/nexus
ExecStart=/usr/bin/python3 security/forensics/log-watcher.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo mv /tmp/log-watcher.service /etc/systemd/system/
```

## Step 3: Firmware Update System

Setup the secure update mechanism:

```bash
# Create update directories
sudo mkdir -p /var/lib/nexus/updates
sudo mkdir -p /var/lib/nexus/backups

# Generate GPG key for signing (if not already done)
gpg --full-generate-key
# Select: RSA and RSA
# Key size: 4096
# Expiration: as needed
# Name: Nexus Update System
# Email: updates@nexus.local

# Test the update system
./security/firmware-updates/update-firmware.sh check
```

## Step 4: Distributed Backup System

Configure IPFS backups:

```bash
# Initialize IPFS
export IPFS_PATH=/var/lib/nexus/ipfs
ipfs init

# Start IPFS daemon (in background)
ipfs daemon &

# Wait a few seconds for daemon to start
sleep 5

# Create first backup
./security/backups/backup-system.sh create

# List backups
./security/backups/backup-system.sh list

# Setup cron for automated backups (daily at 2 AM)
crontab -e
# Add this line:
# 0 2 * * * /home/runner/work/nexus/nexus/security/backups/backup-system.sh create >> /var/log/nexus/backup.log 2>&1
```

## Step 5: Protocol Hardening

Apply communication protocol security:

```bash
# Run hardening script
sudo ./security/protocols/harden-protocols.sh

# This will:
# 1. Generate test SSL certificates
# 2. Configure Nginx for QUIC + TLS 1.3
# 3. Disable insecure protocols
# 4. Setup monitoring

# For production, replace test certificates with real ones:
sudo openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
  -keyout /etc/nexus/ssl/key.pem \
  -out /etc/nexus/ssl/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Nexus/CN=yourdomain.com"

# Restart Nginx
sudo systemctl restart nginx
```

## Verification

### Verify Monitoring
```bash
# Check Grafana
curl http://localhost:3000/api/health

# Check Prometheus
curl http://localhost:9090/-/healthy

# Check Loki
curl http://localhost:3100/ready
```

### Verify Forensic System
```bash
# Check if running
ps aux | grep log-watcher

# Check logs
tail -f /var/log/nexus/forensics/forensics.log
```

### Verify Backup System
```bash
# Check IPFS
ipfs swarm peers

# Verify backup manifest
cat /var/lib/nexus/backups/backup-manifest.json
```

### Verify Protocol Hardening
```bash
# Test TLS 1.3
openssl s_client -connect localhost:443 -tls1_3

# Check Nginx status
sudo systemctl status nginx
```

## Troubleshooting

### Monitoring Not Starting
```bash
# Check Docker
sudo systemctl status docker

# Check logs
cd monitoring && docker-compose logs -f
```

### IPFS Issues
```bash
# Check IPFS daemon
ipfs swarm peers

# Restart daemon
pkill ipfs
ipfs daemon &
```

### Nginx QUIC Not Working
```bash
# Check if nginx supports QUIC
nginx -V 2>&1 | grep quic

# If not, you may need to compile nginx with QUIC support
# or use a pre-built nginx-quic package
```

## Security Checklist

- [ ] Change Grafana admin password
- [ ] Configure firewall rules
- [ ] Setup SSL certificates (replace test certs)
- [ ] Configure backup GPG key
- [ ] Test restore procedures
- [ ] Enable monitoring alerts
- [ ] Review forensic detection patterns
- [ ] Test update rollback
- [ ] Document incident response procedures
- [ ] Schedule security audits

## Maintenance Tasks

### Daily
- Review Grafana dashboards
- Check forensic logs for alerts

### Weekly
- Verify backup integrity
- Review blocked IPs
- Update detection patterns

### Monthly
- Test backup restoration
- Update dependencies
- Review security logs

### Quarterly
- Rotate GPG keys
- Security audit
- Update documentation

## Support

For issues or questions:
1. Check component-specific README files
2. Review logs in `/var/log/nexus/`
3. Consult SECURITY_IMPLEMENTATION.md
4. Open GitHub issue

---

**Note**: This is a comprehensive security implementation. Adjust configurations based on your specific requirements and environment.
