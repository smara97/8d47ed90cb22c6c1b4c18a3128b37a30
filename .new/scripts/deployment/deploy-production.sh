#!/bin/bash
# Production deployment script

set -e

ENVIRONMENT=${1:-production}
VERSION=${2:-latest}

echo "🚀 Deploying Video RAG to $ENVIRONMENT environment..."

# Validate environment
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    echo "❌ Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

# Pre-deployment checks
echo "🔍 Running pre-deployment checks..."
make test-all
make health

# Build production images
echo "🏗️ Building production images..."
docker-compose -f infrastructure/docker-compose.yml -f configs/docker/docker-compose.prod.yml build

# Deploy services
echo "📦 Deploying services..."
docker-compose -f infrastructure/docker-compose.yml -f configs/docker/docker-compose.prod.yml up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 30
make health

# Run smoke tests
echo "🧪 Running smoke tests..."
make test-integration

echo "✅ Deployment to $ENVIRONMENT completed successfully!"