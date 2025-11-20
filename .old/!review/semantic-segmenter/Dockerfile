# ============================================================================
# Semantic Segmenter Service Dockerfile
# ============================================================================
# Purpose: Segments video into semantic chunks based on content similarity
# Dependencies: Python 3.11, FastAPI, scikit-learn
# ============================================================================

FROM python:3.11-slim

WORKDIR /app

RUN pip install --upgrade pip

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
RUN mkdir -p /app/logs

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')"

CMD ["python", "src/main.py"]
