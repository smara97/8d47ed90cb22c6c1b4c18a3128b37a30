# Kafka Integration Testing Guide

## Overview

This guide explains how to test the Kafka integration between all microservices in the Video RAG system.

## Architecture Flow

```
Test Producer → raw-frames → [OCR, Detector, Captioner] → [ocr-results, detection-results, caption-results]
```

## Prerequisites

1. Infrastructure services running: `make infra-up`
2. All microservices built and running: `make services-up`
3. Python 3.11+ with kafka-python installed

## Testing Steps

### 1. Start All Services

```bash
# Start everything
make up

# Check status
make status
```

### 2. Monitor Topics (Terminal 1)

```bash
# Monitor all result topics
make monitor-topics

# Or monitor specific topic
make monitor-topic TOPIC=ocr-results
```

### 3. Send Test Frames (Terminal 2)

```bash
# Send 5 test frames with 2-second intervals
make test-integration

# Or use the script directly
python3 scripts/test-producer.py --frames 5 --interval 2
```

### 4. Verify Results

You should see output in the monitoring terminal showing:

**OCR Results:**

```
Topic: ocr-results
Frame ID: abc-123-def
Service: ocr-service
OCR Text: Sample text detected in frame abc-123-def
Confidence: 0.95
Processing Time: 50.0ms
```

**Detection Results:**

```
Topic: detection-results
Frame ID: abc-123-def
Service: detector-service
Detections: 2 objects
  1. person (0.92)
  2. car (0.87)
Processing Time: 45.2ms
```

**Caption Results:**

```
Topic: caption-results
Frame ID: abc-123-def
Service: captioner-service
Caption: a person walking with a dog in a park
Confidence: 0.89
Processing Time: 125.7ms
```

## Available Commands

### Infrastructure

- `make infra-up` - Start Kafka, Zookeeper, MinIO, Qdrant
- `make infra-down` - Stop infrastructure
- `make status` - Check container status

### Services

- `make services-up` - Build and start all microservices
- `make services-down` - Stop all microservices
- `make service-logs SERVICE=ocr-service` - View specific service logs

### Testing

- `make test-integration` - Send test frames
- `make monitor-topics` - Monitor all result topics
- `make monitor-topic TOPIC=<topic>` - Monitor specific topic
- `make test-kafka` - Test Kafka connectivity

### Health Checks

- `curl http://localhost:8001/health` - OCR service health
- `curl http://localhost:8002/health` - Detector service health
- `curl http://localhost:8003/health` - Captioner service health

## Kafka Topics

| Topic             | Purpose                  | Producer          | Consumer     |
| ----------------- | ------------------------ | ----------------- | ------------ |
| raw-frames        | Input video frames       | Test Producer     | All Services |
| ocr-results       | Text extraction results  | OCR Service       | Aggregator   |
| detection-results | Object detection results | Detector Service  | Aggregator   |
| caption-results   | Image captions           | Captioner Service | Aggregator   |

## Troubleshooting

### Services Not Consuming

1. Check Kafka connectivity: `make test-kafka`
2. Verify topics exist in Kafka UI: http://kafka-ui.video-rag.orb.local
3. Check service logs: `make service-logs SERVICE=ocr-service`

### No Results Produced

1. Check service health endpoints
2. Verify environment variables in docker-compose files
3. Check for errors in service logs

### Kafka Connection Issues

1. Ensure infrastructure is running: `make status`
2. Check Kafka health: `docker logs kafka`
3. Verify network connectivity between containers

## Performance Testing

### Load Testing

```bash
# Send 100 frames rapidly
python3 scripts/test-producer.py --frames 100 --interval 0.1
```

### Latency Testing

Monitor processing times in the consumer output to verify:

- OCR: ~50ms
- Detection: ~45ms
- Captioning: ~125ms

## Next Steps

1. **Add Real ML Models**: Uncomment dependencies in requirements.txt
2. **Implement Aggregator**: Service to combine all results
3. **Add Monitoring**: Prometheus metrics for throughput/latency
4. **Scale Testing**: Multiple consumer instances per service

## Access Points

- **Kafka UI**: http://kafka-ui.video-rag.orb.local
- **MinIO Console**: http://minio.video-rag.orb.local:9001
- **Qdrant API**: http://qdrant.video-rag.orb.local
- **OCR Service**: http://localhost:8001/health
- **Detector Service**: http://localhost:8002/health
- **Captioner Service**: http://localhost:8003/health
