# Docker Standards Rules

## Container Security

- All containers must run as non-root users
- Use `no-new-privileges:true` security option
- Remove package managers from runtime images
- Implement multi-stage builds for minimal attack surface

## Resource Management

- Define memory and CPU limits for all services
- Set resource reservations for guaranteed performance
- Configure appropriate restart policies
- Use health checks with optimized intervals

## Production Readiness

- Implement structured JSON logging with rotation
- Configure proper environment variable validation
- Use external volumes for data persistence
- Apply service-specific resource tuning

## Image Optimization

- Minimize layer count and image size
- Use appropriate base images for each service
- Cache dependencies effectively in build stages
- Clean up package caches and temporary files

## Monitoring Integration

- Include service labels for log aggregation
- Configure health check endpoints
- Implement readiness and liveness probes
- Support metrics collection and observability
