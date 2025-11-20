# ============================================================================
# Video RAG Microservices - Makefile
# ============================================================================
#
# PURPOSE:
#   Robust build and deployment automation for Video RAG system.
#   Manages infrastructure and microservices with proper dependency handling.
#
# USAGE:
#   make help              - Show all available commands
#   make infra-up          - Start infrastructure services
#   make services-up       - Start all microservices
#   make up                - Start everything (infra + services)
#   make down              - Stop all services
#   make clean             - Stop and remove all data
#   make logs              - Show logs for all services
#   make health            - Check health of all services
#   make status            - Check status of the whole infra.
#
# REQUIREMENTS:
#   - Docker 20.10+
#   - Docker Compose 2.0+
#   - NVIDIA Docker runtime (for GPU services)
#
# ============================================================================

# Default target
.DEFAULT_GOAL := help

# Configuration
PROJECT_NAME := video-rag
COMPOSE_PROJECT_NAME := video-rag
ROOT_COMPOSE_FILE := docker-compose.yml
INFRA_COMPOSE_FILE := infrastructure/docker-compose.yml
ENV_FILE := infrastructure/.env
SERVICES_DIR := services
CONFIGS_DIR := configs

# Available services (only existing ones)
SERVICES := ocr-service detector-service captioner-service frame-aggregator

# Environment-specific compose files
DEV_OVERRIDE := $(CONFIGS_DIR)/dev/docker/docker-compose.dev.yml
STAGING_OVERRIDE := $(CONFIGS_DIR)/staging/docker/docker-compose.staging.yml
PROD_OVERRIDE := $(CONFIGS_DIR)/production/docker/docker-compose.prod.yml

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# ============================================================================
# HELP AND INFORMATION
# ============================================================================

.PHONY: help
help: ## Show this help message
	@echo "$(BLUE)============================================================================$(NC)"
	@echo "$(BLUE)Video RAG Microservices - Available Commands$(NC)"
	@echo "$(BLUE)============================================================================$(NC)"
	@echo ""
	@echo "$(GREEN)Infrastructure:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / && /infra|network|clean/ {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Services:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / && /service|build|up|down/ && !/infra/ {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Monitoring:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / && /health|logs|status/ {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Utilities:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / && /help|check|test/ {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""

.PHONY: check-requirements
check-requirements: ## Check system requirements
	@echo "$(BLUE)Checking system requirements...$(NC)"
	@command -v docker >/dev/null 2>&1 || { echo "$(RED)Error: Docker is not installed$(NC)"; exit 1; }
	@command -v docker-compose >/dev/null 2>&1 || { echo "$(RED)Error: Docker Compose is not installed$(NC)"; exit 1; }
	@docker --version | grep -E "20\.|2[1-9]\." >/dev/null || { echo "$(RED)Error: Docker 20.10+ required$(NC)"; exit 1; }
	@docker-compose --version | grep -E "2\." >/dev/null || { echo "$(RED)Error: Docker Compose 2.0+ required$(NC)"; exit 1; }
	@echo "$(GREEN)✓ All requirements satisfied$(NC)"

# ============================================================================
# NETWORK MANAGEMENT
# ============================================================================

.PHONY: network-create
network-create: ## Create Docker network
	@echo "$(BLUE)Creating Docker network...$(NC)"
	@docker network create video-rag-network 2>/dev/null || echo "$(YELLOW)Network already exists$(NC)"

.PHONY: network-remove
network-remove: ## Remove Docker network
	@echo "$(BLUE)Removing Docker network...$(NC)"
	@docker network rm video-rag-network 2>/dev/null || echo "$(YELLOW)Network doesn't exist$(NC)"

# ============================================================================
# INFRASTRUCTURE MANAGEMENT
# ============================================================================

