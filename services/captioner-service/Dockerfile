# ============================================================================
# Image Captioning Service - Vision-Language Model Container
# ============================================================================
#
# PURPOSE:
#   Advanced image captioning microservice using transformer-based models.
#   Generates natural language descriptions of video frame content for
#   enhanced semantic understanding and narrative generation.
#
# BASE IMAGE:
#   nvidia/cuda:12.4-runtime-ubuntu22.04
#   - CUDA 12.4 runtime for modern PyTorch compatibility
#   - Transformers library handles its own optimizations
#   - Ubuntu 22.04 LTS for package stability
#
# ARCHITECTURE:
#   Input: Kafka raw-frames topic (base64 encoded images)
#   Process: BLIP/BLIP-2 vision-language model inference
#   Output: Kafka caption-results topic (natural language descriptions)
#
# PERFORMANCE:
#   - GPU-accelerated transformer inference (~100-150ms per frame)
#   - Memory usage: ~3-5GB GPU RAM (model dependent)
#   - Supports batch processing for efficiency
#
# ============================================================================

# ============================================================================
# BUILD STAGE
# ============================================================================
FROM nvidia/cuda:12.2.2-runtime-ubuntu22.04 AS builder

WORKDIR /build
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3.11 python3.11-dev python3-pip build-essential \
    libglib2.0-0 libsm6 libxext6 libxrender-dev libgomp1 \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python3.11 /usr/bin/python
RUN python -m pip install --upgrade pip

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt
COPY src/ ./src/

# ============================================================================
# RUNTIME STAGE
# ============================================================================
FROM nvidia/cuda:12.2.2-runtime-ubuntu22.04 AS runtime

WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies and create non-root user
RUN apt-get update && apt-get install -y \
    python3.11 libglib2.0-0 libsm6 libxext6 libxrender-dev libgomp1 \
    libgl1-mesa-glx \
    && groupadd -r appuser && useradd -r -g appuser -u 1000 appuser \
    && rm -rf /var/lib/apt/lists/* /usr/bin/apt* /usr/bin/dpkg*

RUN ln -s /usr/bin/python3.11 /usr/bin/python

# Copy from build stage
COPY --from=builder /root/.local /home/appuser/.local
COPY --from=builder /build/src ./src

# Create directories with proper ownership
RUN mkdir -p /app/logs && chown -R appuser:appuser /app

ENV PATH=/home/appuser/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 PYTHONHASHSEED=0 PYTHONOPTIMIZE=1 \
    QT_QPA_PLATFORM=offscreen

# Switch to non-root user
USER appuser

# Expose port and configure health check
EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=2s --start-period=45s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health', timeout=2)" || exit 1

# Start service
CMD ["python", "src/main.py"]
