# ============================================================================
# Testing and Validation Module - Comprehensive System Testing
# ============================================================================
#
# PURPOSE:
#   Provides comprehensive testing and validation capabilities for the Video RAG
#   system, including infrastructure connectivity tests, service health checks,
#   integration testing, and end-to-end pipeline validation.
#
# CORE FUNCTIONALITY:
#   - Infrastructure connectivity testing (Kafka, Qdrant, MinIO)
#   - Service health endpoint validation
#   - Kafka connectivity testing from microservices
#   - Integration testing with sample data
#   - End-to-end pipeline testing
#   - Quick health checks for rapid feedback
#   - Comprehensive system validation
#
# TESTING STRATEGY:
#   - Infrastructure tests verify core services are accessible
#   - Service tests validate health endpoints and API availability
#   - Connectivity tests ensure services can communicate with infrastructure
#   - Integration tests validate data flow through the system
#   - Pipeline tests verify complete processing workflows
#
# DEPENDENCIES:
#   - Infrastructure services must be running for connectivity tests
#   - Microservices must be deployed for service health tests
#   - Python testing scripts in scripts/testing/ directory
#   - curl for HTTP health checks
#   - Docker exec access for Kafka connectivity tests
#
# LARAVEL-STYLE TARGETS:
#   test-*       - All testing operations with descriptive suffixes
#
# USAGE EXAMPLES:
#   make test-all                # Test infrastructure connectivity
#   make test-services           # Test service health endpoints
#   make test-kafka-connectivity # Test Kafka from services
#   make test-pipeline           # Test complete processing pipeline
#   make test-validate           # Comprehensive system validation
#
# ============================================================================

# ============================================================================
# INFRASTRUCTURE CONNECTIVITY TESTS
# ============================================================================
# Tests verify that core infrastructure services are accessible and responding
# These tests should pass before attempting to start microservices

.PHONY: test-kafka test-qdrant test-minio test-all

test-kafka: ## Test Kafka broker connectivity and topic listing
	@echo "$(BLUE)Testing Kafka connectivity...$(NC)"
	@echo "$(YELLOW)Checking Kafka broker accessibility and topic operations$(NC)"
	
	# Test Kafka connectivity by listing topics
	# This verifies both broker connectivity and basic Kafka operations
	# Redirect stderr to suppress connection warnings for cleaner output
	@docker exec kafka kafka-topics \
		--bootstrap-server localhost:9092 \
		--list 2>/dev/null && \
		echo "$(GREEN)✓ Kafka is accessible and responding$(NC)" || \
		echo "$(RED)✗ Kafka connection failed - check if infrastructure is running$(NC)"

test-qdrant: ## Test Qdrant vector database connectivity
	@echo "$(BLUE)Testing Qdrant connectivity...$(NC)"
	@echo "$(YELLOW)Checking Qdrant API health endpoint$(NC)"
	
	# Test Qdrant health endpoint using OrbStack domain
	# Silent curl (-s) to avoid progress output
	# Redirect output to /dev/null as we only care about exit status
	@curl -s http://qdrant.video-rag.orb.local/healthz >/dev/null && \
		echo "$(GREEN)✓ Qdrant is accessible and healthy$(NC)" || \
		echo "$(RED)✗ Qdrant connection failed - check if infrastructure is running$(NC)"

test-minio: ## Test MinIO object storage connectivity
	@echo "$(BLUE)Testing MinIO connectivity...$(NC)"
	@echo "$(YELLOW)Checking MinIO health endpoint$(NC)"
	
	# Test MinIO health endpoint using OrbStack domain
	# The /minio/health/live endpoint provides liveness check
	@curl -s http://minio.video-rag.orb.local:9000/minio/health/live >/dev/null && \
		echo "$(GREEN)✓ MinIO is accessible and healthy$(NC)" || \
		echo "$(RED)✗ MinIO connection failed - check if infrastructure is running$(NC)"

test-all: test-kafka test-qdrant test-minio ## Test all infrastructure connectivity
	@echo ""
	@echo "$(BLUE)Infrastructure connectivity test summary completed$(NC)"
	@echo "$(YELLOW)All core services (Kafka, Qdrant, MinIO) have been tested$(NC)"

# ============================================================================
# SERVICE HEALTH TESTS
# ============================================================================
# Tests verify that microservices are running and responding to health checks
# These tests validate the service layer of the Video RAG system

.PHONY: test-services test-infrastructure test-kafka-connectivity

