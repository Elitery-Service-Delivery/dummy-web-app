# FastFetch Server - Ubuntu 24.04 Deployment Guide

This guide covers deploying FastFetch Server as a systemd service on Ubuntu 24.04.

## Prerequisites

- Ubuntu 24.04 LTS (AMD64)
- `fastfetch` package installed
- sudo privileges
- Built binary (use `./build.sh`)

## Quick Deployment

### 1. Download or Build
```bash
# Option A: Download from GitHub Releases
wget https://github.com/Elitery-Service-Delivery/dummy-web-app/releases/latest/download/fastfetch-server-linux-amd64.tar.gz
tar -xzf fastfetch-server-linux-amd64.tar.gz

# Option B: Build from source
git clone <repository-url>
cd dummy-apps
./build.sh
```

### 2. Install Service
```bash
# Run the installation script
sudo ./install-service.sh
```

The installer will:
- ✅ Install `fastfetch` if not present
- ✅ Create system user `fastfetch`
- ✅ Install binary to `/opt/fastfetch-server/`
- ✅ Create systemd service
- ✅ Enable and start the service
- ✅ Configure security settings

### 3. Verify Installation
```bash
# Check service status
./service.sh status

# View logs
./service.sh logs

# Test the web interface
curl http://localhost:3131
```

## Service Management

### Using the Service Script
```bash
./service.sh status      # Check status
./service.sh start       # Start service
./service.sh stop        # Stop service
./service.sh restart     # Restart service
./service.sh logs        # View logs
./service.sh logs -f     # Follow logs
./service.sh enable      # Enable auto-start
./service.sh disable     # Disable auto-start
./service.sh uninstall   # Remove service
```

### Direct systemctl Commands
```bash
sudo systemctl status fastfetch-server
sudo systemctl start fastfetch-server
sudo systemctl stop fastfetch-server
sudo systemctl restart fastfetch-server
sudo systemctl enable fastfetch-server
sudo systemctl disable fastfetch-server
```

## Configuration

### Service Configuration
The service is configured in `/etc/systemd/system/fastfetch-server.service`:

- **User**: `fastfetch` (unprivileged)
- **Working Directory**: `/opt/fastfetch-server`
- **Port**: `3131`
- **Auto-restart**: Yes (on failure)
- **Security**: Hardened with multiple protections

### Security Features
- Runs as non-root user
- No new privileges
- Private temp directory
- Protected system directories
- Restricted syscalls
- Resource limits

## Troubleshooting

### Service Won't Start
```bash
# Check detailed status
sudo systemctl status fastfetch-server -l

# Check logs
sudo journalctl -u fastfetch-server --no-pager

# Check if fastfetch is installed
fastfetch --version

# Check if port is available
sudo ss -tlnp | grep :3131
```

### Common Issues

**"fastfetch command not found"**
```bash
sudo apt update && sudo apt install fastfetch
```

**"Port 3131 already in use"**
```bash
sudo ss -tlnp | grep :3131  # Find what's using the port
sudo systemctl stop <other-service>
```

**"Permission denied"**
```bash
# Check binary permissions
ls -la /opt/fastfetch-server/fastfetch-server

# Fix if needed
sudo chown fastfetch:fastfetch /opt/fastfetch-server/fastfetch-server
sudo chmod +x /opt/fastfetch-server/fastfetch-server
```

### Log Analysis
```bash
# Show recent logs
sudo journalctl -u fastfetch-server --since "10 minutes ago"

# Follow logs in real-time
sudo journalctl -u fastfetch-server -f

# Show only errors
sudo journalctl -u fastfetch-server -p err

# Export logs
sudo journalctl -u fastfetch-server --no-pager > fastfetch-logs.txt
```

## Updating

### Update Binary
```bash
# 1. Stop service
./service.sh stop

# 2. Replace binary
sudo cp dist/fastfetch-server-linux-amd64 /opt/fastfetch-server/fastfetch-server
sudo chown fastfetch:fastfetch /opt/fastfetch-server/fastfetch-server
sudo chmod +x /opt/fastfetch-server/fastfetch-server

# 3. Start service
./service.sh start
```

### Update Service Configuration
```bash
# 1. Stop service
sudo systemctl stop fastfetch-server

# 2. Update service file
sudo cp systemd/fastfetch-server.service /etc/systemd/system/

# 3. Reload and restart
sudo systemctl daemon-reload
sudo systemctl start fastfetch-server
```

## Uninstalling

### Complete Removal
```bash
# Use the service script
./service.sh uninstall

# Or manually:
sudo systemctl stop fastfetch-server
sudo systemctl disable fastfetch-server
sudo rm /etc/systemd/system/fastfetch-server.service
sudo systemctl daemon-reload
sudo rm -rf /opt/fastfetch-server
sudo userdel fastfetch
sudo groupdel fastfetch
```

## Monitoring

### Health Check
```bash
# Simple health check
curl -f http://localhost:3131 >/dev/null && echo "OK" || echo "FAIL"

# Create a monitoring script
cat > check-fastfetch.sh << 'EOF'
#!/bin/bash
if systemctl is-active --quiet fastfetch-server; then
    if curl -f http://localhost:3131 >/dev/null 2>&1; then
        echo "FastFetch Server: OK"
        exit 0
    else
        echo "FastFetch Server: Service running but not responding"
        exit 1
    fi
else
    echo "FastFetch Server: Service not running"
    exit 2
fi
EOF
chmod +x check-fastfetch.sh
```

### Performance Monitoring
```bash
# Monitor resource usage
sudo systemctl status fastfetch-server | grep -E "(Memory|Tasks)"

# View detailed resource usage
sudo systemd-cgtop -n 1 | grep fastfetch

# Monitor connections
sudo ss -tlnp | grep :3131
```

## Firewall Configuration

If you need to access the service from external networks:

```bash
# Allow port 3131 through UFW
sudo ufw allow 3131/tcp

# Or for specific IP ranges
sudo ufw allow from 192.168.1.0/24 to any port 3131
```

## Backup

### Backup Configuration
```bash
# Backup service files
sudo cp /etc/systemd/system/fastfetch-server.service ~/fastfetch-backup.service
sudo cp -r /opt/fastfetch-server ~/fastfetch-binary-backup
```

This completes the deployment guide for Ubuntu 24.04!