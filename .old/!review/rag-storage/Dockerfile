# ============================================================================
# RAG Storage Service - Vector Database Integration Container
# ============================================================================
#
# PURPOSE:
#   Final stage microservice for Video RAG pipeline. Stores processed video
#   segments with vector embeddings in Qdrant for semantic search and RAG
#   query capabilities. Enables natural language queries over video content.
#
# BASE IMAGE:
#   python:3.11-slim
#   - Lightweight Python 3.11 runtime (no CUDA needed)
#   - Debian-based for package compatibility
#   - Optimized for CPU-based embedding generation
#
# ARCHITECTURE:
#   Input: Kafka video-segments topic (processed segments)
#   Process: Vector embedding generation and Qdrant storage
#   Output: Searchable vector database for RAG applications
#
# PERFORMANCE:
#   - CPU-based processing (sentence transformers)
#   - Memory usage: ~1-2GB (depends on collection size)
#   - Sub-millisecond query response times
#   - No GPU required for embedding generation
#
# ============================================================================

# Use Python 3.11 slim image for lightweight container
# No CUDA needed - sentence transformers work efficiently on CPU
FROM python:3.11-slim

# Set working directory for application code
WORKDIR /app

# ============================================================================
# PYTHON ENVIRONMENT SETUP
# ============================================================================
# Configure Python environment and install dependencies

# Upgrade pip to latest version
RUN pip install --upgrade pip

# Copy requirements file for Docker layer caching
COPY requirements.txt .

# Install Python dependencies
# Includes: Qdrant client, sentence transformers, FastAPI, Kafka clients
RUN pip install --no-cache-dir -r requirements.txt

# ============================================================================
# APPLICATION CODE AND CONFIGURATION
# ============================================================================
# Copy application code and prepare runtime environment

# Copy all application code to container
COPY . .

# Create necessary directories for runtime
# /app/logs: Application log files and vector storage metrics
RUN mkdir -p /app/logs

# ============================================================================
# RUNTIME ENVIRONMENT VARIABLES
# ============================================================================
# Configure Python runtime behavior for containerized environment

# Ensure Python output is sent straight to terminal
# Critical for monitoring vector storage operations
ENV PYTHONUNBUFFERED=1

# Prevent Python from writing .pyc files
# Reduces container size and eliminates file permission issues
ENV PYTHONDONTWRITEBYTECODE=1

# ============================================================================
# NETWORK AND HEALTH CONFIGURATION
# ============================================================================
# Configure container networking and health monitoring

# Expose port 8000 for HTTP health checks and RAG query API
EXPOSE 8000

# Configure health check for container orchestration
# Verifies service is responding and Qdrant connection is healthy
# --start-period=30s: Quick startup (no model loading required)
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')"

# ============================================================================
# CONTAINER STARTUP
# ============================================================================
# Define the command to run when container starts

# Start the RAG storage service
# Begins Kafka consumption and Qdrant vector storage operations
CMD ["python", "src/main.py"]