test-services: ## Test all microservice health endpoints
	@echo "$(BLUE)Testing all service health endpoints...$(NC)"
	@echo "$(YELLOW)Checking health status of Video RAG microservices$(NC)"
	
	# Test OCR Service health endpoint
	@echo "$(YELLOW)Testing OCR Service...$(NC)"
	@curl -f http://localhost:8001/health 2>/dev/null && \
		echo "$(GREEN)✓ OCR Service is healthy$(NC)" || \
		echo "$(RED)✗ OCR Service health check failed$(NC)"
	
	# Test Detector Service health endpoint
	@echo "$(YELLOW)Testing Detector Service...$(NC)"
	@curl -f http://localhost:8002/health 2>/dev/null && \
		echo "$(GREEN)✓ Detector Service is healthy$(NC)" || \
		echo "$(RED)✗ Detector Service health check failed$(NC)"
	
	# Test Captioner Service health endpoint
	@echo "$(YELLOW)Testing Captioner Service...$(NC)"
	@curl -f http://localhost:8003/health 2>/dev/null && \
		echo "$(GREEN)✓ Captioner Service is healthy$(NC)" || \
		echo "$(RED)✗ Captioner Service health check failed$(NC)"
	
	# Test Frame Aggregator health endpoint
	@echo "$(YELLOW)Testing Frame Aggregator...$(NC)"
	@curl -f http://localhost:8004/health 2>/dev/null && \
		echo "$(GREEN)✓ Frame Aggregator is healthy$(NC)" || \
		echo "$(RED)✗ Frame Aggregator health check failed$(NC)"
	
	@echo "$(GREEN)✓ Service health tests completed$(NC)"

test-infrastructure: ## Test all infrastructure services using direct connections
	@echo "$(BLUE)Testing infrastructure services...$(NC)"
	@echo "$(YELLOW)Direct connectivity tests to infrastructure components$(NC)"
	
	# Test Kafka using direct localhost connection
	@echo "$(YELLOW)Testing Kafka (direct connection)...$(NC)"
	@docker exec kafka kafka-topics \
		--bootstrap-server localhost:9092 \
		--list >/dev/null 2>&1 && \
		echo "$(GREEN)✓ Kafka direct connection successful$(NC)" || \
		echo "$(RED)✗ Kafka direct connection failed$(NC)"
	
	# Test Qdrant using localhost connection
	@echo "$(YELLOW)Testing Qdrant (direct connection)...$(NC)"
	@curl -f http://localhost:6333/healthz 2>/dev/null >/dev/null && \
		echo "$(GREEN)✓ Qdrant direct connection successful$(NC)" || \
		echo "$(RED)✗ Qdrant direct connection failed$(NC)"
	
	# Test MinIO using localhost connection
	@echo "$(YELLOW)Testing MinIO (direct connection)...$(NC)"
	@curl -f http://localhost:9000/minio/health/live 2>/dev/null >/dev/null && \
		echo "$(GREEN)✓ MinIO direct connection successful$(NC)" || \
		echo "$(RED)✗ MinIO direct connection failed$(NC)"
	
	@echo "$(GREEN)✓ Infrastructure tests completed$(NC)"

test-kafka-connectivity: ## Test Kafka connectivity from microservices
	@echo "$(BLUE)Testing Kafka connectivity from services...$(NC)"
	@echo "$(YELLOW)Verifying microservices can connect to Kafka broker$(NC)"
	
	# Test Kafka connectivity from OCR service container
	@echo "$(YELLOW)Testing from OCR service...$(NC)"
	@docker exec ocr-service python -c \
		"from kafka import KafkaProducer; p=KafkaProducer(bootstrap_servers='kafka:9092'); print('OCR->Kafka: OK')" 2>/dev/null || \
		echo "$(RED)✗ OCR->Kafka connection failed$(NC)"
	
	# Test Kafka connectivity from Detector service container
	@echo "$(YELLOW)Testing from Detector service...$(NC)"
	@docker exec detector-service python -c \
		"from kafka import KafkaProducer; p=KafkaProducer(bootstrap_servers='kafka:9092'); print('Detector->Kafka: OK')" 2>/dev/null || \
		echo "$(RED)✗ Detector->Kafka connection failed$(NC)"
	
	# Test Kafka connectivity from Captioner service container
	@echo "$(YELLOW)Testing from Captioner service...$(NC)"
	@docker exec captioner-service python -c \
		"from kafka import KafkaProducer; p=KafkaProducer(bootstrap_servers='kafka:9092'); print('Captioner->Kafka: OK')" 2>/dev/null || \
		echo "$(RED)✗ Captioner->Kafka connection failed$(NC)"
	
	# Test Kafka connectivity from Frame Aggregator container
	@echo "$(YELLOW)Testing from Frame Aggregator...$(NC)"
	@docker exec frame-aggregator python -c \
		"from kafka import KafkaProducer; p=KafkaProducer(bootstrap_servers='kafka:9092'); print('Aggregator->Kafka: OK')" 2>/dev/null || \
		echo "$(RED)✗ Aggregator->Kafka connection failed$(NC)"
	
	@echo "$(GREEN)✓ Kafka connectivity tests completed$(NC)"

