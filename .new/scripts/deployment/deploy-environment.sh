#!/bin/bash
# ============================================================================
# Environment-Specific Deployment Script
# ============================================================================
#
# PURPOSE:
#   Deploy Video RAG system to specific environments (dev, staging, production)
#   with appropriate configuration overrides and validation steps.
#
# USAGE:
#   ./deploy-environment.sh <environment> [version]
#   
# EXAMPLES:
#   ./deploy-environment.sh dev
#   ./deploy-environment.sh staging v1.2.0
#   ./deploy-environment.sh production v1.2.0
#
# ============================================================================

set -e

# Configuration
ENVIRONMENT=${1:-dev}
VERSION=${2:-latest}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Validate environment
validate_environment() {
    case $ENVIRONMENT in
        dev|staging|production)
            log_info "Deploying to $ENVIRONMENT environment"
            ;;
        *)
            log_error "Invalid environment: $ENVIRONMENT"
            log_info "Valid environments: dev, staging, production"
            exit 1
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking deployment prerequisites..."
    
    # Check required tools
    command -v docker >/dev/null 2>&1 || { log_error "Docker is required"; exit 1; }
    command -v docker-compose >/dev/null 2>&1 || { log_error "Docker Compose is required"; exit 1; }
    
    # Check configuration files exist
    local config_dir="$PROJECT_ROOT/configs/$ENVIRONMENT"
    if [[ ! -d "$config_dir" ]]; then
        log_error "Configuration directory not found: $config_dir"
        exit 1
    fi
    
    log_success "Prerequisites validated"
}

# Environment-specific deployment
deploy_dev() {
    log_info "Deploying development environment..."
    
    cd "$PROJECT_ROOT"
    
    # Use development overrides
    export COMPOSE_FILE="infrastructure/docker-compose.yml:configs/dev/docker/docker-compose.override.yml"
    
    # Start infrastructure
    make infra-up
    
    # Build and start services
    make services-build
    make services-up
    
    log_success "Development environment deployed"
    log_info "Access points:"
    log_info "  - Kafka UI: http://kafka-ui.video-rag.orb.local"
    log_info "  - MinIO Console: http://minio.video-rag.orb.local:9001"
}

deploy_staging() {
    log_info "Deploying staging environment..."
    
    cd "$PROJECT_ROOT"
    
    # Use staging configuration
    export COMPOSE_FILE="infrastructure/docker-compose.yml:configs/staging/docker/docker-compose.staging.yml"
    
    # Pre-deployment validation
    log_info "Running pre-deployment tests..."
    make test-all || { log_error "Pre-deployment tests failed"; exit 1; }
    
    # Deploy infrastructure
    docker-compose up -d --remove-orphans
    
    # Wait for services to be ready
    log_info "Waiting for services to initialize..."
    sleep 60
    
    # Run health checks
    make health || { log_error "Health checks failed"; exit 1; }
    
    # Run integration tests
    log_info "Running integration tests..."
    make test-integration || { log_error "Integration tests failed"; exit 1; }
    
    log_success "Staging environment deployed and validated"
}

deploy_production() {
    log_info "Deploying production environment..."
    
    # Production safety checks
    if [[ "$VERSION" == "latest" ]]; then
        log_error "Production deployment requires explicit version tag"
        exit 1
    fi
    
    # Confirmation prompt
    log_warning "You are about to deploy to PRODUCTION environment"
    read -p "Are you sure? (yes/no): " -r
    if [[ ! $REPLY =~ ^yes$ ]]; then
        log_info "Production deployment cancelled"
        exit 0
    fi
    
    cd "$PROJECT_ROOT"
    
    # Use production configuration
    export COMPOSE_FILE="infrastructure/docker-compose.yml:configs/production/docker/docker-compose.prod.yml"
    
    # Backup current state (if applicable)
    log_info "Creating deployment backup..."
    # Add backup logic here
    
    # Deploy with zero-downtime strategy
    log_info "Deploying production services..."
    docker-compose up -d --remove-orphans --no-deps
    
    # Progressive health checking
    log_info "Validating production deployment..."
    for i in {1..10}; do
        if make health >/dev/null 2>&1; then
            log_success "Production deployment validated"
            break
        fi
        log_info "Health check attempt $i/10..."
        sleep 30
    done
    
    # Final validation
    make test-integration || { 
        log_error "Production validation failed - consider rollback"
        exit 1
    }
    
    log_success "Production environment deployed successfully"
    log_info "Monitor system closely for the next 30 minutes"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up deployment artifacts..."
    # Add cleanup logic here
}

# Main deployment logic
main() {
    log_info "Starting Video RAG deployment..."
    log_info "Environment: $ENVIRONMENT"
    log_info "Version: $VERSION"
    
    validate_environment
    check_prerequisites
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    case $ENVIRONMENT in
        dev)
            deploy_dev
            ;;
        staging)
            deploy_staging
            ;;
        production)
            deploy_production
            ;;
    esac
    
    log_success "Deployment completed successfully!"
}

# Run main function
main "$@"