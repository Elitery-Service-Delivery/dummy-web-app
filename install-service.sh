#!/bin/bash

# FastFetch Server Installation Script for Ubuntu 24.04
# This script installs the FastFetch server as a systemd service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SERVICE_NAME="fastfetch-server"
SERVICE_USER="fastfetch"
SERVICE_GROUP="fastfetch"
INSTALL_DIR="/opt/fastfetch-server"
BINARY_NAME="fastfetch-server"
SERVICE_FILE="systemd/fastfetch-server.service"

echo -e "${BLUE}🚀 FastFetch Server Installation Script${NC}"
echo -e "${BLUE}=====================================${NC}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This script must be run as root (use sudo)${NC}"
   exit 1
fi

# Check if fastfetch is installed
if ! command -v fastfetch &> /dev/null; then
    echo -e "${YELLOW}⚠️  fastfetch is not installed. Installing it...${NC}"
    apt update && apt install -y fastfetch
    if ! command -v fastfetch &> /dev/null; then
        echo -e "${RED}❌ Failed to install fastfetch. Please install it manually:${NC}"
        echo -e "${RED}   sudo apt update && sudo apt install fastfetch${NC}"
        exit 1
    fi
fi

# Check if binary exists
if [[ ! -f "dist/${BINARY_NAME}-linux-amd64" ]]; then
    echo -e "${RED}❌ Binary not found: dist/${BINARY_NAME}-linux-amd64${NC}"
    echo -e "${YELLOW}💡 Please run './build.sh' first to build the binary${NC}"
    exit 1
fi

# Check if service file exists
if [[ ! -f "$SERVICE_FILE" ]]; then
    echo -e "${RED}❌ Service file not found: $SERVICE_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Installation Steps:${NC}"
echo "1. Create service user and group"
echo "2. Create installation directory"
echo "3. Copy binary and set permissions"
echo "4. Install systemd service"
echo "5. Enable and start service"
echo ""

# Create service user and group
echo -e "${BLUE}👤 Creating service user and group...${NC}"
if ! id "$SERVICE_USER" &>/dev/null; then
    useradd --system --no-create-home --shell /bin/false --group "$SERVICE_GROUP" "$SERVICE_USER"
    echo -e "${GREEN}✅ Created user: $SERVICE_USER${NC}"
else
    echo -e "${YELLOW}ℹ️  User $SERVICE_USER already exists${NC}"
fi

# Create installation directory
echo -e "${BLUE}📁 Creating installation directory...${NC}"
mkdir -p "$INSTALL_DIR"
chown "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR"
echo -e "${GREEN}✅ Created directory: $INSTALL_DIR${NC}"

# Copy binary
echo -e "${BLUE}📦 Installing binary...${NC}"
cp "dist/${BINARY_NAME}-linux-amd64" "$INSTALL_DIR/$BINARY_NAME"
chown "$SERVICE_USER:$SERVICE_GROUP" "$INSTALL_DIR/$BINARY_NAME"
chmod +x "$INSTALL_DIR/$BINARY_NAME"
echo -e "${GREEN}✅ Installed binary: $INSTALL_DIR/$BINARY_NAME${NC}"

# Install systemd service
echo -e "${BLUE}⚙️  Installing systemd service...${NC}"
cp "$SERVICE_FILE" "/etc/systemd/system/${SERVICE_NAME}.service"
systemctl daemon-reload
echo -e "${GREEN}✅ Installed service: ${SERVICE_NAME}.service${NC}"

# Enable service
echo -e "${BLUE}🔧 Enabling service...${NC}"
systemctl enable "$SERVICE_NAME"
echo -e "${GREEN}✅ Service enabled${NC}"

# Start service
echo -e "${BLUE}▶️  Starting service...${NC}"
systemctl start "$SERVICE_NAME"

# Check service status
sleep 2
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo -e "${GREEN}✅ Service started successfully!${NC}"
    echo ""
    echo -e "${BLUE}📊 Service Status:${NC}"
    systemctl status "$SERVICE_NAME" --no-pager -l
    echo ""
    echo -e "${GREEN}🌐 FastFetch Server is now running at: http://localhost:3131${NC}"
    echo ""
    echo -e "${BLUE}📋 Useful Commands:${NC}"
    echo "  sudo systemctl status $SERVICE_NAME     # Check status"
    echo "  sudo systemctl restart $SERVICE_NAME    # Restart service"
    echo "  sudo systemctl stop $SERVICE_NAME       # Stop service"
    echo "  sudo systemctl start $SERVICE_NAME      # Start service"
    echo "  sudo journalctl -u $SERVICE_NAME -f     # View logs"
    echo "  sudo journalctl -u $SERVICE_NAME        # View all logs"
else
    echo -e "${RED}❌ Service failed to start!${NC}"
    echo -e "${YELLOW}📋 Check the logs:${NC}"
    journalctl -u "$SERVICE_NAME" --no-pager -l
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 Installation completed successfully!${NC}"