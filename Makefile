.PHONY: build run test clean docker docker-dev help

# Default target
help:
	@echo "Available targets:"
	@echo "  build      - Build the Rust application"
	@echo "  run        - Run the application locally"
	@echo "  test       - Run tests"
	@echo "  clean      - Clean build artifacts"
	@echo "  docker     - Build Docker image for development"
	@echo "  docker-dev - Run with docker-compose"
	@echo "  fmt        - Format code"
	@echo "  clippy     - Run clippy linter"

# Build the application
build:
	cargo build --release

# Run the application
run:
	cargo run

# Run tests
test:
	cargo test

# Clean build artifacts
clean:
	cargo clean

# Format code
fmt:
	cargo fmt

# Run clippy
clippy:
	cargo clippy -- -D warnings

# Build Docker image for development
docker:
	docker build -f Dockerfile.dev -t ip-fetcher:dev .

# Run with docker-compose
docker-dev:
	docker-compose up --build

# Stop docker-compose services
docker-stop:
	docker-compose down

# View logs
docker-logs:
	docker-compose logs -f ip-fetcher

# Check if the service is running
check:
	@echo "Checking if service is running..."
	@curl -s http://localhost:3000/health || echo "Service is not running"
	@echo ""
	@curl -s http://localhost:3000/ | head -c 100 || echo "Service is not responding to main endpoint"