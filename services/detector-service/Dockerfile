# ============================================================================
# Object Detection Service - YOLO-based Computer Vision Container
# ============================================================================
#
# PURPOSE:
#   High-performance object detection microservice using YOLO models.
#   Processes video frames to identify and localize objects, people, vehicles,
#   and other entities for comprehensive scene understanding.
#
# BASE IMAGE:
#   nvidia/cuda:12.4-cudnn9-runtime-ubuntu22.04
#   - CUDA 12.4 runtime for GPU-accelerated inference
#   - cuDNN 9 for optimized convolutional operations
#   - Ubuntu 22.04 LTS for package stability
#
# ARCHITECTURE:
#   Input: Kafka raw-frames topic (base64 encoded images)
#   Process: YOLO object detection with NMS filtering
#   Output: Kafka detection-results topic (bounding boxes + classes)
#
# PERFORMANCE:
#   - GPU-accelerated inference (~30-60ms per frame)
#   - Memory usage: ~1-6GB GPU RAM (model dependent)
#   - Supports YOLO11n (nano) to YOLO11x (extra-large)
#
# ============================================================================

# ============================================================================
# BUILD STAGE - Development Environment
# ============================================================================
FROM nvidia/cuda:12.2.2-cudnn8-runtime-ubuntu22.04 AS builder

WORKDIR /build
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    python3.11 python3.11-dev python3-pip build-essential \
    libglib2.0-0 libsm6 libxext6 libxrender-dev libgomp1 \
    libgl1-mesa-glx libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python3.11 /usr/bin/python
RUN python -m pip install --upgrade pip

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt
COPY src/ ./src/

# ============================================================================
# RUNTIME STAGE - Production Environment
# ============================================================================
FROM nvidia/cuda:12.2.2-cudnn8-runtime-ubuntu22.04 AS runtime

WORKDIR /app
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies and create non-root user
RUN apt-get update && apt-get install -y \
    python3.11 libglib2.0-0 libsm6 libxext6 libxrender-dev \
    libgomp1 libgl1-mesa-glx \
    && groupadd -r appuser && useradd -r -g appuser -u 1000 appuser \
    && rm -rf /var/lib/apt/lists/* /usr/bin/apt* /usr/bin/dpkg*

RUN ln -s /usr/bin/python3.11 /usr/bin/python

# Copy from build stage
COPY --from=builder /root/.local /home/appuser/.local
COPY --from=builder /build/src ./src

# Create directories with proper ownership
RUN mkdir -p /app/logs /app/models \
    && chown -R appuser:appuser /app

ENV PATH=/home/appuser/.local/bin:$PATH

# Production runtime environment
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONHASHSEED=0 \
    PYTHONOPTIMIZE=1 \
    TORCHVISION_DISABLE_NMS_CUDA=1 \
    QT_QPA_PLATFORM=offscreen

# Switch to non-root user
USER appuser

# Expose port and configure health check
EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=2s --start-period=30s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health', timeout=2)" || exit 1

# Start service
CMD ["python", "src/main.py"]
