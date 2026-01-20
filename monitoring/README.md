# Nexus Real-time Monitoring Dashboard

## Overview
This monitoring stack provides comprehensive visibility into the Nexus decentralized system using Grafana, Loki, Prometheus, and supporting tools.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Grafana Dashboard                        │
│              (Visualization & Alerting)                      │
└────────────┬────────────────────────┬───────────────────────┘
             │                        │
             v                        v
    ┌────────────────┐      ┌──────────────────┐
    │   Prometheus   │      │      Loki        │
    │   (Metrics)    │      │   (Logs)         │
    └────────┬───────┘      └─────────┬────────┘
             │                        │
             v                        v
    ┌────────────────┐      ┌──────────────────┐
    │ Node Exporter  │      │    Promtail      │
    │ (System Stats) │      │ (Log Collector)  │
    └────────────────┘      └──────────────────┘
```

## Quick Start

### 1. Start the Stack
```bash
cd monitoring/
docker-compose up -d
```

### 2. Access Services
- **Grafana**: http://localhost:3000
  - Username: `admin`
  - Password: `changeme` (change immediately!)

- **Prometheus**: http://localhost:9090
- **Loki**: http://localhost:3100

### 3. View Dashboard
1. Open Grafana at http://localhost:3000
2. Login with default credentials
3. Navigate to Dashboards → Nexus Real-time Monitoring Dashboard

## Components

### Grafana
- **Purpose**: Visualization and dashboards
- **Port**: 3000
- **Volume**: `grafana-storage` (persistent data)
- **Config**: `grafana/provisioning/`

### Loki
- **Purpose**: Log aggregation and querying
- **Port**: 3100
- **Volume**: `loki-storage` (persistent logs)
- **Config**: `loki/loki-config.yml`
- **Retention**: 7 days (configurable)

### Promtail
- **Purpose**: Log collection and shipping to Loki
- **Config**: `loki/promtail-config.yml`
- **Monitored Logs**:
  - `/var/log/auth.log` (authentication)
  - `/var/log/syslog` (system)
  - `/var/log/nexus/*.log` (application)

### Prometheus
- **Purpose**: Metrics collection and storage
- **Port**: 9090
- **Volume**: `prometheus-storage` (persistent metrics)
- **Config**: `prometheus/prometheus.yml`
- **Scrape Interval**: 15 seconds

### Node Exporter
- **Purpose**: System-level metrics
- **Port**: 9100
- **Metrics**: CPU, memory, disk, network

## Dashboard Panels

### 1. CPU Usage
- Real-time CPU utilization
- Historical trends
- Alert threshold: 80%

### 2. Memory Usage
- Memory consumption
- Available memory
- Alert threshold: 80%

### 3. Network Latency
- Network performance metrics
- Connection status
- Response times

### 4. Security & Intrusion Logs
- Failed authentication attempts
- Suspicious activity patterns
- Real-time security events
- Filtered for keywords: failed, invalid, unauthorized, intrusion

### 5. Application Logs
- Nexus application logs
- Error tracking
- Request logging

## Configuration

### Environment Variables
Create `.env` file in the `monitoring/` directory:
```bash
GRAFANA_ADMIN_PASSWORD=your_secure_password
```

### Loki Retention
Edit `loki/loki-config.yml`:
```yaml
table_manager:
  retention_deletes_enabled: true
  retention_period: 168h  # 7 days
```

### Prometheus Scraping
Edit `prometheus/prometheus.yml` to add custom targets:
```yaml
scrape_configs:
  - job_name: 'custom-app'
    static_configs:
      - targets: ['app-host:8080']
```

## Alert Configuration

### Creating Alerts in Grafana
1. Navigate to Alerting → Alert Rules
2. Create new alert rule
3. Configure conditions (e.g., CPU > 80%)
4. Set notification channel

### Notification Channels
Configure in Grafana:
- Email
- Slack
- Webhook
- PagerDuty

## Querying

### Loki Query Examples
```
# View all nexus logs
{job="nexus"}

# Security events
{job="security"} |~ "(?i)(failed|invalid|unauthorized)"

# Errors only
{job="nexus"} |= "ERROR"

# Rate of log messages
rate({job="nexus"}[5m])
```

### Prometheus Query Examples
```
# CPU usage
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk I/O
rate(node_disk_io_time_seconds_total[5m])
```

## Monitoring Best Practices

### 1. Regular Reviews
- Review dashboards daily
- Investigate anomalies
- Tune alert thresholds

### 2. Log Management
- Rotate logs regularly
- Archive old logs
- Monitor disk usage

### 3. Performance Optimization
- Adjust retention periods
- Optimize query performance
- Scale components as needed

### 4. Security
- Change default passwords
- Enable authentication
- Use HTTPS for Grafana
- Restrict network access

## Troubleshooting

### Containers Not Starting
```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs -f grafana
docker-compose logs -f loki

# Restart services
docker-compose restart
```

### Loki Not Receiving Logs
```bash
# Check Promtail logs
docker-compose logs promtail

# Verify log file permissions
ls -la /var/log/nexus/

# Test Loki API
curl http://localhost:3100/ready
```

### Prometheus Not Scraping
```bash
# Check targets
curl http://localhost:9090/api/v1/targets

# Verify network connectivity
docker exec nexus-prometheus ping node-exporter
```

### Grafana Dashboard Issues
```bash
# Reset admin password
docker exec -it nexus-grafana grafana-cli admin reset-admin-password newpassword

# Check datasource connectivity
# Grafana UI → Configuration → Data Sources → Test
```

## Maintenance

### Backup
```bash
# Backup Grafana dashboards
docker exec nexus-grafana tar czf - /var/lib/grafana > grafana-backup.tar.gz

# Backup Prometheus data
docker exec nexus-prometheus tar czf - /prometheus > prometheus-backup.tar.gz
```

### Cleanup Old Data
```bash
# Clean Loki data
docker exec nexus-loki rm -rf /loki/chunks/old-data

# Clean Prometheus data
docker exec nexus-prometheus promtool tsdb delete -r /prometheus
```

### Update Stack
```bash
# Pull latest images
docker-compose pull

# Recreate containers
docker-compose up -d
```

## Advanced Configuration

### Custom Dashboard
1. Create JSON dashboard file in `grafana/dashboards/`
2. Restart Grafana: `docker-compose restart grafana`
3. Dashboard will auto-load

### Custom Metrics
Add to your application:
```python
from prometheus_client import Counter, Gauge

request_count = Counter('nexus_requests_total', 'Total requests')
active_users = Gauge('nexus_active_users', 'Active users')
```

Expose metrics endpoint at `/metrics`

### Log Parsing
Add custom pipeline in `promtail-config.yml`:
```yaml
pipeline_stages:
  - regex:
      expression: '(?P<timestamp>.*) (?P<level>.*) (?P<message>.*)'
  - labels:
      level:
  - timestamp:
      source: timestamp
      format: RFC3339
```

## Integration with Security Systems

### Forensic Log Watcher
The monitoring system integrates with the forensic automation:
- Security logs feed into Loki
- Grafana dashboards visualize threats
- Alerts trigger forensic responses

### Backup Monitoring
Monitor backup operations:
```
{job="nexus"} |= "backup" |= "success"
```

## Performance Metrics

### Expected Resource Usage
- Grafana: ~200MB RAM
- Loki: ~500MB RAM
- Prometheus: ~1GB RAM
- Promtail: ~50MB RAM
- Node Exporter: ~20MB RAM

### Scaling
For larger deployments:
- Use external storage for Loki
- Implement Prometheus federation
- Add load balancer for Grafana

## Support

For issues:
1. Check logs: `docker-compose logs`
2. Review configuration files
3. Consult Grafana/Loki/Prometheus documentation
4. Open GitHub issue

---

*Last Updated: 2026-01-20*
