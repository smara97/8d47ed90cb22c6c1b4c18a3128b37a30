# ============================================================================
# Development Utilities Module - Helper Functions and System Setup
# ============================================================================
#
# PURPOSE:
#   Provides essential development utilities, system setup functions, and
#   informational commands that support the Video RAG development workflow.
#   Includes system requirements validation, environment setup, and system
#   information display.
#
# CORE FUNCTIONALITY:
#   - System requirements validation and compatibility checking
#   - Development environment setup and dependency installation
#   - System information display and configuration overview
#   - Access point documentation and service discovery
#   - Development workflow shortcuts and aliases
#
# UTILITY CATEGORIES:
#   - Requirements: Docker, Docker Compose, and tool version validation
#   - Setup: Automated development environment configuration
#   - Information: System status, configuration, and access points
#   - Shortcuts: Common development workflow aliases
#
# DEPENDENCIES:
#   - Docker 20.10+ with Compose V2 support
#   - Bash 4.0+ for script execution
#   - Setup scripts in scripts/setup/ directory
#   - System configuration files and environment variables
#
# LARAVEL-STYLE TARGETS:
#   check-*      - System validation and requirement checking
#   setup        - Environment setup and configuration
#   info         - System information and documentation
#   all          - Convenience aliases and shortcuts
#
# USAGE EXAMPLES:
#   make check-requirements  # Validate system requirements
#   make setup              # Setup development environment
#   make info               # Show system information
#   make all                # Shortcut for 'make up'
#
# ============================================================================

# ============================================================================
# SYSTEM REQUIREMENTS VALIDATION
# ============================================================================
# Validates that all required tools and versions are available for
# Video RAG development and deployment

.PHONY: check-requirements

check-requirements: ## Check and validate all system requirements
	@echo "$(BLUE)Checking Video RAG system requirements...$(NC)"
	@echo "$(YELLOW)Validating required tools and versions...$(NC)"
	@echo ""
	
	# Check Docker installation and version
	@echo "$(BLUE)Checking Docker installation...$(NC)"
	@command -v docker >/dev/null 2>&1 || { \
		echo "$(RED)Error: Docker is not installed$(NC)"; \
		echo "Please install Docker 20.10+ from https://docker.com"; \
		exit 1; \
	}
	
	# Check Docker Compose installation
	@echo "$(BLUE)Checking Docker Compose installation...$(NC)"
	@command -v docker compose >/dev/null 2>&1 || { \
		echo "$(RED)Error: Docker Compose is not installed$(NC)"; \
		echo "Please install Docker Compose V2"; \
		exit 1; \
	}
	
	# Validate Docker version (20.10+ required)
	@echo "$(BLUE)Validating Docker version...$(NC)"
	@docker --version | grep -E "20\.|2[1-9]\." >/dev/null || { \
		echo "$(RED)Error: Docker 20.10+ is required$(NC)"; \
		echo "Current version: $$(docker --version)"; \
		echo "Please upgrade Docker to version 20.10 or higher"; \
		exit 1; \
	}
	
	# Validate Docker Compose version (V2 required)
	@echo "$(BLUE)Validating Docker Compose version...$(NC)"
	@docker compose version >/dev/null 2>&1 || { \
		echo "$(RED)Error: Docker Compose 2.0+ is required$(NC)"; \
		echo "Please upgrade to Docker Compose V2"; \
		exit 1; \
	}
	
	# Check Docker daemon status
	@echo "$(BLUE)Checking Docker daemon status...$(NC)"
	@docker info >/dev/null 2>&1 || { \
		echo "$(RED)Error: Docker daemon is not running$(NC)"; \
		echo "Please start Docker Desktop or the Docker daemon"; \
		exit 1; \
	}
	
	# Optional tool checks (non-blocking)
	@echo "$(BLUE)Checking optional tools...$(NC)"
	@command -v curl >/dev/null 2>&1 && \
		echo "$(GREEN)✓ curl is available$(NC)" || \
		echo "$(YELLOW)⚠ curl not found (recommended for health checks)$(NC)"
	
	@command -v python3 >/dev/null 2>&1 && \
		echo "$(GREEN)✓ Python 3 is available$(NC)" || \
		echo "$(YELLOW)⚠ Python 3 not found (required for testing scripts)$(NC)"
	
	@command -v jq >/dev/null 2>&1 && \
		echo "$(GREEN)✓ jq is available$(NC)" || \
		echo "$(YELLOW)⚠ jq not found (optional for JSON processing)$(NC)"
	
	@echo ""
	@echo "$(GREEN)✓ All required system requirements are satisfied$(NC)"
	@echo "$(BLUE)System is ready for Video RAG development!$(NC)"

# ============================================================================
# DEVELOPMENT ENVIRONMENT SETUP
# ============================================================================
# Automated setup and configuration of the development environment

.PHONY: setup

