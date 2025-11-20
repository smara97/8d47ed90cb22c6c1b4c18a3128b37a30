#!/usr/bin/env python3
"""
Test Consumer - Monitor Kafka topics for testing
"""

import json
import logging
from datetime import datetime
from kafka import KafkaConsumer
from kafka.errors import KafkaError

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Kafka configuration
KAFKA_BOOTSTRAP_SERVERS = 'localhost:9092'

def monitor_topic(topic_name, group_id=None):
    """Monitor a specific Kafka topic"""
    try:
        if not group_id:
            group_id = f"test-consumer-{topic_name}"
            
        consumer = KafkaConsumer(
            topic_name,
            bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
            group_id=group_id,
            value_deserializer=lambda x: json.loads(x.decode('utf-8')),
            auto_offset_reset='latest'
        )
        
        logger.info(f"Monitoring topic: {topic_name}")
        logger.info("Press Ctrl+C to stop...")
        
        for message in consumer:
            try:
                data = message.value
                timestamp = datetime.fromtimestamp(data.get('timestamp', 0)).strftime('%H:%M:%S')
                
                print(f"\n{'='*60}")
                print(f"Topic: {topic_name}")
                print(f"Partition: {message.partition}, Offset: {message.offset}")
                print(f"Timestamp: {timestamp}")
                print(f"Frame ID: {data.get('frame_id', 'N/A')}")
                print(f"Service: {data.get('service', 'N/A')}")
                
                if 'results' in data:
                    results = data['results']
                    
                    # OCR results
                    if 'text' in results:
                        print(f"OCR Text: {results['text']}")
                        print(f"Confidence: {results.get('confidence', 'N/A')}")
                    
                    # Detection results
                    elif 'detections' in results:
                        detections = results['detections']
                        print(f"Detections: {len(detections)} objects")
                        for i, det in enumerate(detections[:3]):  # Show first 3
                            print(f"  {i+1}. {det.get('class_name', 'unknown')} ({det.get('confidence', 0):.2f})")
                    
                    # Caption results
                    elif 'caption' in results:
                        print(f"Caption: {results['caption']}")
                        print(f"Confidence: {results.get('confidence', 'N/A')}")
                
                processing_time = data.get('processing_time_ms', 'N/A')
                print(f"Processing Time: {processing_time}ms")
                
            except Exception as e:
                logger.error(f"Error processing message: {e}")
                
    except KeyboardInterrupt:
        logger.info("Stopping consumer...")
    except Exception as e:
        logger.error(f"Error monitoring topic {topic_name}: {e}")

def monitor_all_topics():
    """Monitor all result topics simultaneously"""
    import threading
    
    topics = [
        'ocr-results',
        'detection-results', 
        'caption-results'
    ]
    
    threads = []
    
    for topic in topics:
        thread = threading.Thread(
            target=monitor_topic, 
            args=(topic, f"monitor-{topic}")
        )
        thread.daemon = True
        thread.start()
        threads.append(thread)
    
    try:
        # Keep main thread alive
        while True:
            for thread in threads:
                thread.join(timeout=1)
    except KeyboardInterrupt:
        logger.info("Stopping all consumers...")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Monitor Kafka topics')
    parser.add_argument('--topic', type=str, help='Specific topic to monitor')
    parser.add_argument('--all', action='store_true', help='Monitor all result topics')
    
    args = parser.parse_args()
    
    if args.all:
        monitor_all_topics()
    elif args.topic:
        monitor_topic(args.topic)
    else:
        print("Usage: python test-consumer.py --topic <topic_name> or --all")
        print("Available topics: raw-frames, ocr-results, detection-results, caption-results")