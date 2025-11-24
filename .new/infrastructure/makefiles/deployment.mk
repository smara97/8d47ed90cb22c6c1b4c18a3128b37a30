# ============================================================================
# Environment Deployment Module - Multi-Environment Orchestration
# ============================================================================
#
# PURPOSE:
#   Manages deployment and lifecycle operations across multiple environments
#   (development, staging, production) with environment-specific configurations,
#   resource limits, and operational procedures.
#
# CORE FUNCTIONALITY:
#   - Environment-specific deployment with appropriate configurations
#   - System lifecycle management (start, stop, restart, cleanup)
#   - Environment isolation and configuration management
#   - Resource optimization per environment
#   - Graceful shutdown and cleanup procedures
#
# ENVIRONMENT STRATEGY:
#   - Development: Optimized for rapid iteration and debugging
#   - Staging: Production-like environment for integration testing
#   - Production: Optimized for performance, reliability, and monitoring
#
# DEPENDENCIES:
#   - Environment-specific Docker Compose override files
#   - Environment-specific .env configuration files
#   - Infrastructure services (managed by infrastructure.mk)
#   - Service definitions (managed by services.mk)
#
# LARAVEL-STYLE TARGETS:
#   system-*     - System-wide operations (up, down, status)
#   deploy-*     - Environment-specific deployment operations
#
# USAGE EXAMPLES:
#   make system-up           # Start development environment
#   make deploy-staging      # Deploy to staging environment
#   make deploy-prod         # Deploy to production environment
#   make deploy-down-staging # Stop staging environment
#   make clean               # Complete system cleanup
#
# ============================================================================

# ============================================================================
# SYSTEM LIFECYCLE MANAGEMENT
# ============================================================================
# Core system operations that manage the complete Video RAG system
# These operations coordinate infrastructure and services together

.PHONY: system-up system-down up down restart clean

system-up: ## Start complete Video RAG system with development configuration
	@echo "$(BLUE)Starting Video RAG system (development environment)...$(NC)"
	@echo "$(YELLOW)This will start infrastructure + all microservices$(NC)"
	
	# Start the complete system using development configuration
	# Uses main compose file with include directive for all services
	# COMPOSE_PROJECT_NAME ensures consistent container naming
	@COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) docker compose \
		-f $(ROOT_COMPOSE_FILE) \
		--env-file $(ENV_FILE) \
		up -d
	
	@echo "$(GREEN)✓ Video RAG system is running (development)$(NC)"
	@echo ""
	
	# Show system status after startup
	@make system-status
	
	@echo ""
	@echo "$(BLUE)Development environment ready!$(NC)"
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  - Check status: make status"
	@echo "  - View logs: make logs"
	@echo "  - Run tests: make test-validate"

# Legacy alias for backward compatibility with existing workflows
up: system-up

system-down: ## Stop complete Video RAG system (development environment)
	@echo "$(BLUE)Stopping Video RAG system...$(NC)"
	@echo "$(YELLOW)This will stop all services and infrastructure$(NC)"
	
	# Stop the complete system using the same configuration as startup
	# Use 2>/dev/null to suppress errors for already stopped containers
	@docker compose \
		-f $(ROOT_COMPOSE_FILE) \
		--env-file $(ENV_FILE) \
		down 2>/dev/null || true
	
	@echo "$(GREEN)✓ Video RAG system stopped$(NC)"
	@echo "$(YELLOW)Note: Data volumes are preserved. Use 'make clean' to remove all data$(NC)"

# Legacy alias for backward compatibility
down: system-down

# ============================================================================
# ENVIRONMENT-SPECIFIC DEPLOYMENT
# ============================================================================
# Deployment operations for different environments with appropriate configurations
# Each environment has optimized settings for its specific use case

.PHONY: deploy-dev deploy-staging deploy-prod

deploy-dev: ## Deploy to development environment (alias for system-up)
	@echo "$(BLUE)Deploying to development environment...$(NC)"
	@echo "$(YELLOW)Using development-optimized configuration$(NC)"
	
	# Development deployment is the same as system-up
	# Optimized for rapid development and debugging
	@make system-up

deploy-staging: ## Deploy to staging environment with production-like configuration
	@echo "$(BLUE)Deploying to staging environment...$(NC)"
	@echo "$(YELLOW)Using staging configuration with production-like settings$(NC)"
	
	# Start system with staging-specific configuration
	# Uses staging overrides for production-like resource limits and monitoring
	@COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) docker compose \
		-f $(ROOT_COMPOSE_FILE) \
		-f $(STAGING_OVERRIDE) \
		--env-file $(CONFIGS_DIR)/staging/.env \
		up -d
	
	@echo "$(GREEN)✓ Video RAG system deployed to staging$(NC)"
	@echo ""
	
	# Show system status after deployment
	@make system-status
	
	@echo ""
	@echo "$(BLUE)Staging environment ready!$(NC)"
	@echo "$(YELLOW)Recommended next steps:$(NC)"
	@echo "  - Validate deployment: make test-validate"
	@echo "  - Monitor system: make monitor-logs"
	@echo "  - Check performance: make test-pipeline"

