#!/bin/bash

# ============================================================================
# Health Check Script
# ============================================================================
# Checks the health status of all services
#
# Usage: ./scripts/health-check.sh
# ============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================================================"
echo "Video RAG System Health Check"
echo "============================================================================"
echo ""

# Function to check HTTP endpoint
check_http() {
    local name="$1"
    local url="$2"
    local response
    
    printf "%-35s" "$name"
    
    if response=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url" 2>/dev/null); then
        if [ "$response" -eq 200 ]; then
            echo -e "${GREEN}✓ healthy (HTTP $response)${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ responding (HTTP $response)${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ unreachable${NC}"
        return 1
    fi
}

# Function to check docker container
check_container() {
    local name="$1"
    local container="$2"
    
    printf "%-35s" "$name"
    
    if docker ps --filter "name=$container" --filter "status=running" --format '{{.Names}}' | grep -q "$container"; then
        local health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "none")
        if [ "$health" = "healthy" ] || [ "$health" = "none" ]; then
            echo -e "${GREEN}✓ running${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ unhealthy${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ not running${NC}"
        return 1
    fi
}

echo "Infrastructure Services:"
echo "----------------------------------------------------------------------------"
check_container "Zookeeper" "zookeeper"
check_container "Kafka" "kafka"
check_http "Kafka UI (OrbStack)" "http://kafka-ui.video-rag.local"
check_http "MinIO API (OrbStack)" "http://minio.video-rag.local:9000/minio/health/live"
check_http "MinIO Console (OrbStack)" "http://minio-console.video-rag.local"
check_http "Qdrant (OrbStack)" "http://qdrant.video-rag.local/healthz"

echo ""
echo "Microservices:"
echo "----------------------------------------------------------------------------"
check_http "OCR Service" "http://localhost:8001/health"
check_http "Detector Service" "http://localhost:8002/health"
check_http "Captioner Service" "http://localhost:8003/health"

echo ""
echo "============================================================================"
echo "Health check complete"
echo "============================================================================"