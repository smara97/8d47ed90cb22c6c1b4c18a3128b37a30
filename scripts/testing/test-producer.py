#!/usr/bin/env python3
"""
Test Producer - Send sample frames to Kafka for testing
"""

import json
import base64
import uuid
import time
import logging
from datetime import datetime
from kafka import KafkaProducer
from kafka.errors import KafkaError
import cv2
import numpy as np

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Kafka configuration
KAFKA_BOOTSTRAP_SERVERS = 'localhost:9092'
KAFKA_TOPIC = 'raw-frames'

def create_sample_image():
    """Create a sample image for testing"""
    # Create a simple test image
    img = np.zeros((480, 640, 3), dtype=np.uint8)
    
    # Add some colored rectangles
    cv2.rectangle(img, (50, 50), (200, 150), (0, 255, 0), -1)  # Green rectangle
    cv2.rectangle(img, (300, 200), (500, 350), (255, 0, 0), -1)  # Blue rectangle
    
    # Add some text
    cv2.putText(img, 'Test Frame', (250, 100), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
    
    # Encode image to base64
    _, buffer = cv2.imencode('.jpg', img)
    img_base64 = base64.b64encode(buffer).decode('utf-8')
    
    return img_base64

def send_test_frames(num_frames=5, interval=2):
    """Send test frames to Kafka"""
    try:
        # Create Kafka producer
        producer = KafkaProducer(
            bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
            value_serializer=lambda x: json.dumps(x).encode('utf-8')
        )
        
        logger.info(f"Connected to Kafka: {KAFKA_BOOTSTRAP_SERVERS}")
        logger.info(f"Sending {num_frames} test frames to topic: {KAFKA_TOPIC}")
        
        for i in range(num_frames):
            # Create frame data
            frame_data = {
                "frame_id": str(uuid.uuid4()),
                "timestamp": datetime.now().timestamp(),
                "sequence_number": i + 1,
                "video_id": "test-video-001",
                "image": create_sample_image(),
                "metadata": {
                    "width": 640,
                    "height": 480,
                    "format": "jpg",
                    "source": "test-producer"
                }
            }
            
            # Send to Kafka
            future = producer.send(KAFKA_TOPIC, frame_data)
            
            try:
                # Wait for send to complete
                record_metadata = future.get(timeout=10)
                logger.info(f"Sent frame {i+1}/{num_frames} - ID: {frame_data['frame_id']}")
                logger.info(f"  Topic: {record_metadata.topic}, Partition: {record_metadata.partition}, Offset: {record_metadata.offset}")
            except KafkaError as e:
                logger.error(f"Failed to send frame {i+1}: {e}")
            
            # Wait before sending next frame
            if i < num_frames - 1:
                time.sleep(interval)
        
        # Flush and close producer
        producer.flush()
        producer.close()
        
        logger.info("Test frames sent successfully!")
        
    except Exception as e:
        logger.error(f"Error sending test frames: {e}")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Send test frames to Kafka')
    parser.add_argument('--frames', type=int, default=5, help='Number of frames to send')
    parser.add_argument('--interval', type=int, default=2, help='Interval between frames (seconds)')
    
    args = parser.parse_args()
    
    send_test_frames(args.frames, args.interval)