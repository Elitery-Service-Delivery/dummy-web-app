#!/bin/bash

# Build script for FastFetch Server
# This script builds the application for multiple platforms

set -e

APP_NAME="fastfetch-server"
VERSION=${1:-"dev"}

echo "🏗️  Building $APP_NAME version $VERSION"

# Clean previous builds
rm -rf dist/
mkdir -p dist/

# Build for different platforms
PLATFORMS=(
    "linux/amd64"
    "linux/arm64"
    "darwin/amd64"
    "darwin/arm64"
    "windows/amd64"
)

for platform in "${PLATFORMS[@]}"; do
    GOOS=${platform%/*}
    GOARCH=${platform#*/}
    
    output_name="${APP_NAME}-${GOOS}-${GOARCH}"
    if [ "$GOOS" = "windows" ]; then
        output_name="${output_name}.exe"
    fi
    
    echo "📦 Building for $GOOS/$GOARCH..."
    
    env GOOS=$GOOS GOARCH=$GOARCH CGO_ENABLED=0 go build \
        -a -ldflags '-extldflags "-static"' \
        -o "dist/$output_name" \
        main.go
    
    echo "✅ Built: dist/$output_name"
done

echo ""
echo "🎉 Build complete! Binaries available in dist/"
ls -la dist/

echo ""
echo "📋 To test locally:"
echo "   ./dist/${APP_NAME}-$(go env GOOS)-$(go env GOARCH)"