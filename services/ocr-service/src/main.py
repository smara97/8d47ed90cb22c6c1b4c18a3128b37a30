#!/usr/bin/env python3
"""
OCR Service - Kafka Consumer/Producer Integration
Consumes raw frames and produces OCR results
"""

import os
import json
import base64
import logging
from datetime import datetime
from kafka import KafkaConsumer, KafkaProducer
from kafka.errors import KafkaError
import cv2
import numpy as np
from fastapi import FastAPI
from fastapi.responses import JSONResponse
import uvicorn
import threading
import time

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Environment variables
KAFKA_BOOTSTRAP_SERVERS = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'kafka:9092')
KAFKA_INPUT_TOPIC = os.getenv('KAFKA_INPUT_TOPIC', 'raw-frames')
KAFKA_OUTPUT_TOPIC = os.getenv('KAFKA_OUTPUT_TOPIC', 'ocr-results')
KAFKA_CONSUMER_GROUP = os.getenv('KAFKA_CONSUMER_GROUP', 'ocr-service-group')
SERVICE_NAME = os.getenv('SERVICE_NAME', 'ocr-service')

# FastAPI app for health checks
app = FastAPI(title="OCR Service")

class OCRService:
    def __init__(self):
        self.consumer = None
        self.producer = None
        self.running = False
        
    def connect_kafka(self):
        """Connect to Kafka consumer and producer with retry logic"""
        max_retries = 5
        retry_delay = 2
        
        for attempt in range(max_retries):
            try:
                logger.info(f"Attempting Kafka connection (attempt {attempt + 1}/{max_retries})...")
                
                # Test connection first
                test_producer = KafkaProducer(
                    bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
                    value_serializer=lambda x: json.dumps(x).encode('utf-8'),
                    request_timeout_ms=5000,
                    api_version_auto_timeout_ms=5000
                )
                test_producer.close()
                
                # Create actual connections
                self.consumer = KafkaConsumer(
                    KAFKA_INPUT_TOPIC,
                    bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
                    group_id=KAFKA_CONSUMER_GROUP,
                    value_deserializer=lambda x: json.loads(x.decode('utf-8')),
                    auto_offset_reset='latest',
                    consumer_timeout_ms=1000
                )
                
                self.producer = KafkaProducer(
                    bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
                    value_serializer=lambda x: json.dumps(x).encode('utf-8')
                )
                
                logger.info(f"Successfully connected to Kafka: {KAFKA_BOOTSTRAP_SERVERS}")
                return True
                
            except Exception as e:
                logger.warning(f"Kafka connection attempt {attempt + 1} failed: {e}")
                if attempt < max_retries - 1:
                    logger.info(f"Retrying in {retry_delay} seconds...")
                    time.sleep(retry_delay)
                    retry_delay *= 2  # Exponential backoff
                else:
                    logger.error(f"Failed to connect to Kafka after {max_retries} attempts")
        
        return False
    
    def process_frame(self, frame_data):
        """Process frame and extract text (mock implementation)"""
        try:
            # Decode base64 image
            image_data = base64.b64decode(frame_data['image'])
            nparr = np.frombuffer(image_data, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            # Mock OCR processing (replace with actual EasyOCR)
            mock_text = f"Sample text detected in frame {frame_data.get('frame_id', 'unknown')}"
            
            result = {
                "frame_id": frame_data.get('frame_id'),
                "service": SERVICE_NAME,
                "timestamp": datetime.now().timestamp(),
                "results": {
                    "text": mock_text,
                    "confidence": 0.95,
                    "word_count": len(mock_text.split()),
                    "bounding_boxes": [[100, 100, 200, 150]]
                },
                "processing_time_ms": 50.0
            }
            
            return result
            
        except Exception as e:
            logger.error(f"Error processing frame: {e}")
            return None
    
    def consume_messages(self):
        """Consume messages from Kafka"""
        logger.info(f"Starting to consume from topic: {KAFKA_INPUT_TOPIC}")
        
        for message in self.consumer:
            if not self.running:
                break
                
            try:
                frame_data = message.value
                logger.info(f"Received frame: {frame_data.get('frame_id', 'unknown')}")
                
                # Process the frame
                result = self.process_frame(frame_data)
                
                if result:
                    # Send result to output topic
                    self.producer.send(KAFKA_OUTPUT_TOPIC, result)
                    logger.info(f"Sent OCR result for frame: {result['frame_id']}")
                
            except Exception as e:
                logger.error(f"Error processing message: {e}")
    
    def start(self):
        """Start the OCR service"""
        if self.connect_kafka():
            self.running = True
            # Start consuming in a separate thread
            consumer_thread = threading.Thread(target=self.consume_messages)
            consumer_thread.daemon = True
            consumer_thread.start()
            logger.info("OCR Service started successfully")
        else:
            logger.error("Failed to start OCR Service")

# Global service instance
ocr_service = OCRService()

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return JSONResponse({
        "status": "healthy",
        "service": SERVICE_NAME,
        "kafka_connected": ocr_service.consumer is not None,
        "timestamp": datetime.now().isoformat()
    })

@app.get("/ready")
async def readiness_check():
    """Readiness check endpoint"""
    ready = ocr_service.consumer is not None and ocr_service.producer is not None
    return JSONResponse({
        "ready": ready,
        "service": SERVICE_NAME
    })

if __name__ == "__main__":
    # Start OCR service
    ocr_service.start()
    
    # Start FastAPI server
    uvicorn.run(app, host="0.0.0.0", port=8000)