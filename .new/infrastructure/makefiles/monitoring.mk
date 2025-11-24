# ============================================================================
# Monitoring and Logging Module - System Observability
# ============================================================================
#
# PURPOSE:
#   Provides comprehensive monitoring, logging, and observability capabilities
#   for the Video RAG system. Enables real-time system monitoring, log
#   aggregation, health checking, and Kafka topic monitoring for operational
#   visibility and debugging.
#
# CORE FUNCTIONALITY:
#   - Real-time container status monitoring and reporting
#   - Centralized log aggregation and streaming
#   - System health monitoring and alerting
#   - Kafka topic monitoring and message inspection
#   - Service-specific log filtering and analysis
#   - Performance monitoring and metrics collection
#
# MONITORING STRATEGY:
#   - Container-level monitoring for resource usage and status
#   - Application-level health checks for service availability
#   - Message-level monitoring for data flow validation
#   - Real-time log streaming for immediate issue detection
#   - Historical log analysis for trend identification
#
# DEPENDENCIES:
#   - Docker containers with proper labeling for discovery
#   - Service health endpoints for status checking
#   - Kafka topics for message monitoring
#   - Python monitoring scripts in tools/monitoring/
#   - Health check scripts in scripts/testing/
#
# LARAVEL-STYLE TARGETS:
#   system-*     - System-wide monitoring operations
#   monitor-*    - Real-time monitoring and streaming operations
#
# USAGE EXAMPLES:
#   make status            # Show container status
#   make logs              # Show all service logs
#   make monitor-logs      # Real-time log monitoring
#   make monitor-topics    # Monitor all Kafka topics
#   make monitor-topic TOPIC=ocr-results # Monitor specific topic
#   make health            # Check system health
#
# ============================================================================

# ============================================================================
# SYSTEM STATUS MONITORING
# ============================================================================
# Provides real-time visibility into container status, resource usage,
# and system health across all Video RAG components

.PHONY: system-status status logs monitor-logs health monitor

system-status: ## Show comprehensive status of all Video RAG containers
	@echo "$(BLUE)Video RAG System Status:$(NC)"
	@echo "$(YELLOW)Checking all containers with Video RAG project label...$(NC)"
	
	# First, try to show containers with the project label for organized output
	# This provides a clean view of only Video RAG related containers
	@docker ps \
		--filter "label=com.docker.compose.project=video-rag" \
		--format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || \
		docker ps \
			--format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | \
			grep -E "(kafka|zookeeper|minio|qdrant|ocr-service|detector-service|captioner-service)" || \
		echo "$(YELLOW)No Video RAG containers are currently running$(NC)"
	
	@echo ""
	@echo "$(BLUE)Container Status Legend:$(NC)"
	@echo "  $(GREEN)Up X minutes$(NC)     - Container is running normally"
	@echo "  $(YELLOW)Restarting$(NC)      - Container is restarting due to issues"
	@echo "  $(RED)Exited$(NC)          - Container has stopped"

# Legacy alias for backward compatibility with existing workflows
status: system-status

logs: ## Show aggregated logs for all running Video RAG services
	@echo "$(BLUE)All service logs (press Ctrl+C to exit):$(NC)"
	@echo "$(YELLOW)Aggregating logs from infrastructure and microservices...$(NC)"
	
	# Start infrastructure log streaming in background
	@docker compose \
		-f $(ROOT_COMPOSE_FILE) \
		--env-file $(ENV_FILE) \
		logs -f &
	
	# Start microservice log streaming
	# This will aggregate logs from all services defined in SERVICES variable
	@make services-logs

monitor-logs: ## Monitor all service logs in real-time with timestamps
	@echo "$(BLUE)Monitoring all service logs in real-time (press Ctrl+C to stop)...$(NC)"
	@echo "$(YELLOW)Streaming logs with timestamps from all Video RAG components...$(NC)"
	
	# Stream logs from the main compose file with timestamps
	# --tail=10 shows last 10 lines from each service for context
	# -f follows log output in real-time
	@docker compose \
		-f $(ROOT_COMPOSE_FILE) \
		logs -f --tail=10

health: ## Check comprehensive health status of all system components
	@echo "$(BLUE)Checking comprehensive system health...$(NC)"
	@echo "$(YELLOW)Running health checks on infrastructure and services...$(NC)"
	
	# Execute the comprehensive health check script
	# This script tests connectivity, service health, and system readiness
	@./scripts/testing/health-check.sh
	
	@echo ""
	@echo "$(BLUE)Health Check Summary:$(NC)"
	@echo "  $(GREEN)✓$(NC) - Component is healthy and responding"
	@echo "  $(RED)✗$(NC) - Component has issues or is not responding"
	@echo "  $(YELLOW)?$(NC) - Component status is unknown or partially healthy"

monitor: ## Start continuous service monitoring dashboard
	@echo "$(BLUE)Starting continuous service monitor (press Ctrl+C to stop)...$(NC)"
	@echo "$(YELLOW)Launching real-time monitoring dashboard...$(NC)"
	
	# Launch the Python-based monitoring dashboard
	# This provides real-time metrics, alerts, and system overview
	@python3 tools/monitoring/service-monitor.py

# ============================================================================
# KAFKA TOPIC MONITORING
# ============================================================================
# Specialized monitoring for Kafka message flows and topic activity
# Essential for debugging data processing pipelines

.PHONY: monitor-topics monitor-topic

monitor-topics: ## Monitor all Kafka result topics for message activity
	@echo "$(BLUE)Monitoring all Kafka topics (press Ctrl+C to stop)...$(NC)"
	@echo "$(YELLOW)Watching message flow across all Video RAG topics...$(NC)"
	@echo ""
	@echo "$(BLUE)Topics being monitored:$(NC)"
	@echo "  - raw-frames: Input video frames"
	@echo "  - ocr-results: OCR processing results"
	@echo "  - detection-results: Object detection results"
	@echo "  - caption-results: Image captioning results"
	@echo ""
	
	# Run the comprehensive topic monitoring script
	# --all flag monitors all Video RAG related topics simultaneously
	@python3 scripts/testing/test-consumer.py --all

monitor-topic: ## Monitor specific Kafka topic (usage: make monitor-topic TOPIC=ocr-results)
	# Validate that TOPIC parameter is provided
	@if [ -z "$(TOPIC)" ]; then \
		echo "$(RED)Error: TOPIC parameter required$(NC)"; \
		echo "Usage: make monitor-topic TOPIC=ocr-results"; \
		echo ""; \
		echo "$(YELLOW)Available topics:$(NC)"; \
		echo "  - raw-frames: Input video frames"; \
		echo "  - ocr-results: OCR processing results"; \
		echo "  - detection-results: Object detection results"; \
		echo "  - caption-results: Image captioning results"; \
		exit 1; \
	fi
	
	@echo "$(BLUE)Monitoring Kafka topic: $(TOPIC)$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop monitoring...$(NC)"
	@echo ""
	@echo "$(BLUE)Message format will show:$(NC)"
	@echo "  - Timestamp: When message was received"
	@echo "  - Partition: Kafka partition number"
	@echo "  - Offset: Message offset in partition"
	@echo "  - Key: Message key (if present)"
	@echo "  - Value: Message content"
	@echo ""
	
	# Run topic-specific monitoring
	# --topic flag specifies which topic to monitor
	@python3 scripts/testing/test-consumer.py --topic $(TOPIC)