#!/usr/bin/env python3
"""
Frame Aggregator Service - Video RAG System

Aggregates results from OCR, detection, and captioning services
into unified frame metadata for downstream processing.
"""

import json
import logging
import asyncio
from typing import Dict, List, Optional
from dataclasses import dataclass, asdict
from datetime import datetime

from kafka import KafkaConsumer, KafkaProducer
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
import uvicorn

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@dataclass
class FrameMetadata:
    """Aggregated frame metadata structure"""
    frame_id: str
    timestamp: float
    ocr_results: Optional[Dict] = None
    detection_results: Optional[Dict] = None
    caption_results: Optional[Dict] = None
    aggregated_at: Optional[str] = None
    
    def is_complete(self) -> bool:
        """Check if all required results are present"""
        return all([
            self.ocr_results is not None,
            self.detection_results is not None,
            self.caption_results is not None
        ])

class FrameAggregator:
    """Aggregates frame processing results from multiple services"""
    
    def __init__(self):
        self.kafka_servers = "kafka:9092"
        self.consumer_group = "frame-aggregator-group"
        self.input_topics = ["ocr-results", "detection-results", "caption-results"]
        self.output_topic = "aggregated-frame-metadata"
        
        # In-memory storage for partial results
        self.frame_cache: Dict[str, FrameMetadata] = {}
        
        # Kafka clients
        self.consumer = None
        self.producer = None
        
    def setup_kafka(self):
        """Initialize Kafka consumer and producer with retry logic"""
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
                    *self.input_topics,
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
                return
                
            except Exception as e:
                logger.warning(f"Kafka connection attempt {attempt + 1} failed: {e}")
                if attempt < max_retries - 1:
                    logger.info(f"Retrying in {retry_delay} seconds...")
                    time.sleep(retry_delay)
                    retry_delay *= 2
                else:
                    logger.error(f"Failed to connect to Kafka after {max_retries} attempts")
                    raise Exception("Could not establish Kafka connection")
    
    def process_message(self, message):
        """Process incoming service result message"""
        try:
            data = message.value
            topic = message.topic
            frame_id = data.get('frame_id')
            
            if not frame_id:
                logger.warning(f"Message missing frame_id: {data}")
                return
            
            # Get or create frame metadata
            if frame_id not in self.frame_cache:
                self.frame_cache[frame_id] = FrameMetadata(
                    frame_id=frame_id,
                    timestamp=data.get('timestamp', datetime.now().timestamp())
                )
            
            frame_meta = self.frame_cache[frame_id]
            
            # Update appropriate result based on topic
            if topic == "ocr-results":
                frame_meta.ocr_results = data.get('results', {})
            elif topic == "detection-results":
                frame_meta.detection_results = data.get('results', {})
            elif topic == "caption-results":
                frame_meta.caption_results = data.get('results', {})
            
            # Check if frame is complete and publish
            if frame_meta.is_complete():
                self.publish_aggregated_frame(frame_meta)
                del self.frame_cache[frame_id]
                
        except Exception as e:
            logger.error(f"Error processing message: {e}")
    
    def publish_aggregated_frame(self, frame_meta: FrameMetadata):
        """Publish complete frame metadata to output topic"""
        frame_meta.aggregated_at = datetime.now().isoformat()
        
        aggregated_data = asdict(frame_meta)
        
        self.producer.send(self.output_topic, aggregated_data)
        self.producer.flush()
        
        logger.info(f"Published aggregated frame: {frame_meta.frame_id}")
    
    async def run(self):
        """Main processing loop"""
        self.setup_kafka()
        
        logger.info("Frame Aggregator started, waiting for messages...")
        
        try:
            for message in self.consumer:
                self.process_message(message)
        except KeyboardInterrupt:
            logger.info("Shutting down Frame Aggregator...")
        finally:
            if self.consumer:
                self.consumer.close()
            if self.producer:
                self.producer.close()

# FastAPI app for health checks and monitoring
app = FastAPI(title="Frame Aggregator Service", version="1.0.0")

aggregator = FrameAggregator()

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "frame-aggregator"}

@app.get("/metrics")
async def get_metrics():
    """Service metrics endpoint"""
    return {
        "cached_frames": len(aggregator.frame_cache),
        "service": "frame-aggregator",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/cache")
async def get_cache_status():
    """Get current cache status"""
    return {
        "frame_count": len(aggregator.frame_cache),
        "frame_ids": list(aggregator.frame_cache.keys())
    }

if __name__ == "__main__":
    import threading
    
    # Start Kafka processing in background thread
    def start_aggregator():
        asyncio.run(aggregator.run())
    
    kafka_thread = threading.Thread(target=start_aggregator, daemon=True)
    kafka_thread.start()
    
    # Start FastAPI server
    uvicorn.run(app, host="0.0.0.0", port=8000)