.PHONY: infra-up
infra-up: check-requirements network-create ## Start infrastructure services (Kafka, Qdrant, MinIO)
	@echo "$(BLUE)Starting infrastructure services...$(NC)"
	@COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) docker-compose -f $(INFRA_COMPOSE_FILE) --env-file $(ENV_FILE) up -d
	@echo "$(GREEN)✓ Infrastructure services started$(NC)"
	@echo "$(YELLOW)Access points (OrbStack automatic domains):$(NC)"
	@echo "  - Kafka UI:      http://kafka-ui.video-rag.orb.local"
	@echo "  - MinIO Console: http://minio.video-rag.orb.local:9001"
	@echo "  - MinIO API:     http://minio.video-rag.orb.local:9000"
	@echo "  - Qdrant API:    http://qdrant.video-rag.orb.local"
	@echo "  - Kafka Broker:  kafka.video-rag.orb.local:9093"

.PHONY: infra-down
infra-down: ## Stop infrastructure services
	@echo "$(BLUE)Stopping infrastructure services...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) down
	@echo "$(GREEN)✓ Infrastructure services stopped$(NC)"

.PHONY: infra-logs
infra-logs: ## Show infrastructure logs
	@docker-compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) logs -f

.PHONY: infra-health
infra-health: ## Check infrastructure health
	@echo "$(BLUE)Checking infrastructure health...$(NC)"
	@./scripts/testing/health-check.sh | head -20

# ============================================================================
# SERVICE MANAGEMENT
# ============================================================================

.PHONY: services-build
services-build: ## Build all service images
	@echo "$(BLUE)Building service images...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Building $$service...$(NC)"; \
		docker-compose -f $(SERVICES_DIR)/$$service/docker-compose.yml --env-file $(ENV_FILE) build || exit 1; \
	done
	@echo "$(GREEN)✓ All services built$(NC)"

.PHONY: services-up
services-up: infra-up services-build ## Start all microservices
	@echo "$(BLUE)Starting microservices...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Starting $$service...$(NC)"; \
		docker-compose -f $(SERVICES_DIR)/$$service/docker-compose.yml --env-file $(ENV_FILE) up -d || exit 1; \
	done
	@echo "$(GREEN)✓ All services started$(NC)"

.PHONY: services-down
services-down: ## Stop all microservices
	@echo "$(BLUE)Stopping microservices...$(NC)"
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Stopping $$service...$(NC)"; \
		docker-compose -f $(SERVICES_DIR)/$$service/docker-compose.yml --env-file $(ENV_FILE) down 2>/dev/null || true; \
	done
	@echo "$(GREEN)✓ All services stopped$(NC)"

.PHONY: services-logs
services-logs: ## Show logs for all services
	@echo "$(BLUE)Service logs (press Ctrl+C to exit):$(NC)"
	@for service in $(SERVICES); do \
		docker-compose -f $(SERVICES_DIR)/$$service/docker-compose.yml --env-file $(ENV_FILE) logs --tail=10 -f & \
	done; \
	wait

.PHONY: service-logs
service-logs: ## Show logs for specific service (usage: make service-logs SERVICE=ocr-service)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE parameter required. Usage: make service-logs SERVICE=ocr-service$(NC)"; \
		exit 1; \
	fi
	@if [ ! -d "$(SERVICES_DIR)/$(SERVICE)" ]; then \
		echo "$(RED)Error: Service $(SERVICE) not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Showing logs for $(SERVICE)...$(NC)"
	@docker-compose -f $(SERVICES_DIR)/$(SERVICE)/docker-compose.yml --env-file $(ENV_FILE) logs -f

# ============================================================================
# COMBINED OPERATIONS
# ============================================================================

.PHONY: up
up: ## Start everything with development configuration
	@echo "$(BLUE)Starting Video RAG system (development)...$(NC)"
	@COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) docker-compose -f $(ROOT_COMPOSE_FILE) -f $(DEV_OVERRIDE) --env-file $(ENV_FILE) up -d
	@echo "$(GREEN)✓ Video RAG system is running (development)$(NC)"
	@make status

