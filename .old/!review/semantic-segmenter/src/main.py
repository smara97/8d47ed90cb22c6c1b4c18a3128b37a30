#!/usr/bin/env python3
"""Semantic Segmenter Service - Main Entry Point"""

import os
import logging
from fastapi import FastAPI
from fastapi.responses import JSONResponse
import uvicorn

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger(__name__)

app = FastAPI(title="Semantic Segmenter Service", version="1.0.0")

@app.get("/health")
async def health_check():
    return JSONResponse(status_code=200, content={
        "status": "healthy",
        "service": os.getenv("SERVICE_NAME", "semantic-segmenter"),
        "kafka_bootstrap": os.getenv("KAFKA_BOOTSTRAP_SERVERS", "not-configured"),
        "input_topic": os.getenv("KAFKA_INPUT_TOPIC", "not-configured"),
        "output_topic": os.getenv("KAFKA_OUTPUT_TOPIC", "not-configured"),
        "threshold": os.getenv("SEGMENTATION_THRESHOLD", "0.65")
    })

@app.get("/ready")
async def readiness_check():
    return JSONResponse(status_code=200, content={"status": "ready", "service": os.getenv("SERVICE_NAME", "semantic-segmenter")})

if __name__ == "__main__":
    logger.info("Starting Semantic Segmenter Service...")
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level=os.getenv("LOG_LEVEL", "info").lower())
