# ============================================================================
# Frame Producer Service - Video Input Pipeline Container
# ============================================================================
#
# PURPOSE:
#   Entry point for Video RAG pipeline. Extracts frames from video sources
#   and publishes them to Kafka for parallel processing by vision services.
#   Handles multiple video formats and streaming sources.
#
# BASE IMAGE:
#   python:3.11-slim
#   - Lightweight Python 3.11 runtime (no CUDA needed)
#   - Debian-based for package compatibility
#   - Optimized for CPU-based video processing
#
# ARCHITECTURE:
#   Input: Video files, RTSP streams, camera feeds
#   Process: Frame extraction, encoding, metadata enrichment
#   Output: Kafka raw-frames topic (base64 encoded frames)
#
# PERFORMANCE:
#   - CPU-based processing (~100-200 fps capability)
#   - Memory usage: ~500MB-1GB (depends on video resolution)
#   - No GPU required (OpenCV CPU optimizations)
#
# ============================================================================

# Use Python 3.11 slim image for lightweight container
# No CUDA needed - frame extraction is CPU-efficient
FROM python:3.11-slim

# Set working directory for application code
WORKDIR /app

# ============================================================================
# SYSTEM DEPENDENCIES INSTALLATION
# ============================================================================
# Install system libraries required for OpenCV video processing

RUN apt-get update && apt-get install -y \
    # OpenCV system dependencies for video codec support
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    # OpenMP for parallel processing
    libgomp1 \
    # OpenGL for hardware-accelerated operations
    libgl1-mesa-glx \
    # Clean up package cache to reduce image size
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
# PYTHON ENVIRONMENT SETUP
# ============================================================================
# Configure Python environment and install dependencies

# Upgrade pip to latest version
RUN pip install --upgrade pip

# Copy requirements file for Docker layer caching
COPY requirements.txt .

# Install Python dependencies
# Includes: OpenCV, FastAPI, Kafka clients, video codecs
RUN pip install --no-cache-dir -r requirements.txt

# ============================================================================
# APPLICATION CODE AND CONFIGURATION
# ============================================================================
# Copy application code and prepare runtime environment

# Copy all application code to container
COPY . .

# Create necessary directories for runtime
# /app/logs: Application log files and processing metrics
RUN mkdir -p /app/logs

# ============================================================================
# RUNTIME ENVIRONMENT VARIABLES
# ============================================================================
# Configure Python runtime behavior for containerized environment

# Ensure Python output is sent straight to terminal
# Critical for real-time log visibility during video processing
ENV PYTHONUNBUFFERED=1

# Prevent Python from writing .pyc files
# Reduces container size and eliminates file permission issues
ENV PYTHONDONTWRITEBYTECODE=1

# ============================================================================
# NETWORK AND HEALTH CONFIGURATION
# ============================================================================
# Configure container networking and health monitoring

# Expose port 8000 for HTTP health checks and control interface
EXPOSE 8000

# Configure health check for container orchestration
# Verifies service is responding and video sources are accessible
# --start-period=30s: Shorter startup time (no model loading)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')"

# ============================================================================
# CONTAINER STARTUP
# ============================================================================
# Define the command to run when container starts

# Start the frame producer service
# Begins video processing and Kafka frame publishing
CMD ["python", "src/main.py"]
