# IP Fetcher Service

A lightweight Rust web service that fetches and caches IP information from ifconfig.co. The service implements a simple caching mechanism with a 1-minute TTL to reduce external API calls.

## Features

- 🚀 Fast HTTP server built with Axum
- 🔄 In-memory caching with 1-minute TTL
- 🐳 Docker support with multi-stage builds
- 🔄 GitHub Actions CI/CD pipeline
- 📦 Automated artifact and container publishing
- 🔒 Security-focused container configuration
- 🏥 Health check endpoints

## API Endpoints

- `GET /` - Returns IP information (cached for 1 minute)
- `GET /health` - Health check endpoint

## Quick Start

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/Elitery-Service-Delivery/dummy-web-app.git
   cd dummy-web-app
   ```

2. **Run with Cargo**
   ```bash
   cargo run
   ```

3. **Test the service**
   ```bash
   curl http://localhost:3000/
   ```

### Docker Development

1. **Using Docker Compose (recommended)**
   ```bash
   docker compose up --build
   ```

2. **Using Docker directly**
   ```bash
   docker build -f Dockerfile.dev -t ip-fetcher .
   docker run -p 3000:3000 ip-fetcher
   ```

### Production Deployment

**Note**: The published Docker image will be available after the first successful CI/CD pipeline run.

1. **Update the image reference in `docker-compose.yml`**
   ```yaml
   # Comment out the build section and uncomment the image line:
   image: ghcr.io/elitery-service-delivery/dummy-web-app:latest
   # build:
   #   context: .
   #   dockerfile: Dockerfile.dev
   ```

2. **Run in production mode**
   ```bash
   docker compose up -d
   ```

## GitHub Actions CI/CD

The repository includes a comprehensive CI/CD pipeline that:

1. **Build Job:**
   - Runs tests
   - Builds the Rust binary
   - Uploads binary as GitHub Actions artifact

2. **Docker Job:**
   - Downloads the built binary
   - Builds and pushes Docker image to GitHub Container Registry
   - Tags images appropriately (latest, version tags)

3. **Release Job:**
   - Creates release artifacts when a GitHub release is published
   - Packages binary into tar.gz for distribution

### Setting Up CI/CD

1. **Enable GitHub Actions** in your repository settings

2. **Enable GitHub Container Registry:**
   - Go to repository Settings → Actions → General
   - Under "Workflow permissions", select "Read and write permissions"

3. **Push to main/master branch** to trigger the build

4. **Published Docker images** will be available at:
   ```
   ghcr.io/elitery-service-delivery/dummy-web-app:latest
   ```

### Docker Resource Limits

The Docker Compose configuration includes:
- Memory limit: 256MB
- CPU limit: 1.0 cores
- Memory reservation: 128MB
- CPU reservation: 0.2 cores

## API Response Format

```json
{
  "ip": "192.168.1.100",
  "country": "United States",
  "country_code": "US",
  "city": "New York",
  "region": "New York",
  "region_code": "NY",
  "zip": "10001",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "timezone": "America/New_York",
  "asn": "AS12345",
  "org": "Example ISP"
}
```

## Architecture

The application follows the flow described in the design:

1. **Start** - Initialize the HTTP server
2. **Open Port 3000/TCP** - Bind to port 3000
3. **Handle `/` requests** - Process incoming HTTP requests
4. **Fetch from ifconfig.co/json** - Make HTTP request to external API
5. **Return cached result** - Serve response with 1-minute cache
6. **Done** - Complete the request cycle

## Development

### Prerequisites

- Rust 1.75 or later
- Docker (optional)
- Docker Compose (optional)

### Building

```bash
cargo build --release
```

### Testing

```bash
cargo test
```

### Code Structure

- `src/main.rs` - Main application code
- `Cargo.toml` - Rust dependencies and metadata
- `Dockerfile` - Production container (uses pre-built artifacts)
- `Dockerfile.dev` - Development container (builds from source)
- `.github/workflows/build.yml` - CI/CD pipeline

## Security Features

- Non-root user in containers
- Read-only root filesystem in production
- Resource limits and reservations
- Health checks for container orchestration
- Minimal base image (Debian slim)

## Monitoring

The service includes a health check endpoint at `/health` that returns "OK" when the service is running properly.

For production monitoring, consider:
- Setting up log aggregation
- Monitoring the health check endpoint
- Setting up alerts for container resource usage

## License

This project is licensed under the MIT License - see the LICENSE file for details.