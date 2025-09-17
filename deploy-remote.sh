#!/bin/bash

# Remote Deployment Script for FastFetch Server
# Deploys to veeam.jk3 via SSH

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REMOTE_HOST="veeam.jk3"
REMOTE_USER="${REMOTE_USER:-$(whoami)}"
REMOTE_TEMP_DIR="/tmp/fastfetch-server-deploy"
LOCAL_BUILD_DIR="dist"
BINARY_NAME="fastfetch-server-linux-amd64"

echo -e "${BLUE}🚀 FastFetch Server Remote Deployment${NC}"
echo -e "${BLUE}====================================${NC}"
echo -e "${YELLOW}Target: ${REMOTE_USER}@${REMOTE_HOST}${NC}"
echo ""

# Function to check if binary exists
check_binary() {
    if [[ ! -f "$LOCAL_BUILD_DIR/$BINARY_NAME" ]]; then
        echo -e "${RED}❌ Binary not found: $LOCAL_BUILD_DIR/$BINARY_NAME${NC}"
        echo -e "${YELLOW}💡 Building binary first...${NC}"
        ./build.sh
        if [[ ! -f "$LOCAL_BUILD_DIR/$BINARY_NAME" ]]; then
            echo -e "${RED}❌ Build failed or binary still not found${NC}"
            exit 1
        fi
    fi
    echo -e "${GREEN}✅ Binary found: $LOCAL_BUILD_DIR/$BINARY_NAME${NC}"
}

# Function to test SSH connectivity
test_ssh() {
    echo -e "${BLUE}🔗 Testing SSH connectivity...${NC}"
    if ssh -o ConnectTimeout=10 -o BatchMode=yes "$REMOTE_USER@$REMOTE_HOST" exit 2>/dev/null; then
        echo -e "${GREEN}✅ SSH connection successful${NC}"
    else
        echo -e "${RED}❌ SSH connection failed${NC}"
        echo -e "${YELLOW}💡 Please ensure:${NC}"
        echo "   - SSH key is configured"
        echo "   - Server is accessible"
        echo "   - User has sudo privileges"
        exit 1
    fi
}