.PHONY: up-staging
up-staging: ## Start everything with staging configuration
	@echo "$(BLUE)Starting Video RAG system (staging)...$(NC)"
	@COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) docker-compose -f $(ROOT_COMPOSE_FILE) -f $(STAGING_OVERRIDE) --env-file $(CONFIGS_DIR)/staging/.env up -d
	@echo "$(GREEN)✓ Video RAG system is running (staging)$(NC)"
	@make status

.PHONY: up-prod
up-prod: ## Start everything with production configuration
	@echo "$(BLUE)Starting Video RAG system (production)...$(NC)"
	@COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) docker-compose -f $(ROOT_COMPOSE_FILE) -f $(PROD_OVERRIDE) --env-file $(CONFIGS_DIR)/production/.env up -d
	@echo "$(GREEN)✓ Video RAG system is running (production)$(NC)"
	@make status

.PHONY: down
down: ## Stop all services and infrastructure (development)
	@echo "$(BLUE)Stopping Video RAG system...$(NC)"
	@docker-compose -f $(ROOT_COMPOSE_FILE) -f $(DEV_OVERRIDE) --env-file $(ENV_FILE) down 2>/dev/null || true
	@echo "$(GREEN)✓ Video RAG system stopped$(NC)"

.PHONY: down-staging
down-staging: ## Stop staging environment
	@echo "$(BLUE)Stopping Video RAG system (staging)...$(NC)"
	@docker-compose -f $(ROOT_COMPOSE_FILE) -f $(STAGING_OVERRIDE) --env-file $(CONFIGS_DIR)/staging/.env down 2>/dev/null || true
	@echo "$(GREEN)✓ Video RAG system stopped (staging)$(NC)"

.PHONY: down-prod
down-prod: ## Stop production environment
	@echo "$(BLUE)Stopping Video RAG system (production)...$(NC)"
	@docker-compose -f $(ROOT_COMPOSE_FILE) -f $(PROD_OVERRIDE) --env-file $(CONFIGS_DIR)/production/.env down 2>/dev/null || true
	@echo "$(GREEN)✓ Video RAG system stopped (production)$(NC)"

.PHONY: restart
restart: down up ## Restart everything

.PHONY: clean
clean: down ## Stop everything and remove all data
	@echo "$(BLUE)Cleaning up all data...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) down -v 2>/dev/null || true
	@for service in $(SERVICES); do \
		docker-compose -f $(SERVICES_DIR)/$$service/docker-compose.yml --env-file $(ENV_FILE) down -v 2>/dev/null || true; \
	done
	@docker system prune -f
	@make network-remove
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

# ============================================================================
# MONITORING AND HEALTH
# ============================================================================

.PHONY: health
health: ## Check health of all services
	@echo "$(BLUE)Checking system health...$(NC)"
	@./scripts/testing/health-check.sh

.PHONY: monitor
monitor: ## Start continuous service monitoring
	@echo "$(BLUE)Starting service monitor (press Ctrl+C to stop)...$(NC)"
	@python3 tools/monitoring/service-monitor.py

.PHONY: setup
setup: ## Setup development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@./scripts/setup/install-dependencies.sh

.PHONY: deploy
deploy: ## Deploy to environment (usage: make deploy ENV=staging VERSION=v1.0.0)
	@echo "$(BLUE)Deploying to $(ENV)...$(NC)"
	@./scripts/deployment/deploy-environment.sh $(ENV) $(VERSION)

.PHONY: deploy-dev
deploy-dev: ## Deploy to development environment
	@echo "$(BLUE)Deploying to development...$(NC)"
	@make up

.PHONY: deploy-staging
deploy-staging: ## Deploy to staging environment
	@echo "$(BLUE)Deploying to staging...$(NC)"
	@make up-staging

