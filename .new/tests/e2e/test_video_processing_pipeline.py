#!/usr/bin/env python3
"""
End-to-End tests for complete video processing pipeline
"""

import json
import time
import uuid
import pytest
import requests
from kafka import KafkaProducer, KafkaConsumer
from kafka.errors import KafkaError

KAFKA_BOOTSTRAP_SERVERS = 'localhost:9092'
SERVICE_ENDPOINTS = {
    'ocr': 'http://localhost:8001',
    'detector': 'http://localhost:8002',
    'captioner': 'http://localhost:8003',
    'aggregator': 'http://localhost:8004'
}

class TestVideoProcessingPipeline:
    """End-to-end tests for complete video processing workflow"""
    
    @pytest.fixture(autouse=True)
    def setup_method(self):
        """Setup test fixtures"""
        self.producer = KafkaProducer(
            bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
            value_serializer=lambda x: json.dumps(x).encode('utf-8')
        )
        yield
        if hasattr(self, 'producer'):
            self.producer.close()
    
    def test_all_services_healthy(self):
        """Test that all services are running and healthy"""
        for service_name, endpoint in SERVICE_ENDPOINTS.items():
            try:
                response = requests.get(f"{endpoint}/health", timeout=5)
                assert response.status_code == 200
                
                health_data = response.json()
                assert health_data["status"] == "healthy"
                print(f"✓ {service_name} service is healthy")
                
            except requests.RequestException as e:
                pytest.fail(f"Service {service_name} at {endpoint} is not accessible: {e}")
    
    def test_complete_frame_processing_flow(self):
        """Test complete flow from raw frame to aggregated results"""
        frame_id = str(uuid.uuid4())
        
        # Step 1: Send raw frame data
        frame_data = {
            "frame_id": frame_id,
            "timestamp": time.time(),
            "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==",  # 1x1 pixel PNG
            "video_id": "test-video-123",
            "frame_number": 1
        }
        
        print(f"Sending frame {frame_id} to raw-frames topic...")
        future = self.producer.send('raw-frames', frame_data)
        record_metadata = future.get(timeout=10)
        
        assert record_metadata.topic == 'raw-frames'
        print(f"✓ Frame sent to Kafka successfully")
        
        # Step 2: Wait for processing
        print("Waiting for services to process frame...")
        time.sleep(10)  # Allow time for all services to process
        
        # Step 3: Check individual service results
        service_topics = ['ocr-results', 'detection-results', 'caption-results']
        service_results = {}
        
        for topic in service_topics:
            print(f"Checking {topic}...")
            consumer = KafkaConsumer(
                topic,
                bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
                value_deserializer=lambda x: json.loads(x.decode('utf-8')),
                auto_offset_reset='earliest',
                consumer_timeout_ms=5000
            )
            
            messages = []
            for message in consumer:
                if message.value.get('frame_id') == frame_id:
                    messages.append(message.value)
                    break
            
            consumer.close()
            
            assert len(messages) > 0, f"No results found in {topic} for frame {frame_id}"
            
            result = messages[0]
            assert result['frame_id'] == frame_id
            assert 'results' in result
            
            service_results[topic] = result
            print(f"✓ Found result in {topic}")
        
        # Step 4: Check aggregated results
        print("Checking aggregated results...")
        aggregated_consumer = KafkaConsumer(
            'aggregated-frame-metadata',
            bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
            value_deserializer=lambda x: json.loads(x.decode('utf-8')),
            auto_offset_reset='earliest',
            consumer_timeout_ms=10000
        )
        
        aggregated_result = None
        for message in aggregated_consumer:
            if message.value.get('frame_id') == frame_id:
                aggregated_result = message.value
                break
        
        aggregated_consumer.close()
        
        assert aggregated_result is not None, f"No aggregated result found for frame {frame_id}"
        
        # Verify aggregated result structure
        assert aggregated_result['frame_id'] == frame_id
        assert 'ocr_results' in aggregated_result
        assert 'detection_results' in aggregated_result
        assert 'caption_results' in aggregated_result
        assert 'aggregated_at' in aggregated_result
        
        print(f"✓ Complete pipeline test successful for frame {frame_id}")
    
    def test_multiple_frames_processing(self):
        """Test processing multiple frames concurrently"""
        frame_count = 3
        frame_ids = []
        
        # Send multiple frames
        for i in range(frame_count):
            frame_id = str(uuid.uuid4())
            frame_ids.append(frame_id)
            
            frame_data = {
                "frame_id": frame_id,
                "timestamp": time.time(),
                "image": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==",
                "video_id": "test-video-multi",
                "frame_number": i + 1
            }
            
            self.producer.send('raw-frames', frame_data)
        
        self.producer.flush()
        print(f"Sent {frame_count} frames for processing")
        
        # Wait for processing
        time.sleep(15)
        
        # Check that all frames were aggregated
        aggregated_consumer = KafkaConsumer(
            'aggregated-frame-metadata',
            bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
            value_deserializer=lambda x: json.loads(x.decode('utf-8')),
            auto_offset_reset='earliest',
            consumer_timeout_ms=10000
        )
        
        found_frames = set()
        for message in aggregated_consumer:
            frame_id = message.value.get('frame_id')
            if frame_id in frame_ids:
                found_frames.add(frame_id)
                if len(found_frames) == frame_count:
                    break
        
        aggregated_consumer.close()
        
        assert len(found_frames) == frame_count, f"Expected {frame_count} aggregated frames, found {len(found_frames)}"
        print(f"✓ Successfully processed {frame_count} frames concurrently")
    
    def test_service_metrics_collection(self):
        """Test that all services are collecting metrics"""
        for service_name, endpoint in SERVICE_ENDPOINTS.items():
            try:
                response = requests.get(f"{endpoint}/metrics", timeout=5)
                assert response.status_code == 200
                
                metrics = response.json()
                assert "service" in metrics
                print(f"✓ {service_name} metrics: {metrics}")
                
            except requests.RequestException as e:
                print(f"Warning: Could not get metrics from {service_name}: {e}")
    
    def test_error_handling_invalid_frame(self):
        """Test system behavior with invalid frame data"""
        invalid_frame = {
            "frame_id": "invalid-frame",
            "timestamp": time.time(),
            "image": "invalid_base64_data",
            "video_id": "test-error-handling"
        }
        
        # Send invalid frame
        self.producer.send('raw-frames', invalid_frame)
        self.producer.flush()
        
        # Wait briefly
        time.sleep(5)
        
        # System should handle gracefully without crashing
        # Check that services are still healthy
        for service_name, endpoint in SERVICE_ENDPOINTS.items():
            response = requests.get(f"{endpoint}/health", timeout=5)
            assert response.status_code == 200
        
        print("✓ System handles invalid frames gracefully")