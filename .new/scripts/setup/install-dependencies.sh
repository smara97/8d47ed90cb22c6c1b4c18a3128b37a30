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
if command -v pip3 >/dev/null 2>&1; then
    pip3 install --user -r requirements-dev.txt 2>/dev/null || \
    echo "⚠️  Python dependencies skipped (externally managed environment)"
else
    echo "⚠️  pip3 not available, skipping Python dependencies"
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p logs models data

# Set up Git hooks (optional)
echo "🔧 Setting up Git hooks..."
if [ -f "scripts/setup/pre-commit" ]; then
    cp scripts/setup/pre-commit .git/hooks/
    chmod +x .git/hooks/pre-commit
    echo "✅ Git hooks configured"
else
    echo "⚠️  Git hooks skipped (pre-commit script not found)"
fi

# Initialize environment
echo "🔧 Initializing environment..."
if [ -f "infrastructure/.env.example" ]; then
    cp infrastructure/.env.example infrastructure/.env
    echo "✅ Environment file initialized"
else
    echo "⚠️  Environment initialization skipped (.env.example not found)"
fi

echo "✅ Setup complete!"
echo "📖 Next steps:"
echo "   1. Review infrastructure/.env configuration"
echo "   2. Run 'make up' to start services"
echo "   3. Run 'make test-integration' to verify setup"