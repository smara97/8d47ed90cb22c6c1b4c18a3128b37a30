#!/bin/bash
# ============================================================================
# AWS Deployment Script - Video RAG Microservices
# ============================================================================
#
# PURPOSE:
#   Deploy Video RAG system to AWS using ECS Fargate with proper
#   infrastructure setup and security configurations.
#
# USAGE:
#   ./deploy-aws.sh [environment] [region]
#   Example: ./deploy-aws.sh production us-west-2
#
# ============================================================================

set -euo pipefail

# Configuration
ENVIRONMENT=${1:-staging}
AWS_REGION=${2:-us-west-2}
PROJECT_NAME="video-rag"
CLUSTER_NAME="${PROJECT_NAME}-${ENVIRONMENT}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    command -v aws >/dev/null 2>&1 || error "AWS CLI not installed"
    command -v docker >/dev/null 2>&1 || error "Docker not installed"
    command -v jq >/dev/null 2>&1 || error "jq not installed"
    
    # Check AWS credentials
    aws sts get-caller-identity >/dev/null 2>&1 || error "AWS credentials not configured"
    
    success "Prerequisites check passed"
}

# Create ECR repositories
create_ecr_repositories() {
    log "Creating ECR repositories..."
    
    SERVICES=("ocr-service" "detector-service" "captioner-service" "frame-aggregator")
    
    for service in "${SERVICES[@]}"; do
        REPO_NAME="${PROJECT_NAME}/${service}"
        
        if aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
            log "Repository $REPO_NAME already exists"
        else
            aws ecr create-repository \
                --repository-name "$REPO_NAME" \
                --region "$AWS_REGION" \
                --image-scanning-configuration scanOnPush=true \
                --encryption-configuration encryptionType=AES256
            
            success "Created ECR repository: $REPO_NAME"
        fi
    done
}

# Build and push Docker images
build_and_push_images() {
    log "Building and pushing Docker images..."
    
    # Get ECR login token
    aws ecr get-login-password --region "$AWS_REGION" | \
        docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    
    SERVICES=("ocr-service" "detector-service" "captioner-service" "frame-aggregator")
    
    for service in "${SERVICES[@]}"; do
        log "Building $service..."
        
        cd "services/$service"
        
        IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}/${service}:${ENVIRONMENT}"
        
        docker build -t "$IMAGE_URI" .
        docker push "$IMAGE_URI"
        
        success "Pushed $service to ECR"
        cd - >/dev/null
    done
}

# Create ECS cluster
create_ecs_cluster() {
    log "Creating ECS cluster..."
    
    if aws ecs describe-clusters --clusters "$CLUSTER_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
        log "ECS cluster $CLUSTER_NAME already exists"
    else
        aws ecs create-cluster \
            --cluster-name "$CLUSTER_NAME" \
            --capacity-providers FARGATE \
            --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1 \
            --region "$AWS_REGION"
        
        success "Created ECS cluster: $CLUSTER_NAME"
    fi
}

# Deploy infrastructure services
deploy_infrastructure() {
    log "Deploying infrastructure services..."
    
    # Deploy using CloudFormation or Terraform
    # This is a simplified version - in production, use proper IaC
    
    cat > infrastructure-stack.json <<EOF
{
    "AWSTemplateFormatVersion": "2010-09-09",
    "Description": "Video RAG Infrastructure Stack",
    "Resources": {
        "VPC": {
            "Type": "AWS::EC2::VPC",
            "Properties": {
                "CidrBlock": "10.0.0.0/16",
                "EnableDnsHostnames": true,
                "EnableDnsSupport": true
            }
        },
        "MSKCluster": {
            "Type": "AWS::MSK::Cluster",
            "Properties": {
                "ClusterName": "${PROJECT_NAME}-kafka-${ENVIRONMENT}",
                "KafkaVersion": "2.8.1",
                "NumberOfBrokerNodes": 3,
                "BrokerNodeGroupInfo": {
                    "InstanceType": "kafka.m5.large",
                    "ClientSubnets": [{"Ref": "PrivateSubnet1"}],
                    "SecurityGroups": [{"Ref": "MSKSecurityGroup"}]
                }
            }
        }
    }
}
EOF
    
    aws cloudformation deploy \
        --template-body file://infrastructure-stack.json \
        --stack-name "${PROJECT_NAME}-infrastructure-${ENVIRONMENT}" \
        --region "$AWS_REGION" \
        --capabilities CAPABILITY_IAM
    
    success "Infrastructure deployed"
}

# Deploy services
deploy_services() {
    log "Deploying microservices..."
    
    SERVICES=("ocr-service" "detector-service" "captioner-service" "frame-aggregator")
    
    for service in "${SERVICES[@]}"; do
        log "Deploying $service..."
        
        # Create task definition
        cat > "${service}-task-definition.json" <<EOF
{
    "family": "${PROJECT_NAME}-${service}-${ENVIRONMENT}",
    "networkMode": "awsvpc",
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "512",
    "memory": "1024",
    "executionRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/ecsTaskExecutionRole",
    "containerDefinitions": [
        {
            "name": "${service}",
            "image": "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${PROJECT_NAME}/${service}:${ENVIRONMENT}",
            "portMappings": [
                {
                    "containerPort": 8000,
                    "protocol": "tcp"
                }
            ],
            "environment": [
                {
                    "name": "ENVIRONMENT",
                    "value": "${ENVIRONMENT}"
                },
                {
                    "name": "KAFKA_BOOTSTRAP_SERVERS",
                    "value": "kafka.${PROJECT_NAME}.local:9092"
                }
            ],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "/ecs/${PROJECT_NAME}/${service}",
                    "awslogs-region": "${AWS_REGION}",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
}
EOF
        
        # Register task definition
        aws ecs register-task-definition \
            --cli-input-json file://"${service}-task-definition.json" \
            --region "$AWS_REGION"
        
        # Create service
        aws ecs create-service \
            --cluster "$CLUSTER_NAME" \
            --service-name "${service}-${ENVIRONMENT}" \
            --task-definition "${PROJECT_NAME}-${service}-${ENVIRONMENT}" \
            --desired-count 2 \
            --launch-type FARGATE \
            --network-configuration "awsvpcConfiguration={subnets=[subnet-12345],securityGroups=[sg-12345],assignPublicIp=ENABLED}" \
            --region "$AWS_REGION" || true
        
        success "Deployed $service"
        
        # Cleanup
        rm "${service}-task-definition.json"
    done
}

# Main deployment function
main() {
    log "Starting AWS deployment for environment: $ENVIRONMENT"
    
    # Get AWS account ID
    export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    
    check_prerequisites
    create_ecr_repositories
    build_and_push_images
    create_ecs_cluster
    deploy_infrastructure
    deploy_services
    
    success "Deployment completed successfully!"
    log "Services are being deployed to ECS cluster: $CLUSTER_NAME"
    log "Monitor deployment status in AWS Console"
}

# Run main function
main "$@"