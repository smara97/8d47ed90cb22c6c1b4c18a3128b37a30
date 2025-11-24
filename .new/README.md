# Video RAG Microservices

Enterprise-grade video processing pipeline with Kafka-based event streaming.

## Quick Start
```bash
make up          # Start everything
make status      # Check status
make test-integration  # Test Kafka integration
```

## Documentation
All documentation is located in [.docs/](.docs/):

- [Enterprise Features](.docs/ENTERPRISE_FEATURES.md)
- [Kafka Integration Testing](.docs/KAFKA_INTEGRATION_TESTING.md)
- [Makefile Usage](.docs/MAKEFILE_USAGE.md)

## Architecture
```
Video Frames → Kafka → [OCR, Detection, Captioning] → Results → Vector DB
```

## Access Points
- Kafka UI: http://kafka-ui.video-rag.orb.local
- MinIO Console: http://minio.video-rag.orb.local:9001
- Qdrant API: http://qdrant.video-rag.orb.local