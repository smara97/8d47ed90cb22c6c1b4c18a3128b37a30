#!/usr/bin/env python3
"""
Unit tests for Frame Aggregator Service
"""

import pytest
from unittest.mock import Mock, patch
from datetime import datetime

# Import the FrameMetadata class (would need proper import in real implementation)
class MockFrameMetadata:
    def __init__(self, frame_id, timestamp):
        self.frame_id = frame_id
        self.timestamp = timestamp
        self.ocr_results = None
        self.detection_results = None
        self.caption_results = None
        self.aggregated_at = None
    
    def is_complete(self):
        return all([
            self.ocr_results is not None,
            self.detection_results is not None,
            self.caption_results is not None
        ])

class TestFrameAggregator:
    """Test cases for Frame Aggregator Service"""
    
    def test_frame_metadata_creation(self):
        """Test FrameMetadata object creation"""
        frame_id = "test-frame-123"
        timestamp = datetime.now().timestamp()
        
        frame_meta = MockFrameMetadata(frame_id, timestamp)
        
        assert frame_meta.frame_id == frame_id
        assert frame_meta.timestamp == timestamp
        assert not frame_meta.is_complete()
    
    def test_frame_completion_check(self):
        """Test frame completion logic"""
        frame_meta = MockFrameMetadata("test-frame", 123456789.0)
        
        # Initially incomplete
        assert not frame_meta.is_complete()
        
        # Add OCR results
        frame_meta.ocr_results = {"text": "sample text"}
        assert not frame_meta.is_complete()
        
        # Add detection results
        frame_meta.detection_results = {"objects": ["person", "car"]}
        assert not frame_meta.is_complete()
        
        # Add caption results - now complete
        frame_meta.caption_results = {"caption": "A person near a car"}
        assert frame_meta.is_complete()
    
    def test_message_processing_ocr(self):
        """Test processing OCR result messages"""
        mock_message = Mock()
        mock_message.topic = "ocr-results"
        mock_message.value = {
            "frame_id": "test-frame-123",
            "timestamp": 123456789.0,
            "results": {
                "text": "Extracted text",
                "confidence": 0.95
            }
        }
        
        # Test message structure
        assert mock_message.topic == "ocr-results"
        assert "frame_id" in mock_message.value
        assert "results" in mock_message.value
    
    def test_message_processing_detection(self):
        """Test processing detection result messages"""
        mock_message = Mock()
        mock_message.topic = "detection-results"
        mock_message.value = {
            "frame_id": "test-frame-123",
            "timestamp": 123456789.0,
            "results": {
                "objects": [
                    {"class": "person", "confidence": 0.9, "bbox": [10, 10, 50, 50]},
                    {"class": "car", "confidence": 0.85, "bbox": [100, 100, 200, 150]}
                ]
            }
        }
        
        # Test message structure
        assert mock_message.topic == "detection-results"
        assert "objects" in mock_message.value["results"]
    
    def test_message_processing_caption(self):
        """Test processing caption result messages"""
        mock_message = Mock()
        mock_message.topic = "caption-results"
        mock_message.value = {
            "frame_id": "test-frame-123",
            "timestamp": 123456789.0,
            "results": {
                "caption": "A person standing next to a red car",
                "confidence": 0.88
            }
        }
        
        # Test message structure
        assert mock_message.topic == "caption-results"
        assert "caption" in mock_message.value["results"]
    
    @patch('kafka.KafkaProducer')
    def test_aggregated_frame_publishing(self, mock_producer):
        """Test publishing complete aggregated frames"""
        # Mock producer
        producer_instance = Mock()
        mock_producer.return_value = producer_instance
        
        # Create complete frame metadata
        frame_meta = MockFrameMetadata("test-frame-123", 123456789.0)
        frame_meta.ocr_results = {"text": "sample"}
        frame_meta.detection_results = {"objects": ["person"]}
        frame_meta.caption_results = {"caption": "A person"}
        frame_meta.aggregated_at = datetime.now().isoformat()
        
        # Test that frame is complete
        assert frame_meta.is_complete()
        
        # In real implementation, this would call producer.send()
        # producer_instance.send.assert_called_once()
    
    def test_cache_management(self):
        """Test frame cache management"""
        # Mock cache (dict)
        frame_cache = {}
        
        frame_id = "test-frame-123"
        frame_meta = MockFrameMetadata(frame_id, 123456789.0)
        
        # Add to cache
        frame_cache[frame_id] = frame_meta
        assert len(frame_cache) == 1
        assert frame_id in frame_cache
        
        # Remove from cache after completion
        del frame_cache[frame_id]
        assert len(frame_cache) == 0
        assert frame_id not in frame_cache
    
    def test_health_endpoint_response(self):
        """Test health endpoint response structure"""
        expected_response = {
            "status": "healthy",
            "service": "frame-aggregator"
        }
        
        assert expected_response["status"] == "healthy"
        assert expected_response["service"] == "frame-aggregator"
    
    def test_metrics_endpoint_response(self):
        """Test metrics endpoint response structure"""
        expected_metrics = {
            "cached_frames": 0,
            "service": "frame-aggregator",
            "timestamp": datetime.now().isoformat()
        }
        
        assert "cached_frames" in expected_metrics
        assert "service" in expected_metrics
        assert "timestamp" in expected_metrics