.PHONY: deploy-prod
deploy-prod: ## Deploy to production environment
	@echo "$(BLUE)Deploying to production...$(NC)"
	@make up-prod

.PHONY: test-unit
test-unit: ## Run unit tests
	@echo "$(BLUE)Running unit tests...$(NC)"
	@python3 -m pytest tests/unit/ -v

.PHONY: test-e2e
test-e2e: ## Run end-to-end tests
	@echo "$(BLUE)Running e2e tests...$(NC)"
	@python3 -m pytest tests/e2e/ -v

.PHONY: status
status: ## Show status of all containers
	@echo "$(BLUE)Container status:$(NC)"
	@docker ps --filter "label=com.docker.compose.project=video-rag" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || \
		docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(kafka|zookeeper|minio|qdrant|ocr-service|detector-service|captioner-service)" || \
		echo "$(YELLOW)No containers running$(NC)"

.PHONY: logs
logs: ## Show logs for all running services
	@echo "$(BLUE)All service logs (press Ctrl+C to exit):$(NC)"
	@docker-compose -f $(COMPOSE_FILE) --env-file $(ENV_FILE) logs -f &
	@make services-logs

# ============================================================================
# DEVELOPMENT UTILITIES
# ============================================================================

.PHONY: build-service
build-service: ## Build specific service (usage: make build-service SERVICE=ocr-service)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE parameter required. Usage: make build-service SERVICE=ocr-service$(NC)"; \
		exit 1; \
	fi
	@if [ ! -d "$(SERVICES_DIR)/$(SERVICE)" ]; then \
		echo "$(RED)Error: Service $(SERVICE) not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Building $(SERVICE)...$(NC)"
	@docker-compose -f $(SERVICES_DIR)/$(SERVICE)/docker-compose.yml --env-file $(ENV_FILE) build
	@echo "$(GREEN)✓ $(SERVICE) built$(NC)"

.PHONY: start-service
start-service: infra-up ## Start specific service (usage: make start-service SERVICE=ocr-service)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE parameter required. Usage: make start-service SERVICE=ocr-service$(NC)"; \
		exit 1; \
	fi
	@if [ ! -d "$(SERVICES_DIR)/$(SERVICE)" ]; then \
		echo "$(RED)Error: Service $(SERVICE) not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Starting $(SERVICE)...$(NC)"
	@docker-compose -f $(SERVICES_DIR)/$(SERVICE)/docker-compose.yml --env-file $(ENV_FILE) up -d
	@echo "$(GREEN)✓ $(SERVICE) started$(NC)"

.PHONY: stop-service
stop-service: ## Stop specific service (usage: make stop-service SERVICE=ocr-service)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE parameter required. Usage: make stop-service SERVICE=ocr-service$(NC)"; \
		exit 1; \
	fi
	@if [ ! -d "$(SERVICES_DIR)/$(SERVICE)" ]; then \
		echo "$(RED)Error: Service $(SERVICE) not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Stopping $(SERVICE)...$(NC)"
	@docker-compose -f $(SERVICES_DIR)/$(SERVICE)/docker-compose.yml --env-file $(ENV_FILE) down
	@echo "$(GREEN)✓ $(SERVICE) stopped$(NC)"

.PHONY: shell-service
shell-service: ## Open shell in service container (usage: make shell-service SERVICE=ocr-service)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE parameter required. Usage: make shell-service SERVICE=ocr-service$(NC)"; \
		exit 1; \
	fi
	@CONTAINER_NAME=$$(docker ps --filter "name=$(SERVICE)" --format "{{.Names}}" | head -1); \
	if [ -z "$$CONTAINER_NAME" ]; then \
		echo "$(RED)Error: $(SERVICE) container not running$(NC)"; \
		exit 1; \
	fi; \
	echo "$(BLUE)Opening shell in $$CONTAINER_NAME...$(NC)"; \
	docker exec -it $$CONTAINER_NAME /bin/bash

# ============================================================================
# TESTING AND VALIDATION
# ============================================================================

