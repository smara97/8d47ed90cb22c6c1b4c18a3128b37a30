# ============================================================================
# Video RAG Microservices - Enhanced Modular Makefile
# ============================================================================
#
# PURPOSE:
#   Comprehensive build, deployment, and management automation for Video RAG
#   microservices system with Laravel-style namespace commands, modular
#   architecture, and enterprise-grade operational capabilities.
#
# CORE FUNCTIONALITY:
#   - Laravel-style namespace command organization (service-*, infra-*, test-*)
#   - Modular architecture with specialized makefiles for different concerns
#   - Template-based service generation and management
#   - Multi-environment deployment (dev/staging/production)
#   - Infrastructure orchestration (Kafka, Qdrant, MinIO)
#   - Comprehensive testing and validation suite
#   - Real-time monitoring and health checking
#   - Automated service discovery and networking
#
# QUICK START:
#   make help              - Show all available commands with categories
#   make up                - Start complete system (development mode)
#   make status            - Check status of all containers
#   make test-validate     - Run comprehensive system validation
#   make clean             - Stop everything and clean up
#
# LARAVEL-STYLE NAMESPACES:
#   service-*              - Service management (build, start, stop, logs, shell, make)
#   services-*             - Bulk service operations (build-all, up-all, down-all)
#   infra-*                - Infrastructure management (up, down, health, logs)
#   network-*              - Docker network operations (create, remove)
#   test-*                 - Testing and validation (all, services, pipeline, validate)
#   deploy-*               - Environment deployment (dev, staging, prod)
#   monitor-*              - Monitoring and logging (logs, topics, health)
#   system-*               - System operations (up, down, status)
#
# SERVICE MANAGEMENT:
#   make service-make SERVICE=my-service ARGS="--port=8005 --method=ai"
#   make service-build SERVICE=ocr-service
#   make service-start SERVICE=detector-service
#   make service-logs SERVICE=captioner-service
#   make service-shell SERVICE=ocr-service
#   make service-stop SERVICE=detector-service
#
# ENVIRONMENT DEPLOYMENT:
#   make deploy-dev        - Deploy to development environment
#   make deploy-staging    - Deploy to staging environment
#   make deploy-prod       - Deploy to production environment
#   make deploy-down-staging - Stop staging environment
#   make deploy-down-prod  - Stop production environment
#
# TESTING & VALIDATION:
#   make test-services     - Test all service health endpoints
#   make test-all          - Test Kafka, Qdrant, MinIO connectivity
#   make test-kafka-connectivity - Test Kafka connections from services
#   make test-pipeline     - Test complete processing pipeline
#   make test-quick        - Quick health check of all services
#   make test-validate     - Comprehensive system validation
#
# MONITORING & DEBUGGING:
#   make status            - Show container status and ports
#   make logs              - Show logs for all services
#   make monitor-logs      - Real-time log monitoring
#   make service-logs SERVICE=name - Show logs for specific service
#   make service-shell SERVICE=name - Open shell in service container
#   make monitor-topics    - Monitor all Kafka result topics
#   make monitor-topic TOPIC=name - Monitor specific Kafka topic
#
# INFRASTRUCTURE MANAGEMENT:
#   make infra-up          - Start infrastructure services only
#   make infra-down        - Stop infrastructure services
#   make infra-health      - Check infrastructure health
#   make infra-logs        - Show infrastructure logs
#   make network-create    - Create Docker network
#   make network-remove    - Remove Docker network
#
# MODULAR ARCHITECTURE:
#   - makefiles/infrastructure.mk - Network and core services (Kafka, Qdrant, MinIO)
#   - makefiles/services.mk      - Microservice management and operations
#   - makefiles/testing.mk       - Testing and validation suite
#   - makefiles/deployment.mk    - Environment deployment and lifecycle
#   - makefiles/monitoring.mk    - Logging, health checks, and monitoring
#   - makefiles/utilities.mk     - Development utilities and helpers
#
# REQUIREMENTS:
#   - Docker 20.10+ with Compose V2
#   - OrbStack or Docker Desktop (for automatic domains)
#   - Bash 4.0+ (for script execution)
#   - curl (for health checks and testing)
#   - Python 3.8+ (for testing scripts)
#   - jq (optional, for JSON processing)
#
# ENVIRONMENT VARIABLES:
#   PROJECT_NAME          - Project identifier (default: video-rag)
#   COMPOSE_PROJECT_NAME  - Docker Compose project name
#   ENV_FILE             - Environment file path
#   SERVICE              - Target service for service-specific commands
#   ARGS                 - Additional arguments for service generation
#   TOPIC                - Kafka topic name for monitoring commands
#   ENV                  - Target environment for deployment commands
#   VERSION              - Version tag for deployment commands
#
# ACCESS POINTS (OrbStack automatic domains):
#   - Kafka UI:      http://kafka-ui.video-rag.orb.local
#   - MinIO Console: http://minio.video-rag.orb.local:9001 (minioadmin/minioadmin)
#   - MinIO API:     http://minio.video-rag.orb.local:9000
#   - Qdrant API:    http://qdrant.video-rag.orb.local
#   - Kafka Broker:  kafka.video-rag.orb.local:9093
#   - Services:      http://localhost:8001-8099 (auto-assigned ports)
#
# EXAMPLES:
#   # Generate new AI service with custom configuration
#   make service-make SERVICE=ai-analyzer ARGS="--port=8005 --method=transformer"
#   
#   # Deploy to staging with comprehensive validation
#   make deploy-staging && make test-validate
#   
#   # Debug specific service with logs and shell access
#   make service-logs SERVICE=ocr-service
#   make service-shell SERVICE=detector-service
#   
#   # Test complete pipeline with monitoring
#   make up && sleep 30 && make test-pipeline && make monitor-topics
#
#   # Infrastructure-only operations
#   make infra-up && make test-all && make infra-health
#
#   # Environment-specific operations
#   make deploy-prod && make test-services && make monitor-logs
#
# MAINTENANCE:
#   - Each module is self-contained and can be modified independently
#   - All targets follow Laravel-style namespace conventions
#   - Comprehensive error handling and user feedback
#   - Color-coded output for better readability
#   - Detailed help system with categorized commands
#
# ============================================================================

