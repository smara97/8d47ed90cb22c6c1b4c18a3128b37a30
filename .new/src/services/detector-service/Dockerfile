# ============================================================================
# detector service Service - Multi-stage Docker Build
# ============================================================================
#
# PURPOSE:
#   Containerized detector-service service for the Video RAG microservices
#   architecture with enterprise security and performance optimization.
#
# ARCHITECTURE:
#   Multi-stage build pattern for optimized production images:
#   1. Builder stage: Compiles dependencies with build tools
#   2. Runtime stage: Minimal production image with only runtime requirements
#
# SECURITY FEATURES:
#   - Non-root user execution for container security
#   - Minimal attack surface with slim base image
#   - No package managers in final runtime image
#   - Proper file ownership and permission management
#
# PERFORMANCE OPTIMIZATIONS:
#   - Multi-stage build reduces final image size
#   - Cached dependency layer for faster rebuilds
#   - Optimized Python package installation
#
# MONITORING:
#   - Built-in health check endpoint for container orchestration
#   - Configurable health check intervals and timeouts
#   - Proper exit codes for monitoring systems
#
# ============================================================================

# Build stage - Contains build tools and compiles dependencies
FROM python:3.11-slim as builder

# Set working directory for build operations
WORKDIR /build

# Install build dependencies required for Python package compilation
# gcc: Required for compiling native extensions in Python packages
# Clean up package cache to reduce layer size
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file for dependency installation
# Separate COPY for better Docker layer caching
COPY requirements.txt .

# Upgrade pip to latest version for better dependency resolution
RUN python -m pip install --upgrade pip

# Install Python dependencies to user directory
# --no-cache-dir: Prevents pip cache to reduce image size
# --user: Installs to user directory for easy copying to runtime stage
RUN pip install --no-cache-dir --user -r requirements.txt

# Copy application source code
# Separate COPY for better layer caching when code changes
COPY src/ ./src/

# Runtime stage - Minimal production image
FROM python:3.11-slim

# Set working directory for application
WORKDIR /app

# Install minimal runtime dependencies and create non-root user
# groupadd/useradd: Creates system user/group for security
# Clean up package cache and remove package managers for security
RUN apt-get update && apt-get install -y \
    curl \
    && groupadd -r appuser \
    && useradd -r -g appuser -u 1000 appuser \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/bin/apt* /usr/bin/dpkg*

# Copy compiled Python packages from builder stage
# Copies only the installed packages, not build tools
COPY --from=builder /root/.local /home/appuser/.local

# Copy application source code from builder
COPY --from=builder /build/src ./src

# Create necessary directories and set proper ownership
# Ensures appuser owns all application files and directories
RUN mkdir -p /app/logs \
    && chown -R appuser:appuser /app

# Switch to non-root user for runtime security
USER appuser

# Add user-installed packages to PATH
# Allows execution of installed Python packages
ENV PATH=/home/appuser/.local/bin:$PATH

# Configure health check for container orchestration
# --interval: How often to run health check (30s)
# --timeout: Maximum time to wait for health check (10s)
# --start-period: Grace period before health checks start (5s)
# --retries: Number of consecutive failures before marking unhealthy (3)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Expose application port for external access
# Port 8000 is the standard FastAPI development port
EXPOSE 8000

# Define container startup command
# Runs the main application module directly
CMD ["python", "src/main.py"]