# Use a minimal base image
FROM debian:bookworm-slim

# Install CA certificates for HTTPS requests
RUN apt-get update && \
    apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -r -s /bin/false appuser

# Copy the binary from the artifacts directory (populated by GitHub Actions)
COPY ./artifacts/ip-fetcher /usr/local/bin/ip-fetcher

# Make sure the binary is executable
RUN chmod +x /usr/local/bin/ip-fetcher

# Change ownership to the app user
RUN chown appuser:appuser /usr/local/bin/ip-fetcher

# Switch to non-root user
USER appuser

# Expose port 3000
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# Run the binary
CMD ["/usr/local/bin/ip-fetcher"]