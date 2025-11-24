# ============================================================================
# Service Management Module - Microservice Lifecycle Operations
# ============================================================================
#
# PURPOSE:
#   Manages the complete lifecycle of Video RAG microservices including
#   generation, building, deployment, monitoring, and debugging operations.
#   Supports both individual service operations and bulk operations across
#   all services in the system.
#
# CORE FUNCTIONALITY:
#   - Template-based service generation with customizable parameters
#   - Individual service lifecycle management (build, start, stop)
#   - Bulk operations for managing multiple services simultaneously
#   - Real-time log monitoring and debugging capabilities
#   - Interactive shell access for service containers
#   - Service health monitoring and status reporting
#
# DEPENDENCIES:
#   - Infrastructure services (Kafka, Qdrant, MinIO) must be running
#   - Service-specific docker compose.yml files in services/ directory
#   - Service generation script: scripts/generate-service.sh
#   - Docker containers must be properly labeled for discovery
#
# LARAVEL-STYLE TARGETS:
#   services-*   - Bulk operations affecting all services
#   service-*    - Individual service operations requiring SERVICE parameter
#
# USAGE EXAMPLES:
#   make service-make SERVICE=ai-analyzer ARGS="--port=8005"
#   make service-build SERVICE=ocr-service
#   make service-start SERVICE=detector-service
#   make service-logs SERVICE=captioner-service
#   make service-shell SERVICE=ocr-service
#   make services-up          # Start all services
#   make services-down        # Stop all services
#
# ============================================================================

# ============================================================================
# BULK SERVICE OPERATIONS
# ============================================================================
# Operations that affect all services in the SERVICES variable
# These are useful for system-wide operations and deployment scenarios

.PHONY: services-build services-up services-down services-logs

services-build: ## Build Docker images for all registered services
	@echo "$(BLUE)Building service images...$(NC)"
	@echo "$(YELLOW)Services to build: $(SERVICES)$(NC)"
	
	# Iterate through all registered services and build their Docker images
	# Exit immediately if any build fails to prevent partial deployments
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Building $$service...$(NC)"; \
		docker compose \
			-f $(SERVICES_DIR)/$$service/docker-compose.yml \
			--env-file $(ENV_FILE) \
			build || exit 1; \
	done
	
	@echo "$(GREEN)✓ All service images built successfully$(NC)"

services-up: infra-up services-build ## Start all microservices (requires infrastructure)
	@echo "$(BLUE)Starting microservices...$(NC)"
	@echo "$(YELLOW)Services to start: $(SERVICES)$(NC)"
	
	# Start all services in dependency order
	# Infrastructure must be running first (handled by infra-up dependency)
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Starting $$service...$(NC)"; \
		docker compose \
			-f $(SERVICES_DIR)/$$service/docker-compose.yml \
			--env-file $(ENV_FILE) \
			up -d || exit 1; \
	done
	
	@echo "$(GREEN)✓ All microservices started successfully$(NC)"
	@echo "$(BLUE)Tip: Use 'make test-services' to verify all services are healthy$(NC)"

services-down: ## Stop all microservices (preserves infrastructure)
	@echo "$(BLUE)Stopping microservices...$(NC)"
	@echo "$(YELLOW)Services to stop: $(SERVICES)$(NC)"
	
	# Stop all services gracefully
	# Use 2>/dev/null to suppress errors for already stopped services
	# Continue with remaining services even if one fails (|| true)
	@for service in $(SERVICES); do \
		echo "$(YELLOW)Stopping $$service...$(NC)"; \
		docker compose \
			-f $(SERVICES_DIR)/$$service/docker-compose.yml \
			--env-file $(ENV_FILE) \
			down 2>/dev/null || true; \
	done
	
	@echo "$(GREEN)✓ All microservices stopped$(NC)"
	@echo "$(YELLOW)Note: Infrastructure services are still running$(NC)"

services-logs: ## Show aggregated logs for all services
	@echo "$(BLUE)Service logs (press Ctrl+C to exit):$(NC)"
	@echo "$(YELLOW)Monitoring logs from: $(SERVICES)$(NC)"
	
	# Start log following for all services in background
	# Each service gets its own background process for parallel log streaming
	@for service in $(SERVICES); do \
		docker compose \
			-f $(SERVICES_DIR)/$$service/docker-compose.yml \
			--env-file $(ENV_FILE) \
			logs --tail=10 -f & \
	done; \
	wait  # Wait for all background processes to complete

# ============================================================================
# INDIVIDUAL SERVICE OPERATIONS
# ============================================================================
# Operations that target a specific service identified by the SERVICE parameter
# These provide fine-grained control over individual service lifecycle

.PHONY: service-logs service-build service-start service-stop service-shell service-make

service-logs: ## Show real-time logs for specific service (usage: make service-logs SERVICE=ocr-service)
	# Validate that SERVICE parameter is provided
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE parameter required$(NC)"; \
		echo "Usage: make service-logs SERVICE=ocr-service"; \
		echo "Available services: $(SERVICES)"; \
		exit 1; \
	fi
	
	# Validate that the service directory exists
	@if [ ! -d "$(SERVICES_DIR)/$(SERVICE)" ]; then \
		echo "$(RED)Error: Service '$(SERVICE)' not found$(NC)"; \
		echo "Service directory $(SERVICES_DIR)/$(SERVICE) does not exist"; \
		echo "Available services: $(SERVICES)"; \
		exit 1; \
	fi
	
	@echo "$(BLUE)Showing logs for $(SERVICE) (press Ctrl+C to exit)...$(NC)"
	
	# Follow logs for the specific service
	# -f flag provides real-time log streaming
	@docker compose \
		-f $(SERVICES_DIR)/$(SERVICE)/docker-compose.yml \
		--env-file $(ENV_FILE) \
		logs -f

