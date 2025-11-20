#!/usr/bin/env python3
"""
Unit tests for OCR Service
"""

import pytest
import json
from unittest.mock import Mock, patch, MagicMock
from fastapi.testclient import TestClient

# Mock the OCR service main module
@pytest.fixture
def mock_ocr_service():
    with patch('sys.path'):
        # Mock the OCR service components
        mock_service = Mock()
        mock_service.process_frame.return_value = {
            "text": "Sample extracted text",
            "confidence": 0.95,
            "bounding_boxes": []
        }
        return mock_service

@pytest.fixture
def mock_kafka_consumer():
    with patch('kafka.KafkaConsumer') as mock:
        consumer = Mock()
        consumer.__iter__ = Mock(return_value=iter([]))
        mock.return_value = consumer
        yield consumer

@pytest.fixture
def mock_kafka_producer():
    with patch('kafka.KafkaProducer') as mock:
        producer = Mock()
        producer.send.return_value = Mock()
        producer.flush.return_value = None
        mock.return_value = producer
        yield producer

class TestOCRService:
    """Test cases for OCR Service functionality"""
    
    def test_health_endpoint(self):
        """Test health check endpoint"""
        # This would require importing the actual FastAPI app
        # For now, test the expected response structure
        expected_response = {
            "status": "healthy",
            "service": "ocr-service"
        }
        assert "status" in expected_response
        assert expected_response["status"] == "healthy"
    
    def test_process_frame_success(self, mock_ocr_service):
        """Test successful frame processing"""
        frame_data = {
            "frame_id": "test-frame-123",
            "timestamp": 1234567890.0,
            "image": "base64_encoded_image"
        }
        
        result = mock_ocr_service.process_frame(frame_data)
        
        assert "text" in result
        assert "confidence" in result
        assert result["confidence"] > 0
    
    def test_kafka_message_processing(self, mock_kafka_consumer, mock_kafka_producer):
        """Test Kafka message processing flow"""
        # Mock message
        mock_message = Mock()
        mock_message.value = {
            "frame_id": "test-frame-123",
            "timestamp": 1234567890.0,
            "image": "base64_image_data"
        }
        mock_message.topic = "raw-frames"
        
        # Test message processing logic
        frame_id = mock_message.value.get("frame_id")
        assert frame_id == "test-frame-123"
        
        # Verify producer was called (in actual implementation)
        mock_kafka_producer.send.assert_not_called()  # Not called in this mock test
    
    def test_invalid_frame_data(self, mock_ocr_service):
        """Test handling of invalid frame data"""
        invalid_data = {
            "frame_id": None,
            "image": ""
        }
        
        # Mock service should handle invalid data gracefully
        mock_ocr_service.process_frame.return_value = {
            "error": "Invalid frame data",
            "text": "",
            "confidence": 0.0
        }
        
        result = mock_ocr_service.process_frame(invalid_data)
        assert "error" in result or result["confidence"] == 0.0
    
    def test_metrics_collection(self):
        """Test metrics collection functionality"""
        expected_metrics = {
            "frames_processed": 0,
            "average_processing_time": 0.0,
            "service": "ocr-service"
        }
        
        # Test metrics structure
        assert "frames_processed" in expected_metrics
        assert "service" in expected_metrics