setup: ## Setup and configure development environment
	@echo "$(BLUE)Setting up Video RAG development environment...$(NC)"
	@echo "$(YELLOW)This will install dependencies and configure the environment$(NC)"
	@echo ""
	
	# Ensure system requirements are met before setup
	@make check-requirements
	@echo ""
	
	# Execute the development setup script
	# This script handles dependency installation, configuration, and setup
	@echo "$(BLUE)Running development setup script...$(NC)"
	@./scripts/setup/install-dependencies.sh
	
	@echo ""
	@echo "$(GREEN)✓ Development environment setup completed$(NC)"
	@echo ""
	@echo "$(BLUE)Next steps:$(NC)"
	@echo "  1. Start the system: $(YELLOW)make up$(NC)"
	@echo "  2. Check status: $(YELLOW)make status$(NC)"
	@echo "  3. Run tests: $(YELLOW)make test-validate$(NC)"
	@echo "  4. View logs: $(YELLOW)make logs$(NC)"

# ============================================================================
# SYSTEM INFORMATION AND DOCUMENTATION
# ============================================================================
# Displays comprehensive system information, configuration, and access points

.PHONY: info

info: ## Show comprehensive Video RAG system information
	@echo "$(BLUE)============================================================================$(NC)"
	@echo "$(BLUE)Video RAG System Information$(NC)"
	@echo "$(BLUE)============================================================================$(NC)"
	@echo ""
	
	# Project configuration information
	@echo "$(GREEN)Project Configuration:$(NC)"
	@echo "  Project Name:     $(PROJECT_NAME)"
	@echo "  Compose Project:  $(COMPOSE_PROJECT_NAME)"
	@echo "  Services:         $(SERVICES)"
	@echo "  Main Compose:     $(ROOT_COMPOSE_FILE)"
	@echo "  Infrastructure:   $(INFRA_COMPOSE_FILE)"
	@echo "  Environment:      $(ENV_FILE)"
	@echo ""
	
	# Access points and service URLs
	@echo "$(GREEN)Access Points (OrbStack automatic domains):$(NC)"
	@echo "  $(YELLOW)Infrastructure Services:$(NC)"
	@echo "    - Kafka UI:      http://kafka-ui.video-rag.orb.local"
	@echo "    - MinIO Console: http://minio.video-rag.orb.local:9001"
	@echo "    - MinIO API:     http://minio.video-rag.orb.local:9000"
	@echo "    - Qdrant API:    http://qdrant.video-rag.orb.local"
	@echo "    - Kafka Broker:  kafka.video-rag.orb.local:9093"
	@echo ""
	@echo "  $(YELLOW)Microservices (localhost):$(NC)"
	@echo "    - OCR Service:   http://localhost:8001/health"
	@echo "    - Detector:      http://localhost:8002/health"
	@echo "    - Captioner:     http://localhost:8003/health"
	@echo "    - Aggregator:    http://localhost:8004/health"
	@echo ""
	
	# Default credentials and configuration
	@echo "$(GREEN)Default Credentials:$(NC)"
	@echo "  MinIO Console:    minioadmin / minioadmin"
	@echo "  Kafka UI:         No authentication required"
	@echo "  Qdrant API:       No authentication required"
	@echo ""
	
	# Directory structure information
	@echo "$(GREEN)Directory Structure:$(NC)"
	@echo "  Services:         $(SERVICES_DIR)/"
	@echo "  Configurations:   $(CONFIGS_DIR)/"
	@echo "  Infrastructure:   infrastructure/"
	@echo "  Scripts:          scripts/"
	@echo "  Tests:            tests/"
	@echo "  Documentation:    .docs/"
	@echo ""
	
	# Environment information
	@echo "$(GREEN)Environment Configurations:$(NC)"
	@echo "  Development:      $(DEV_OVERRIDE)"
	@echo "  Staging:          $(STAGING_OVERRIDE)"
	@echo "  Production:       $(PROD_OVERRIDE)"
	@echo ""
	
	# Quick start commands
	@echo "$(GREEN)Quick Start Commands:$(NC)"
	@echo "  Start system:     $(YELLOW)make up$(NC)"
	@echo "  Check status:     $(YELLOW)make status$(NC)"
	@echo "  View logs:        $(YELLOW)make logs$(NC)"
	@echo "  Run tests:        $(YELLOW)make test-validate$(NC)"
	@echo "  Stop system:      $(YELLOW)make down$(NC)"
	@echo "  Get help:         $(YELLOW)make help$(NC)"
	@echo ""

# ============================================================================
# CONVENIENCE ALIASES AND SHORTCUTS
# ============================================================================
# Common shortcuts and aliases for development workflow efficiency

.PHONY: all

all: up ## Convenience alias for 'make up' command
	@echo "$(GREEN)✓ System started using 'all' alias$(NC)"
	@echo "$(BLUE)Tip: 'make all' is equivalent to 'make up'$(NC)"