service-build: ## Build Docker image for specific service (usage: make service-build SERVICE=ocr-service)
	# Validate SERVICE parameter
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE parameter required$(NC)"; \
		echo "Usage: make service-build SERVICE=ocr-service"; \
		exit 1; \
	fi
	
	# Validate service directory exists
	@if [ ! -d "$(SERVICES_DIR)/$(SERVICE)" ]; then \
		echo "$(RED)Error: Service '$(SERVICE)' not found$(NC)"; \
		echo "Service directory $(SERVICES_DIR)/$(SERVICE) does not exist"; \
		exit 1; \
	fi
	
	@echo "$(BLUE)Building $(SERVICE)...$(NC)"
	
	# Build the Docker image for the specific service
	# This will use the Dockerfile in the service directory
	@docker compose \
		-f $(SERVICES_DIR)/$(SERVICE)/docker-compose.yml \
		--env-file $(ENV_FILE) \
		build
	
	@echo "$(GREEN)✓ $(SERVICE) built successfully$(NC)"

service-start: infra-up ## Start specific service (usage: make service-start SERVICE=ocr-service)
	# Validate SERVICE parameter
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE parameter required$(NC)"; \
		echo "Usage: make service-start SERVICE=ocr-service"; \
		exit 1; \
	fi
	
	# Validate service directory exists
	@if [ ! -d "$(SERVICES_DIR)/$(SERVICE)" ]; then \
		echo "$(RED)Error: Service '$(SERVICE)' not found$(NC)"; \
		echo "Service directory $(SERVICES_DIR)/$(SERVICE) does not exist"; \
		exit 1; \
	fi
	
	@echo "$(BLUE)Starting $(SERVICE)...$(NC)"
	@echo "$(YELLOW)Infrastructure dependency: ensuring infrastructure is running$(NC)"
	
	# Start the service in detached mode
	# Infrastructure dependency is handled by infra-up prerequisite
	@docker compose \
		-f $(SERVICES_DIR)/$(SERVICE)/docker-compose.yml \
		--env-file $(ENV_FILE) \
		up -d
	
	@echo "$(GREEN)✓ $(SERVICE) started successfully$(NC)"
	@echo "$(BLUE)Tip: Use 'make service-logs SERVICE=$(SERVICE)' to monitor logs$(NC)"

service-stop: ## Stop specific service (usage: make service-stop SERVICE=ocr-service)
	# Validate SERVICE parameter
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE parameter required$(NC)"; \
		echo "Usage: make service-stop SERVICE=ocr-service"; \
		exit 1; \
	fi
	
	# Validate service directory exists
	@if [ ! -d "$(SERVICES_DIR)/$(SERVICE)" ]; then \
		echo "$(RED)Error: Service '$(SERVICE)' not found$(NC)"; \
		echo "Service directory $(SERVICES_DIR)/$(SERVICE) does not exist"; \
		exit 1; \
	fi
	
	@echo "$(BLUE)Stopping $(SERVICE)...$(NC)"
	
	# Stop and remove the service containers
	# This preserves volumes and networks
	@docker compose \
		-f $(SERVICES_DIR)/$(SERVICE)/docker-compose.yml \
		--env-file $(ENV_FILE) \
		down
	
	@echo "$(GREEN)✓ $(SERVICE) stopped successfully$(NC)"

service-shell: ## Open interactive shell in service container (usage: make service-shell SERVICE=ocr-service)
	# Validate SERVICE parameter
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE parameter required$(NC)"; \
		echo "Usage: make service-shell SERVICE=ocr-service"; \
		exit 1; \
	fi
	
	@echo "$(BLUE)Opening shell in $(SERVICE) container...$(NC)"
	
	# Find the running container for the service
	# Use docker ps with filter to find containers matching the service name
	@CONTAINER_NAME=$$(docker ps --filter "name=$(SERVICE)" --format "{{.Names}}" | head -1); \
	if [ -z "$$CONTAINER_NAME" ]; then \
		echo "$(RED)Error: $(SERVICE) container not running$(NC)"; \
		echo "Start the service first: make service-start SERVICE=$(SERVICE)"; \
		exit 1; \
	fi; \
	echo "$(YELLOW)Connecting to container: $$CONTAINER_NAME$(NC)"; \
	docker exec -it $$CONTAINER_NAME /bin/bash

service-make: ## Generate new service from template (usage: make service-make SERVICE=my-service)
	# Validate SERVICE parameter
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE parameter required$(NC)"; \
		echo "Usage: make service-make SERVICE=my-service"; \
		echo "$(YELLOW)Optional: ARGS=\"--input=topic --output=topic --port=8005 --batch-size=10\"$(NC)"; \
		exit 1; \
	fi
	
	@echo "$(BLUE)Generating service: $(SERVICE)$(NC)"
	@echo "$(YELLOW)Using template with arguments: $(ARGS)$(NC)"
	
	# Execute the service generation script
	# ARGS variable allows passing custom configuration to the generator
	@./scripts/generate-service.sh $(SERVICE) $(ARGS)
	
	@echo "$(GREEN)✓ Service $(SERVICE) generated successfully$(NC)"
	@echo "$(BLUE)Next steps:$(NC)"
	@echo "  1. Review generated files in $(SERVICES_DIR)/$(SERVICE)/"
	@echo "  2. Customize service implementation as needed"
	@echo "  3. Build and start: make service-build SERVICE=$(SERVICE) && make service-start SERVICE=$(SERVICE)"