#!/usr/bin/env python3
"""
Detector Service - Kafka Consumer/Producer Integration
Consumes raw frames and produces object detection results
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
KAFKA_OUTPUT_TOPIC = os.getenv('KAFKA_OUTPUT_TOPIC', 'detection-results')
KAFKA_CONSUMER_GROUP = os.getenv('KAFKA_CONSUMER_GROUP', 'detector-service-group')
SERVICE_NAME = os.getenv('SERVICE_NAME', 'detector-service')

# FastAPI app for health checks
app = FastAPI(title="Detector Service")

class DetectorService:
    def __init__(self):
        self.consumer = None
        self.producer = None
        self.running = False
        
    def connect_kafka(self):
        """Connect to Kafka consumer and producer"""
        try:
            self.consumer = KafkaConsumer(
                KAFKA_INPUT_TOPIC,
                bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
                group_id=KAFKA_CONSUMER_GROUP,
                value_deserializer=lambda x: json.loads(x.decode('utf-8')),
                auto_offset_reset='latest'
            )
            
            self.producer = KafkaProducer(
                bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
                value_serializer=lambda x: json.dumps(x).encode('utf-8')
            )
            
            logger.info(f"Connected to Kafka: {KAFKA_BOOTSTRAP_SERVERS}")
            return True
        except Exception as e:
            logger.error(f"Failed to connect to Kafka: {e}")
            return False
    
    def process_frame(self, frame_data):
        """Process frame and detect objects (mock implementation)"""
        try:
            # Decode base64 image
            image_data = base64.b64decode(frame_data['image'])
            nparr = np.frombuffer(image_data, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            # Mock object detection (replace with actual YOLO)
            mock_detections = [
                {
                    "class_id": 0,
                    "class_name": "person",
                    "confidence": 0.92,
                    "bbox": [100, 200, 300, 400],
                    "width": 200,
                    "height": 200
                },
                {
                    "class_id": 2,
                    "class_name": "car",
                    "confidence": 0.87,
                    "bbox": [400, 300, 600, 500],
                    "width": 200,
                    "height": 200
                }
            ]
            
            result = {
                "frame_id": frame_data.get('frame_id'),
                "service": SERVICE_NAME,
                "timestamp": datetime.now().timestamp(),
                "results": {
                    "detections": mock_detections,
                    "detection_count": len(mock_detections)
                },
                "processing_time_ms": 45.2
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
                    logger.info(f"Sent detection result for frame: {result['frame_id']}")
                
            except Exception as e:
                logger.error(f"Error processing message: {e}")
    
    def start(self):
        """Start the detector service"""
        if self.connect_kafka():
            self.running = True
            # Start consuming in a separate thread
            consumer_thread = threading.Thread(target=self.consume_messages)
            consumer_thread.daemon = True
            consumer_thread.start()
            logger.info("Detector Service started successfully")
        else:
            logger.error("Failed to start Detector Service")

# Global service instance
detector_service = DetectorService()

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return JSONResponse({
        "status": "healthy",
        "service": SERVICE_NAME,
        "kafka_connected": detector_service.consumer is not None,
        "timestamp": datetime.now().isoformat()
    })

@app.get("/ready")
async def readiness_check():
    """Readiness check endpoint"""
    ready = detector_service.consumer is not None and detector_service.producer is not None
    return JSONResponse({
        "ready": ready,
        "service": SERVICE_NAME
    })

if __name__ == "__main__":
    # Start detector service
    detector_service.start()
    
    # Start FastAPI server
    uvicorn.run(app, host="0.0.0.0", port=8000)