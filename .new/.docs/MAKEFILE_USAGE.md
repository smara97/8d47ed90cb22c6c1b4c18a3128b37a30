# Video RAG Makefile - Quick Reference

## Quick Start Commands

```bash
# Start everything
make up

# Check system health
make health

# View logs
make logs

# Stop everything
make down

# Clean up (remove all data)
make clean
```

## Infrastructure Management

```bash
make infra-up          # Start Kafka, Qdrant, MinIO
make infra-down        # Stop infrastructure
make infra-health      # Check infrastructure health
make infra-logs        # View infrastructure logs
```

## Service Management

```bash
make services-build    # Build all service images
make services-up       # Start all microservices
make services-down     # Stop all microservices
make services-logs     # View all service logs
```

## Individual Service Operations

```bash
# Build specific service
make build-service SERVICE=ocr-service

# Start specific service
make start-service SERVICE=detector-service

# Stop specific service
make stop-service SERVICE=captioner-service

# View specific service logs
make service-logs SERVICE=ocr-service

# Open shell in service container
make shell-service SERVICE=detector-service
```

## Testing and Monitoring

```bash
make health            # Check all services health
make status            # Show container status
make test-all          # Test infrastructure connectivity
make test-kafka        # Test Kafka only
make test-qdrant       # Test Qdrant only
make test-minio        # Test MinIO only
```

## System Information

```bash
make help              # Show all available commands
make info              # Show system information
make check-requirements # Verify Docker requirements
```

## Available Services

- `ocr-service` - Text extraction (port 8001)
- `detector-service` - Object detection (port 8002)  
- `captioner-service` - Image captioning (port 8003)

## Access Points (OrbStack Domains)

- Kafka UI: http://kafka-ui.video-rag.local
- MinIO Console: http://minio-console.video-rag.local (minioadmin/minioadmin)
- MinIO API: http://minio.video-rag.local:9000
- Qdrant API: http://qdrant.video-rag.local
- Kafka Broker: kafka.video-rag.local:9093
- Service Health: http://localhost:800X/health (X = service port)

## Requirements

- Docker 20.10+
- Docker Compose 2.0+
- NVIDIA Docker runtime (for GPU services)
- 16GB+ RAM recommended