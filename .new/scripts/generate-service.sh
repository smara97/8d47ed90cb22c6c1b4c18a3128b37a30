#!/bin/bash
# ============================================================================
# Service Generator Script - Video RAG System
# ============================================================================
#
# PURPOSE:
#   Generates new microservices from template with proper variable substitution
#   and consistent structure across all services in the Video RAG system.
#
# USAGE:
#   ./generate-service.sh <service-name> [options]
#
# EXAMPLE:
#   ./generate-service.sh text-extractor --input=raw-frames --output=text-results --port=8005
#
# ============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
INPUT_TOPIC="raw-frames"
OUTPUT_TOPIC=""
HOST_PORT=""
BATCH_SIZE="5"
TIMEOUT="30"
PROCESSING_METHOD="mock"
MEMORY_LIMIT="2G"
MEMORY_RESERVATION="1G"
CPU_LIMIT="1.0"
CPU_RESERVATION="0.5"

# Helper functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Show usage
show_usage() {
    cat << EOF
Usage: $0 <service-name> [options]

Arguments:
  service-name          Name of the service (e.g., text-extractor, image-analyzer)

Options:
  --input=TOPIC         Input Kafka topic (default: raw-frames)
  --output=TOPIC        Output Kafka topic (default: <service-name>-results)
  --port=PORT           Host port for the service (default: auto-assigned)
  --batch-size=SIZE     Processing batch size (default: 5)
  --timeout=SECONDS     Processing timeout (default: 30)
  --method=METHOD       Processing method name (default: mock)
  --memory-limit=SIZE   Memory limit (default: 2G)
  --memory-res=SIZE     Memory reservation (default: 1G)
  --cpu-limit=CORES     CPU limit (default: 1.0)
  --cpu-res=CORES       CPU reservation (default: 0.5)
  --help               Show this help message

Examples:
  $0 text-extractor
  $0 image-analyzer --input=video-frames --output=analysis-results --port=8005
  $0 sentiment-analyzer --batch-size=10 --timeout=60 --method=transformer
EOF
}

# Parse command line arguments
parse_args() {
    if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
    SERVICE_NAME="$1"
    shift
    
    # Validate service name
    if [[ ! "$SERVICE_NAME" =~ ^[a-z][a-z0-9-]*[a-z0-9]$ ]]; then
        error "Invalid service name. Use lowercase letters, numbers, and hyphens only."
    fi
    
    # Set default output topic
    OUTPUT_TOPIC="${SERVICE_NAME}-results"
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --input=*)
                INPUT_TOPIC="${1#*=}"
                shift
                ;;
            --output=*)
                OUTPUT_TOPIC="${1#*=}"
                shift
                ;;
            --port=*)
                HOST_PORT="${1#*=}"
                shift
                ;;
            --batch-size=*)
                BATCH_SIZE="${1#*=}"
                shift
                ;;
            --timeout=*)
                TIMEOUT="${1#*=}"
                shift
                ;;
            --method=*)
                PROCESSING_METHOD="${1#*=}"
                shift
                ;;
            --memory-limit=*)
                MEMORY_LIMIT="${1#*=}"
                shift
                ;;
            --memory-res=*)
                MEMORY_RESERVATION="${1#*=}"
                shift
                ;;
            --cpu-limit=*)
                CPU_LIMIT="${1#*=}"
                shift
                ;;
            --cpu-res=*)
                CPU_RESERVATION="${1#*=}"
                shift
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
    
    # Auto-assign port if not provided
    if [[ -z "$HOST_PORT" ]]; then
        # Find next available port starting from 8005
        for port in {8005..8099}; do
            if ! netstat -tuln 2>/dev/null | grep -q ":$port "; then
                HOST_PORT="$port"
                break
            fi
        done
        
        if [[ -z "$HOST_PORT" ]]; then
            error "Could not find available port. Please specify --port manually."
        fi
    fi
}

