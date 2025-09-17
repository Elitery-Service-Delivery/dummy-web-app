#!/bin/bash

# FastFetch Server Service Management Script
# Provides easy commands to manage the FastFetch service

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SERVICE_NAME="fastfetch-server"

# Function to check if service exists
check_service() {
    if ! systemctl list-unit-files | grep -q "$SERVICE_NAME.service"; then
        echo -e "${RED}❌ Service $SERVICE_NAME is not installed${NC}"
        echo -e "${YELLOW}💡 Run './install-service.sh' to install the service${NC}"
        exit 1
    fi
}

# Function to show service status
show_status() {
    echo -e "${BLUE}📊 $SERVICE_NAME Service Status:${NC}"
    systemctl status "$SERVICE_NAME" --no-pager -l
    echo ""
    
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}🟢 Service is running${NC}"
        echo -e "${BLUE}🌐 Available at: http://localhost:3131${NC}"
    else
        echo -e "${RED}🔴 Service is not running${NC}"
    fi
}

# Function to start service
start_service() {
    echo -e "${BLUE}▶️  Starting $SERVICE_NAME...${NC}"
    sudo systemctl start "$SERVICE_NAME"
    sleep 2
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}✅ Service started successfully${NC}"
        echo -e "${BLUE}🌐 Available at: http://localhost:3131${NC}"
    else
        echo -e "${RED}❌ Failed to start service${NC}"
        echo -e "${YELLOW}📋 Check logs: sudo journalctl -u $SERVICE_NAME${NC}"
    fi
}

# Function to stop service
stop_service() {
    echo -e "${BLUE}⏹️  Stopping $SERVICE_NAME...${NC}"
    sudo systemctl stop "$SERVICE_NAME"
    sleep 1
    if ! systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}✅ Service stopped successfully${NC}"
    else
        echo -e "${RED}❌ Failed to stop service${NC}"
    fi
}

# Function to restart service
restart_service() {
    echo -e "${BLUE}🔄 Restarting $SERVICE_NAME...${NC}"
    sudo systemctl restart "$SERVICE_NAME"
    sleep 2
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo -e "${GREEN}✅ Service restarted successfully${NC}"
        echo -e "${BLUE}🌐 Available at: http://localhost:3131${NC}"
    else
        echo -e "${RED}❌ Failed to restart service${NC}"
        echo -e "${YELLOW}📋 Check logs: sudo journalctl -u $SERVICE_NAME${NC}"
    fi
}

# Function to show logs
show_logs() {
    echo -e "${BLUE}📋 $SERVICE_NAME Service Logs:${NC}"
    if [[ "$1" == "--follow" || "$1" == "-f" ]]; then
        echo -e "${YELLOW}Following logs (Ctrl+C to exit)...${NC}"
        sudo journalctl -u "$SERVICE_NAME" -f
    else
        sudo journalctl -u "$SERVICE_NAME" --no-pager -l
    fi
}

# Function to enable service
enable_service() {
    echo -e "${BLUE}🔧 Enabling $SERVICE_NAME...${NC}"
    sudo systemctl enable "$SERVICE_NAME"
    echo -e "${GREEN}✅ Service enabled (will start on boot)${NC}"
}

# Function to disable service
disable_service() {
    echo -e "${BLUE}🔧 Disabling $SERVICE_NAME...${NC}"
    sudo systemctl disable "$SERVICE_NAME"
    echo -e "${GREEN}✅ Service disabled (will not start on boot)${NC}"
}

# Function to uninstall service
uninstall_service() {
    echo -e "${YELLOW}⚠️  This will completely remove the FastFetch service${NC}"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🗑️  Uninstalling $SERVICE_NAME...${NC}"
        
        # Stop and disable service
        sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true
        sudo systemctl disable "$SERVICE_NAME" 2>/dev/null || true
        
        # Remove service file
        sudo rm -f "/etc/systemd/system/$SERVICE_NAME.service"
        sudo systemctl daemon-reload
        
        # Remove installation directory
        sudo rm -rf "/opt/fastfetch-server"
        
        # Remove user (optional)
        read -p "Remove service user 'fastfetch'? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo userdel fastfetch 2>/dev/null || true
            sudo groupdel fastfetch 2>/dev/null || true
            echo -e "${GREEN}✅ Service user removed${NC}"
        fi
        
        echo -e "${GREEN}✅ Service uninstalled successfully${NC}"
    else
        echo -e "${YELLOW}❌ Uninstall cancelled${NC}"
    fi
}

# Function to show help
show_help() {
    echo -e "${BLUE}FastFetch Server Service Management${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status                Show service status"
    echo "  start                 Start the service"
    echo "  stop                  Stop the service"
    echo "  restart               Restart the service"
    echo "  enable                Enable service (start on boot)"
    echo "  disable               Disable service (don't start on boot)"
    echo "  logs                  Show service logs"
    echo "  logs -f, logs --follow Follow service logs"
    echo "  uninstall             Completely remove the service"
    echo "  help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 status             # Check if service is running"
    echo "  $0 restart            # Restart the service"
    echo "  $0 logs -f            # Follow logs in real-time"
    echo ""
    echo -e "${YELLOW}Note: Most commands require sudo privileges${NC}"
}

# Main script logic
case "$1" in
    "status")
        check_service
        show_status
        ;;
    "start")
        check_service
        start_service
        ;;
    "stop")
        check_service
        stop_service
        ;;
    "restart")
        check_service
        restart_service
        ;;
    "enable")
        check_service
        enable_service
        ;;
    "disable")
        check_service
        disable_service
        ;;
    "logs")
        check_service
        show_logs "$2"
        ;;
    "uninstall")
        check_service
        uninstall_service
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    "")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac