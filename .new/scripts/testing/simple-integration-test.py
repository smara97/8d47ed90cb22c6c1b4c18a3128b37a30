#!/usr/bin/env python3
"""
Simple integration test for Video RAG system
"""

import json
import time
import uuid
import sys
import requests

def test_service_health():
    """Test all service health endpoints"""
    services = {
        'OCR': 'http://localhost:8001/health',
        'Detector': 'http://localhost:8002/health', 
        'Captioner': 'http://localhost:8003/health',
        'Aggregator': 'http://localhost:8004/health'
    }
    
    print("🔍 Testing service health endpoints...")
    all_healthy = True
    
    for name, url in services.items():
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                data = response.json()
                status = data.get('status', 'unknown')
                print(f"✅ {name} Service: {status}")
            else:
                print(f"❌ {name} Service: HTTP {response.status_code}")
                all_healthy = False
        except Exception as e:
            print(f"❌ {name} Service: {str(e)}")
            all_healthy = False
    
    return all_healthy

def test_kafka_topics():
    """Test Kafka topic creation"""
    print("\n🔍 Testing Kafka topics...")
    try:
        # This would require kafka-python, so we'll use docker exec instead
        import subprocess
        result = subprocess.run([
            'docker', 'exec', 'kafka', 
            'kafka-topics', '--bootstrap-server', 'localhost:9092', '--list'
        ], capture_output=True, text=True, timeout=10)
        
        if result.returncode == 0:
            topics = result.stdout.strip().split('\n')
            expected_topics = ['raw-frames', 'ocr-results', 'detection-results', 'caption-results']
            
            for topic in expected_topics:
                if topic in topics:
                    print(f"✅ Topic exists: {topic}")
                else:
                    print(f"❌ Topic missing: {topic}")
                    return False
            return True
        else:
            print(f"❌ Failed to list topics: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Kafka test failed: {str(e)}")
        return False

def test_infrastructure():
    """Test infrastructure services"""
    print("\n🔍 Testing infrastructure services...")
    
    # Test Qdrant
    try:
        response = requests.get('http://localhost:6333/healthz', timeout=5)
        if response.status_code == 200:
            print("✅ Qdrant: healthy")
        else:
            print(f"❌ Qdrant: HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Qdrant: {str(e)}")
        return False
    
    # Test MinIO
    try:
        response = requests.get('http://localhost:9000/minio/health/live', timeout=5)
        if response.status_code == 200:
            print("✅ MinIO: healthy")
        else:
            print(f"❌ MinIO: HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ MinIO: {str(e)}")
        return False
    
    return True

def main():
    """Run all tests"""
    print("🚀 Starting Video RAG System Integration Test\n")
    
    tests = [
        ("Service Health", test_service_health),
        ("Infrastructure", test_infrastructure), 
        ("Kafka Topics", test_kafka_topics)
    ]
    
    results = []
    for test_name, test_func in tests:
        print(f"\n{'='*50}")
        print(f"Running {test_name} Test")
        print('='*50)
        
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} test failed with exception: {str(e)}")
            results.append((test_name, False))
    
    # Summary
    print(f"\n{'='*50}")
    print("TEST SUMMARY")
    print('='*50)
    
    passed = 0
    for test_name, result in results:
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"{test_name}: {status}")
        if result:
            passed += 1
    
    print(f"\nOverall: {passed}/{len(results)} tests passed")
    
    if passed == len(results):
        print("🎉 All tests passed! System is ready.")
        return 0
    else:
        print("⚠️  Some tests failed. Check the output above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())