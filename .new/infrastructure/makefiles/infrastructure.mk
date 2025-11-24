# ============================================================================
# Infrastructure Management Module - Kafka, Qdrant, MinIO, Networking
# ============================================================================
#
# PURPOSE:
#   Manages core infrastructure services required by the Video RAG system.
#   Handles Docker networking, service orchestration, and health monitoring
#   for Kafka (message streaming), Qdrant (vector database), and MinIO (object storage).
#
# CORE FUNCTIONALITY:
#   - Docker network creation and management for service isolation
#   - Infrastructure service lifecycle management (start/stop/restart)
#   - Health checking and status monitoring for all infrastructure components
#   - Centralized logging and troubleshooting for infrastructure services
#   - OrbStack domain configuration for seamless local development
#
# DEPENDENCIES:
#   - Docker 20.10+ with Compose V2
#   - OrbStack or Docker Desktop for automatic domain resolution
#   - infrastructure/docker compose.yml file with service definitions
#   - infrastructure/.env file with environment configuration
#
# LARAVEL-STYLE TARGETS:
#   network-*    - Docker network operations (create, remove)
#   infra-*      - Infrastructure service operations (up, down, health, logs)
#
# USAGE EXAMPLES:
#   make network-create     # Create isolated Docker network
#   make infra-up           # Start all infrastructure services
#   make infra-health       # Check health of all infrastructure components
#   make infra-logs         # Monitor infrastructure service logs
#   make infra-down         # Stop all infrastructure services
#   make network-remove     # Clean up Docker network
#
# ============================================================================

# ============================================================================
# DOCKER NETWORK MANAGEMENT
# ============================================================================
# Manages isolated Docker network for Video RAG services to ensure
# proper service discovery and communication isolation

.PHONY: network-create network-remove

network-create: ## Create Docker network for Video RAG services
	@echo "$(BLUE)Creating Docker network for Video RAG services...$(NC)"
	# Create custom bridge network with automatic DNS resolution
	# This enables services to communicate using service names instead of IP addresses
	@docker network create video-rag-network 2>/dev/null || echo "$(YELLOW)Network 'video-rag-network' already exists$(NC)"
	@echo "$(GREEN)✓ Docker network ready for service communication$(NC)"

network-remove: ## Remove Docker network (cleanup operation)
	@echo "$(BLUE)Removing Docker network...$(NC)"
	# Remove the custom network - this will fail if containers are still attached
	# Use 2>/dev/null to suppress error messages for non-existent networks
	@docker network rm video-rag-network 2>/dev/null || echo "$(YELLOW)Network 'video-rag-network' doesn't exist or is in use$(NC)"
	@echo "$(GREEN)✓ Docker network cleanup completed$(NC)"

# ============================================================================
# INFRASTRUCTURE SERVICE MANAGEMENT
# ============================================================================
# Orchestrates the core infrastructure services that support the Video RAG
# microservices ecosystem: Kafka for messaging, Qdrant for vector storage,
# and MinIO for object storage

.PHONY: infra-up infra-down infra-logs infra-health

infra-up: check-requirements network-create ## Start all infrastructure services (Kafka, Qdrant, MinIO)
	@echo "$(BLUE)Starting infrastructure services...$(NC)"
	@echo "$(YELLOW)This will start: Kafka, Zookeeper, Qdrant, MinIO, and Kafka UI$(NC)"
	
	# Start infrastructure services using Docker Compose
	# COMPOSE_PROJECT_NAME ensures consistent naming across environments
	# -d flag runs services in detached mode (background)
	@COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) docker compose \
		$(foreach file,$(INFRA_COMPOSE_FILES),-f $(file)) \
		--env-file $(ENV_FILE) \
		up -d
	
	@echo "$(GREEN)✓ Infrastructure services started successfully$(NC)"
	@echo ""
	@echo "$(YELLOW)Access points (OrbStack automatic domains):$(NC)"
	@echo "  - Kafka UI:      http://kafka-ui.video-rag.orb.local"
	@echo "  - MinIO Console: http://minio.video-rag.orb.local:9001"
	@echo "  - MinIO API:     http://minio.video-rag.orb.local:9000"
	@echo "  - Qdrant API:    http://qdrant.video-rag.orb.local"
	@echo "  - Kafka Broker:  kafka.video-rag.orb.local:9093"
	@echo ""
	@echo "$(BLUE)Tip: Use 'make infra-health' to verify all services are running$(NC)"

infra-down: ## Stop all infrastructure services
	@echo "$(BLUE)Stopping infrastructure services...$(NC)"
	@echo "$(YELLOW)This will stop: Kafka, Zookeeper, Qdrant, MinIO, and Kafka UI$(NC)"
	
	# Stop and remove containers, but preserve volumes for data persistence
	# Using the same compose file and environment as startup
	@docker compose \
		$(foreach file,$(INFRA_COMPOSE_FILES),-f $(file)) \
		--env-file $(ENV_FILE) \
		down
	
	@echo "$(GREEN)✓ Infrastructure services stopped$(NC)"
	@echo "$(YELLOW)Note: Data volumes are preserved. Use 'make clean' to remove all data$(NC)"

infra-logs: ## Show real-time logs for all infrastructure services
	@echo "$(BLUE)Showing infrastructure service logs (press Ctrl+C to exit)...$(NC)"
	@echo "$(YELLOW)Monitoring: Kafka, Zookeeper, Qdrant, MinIO, Kafka UI$(NC)"
	
	# Follow logs from all infrastructure services
	# -f flag follows log output in real-time
	@docker compose \
		$(foreach file,$(INFRA_COMPOSE_FILES),-f $(file)) \
		--env-file $(ENV_FILE) \
		logs -f

infra-health: ## Check health status of all infrastructure services
	@echo "$(BLUE)Checking infrastructure health...$(NC)"
	@echo "$(YELLOW)Testing connectivity to: Kafka, Qdrant, MinIO$(NC)"
	
	# Run comprehensive health check script
	# Limit output to prevent overwhelming the terminal
	# The health-check.sh script tests each service individually
	@./scripts/testing/health-check.sh | head -20
	
	@echo ""
	@echo "$(BLUE)For detailed health information, run: ./scripts/testing/health-check.sh$(NC)"