# Generate service variables
generate_variables() {
    # Service name variations
    SERVICE_NAME_UPPER=$(echo "$SERVICE_NAME" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
    SERVICE_NAME_TITLE=$(echo "$SERVICE_NAME" | sed 's/-/ /g' | sed 's/\b\w/\U&/g')
    SERVICE_CLASS_NAME=$(echo "$SERVICE_NAME" | sed 's/-//g' | sed 's/\b\w/\U&/g')Service
    
    # Descriptions
    SERVICE_DESCRIPTION="Processes video frames using $PROCESSING_METHOD method for $SERVICE_NAME analysis"
    SERVICE_DESCRIPTION_LOWER=$(echo "$SERVICE_DESCRIPTION" | tr '[:upper:]' '[:lower:]')
    SERVICE_ROLE_DESCRIPTION="Consumes frames from $INPUT_TOPIC, processes them using $PROCESSING_METHOD, and publishes results to $OUTPUT_TOPIC"
    RESOURCE_DESCRIPTION="Optimized for $PROCESSING_METHOD processing with $BATCH_SIZE batch size"
    OPTIMIZATION_TARGET="$PROCESSING_METHOD processing workloads"
    
    # Service-specific configurations
    SERVICE_SPECIFIC_DEPENDENCIES="# $SERVICE_NAME specific processing libraries"
    SERVICE_SPECIFIC_ENV_VARS="# $SERVICE_NAME specific environment variables"
    SERVICE_SPECIFIC_CONFIG="# $SERVICE_NAME specific configuration"
    
    log "Generated variables for service: $SERVICE_NAME"
    log "  - Class Name: $SERVICE_CLASS_NAME"
    log "  - Input Topic: $INPUT_TOPIC"
    log "  - Output Topic: $OUTPUT_TOPIC"
    log "  - Host Port: $HOST_PORT"
}

# Substitute variables in file
substitute_variables() {
    local file="$1"
    
    # Perform all substitutions
    sed -i.bak \
        -e "s/{{SERVICE_NAME}}/$SERVICE_NAME/g" \
        -e "s/{{SERVICE_NAME_UPPER}}/$SERVICE_NAME_UPPER/g" \
        -e "s/{{SERVICE_NAME_TITLE}}/$SERVICE_NAME_TITLE/g" \
        -e "s/{{SERVICE_CLASS_NAME}}/$SERVICE_CLASS_NAME/g" \
        -e "s/{{INPUT_TOPIC}}/$INPUT_TOPIC/g" \
        -e "s/{{OUTPUT_TOPIC}}/$OUTPUT_TOPIC/g" \
        -e "s/{{HOST_PORT}}/$HOST_PORT/g" \
        -e "s/{{BATCH_SIZE}}/$BATCH_SIZE/g" \
        -e "s/{{TIMEOUT}}/$TIMEOUT/g" \
        -e "s/{{PROCESSING_METHOD}}/$PROCESSING_METHOD/g" \
        -e "s/{{MEMORY_LIMIT}}/$MEMORY_LIMIT/g" \
        -e "s/{{MEMORY_RESERVATION}}/$MEMORY_RESERVATION/g" \
        -e "s/{{CPU_LIMIT}}/$CPU_LIMIT/g" \
        -e "s/{{CPU_RESERVATION}}/$CPU_RESERVATION/g" \
        -e "s/{{SERVICE_DESCRIPTION}}/$SERVICE_DESCRIPTION/g" \
        -e "s/{{SERVICE_DESCRIPTION_LOWER}}/$SERVICE_DESCRIPTION_LOWER/g" \
        -e "s/{{SERVICE_ROLE_DESCRIPTION}}/$SERVICE_ROLE_DESCRIPTION/g" \
        -e "s/{{RESOURCE_DESCRIPTION}}/$RESOURCE_DESCRIPTION/g" \
        -e "s/{{OPTIMIZATION_TARGET}}/$OPTIMIZATION_TARGET/g" \
        -e "s/{{SERVICE_SPECIFIC_DEPENDENCIES}}/$SERVICE_SPECIFIC_DEPENDENCIES/g" \
        -e "s/{{SERVICE_SPECIFIC_ENV_VARS}}/$SERVICE_SPECIFIC_ENV_VARS/g" \
        -e "s/{{SERVICE_SPECIFIC_CONFIG}}/$SERVICE_SPECIFIC_CONFIG/g" \
        "$file"
    
    # Remove backup file
    rm -f "$file.bak"
}

# Generate service from template
generate_service() {
    local template_dir="templates/service-template"
    local service_dir="services/$SERVICE_NAME"
    
    # Check if template exists
    if [[ ! -d "$template_dir" ]]; then
        error "Template directory not found: $template_dir"
    fi
    
    # Check if service already exists
    if [[ -d "$service_dir" ]]; then
        warn "Service directory already exists: $service_dir"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Service generation cancelled"
            exit 0
        fi
        rm -rf "$service_dir"
    fi
    
    log "Generating service from template..."
    
    # Copy template to service directory
    cp -r "$template_dir" "$service_dir"
    
    # Process all files in the service directory
    find "$service_dir" -type f -name "*.py" -o -name "*.yml" -o -name "*.txt" -o -name "Dockerfile" -o -name ".env" | while read -r file; do
        log "Processing file: $(basename "$file")"
        substitute_variables "$file"
    done
    
    success "Service '$SERVICE_NAME' generated successfully!"
    log "Service directory: $service_dir"
    log "Access URL: http://localhost:$HOST_PORT"
}

# Update Makefile services list
update_makefile() {
    local makefile="Makefile"
    
    if [[ ! -f "$makefile" ]]; then
        warn "Makefile not found, skipping update"
        return
    fi
    
    # Check if service is already in the list
    if grep -q "$SERVICE_NAME" "$makefile"; then
        log "Service already exists in Makefile"
        return
    fi
    
    # Add service to the SERVICES list
    sed -i.bak "s/SERVICES := \(.*\)/SERVICES := \1 $SERVICE_NAME/" "$makefile"
    rm -f "$makefile.bak"
    
    success "Updated Makefile with new service"
}

# Main function
main() {
    log "Starting service generation..."
    
    parse_args "$@"
    generate_variables
    generate_service
    update_makefile
    
    echo
    success "Service generation completed!"
    log "Next steps:"
    log "  1. cd services/$SERVICE_NAME"
    log "  2. Customize src/main.py with your business logic"
    log "  3. Update requirements.txt with specific dependencies"
    log "  4. Build and test: make build-service SERVICE=$SERVICE_NAME"
    log "  5. Start service: make start-service SERVICE=$SERVICE_NAME"
}

# Run main function
main "$@"