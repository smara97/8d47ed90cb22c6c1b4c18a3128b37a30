#!/usr/bin/env python3
"""
Integration tests for Kafka message flow
"""

import json
import time
import uuid
import pytest
from kafka import KafkaProducer, KafkaConsumer
from kafka.errors import KafkaError

KAFKA_BOOTSTRAP_SERVERS = 'localhost:9092'

class TestKafkaFlow:
    
    def setup_method(self):
        """Setup test fixtures"""
        self.producer = KafkaProducer(
            bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
            value_serializer=lambda x: json.dumps(x).encode('utf-8')
        )
    
    def teardown_method(self):
        """Cleanup after tests"""
        if hasattr(self, 'producer'):
            self.producer.close()
    
    def test_raw_frames_topic_exists(self):
        """Test that raw-frames topic can receive messages"""
        frame_data = {
            "frame_id": str(uuid.uuid4()),
            "timestamp": time.time(),
            "image": "base64_encoded_image_data"
        }
        
        future = self.producer.send('raw-frames', frame_data)
        record_metadata = future.get(timeout=10)
        
        assert record_metadata.topic == 'raw-frames'
        assert record_metadata.partition >= 0
    
    def test_service_results_flow(self):
        """Test that services produce results after consuming frames"""
        # Send test frame
        frame_id = str(uuid.uuid4())
        frame_data = {
            "frame_id": frame_id,
            "timestamp": time.time(),
            "image": "test_image_data"
        }
        
        self.producer.send('raw-frames', frame_data)
        self.producer.flush()
        
        # Wait for processing
        time.sleep(5)
        
        # Check for results in output topics
        result_topics = ['ocr-results', 'detection-results', 'caption-results']
        
        for topic in result_topics:
            consumer = KafkaConsumer(
                topic,
                bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
                value_deserializer=lambda x: json.loads(x.decode('utf-8')),
                auto_offset_reset='earliest',
                consumer_timeout_ms=5000
            )
            
            messages = list(consumer)
            consumer.close()
            
            # Should have at least one message
            assert len(messages) > 0, f"No messages found in {topic}"
            
            # Check message structure
            latest_message = messages[-1].value
            assert 'frame_id' in latest_message
            assert 'service' in latest_message
            assert 'results' in latest_message