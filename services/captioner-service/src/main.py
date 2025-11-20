#!/usr/bin/env python3
"""
Captioner Service - Kafka Consumer/Producer Integration
Consumes raw frames and produces image captions
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
KAFKA_OUTPUT_TOPIC = os.getenv('KAFKA_OUTPUT_TOPIC', 'caption-results')
KAFKA_CONSUMER_GROUP = os.getenv('KAFKA_CONSUMER_GROUP', 'captioner-service-group')
SERVICE_NAME = os.getenv('SERVICE_NAME', 'captioner-service')

# FastAPI app for health checks
app = FastAPI(title="Captioner Service")

class CaptionerService:
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
        """Process frame and generate caption (mock implementation)"""
        try:
            # Decode base64 image
            image_data = base64.b64decode(frame_data['image'])
            nparr = np.frombuffer(image_data, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            # Mock image captioning (replace with actual BLIP)
            mock_captions = [
                "a person walking with a dog in a park",
                "a car driving on a busy street",
                "people sitting at a table in a restaurant",
                "a cat sleeping on a couch",
                "children playing in a playground"
            ]
            
            # Select caption based on frame_id for consistency
            frame_id = frame_data.get('frame_id', 'unknown')
            caption_index = hash(frame_id) % len(mock_captions)
            mock_caption = mock_captions[caption_index]
            
            result = {
                "frame_id": frame_data.get('frame_id'),
                "service": SERVICE_NAME,
                "timestamp": datetime.now().timestamp(),
                "results": {
                    "caption": mock_caption,
                    "confidence": 0.89,
                    "word_count": len(mock_caption.split()),
                    "generation_params": {
                        "max_length": 50,
                        "temperature": 0.7
                    }
                },
                "processing_time_ms": 125.7
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
                    logger.info(f"Sent caption result for frame: {result['frame_id']}")
                
            except Exception as e:
                logger.error(f"Error processing message: {e}")
    
    def start(self):
        """Start the captioner service"""
        if self.connect_kafka():
            self.running = True
            # Start consuming in a separate thread
            consumer_thread = threading.Thread(target=self.consume_messages)
            consumer_thread.daemon = True
            consumer_thread.start()
            logger.info("Captioner Service started successfully")
        else:
            logger.error("Failed to start Captioner Service")

# Global service instance
captioner_service = CaptionerService()

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return JSONResponse({
        "status": "healthy",
        "service": SERVICE_NAME,
        "kafka_connected": captioner_service.consumer is not None,
        "timestamp": datetime.now().isoformat()
    })

@app.get("/ready")
async def readiness_check():
    """Readiness check endpoint"""
    ready = captioner_service.consumer is not None and captioner_service.producer is not None
    return JSONResponse({
        "ready": ready,
        "service": SERVICE_NAME
    })

if __name__ == "__main__":
    # Start captioner service
    captioner_service.start()
    
    # Start FastAPI server
    uvicorn.run(app, host="0.0.0.0", port=8000)