# Function to create deployment package
create_package() {
    echo -e "${BLUE}📦 Creating deployment package...${NC}"
    
    local temp_pkg="/tmp/fastfetch-deploy-$(date +%s)"
    mkdir -p "$temp_pkg"
    
    # Copy necessary files
    cp "$LOCAL_BUILD_DIR/$BINARY_NAME" "$temp_pkg/"
    cp install-service.sh "$temp_pkg/"
    cp service.sh "$temp_pkg/"
    cp -r systemd "$temp_pkg/"
    
    # Create a deployment info file
    cat > "$temp_pkg/deploy-info.txt" << EOF
Deployment Package for FastFetch Server
=======================================
Created: $(date)
Binary: $BINARY_NAME
Target: $REMOTE_USER@$REMOTE_HOST
Version: $(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
EOF
    
    echo "$temp_pkg"
}

# Function to deploy to remote server
deploy_remote() {
    local package_dir="$1"
    
    echo -e "${BLUE}🚀 Deploying to remote server...${NC}"
    
    # Create remote temp directory
    ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_TEMP_DIR"
    
    # Copy deployment package
    echo -e "${BLUE}📤 Uploading files...${NC}"
    scp -r "$package_dir"/* "$REMOTE_USER@$REMOTE_HOST:$REMOTE_TEMP_DIR/"
    
    # Execute remote deployment
    echo -e "${BLUE}⚙️  Installing service on remote server...${NC}"
    ssh "$REMOTE_USER@$REMOTE_HOST" << 'EOF'
        set -e
        cd /tmp/fastfetch-server-deploy
        
        echo "🔍 Checking deployment files..."
        ls -la
        
        echo "📋 Deployment info:"
        cat deploy-info.txt
        
        echo ""
        echo "🔧 Installing FastFetch server..."
        
        # Make scripts executable
        chmod +x install-service.sh service.sh
        
        # Create dist directory structure expected by install script
        mkdir -p dist
        cp fastfetch-server-linux-amd64 dist/
        
        # Run installation
        sudo ./install-service.sh
        
        echo ""
        echo "✅ Deployment completed!"
EOF
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Remote deployment successful!${NC}"
    else
        echo -e "${RED}❌ Remote deployment failed${NC}"
        exit 1
    fi
}

# Function to verify deployment
verify_deployment() {
    echo -e "${BLUE}🔍 Verifying deployment...${NC}"
    
    # Check service status
    echo -e "${YELLOW}Checking service status...${NC}"
    ssh "$REMOTE_USER@$REMOTE_HOST" "sudo systemctl status fastfetch-server --no-pager -l || true"
    
    # Test HTTP endpoint
    echo -e "${YELLOW}Testing HTTP endpoint...${NC}"
    if ssh "$REMOTE_USER@$REMOTE_HOST" "curl -s -f http://localhost:3131 >/dev/null"; then
        echo -e "${GREEN}✅ HTTP endpoint is responding${NC}"
    else
        echo -e "${RED}❌ HTTP endpoint is not responding${NC}"
        echo -e "${YELLOW}📋 Checking logs...${NC}"
        ssh "$REMOTE_USER@$REMOTE_HOST" "sudo journalctl -u fastfetch-server --no-pager -l | tail -20"
    fi
}

# Function to show post-deployment info
show_info() {
    echo ""
    echo -e "${GREEN}🎉 Deployment Summary${NC}"
    echo -e "${GREEN}===================${NC}"
    echo -e "${BLUE}Server:${NC} $REMOTE_USER@$REMOTE_HOST"
    echo -e "${BLUE}Service:${NC} fastfetch-server"
    echo -e "${BLUE}URL:${NC} http://$REMOTE_HOST:3131"
    echo -e "${BLUE}Status:${NC} $(ssh "$REMOTE_USER@$REMOTE_HOST" "systemctl is-active fastfetch-server")"
    echo ""
    echo -e "${BLUE}📋 Remote Management Commands:${NC}"
    echo "  ssh $REMOTE_USER@$REMOTE_HOST 'sudo systemctl status fastfetch-server'"
    echo "  ssh $REMOTE_USER@$REMOTE_HOST 'sudo systemctl restart fastfetch-server'"
    echo "  ssh $REMOTE_USER@$REMOTE_HOST 'sudo journalctl -u fastfetch-server -f'"
    echo ""
    echo -e "${BLUE}🌐 Access the service:${NC}"
    echo "  curl http://$REMOTE_HOST:3131"
    echo "  # Or in browser: http://$REMOTE_HOST:3131"
}

# Function to cleanup
cleanup() {
    echo -e "${BLUE}🧹 Cleaning up...${NC}"
    
    # Cleanup local temp files
    if [[ -n "$TEMP_PACKAGE" && -d "$TEMP_PACKAGE" ]]; then
        rm -rf "$TEMP_PACKAGE"
        echo -e "${GREEN}✅ Local cleanup completed${NC}"
    fi
    
    # Cleanup remote temp files
    ssh "$REMOTE_USER@$REMOTE_HOST" "rm -rf $REMOTE_TEMP_DIR" 2>/dev/null || true
    echo -e "${GREEN}✅ Remote cleanup completed${NC}"
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# Main deployment process
main() {
    echo -e "${YELLOW}📋 Deployment Steps:${NC}"
    echo "1. Check binary availability"
    echo "2. Test SSH connectivity"
    echo "3. Create deployment package"
    echo "4. Deploy to remote server"
    echo "5. Verify deployment"
    echo ""
    
    # Execute deployment steps
    check_binary
    test_ssh
    
    TEMP_PACKAGE=$(create_package)
    echo -e "${GREEN}✅ Package created: $TEMP_PACKAGE${NC}"
    
    deploy_remote "$TEMP_PACKAGE"
    verify_deployment
    show_info
    
    echo ""
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
}

# Parse command line arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "status")
        echo -e "${BLUE}📊 Checking remote service status...${NC}"
        ssh "$REMOTE_USER@$REMOTE_HOST" "sudo systemctl status fastfetch-server --no-pager -l"
        ;;
    "logs")
        echo -e "${BLUE}📋 Showing remote service logs...${NC}"
        ssh "$REMOTE_USER@$REMOTE_HOST" "sudo journalctl -u fastfetch-server --no-pager -l"
        ;;
    "restart")
        echo -e "${BLUE}🔄 Restarting remote service...${NC}"
        ssh "$REMOTE_USER@$REMOTE_HOST" "sudo systemctl restart fastfetch-server"
        echo -e "${GREEN}✅ Service restarted${NC}"
        ;;
    "test")
        echo -e "${BLUE}🌐 Testing remote endpoint...${NC}"
        ssh "$REMOTE_USER@$REMOTE_HOST" "curl -v http://localhost:3131" || true
        ;;
    "help"|"--help"|"-h")
        echo "FastFetch Server Remote Deployment Script"
        echo ""
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  deploy     Deploy service to remote server (default)"
        echo "  status     Check remote service status"
        echo "  logs       Show remote service logs"
        echo "  restart    Restart remote service"
        echo "  test       Test remote HTTP endpoint"
        echo "  help       Show this help"
        echo ""
        echo "Environment Variables:"
        echo "  REMOTE_USER    Remote SSH username (default: current user)"
        echo ""
        echo "Examples:"
        echo "  $0 deploy                    # Deploy to veeam.jk3"
        echo "  $0 status                    # Check service status"
        echo "  REMOTE_USER=admin $0 deploy  # Deploy as different user"
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac