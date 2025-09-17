# FastFetch Web Server

A lightweight Go web server that serves system information via [fastfetch](https://github.com/fastfetch-cli/fastfetch) on port 3131.

## ✨ Features

- 🌐 **Web Interface**: Clean HTML interface on `http://localhost:3131`
- ⚡ **Performance**: Built with Go for speed and efficiency
- 💾 **Smart Caching**: 1-minute cache to reduce system load
- 🖥️ **System Info**: Displays comprehensive system information via fastfetch
- 📦 **Single Binary**: Statically compiled with no dependencies

## 🚀 Quick Start

### Prerequisites
- [fastfetch](https://github.com/fastfetch-cli/fastfetch) installed on your system

### Installation

#### Option 1: Download Pre-built Binary
1. Go to [Releases](../../releases)
2. Download the appropriate binary for your system:
   - Linux AMD64: `fastfetch-server-linux-amd64.tar.gz`
   - Linux ARM64: `fastfetch-server-linux-arm64.tar.gz`
   - macOS AMD64: `fastfetch-server-darwin-amd64.tar.gz`
   - macOS ARM64: `fastfetch-server-darwin-arm64.tar.gz`
   - Windows AMD64: `fastfetch-server-windows-amd64.zip`

3. Extract and run:
   ```bash
   # Linux/macOS
   tar -xzf fastfetch-server-*.tar.gz
   chmod +x fastfetch-server-*
   ./fastfetch-server-*
   
   # Windows
   # Extract the zip file and run fastfetch-server-windows-amd64.exe
   ```

#### Option 2: Build from Source
```bash
git clone <repository-url>
cd dummy-apps
go mod download
go build -o fastfetch-server main.go
./fastfetch-server
```

#### Option 3: Use Build Script
```bash
./build.sh
./dist/fastfetch-server-$(go env GOOS)-$(go env GOARCH)
```

### Usage

1. Start the server:
   ```bash
   ./fastfetch-server
   ```

2. Open your browser and visit: `http://localhost:3131`

3. View your system information in a clean, formatted interface!

## 🔧 Development

### Local Development
```bash
# Install dependencies
go mod download

# Run in development mode
go run main.go

# Build for current platform
go build -o fastfetch-server main.go

# Build for all platforms
./build.sh
```

### Project Structure
```
.
├── main.go                         # Main application code
├── go.mod                          # Go module definition
├── build.sh                        # Multi-platform build script
├── install-service.sh              # Ubuntu systemd service installer
├── service.sh                      # Service management script
├── systemd/
│   └── fastfetch-server.service    # Systemd service definition
├── .github/
│   └── workflows/
│       └── build-and-release.yml   # GitHub Actions CI/CD
└── README.md                       # This file
```

## 🚀 Deployment

### Production Deployment (Ubuntu 24.04)

For production deployment as a systemd service:

#### Quick Installation
```bash
# 1. Build the binary (if not already done)
./build.sh

# 2. Install as systemd service (requires sudo)
sudo ./install-service.sh

# 3. The service will be automatically started and enabled
# Visit: http://localhost:3131
```

#### Service Management
```bash
# Check service status
./service.sh status

# Start/stop/restart service
./service.sh start
./service.sh stop
./service.sh restart

# View logs
./service.sh logs
./service.sh logs -f  # Follow logs

# Enable/disable auto-start on boot
./service.sh enable
./service.sh disable

# Completely remove service
./service.sh uninstall
```

#### Manual Service Commands
```bash
# Systemd service commands
sudo systemctl status fastfetch-server
sudo systemctl start fastfetch-server
sudo systemctl stop fastfetch-server
sudo systemctl restart fastfetch-server
sudo systemctl enable fastfetch-server   # Auto-start on boot
sudo systemctl disable fastfetch-server  # Disable auto-start

# View logs
sudo journalctl -u fastfetch-server       # All logs
sudo journalctl -u fastfetch-server -f    # Follow logs
sudo journalctl -u fastfetch-server --since today  # Today's logs
```

#### Service Details
- **Service Name**: `fastfetch-server`
- **Service User**: `fastfetch` (created automatically)
- **Installation Path**: `/opt/fastfetch-server/`
- **Binary Location**: `/opt/fastfetch-server/fastfetch-server`
- **Service File**: `/etc/systemd/system/fastfetch-server.service`
- **Port**: `3131`
- **Auto-restart**: Enabled (restarts on failure)
- **Security**: Runs with restricted privileges

### GitHub Actions
This project includes automated GitHub Actions workflows that:

1. **Build**: Creates binaries for multiple platforms (Linux, macOS, Windows)
2. **Release**: Automatically creates GitHub releases when tags are pushed
3. **Artifacts**: Uploads compiled binaries as release assets

#### Triggering a Release
```bash
# Create and push a tag
git tag v1.0.0
git push origin v1.0.0

# Or trigger manually via GitHub Actions UI
```

#### Manual Release Trigger
You can also trigger releases manually through the GitHub Actions UI with custom version tags.

## 📋 API

### Endpoints

#### `GET /`
Returns system information from fastfetch in a formatted HTML page.

**Response**: HTML page with preformatted system information

**Caching**: Results are cached for 1 minute to prevent excessive system calls

## 🛠️ Configuration

- **Port**: Fixed to `3131` (can be modified in `main.go`)
- **Cache Duration**: 1 minute (can be modified in `main.go`)
- **Command**: Uses `fastfetch` command (ensure it's in your PATH)

## 🔒 Security Considerations

- The server only accepts GET requests on the root path
- No user input is processed directly
- Command execution is limited to the predefined `fastfetch` command
- Consider running behind a reverse proxy in production

## 📄 License

This project is open source. See the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## ❓ Troubleshooting

### Common Issues

**"command not found: fastfetch"**
- Install fastfetch: https://github.com/fastfetch-cli/fastfetch#installation

**"Permission denied"**
- Make the binary executable: `chmod +x fastfetch-server-*`

**"Port already in use"**
- Another service is using port 3131. Stop it or modify the port in `main.go`

**"Failed to execute fastfetch"**
- Ensure fastfetch is installed and in your system PATH
- Test manually: `fastfetch`