# Default target - shows help when no target is specified
.DEFAULT_GOAL := help

# ============================================================================
# CONFIGURATION VARIABLES
# ============================================================================
# Core project configuration that affects all modules

# Project identification and naming
PROJECT_NAME := video-rag
COMPOSE_PROJECT_NAME := video-rag

# Docker Compose file paths for different components
INFRA_COMPONENTS_DIR := infrastructure/components
INFRA_COMPOSE_FILES := $(INFRA_COMPONENTS_DIR)/zookeeper.yml $(INFRA_COMPONENTS_DIR)/kafka.yml $(INFRA_COMPONENTS_DIR)/kafka-ui.yml $(INFRA_COMPONENTS_DIR)/minio.yml $(INFRA_COMPONENTS_DIR)/qdrant.yml
ENV_FILE := infrastructure/.env                            # Default environment file

# Directory structure for modular organization
SERVICES_DIR := src/services
CONFIGS_DIR := src/configs # Environment-specific configurations

# Available services list (populated dynamically by service generation)
# This variable is used by bulk operations in services.mk
SERVICES := ocr-service detector-service captioner-service frame-aggregator test-service

# Environment-specific Docker Compose override files
# These files contain environment-specific configurations and resource limits
DEV_OVERRIDE := $(CONFIGS_DIR)/dev/docker/docker-compose.dev.yml
STAGING_OVERRIDE := $(CONFIGS_DIR)/staging/docker/docker-compose.staging.yml
PROD_OVERRIDE := $(CONFIGS_DIR)/production/docker/docker-compose.prod.yml

# ============================================================================
# OUTPUT FORMATTING AND COLORS
# ============================================================================
# ANSI color codes for enhanced terminal output readability