.PHONY: test-kafka
test-kafka: ## Test Kafka connectivity
	@echo "$(BLUE)Testing Kafka connectivity...$(NC)"
	@docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list 2>/dev/null && \
		echo "$(GREEN)✓ Kafka is accessible$(NC)" || \
		echo "$(RED)✗ Kafka connection failed$(NC)"

.PHONY: test-qdrant
test-qdrant: ## Test Qdrant connectivity
	@echo "$(BLUE)Testing Qdrant connectivity...$(NC)"
	@curl -s http://qdrant.video-rag.orb.local/healthz >/dev/null && \
		echo "$(GREEN)✓ Qdrant is accessible$(NC)" || \
		echo "$(RED)✗ Qdrant connection failed$(NC)"

.PHONY: test-minio
test-minio: ## Test MinIO connectivity
	@echo "$(BLUE)Testing MinIO connectivity...$(NC)"
	@curl -s http://minio.video-rag.orb.local:9000/minio/health/live >/dev/null && \
		echo "$(GREEN)✓ MinIO is accessible$(NC)" || \
		echo "$(RED)✗ MinIO connection failed$(NC)"

.PHONY: test-all
test-all: test-kafka test-qdrant test-minio ## Test all infrastructure connectivity

.PHONY: test-integration
test-integration: ## Test Kafka integration with sample frames
	@echo "$(BLUE)Testing Kafka integration...$(NC)"
	@python3 scripts/testing/test-producer.py --frames 3 --interval 1

.PHONY: monitor-topics
monitor-topics: ## Monitor all Kafka result topics
	@echo "$(BLUE)Monitoring Kafka topics (press Ctrl+C to stop)...$(NC)"
	@python3 scripts/testing/test-consumer.py --all

.PHONY: monitor-topic
monitor-topic: ## Monitor specific topic (usage: make monitor-topic TOPIC=ocr-results)
	@if [ -z "$(TOPIC)" ]; then \
		echo "$(RED)Error: TOPIC parameter required. Usage: make monitor-topic TOPIC=ocr-results$(NC)"; \
		echo "Available topics: raw-frames, ocr-results, detection-results, caption-results"; \
		exit 1; \
	fi
	@echo "$(BLUE)Monitoring topic: $(TOPIC)$(NC)"
	@python3 scripts/testing/test-consumer.py --topic $(TOPIC)

# ============================================================================
# INFORMATION
# ============================================================================

.PHONY: info
info: ## Show system information
	@echo "$(BLUE)============================================================================$(NC)"
	@echo "$(BLUE)Video RAG System Information$(NC)"
	@echo "$(BLUE)============================================================================$(NC)"
	@echo "$(GREEN)Project:$(NC) $(PROJECT_NAME)"
	@echo "$(GREEN)Services:$(NC) $(SERVICES)"
	@echo "$(GREEN)Compose File:$(NC) $(COMPOSE_FILE)"
	@echo "$(GREEN)Environment:$(NC) $(ENV_FILE)"
	@echo ""
	@echo "$(GREEN)Access Points (OrbStack domains):$(NC)"
	@echo "  - Kafka UI:      http://kafka-ui.video-rag.orb.local"
	@echo "  - MinIO Console: http://minio.video-rag.orb.local:9001 (minioadmin/minioadmin)"
	@echo "  - MinIO API:     http://minio.video-rag.orb.local:9000"
	@echo "  - Qdrant API:    http://qdrant.video-rag.orb.local"
	@echo "  - Kafka Broker:  kafka.video-rag.orb.local:9093"
	@echo "  - OCR Service:   http://localhost:8001/health"
	@echo "  - Detector:      http://localhost:8002/health"
	@echo "  - Captioner:     http://localhost:8003/health"
	@echo ""

# ============================================================================
# PHONY TARGETS
# ============================================================================

.PHONY: all
all: up ## Alias for 'up' command