deploy-prod: ## Deploy to production environment with optimized configuration
	@echo "$(BLUE)Deploying to production environment...$(NC)"
	@echo "$(YELLOW)Using production-optimized configuration$(NC)"
	@echo "$(RED)WARNING: This will deploy to production!$(NC)"
	
	# Production deployment with production-specific configuration
	# Uses production overrides for maximum performance and reliability
	@COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) docker compose \
		-f $(ROOT_COMPOSE_FILE) \
		-f $(PROD_OVERRIDE) \
		--env-file $(CONFIGS_DIR)/production/.env \
		up -d
	
	@echo "$(GREEN)✓ Video RAG system deployed to production$(NC)"
	@echo ""
	
	# Show system status after deployment
	@make system-status
	
	@echo ""
	@echo "$(GREEN)Production environment is live!$(NC)"
	@echo "$(YELLOW)Critical next steps:$(NC)"
	@echo "  - Validate deployment: make test-validate"
	@echo "  - Monitor system health: make health"
	@echo "  - Set up monitoring: make monitor-logs"

# ============================================================================
# ENVIRONMENT SHUTDOWN OPERATIONS
# ============================================================================
# Graceful shutdown operations for specific environments

.PHONY: deploy-down-staging deploy-down-prod

deploy-down-staging: ## Stop staging environment gracefully
	@echo "$(BLUE)Stopping Video RAG system (staging environment)...$(NC)"
	@echo "$(YELLOW)Gracefully shutting down staging deployment$(NC)"
	
	# Stop staging environment using staging-specific configuration
	@docker compose \
		-f $(ROOT_COMPOSE_FILE) \
		-f $(STAGING_OVERRIDE) \
		--env-file $(CONFIGS_DIR)/staging/.env \
		down 2>/dev/null || true
	
	@echo "$(GREEN)✓ Staging environment stopped$(NC)"

deploy-down-prod: ## Stop production environment gracefully
	@echo "$(BLUE)Stopping Video RAG system (production environment)...$(NC)"
	@echo "$(RED)WARNING: This will stop the production environment!$(NC)"
	@echo "$(YELLOW)Gracefully shutting down production deployment$(NC)"
	
	# Stop production environment using production-specific configuration
	@docker compose \
		-f $(ROOT_COMPOSE_FILE) \
		-f $(PROD_OVERRIDE) \
		--env-file $(CONFIGS_DIR)/production/.env \
		down 2>/dev/null || true
	
	@echo "$(GREEN)✓ Production environment stopped$(NC)"

# ============================================================================
# CUSTOM DEPLOYMENT OPERATIONS
# ============================================================================
# Advanced deployment operations for custom scenarios

.PHONY: deploy-custom

deploy-custom: ## Deploy to custom environment (usage: make deploy-custom ENV=staging VERSION=v1.0.0)
	@echo "$(BLUE)Deploying to custom environment: $(ENV)$(NC)"
	@echo "$(YELLOW)Version: $(VERSION)$(NC)"
	
	# Execute custom deployment script with environment and version parameters
	# This allows for advanced deployment scenarios and CI/CD integration
	@./scripts/deployment/deploy-environment.sh $(ENV) $(VERSION)
	
	@echo "$(GREEN)✓ Custom deployment completed$(NC)"

# ============================================================================
# SYSTEM MAINTENANCE OPERATIONS
# ============================================================================
# Operations for system maintenance, cleanup, and lifecycle management

restart: down up ## Restart the complete system (development environment)
	@echo "$(GREEN)✓ System restart completed$(NC)"

clean: down ## Stop everything and remove all data (DESTRUCTIVE OPERATION)
	@echo "$(BLUE)Cleaning up all system data...$(NC)"
	@echo "$(RED)WARNING: This will remove all data volumes!$(NC)"
	
	# Stop and remove all containers, networks, and volumes
	# This is a destructive operation that removes all persistent data
	@docker compose \
		-f $(ROOT_COMPOSE_FILE) \
		--env-file $(ENV_FILE) \
		down -v 2>/dev/null || true
	
	# Remove unused Docker resources (images, containers, networks)
	@docker system prune -f
	
	# Remove the custom Docker network
	@make network-remove
	
	@echo "$(GREEN)✓ Complete cleanup finished$(NC)"
	@echo "$(YELLOW)All data has been removed. Use 'make up' to start fresh.$(NC)"