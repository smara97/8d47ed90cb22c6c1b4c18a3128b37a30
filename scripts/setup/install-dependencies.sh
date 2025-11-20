#!/bin/bash
# Setup script for Video RAG development environment

set -e

echo "🚀 Setting up Video RAG development environment..."

# Check system requirements
echo "📋 Checking system requirements..."
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "❌ Docker Compose is required"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Python 3 is required"; exit 1; }

echo "✅ System requirements satisfied"

# Install Python dependencies for testing
echo "📦 Installing Python test dependencies..."
pip3 install -r requirements-dev.txt

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p logs models data

# Set up Git hooks
echo "🔧 Setting up Git hooks..."
cp scripts/setup/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit

# Initialize environment
echo "🔧 Initializing environment..."
cp infrastructure/.env.example infrastructure/.env

echo "✅ Setup complete!"
echo "📖 Next steps:"
echo "   1. Review infrastructure/.env configuration"
echo "   2. Run 'make up' to start services"
echo "   3. Run 'make test-integration' to verify setup"