RED := \033[0;31m      # Error messages and failures
GREEN := \033[0;32m    # Success messages and confirmations
YELLOW := \033[1;33m   # Warnings and informational messages
BLUE := \033[0;34m     # Process messages and headers
NC := \033[0m          # No Color - reset to default

# ============================================================================
# ENHANCED HELP SYSTEM
# ============================================================================
# Comprehensive help system that automatically discovers and categorizes
# all available targets from included modules using Laravel-style namespaces

.PHONY: help
help: ## Show comprehensive help with Laravel-style namespace organization
	@echo "$(BLUE)============================================================================$(NC)"
	@echo "$(BLUE)Video RAG Microservices - Laravel-style Commands$(NC)"
	@echo "$(BLUE)============================================================================$(NC)"
	@echo ""
	@echo "$(GREEN)🚀 Quick Start:$(NC)"
	@echo "  $(YELLOW)make up$(NC)                 - Start complete system (development)"
	@echo "  $(YELLOW)make status$(NC)             - Check container status and ports"
	@echo "  $(YELLOW)make test-validate$(NC)      - Run comprehensive system validation"
	@echo "  $(YELLOW)make down$(NC)               - Stop all services"
	@echo ""
	@echo "$(GREEN)🛠️  Service Management (service-*):$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^service-.*?## / {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@awk 'BEGIN {FS = ":.*?## "} /^services-.*?## / {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)🏗️  Infrastructure (infra-*, network-*):$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^infra-.*?## / {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@awk 'BEGIN {FS = ":.*?## "} /^network-.*?## / {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)🌍 Deployment (deploy-*, system-*):$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^deploy-.*?## / {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@awk 'BEGIN {FS = ":.*?## "} /^system-.*?## / {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)🧪 Testing & Validation (test-*):$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^test-.*?## / {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)📊 Monitoring & Debugging (monitor-*):$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^monitor-.*?## / {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo "  $(YELLOW)status$(NC)                   - Show status of all containers"
	@echo "  $(YELLOW)logs$(NC)                     - Show logs for all running services"
	@echo "  $(YELLOW)health$(NC)                   - Check health of all services"
	@echo ""
	@echo "$(GREEN)🧹 Maintenance & Utilities:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^check-.*?## / {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo "  $(YELLOW)setup$(NC)                    - Setup development environment"
	@echo "  $(YELLOW)info$(NC)                     - Show system information"
	@echo "  $(YELLOW)clean$(NC)                    - Stop everything and remove all data"
	@echo "  $(YELLOW)restart$(NC)                  - Restart everything"
	@echo ""
	@echo "$(GREEN)💡 Laravel-style Examples:$(NC)"
	@echo "  $(YELLOW)make service-make SERVICE=ai-analyzer ARGS=\"--port=8005 --method=transformer\"$(NC)"
	@echo "  $(YELLOW)make service-logs SERVICE=ocr-service$(NC)"
	@echo "  $(YELLOW)make deploy-staging && make test-validate$(NC)"
	@echo "  $(YELLOW)make infra-up && make test-all$(NC)"
	@echo "  $(YELLOW)make monitor-topic TOPIC=ocr-results$(NC)"
	@echo ""
	@echo "$(GREEN)📁 Modular Architecture:$(NC)"
	@echo "  $(YELLOW)infrastructure/makefiles/infrastructure.mk$(NC)  - Network and core services"
	@echo "  $(YELLOW)infrastructure/makefiles/services.mk$(NC)       - Microservice management"
	@echo "  $(YELLOW)infrastructure/makefiles/testing.mk$(NC)        - Testing and validation"
	@echo "  $(YELLOW)infrastructure/makefiles/deployment.mk$(NC)     - Environment deployment"
	@echo "  $(YELLOW)infrastructure/makefiles/monitoring.mk$(NC)     - Logging and monitoring"
	@echo "  $(YELLOW)infrastructure/makefiles/utilities.mk$(NC)      - Development utilities"
	@echo ""

# ============================================================================
# MODULAR MAKEFILE INCLUDES
# ============================================================================
# Include all specialized modules in dependency order
# Each module is self-contained and follows Laravel-style naming conventions

# Infrastructure management - must be included first as other modules depend on it
include infrastructure/makefiles/infrastructure.mk

# Service management - depends on infrastructure for service startup
include infrastructure/makefiles/services.mk

# Testing and validation - depends on both infrastructure and services
include infrastructure/makefiles/testing.mk

# Deployment management - orchestrates infrastructure and services
include infrastructure/makefiles/deployment.mk

# Monitoring and logging - observes infrastructure and services
include infrastructure/makefiles/monitoring.mk

# Development utilities - provides helper functions for all modules
include infrastructure/makefiles/utilities.mk