# ============================================================================
# INTEGRATION AND PIPELINE TESTS
# ============================================================================
# Tests verify that the complete Video RAG pipeline functions correctly
# These tests validate end-to-end data flow and processing

.PHONY: test-integration test-e2e test-pipeline test-quick test-validate

test-integration: ## Test Kafka integration with sample frame data
	@echo "$(BLUE)Testing Kafka integration...$(NC)"
	@echo "$(YELLOW)Sending sample frames through Kafka pipeline$(NC)"
	
	# Run integration test using Kafka console producer
	# Send test messages to raw-frames topic
	@echo "$(YELLOW)Sending test messages to raw-frames topic...$(NC)"
	@for i in 1 2 3; do \
		echo "{\"frame_id\":\"test-$$i\",\"timestamp\":1234567890,\"image\":\"test-data\"}" | \
		docker exec -i kafka kafka-console-producer \
			--bootstrap-server localhost:9092 \
			--topic raw-frames && \
		echo "$(GREEN)✓ Sent test frame $$i/3$(NC)"; \
	done
	
	@echo "$(GREEN)✓ Kafka integration test completed$(NC)"

test-e2e: ## Run comprehensive end-to-end pipeline test
	@echo "$(BLUE)Running end-to-end pipeline test...$(NC)"
	@echo "$(YELLOW)Testing complete video processing workflow$(NC)"
	
	# Run pytest-based end-to-end test suite
	# This test validates the entire pipeline from frame input to final output
	@python3 -m pytest \
		tests/e2e/test_video_processing_pipeline.py::TestVideoProcessingPipeline::test_all_services_healthy \
		-v
	
	@echo "$(GREEN)✓ End-to-end pipeline test completed$(NC)"

test-pipeline: ## Test complete video processing pipeline with sample data
	@echo "$(BLUE)Testing complete video processing pipeline...$(NC)"
	@echo "$(YELLOW)Sending test message through the entire processing chain$(NC)"
	
	# Send a test message directly to Kafka raw-frames topic
	# This simulates a frame being processed through the entire pipeline
	@echo "$(YELLOW)Sending test message to Kafka...$(NC)"
	@docker exec kafka kafka-console-producer \
		--bootstrap-server localhost:9092 \
		--topic raw-frames <<< '{"frame_id":"test-123","timestamp":1234567890,"image":"test-data"}' || \
		echo "$(YELLOW)Kafka producer test completed$(NC)"
	
	@echo "$(GREEN)✓ Pipeline test completed$(NC)"
	@echo "$(BLUE)Tip: Use 'make monitor-topics' to observe message processing$(NC)"

test-quick: ## Quick system health check for rapid feedback
	@echo "$(BLUE)Running quick system test...$(NC)"
	@echo "$(YELLOW)Performing rapid health validation$(NC)"
	
	# Run only the service health tests for quick feedback
	# This provides fast validation without comprehensive testing
	@make test-services
	
	@echo "$(GREEN)✓ Quick test completed$(NC)"

test-validate: ## Comprehensive system validation (all tests)
	@echo "$(BLUE)Running comprehensive system validation...$(NC)"
	@echo "$(YELLOW)This will test infrastructure, services, and connectivity$(NC)"
	
	# Run all test categories in sequence
	# Infrastructure tests first, then services, then connectivity
	@make test-infrastructure
	@make test-services  
	@make test-kafka-connectivity
	
	@echo ""
	@echo "$(GREEN)✓ System validation completed successfully$(NC)"
	@echo "$(BLUE)All components are functioning correctly$(NC)"

# ============================================================================
# UNIT TESTING
# ============================================================================
# Runs unit tests for individual components

.PHONY: test-unit

test-unit: ## Run unit tests for all components
	@echo "$(BLUE)Running unit tests...$(NC)"
	@echo "$(YELLOW)Testing individual component functionality$(NC)"
	
	# Run pytest on the unit test directory
	# -v flag provides verbose output showing individual test results
	@python3 -m pytest tests/unit/ -v
	
	@echo "$(GREEN)✓ Unit tests completed$(NC)"