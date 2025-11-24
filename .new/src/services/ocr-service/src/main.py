#!/usr/bin/env python3
"""
ocr service Service - Video RAG System

Processes video frames using tesseract method for ocr-service analysis
"""

import json
import logging
import time
from typing import Dict, Optional
from datetime import datetime

from kafka import KafkaConsumer, KafkaProducer
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
import uvicorn
import threading

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ocrserviceService:
    """Processes video frames using tesseract method for ocr-service analysis"""
    
    def __init__(self):
        self.kafka_servers = "kafka:9092"
        self.consumer_group = "ocr-service-group"
        self.input_topic = "raw-frames"
        self.output_topic = "ocr-results"
        self.service_name = "ocr-service"
        
        # Kafka clients
        self.consumer = None
        self.producer = None
        self.running = False
        
        # Processing metrics
        self.processed_count = 0
        self.error_count = 0
        self.start_time = datetime.now()
        
    def connect_kafka(self):
        """Connect to Kafka consumer and producer with retry logic"""
        max_retries = 5
        retry_delay = 2
        
        for attempt in range(max_retries):
            try:
                logger.info(f"Attempting Kafka connection (attempt {attempt + 1}/{max_retries})...")
                
                # Test connection first
                test_producer = KafkaProducer(
                    bootstrap_servers=self.kafka_servers,
                    value_serializer=lambda x: json.dumps(x).encode('utf-8'),
                    request_timeout_ms=5000,
                    api_version_auto_timeout_ms=5000
                )
                test_producer.close()
                
                # Create actual connections
                self.consumer = KafkaConsumer(
                    self.input_topic,
                    bootstrap_servers=self.kafka_servers,
                    group_id=self.consumer_group,
                    value_deserializer=lambda x: json.loads(x.decode('utf-8')),
                    auto_offset_reset='latest',
                    consumer_timeout_ms=1000
                )
                
                self.producer = KafkaProducer(
                    bootstrap_servers=self.kafka_servers,
                    value_serializer=lambda x: json.dumps(x).encode('utf-8')
                )
                
                logger.info(f"Successfully connected to Kafka: {self.kafka_servers}")
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
        """Process frame data - Override this method in specific services"""
        try:
            # Mock processing for template
            processing_start = time.time()
            
            # Simulate processing time
            time.sleep(0.1)
            
            processing_time = (time.time() - processing_start) * 1000
            
            result = {
                "frame_id": frame_data.get('frame_id'),
                "service": self.service_name,
                "timestamp": datetime.now().timestamp(),
                "results": {
                    "ocr-service_data": f"Processed by {self.service_name}",
                    "confidence": 0.95,
                    "processing_method": "tesseract"
                },
                "processing_time_ms": processing_time
            }
            
            return result
            
        except Exception as e:
            logger.error(f"Error processing frame: {e}")
            self.error_count += 1
            return None
    
    def consume_messages(self):
        """Consume messages from Kafka"""
        logger.info(f"Starting to consume from topic: {self.input_topic}")
        
        try:
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
                        self.producer.send(self.output_topic, result)
                        self.producer.flush()
                        self.processed_count += 1
                        logger.info(f"Sent {self.service_name} result for frame: {result['frame_id']}")
                    
                except Exception as e:
                    logger.error(f"Error processing message: {e}")
                    self.error_count += 1
                    
        except Exception as e:
            logger.error(f"Consumer error: {e}")
    
    def start(self):
        """Start the service"""
        if self.connect_kafka():
            self.running = True
            # Start consuming in a separate thread
            consumer_thread = threading.Thread(target=self.consume_messages)
            consumer_thread.daemon = True
            consumer_thread.start()
            logger.info(f"{self.service_name} Service started successfully")
        else:
            logger.error(f"Failed to start {self.service_name} Service")
    
    def stop(self):
        """Stop the service"""
        self.running = False
        if self.consumer:
            self.consumer.close()
        if self.producer:
            self.producer.close()
        logger.info(f"{self.service_name} Service stopped")
    
    def get_metrics(self):
        """Get service metrics"""
        uptime = (datetime.now() - self.start_time).total_seconds()
        return {
            "service": self.service_name,
            "processed_count": self.processed_count,
            "error_count": self.error_count,
            "uptime_seconds": uptime,
            "kafka_connected": self.consumer is not None and self.producer is not None,
            "input_topic": self.input_topic,
            "output_topic": self.output_topic,
            "timestamp": datetime.now().isoformat()
        }

# FastAPI app for health checks and monitoring
app = FastAPI(title="ocr service Service", version="1.0.0")

# Global service instance
service = ocrserviceService()

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return JSONResponse({
        "status": "healthy",
        "service": service.service_name,
        "kafka_connected": service.consumer is not None and service.producer is not None,
        "timestamp": datetime.now().isoformat()
    })

@app.get("/ready")
async def readiness_check():
    """Readiness check endpoint"""
    ready = service.consumer is not None and service.producer is not None
    return JSONResponse({
        "ready": ready,
        "service": service.service_name
    })

@app.get("/metrics")
async def get_metrics():
    """Service metrics endpoint"""
    return JSONResponse(service.get_metrics())

@app.post("/process")
async def process_frame_endpoint(frame_data: dict):
    """Direct processing endpoint for testing"""
    try:
        result = service.process_frame(frame_data)
        if result:
            return JSONResponse(result)
        else:
            raise HTTPException(status_code=500, detail="Processing failed")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    # Start service
    service.start()
    
    # Start FastAPI server
    uvicorn.run(app, host="0.0.0.0", port=8000)