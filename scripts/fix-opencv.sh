#!/bin/bash
# ============================================================================
# OpenCV Fix Script - Rebuild Services with Headless OpenCV
# ============================================================================
#
# PURPOSE:
#   Fixes OpenCV import errors by rebuilding all services with proper
#   headless OpenCV configuration and required system libraries.
#
# FIXES APPLIED:
#   - Added libgl1-mesa-glx for OpenGL support
#   - Switched to opencv-python-headless package
#   - Added QT_QPA_PLATFORM=offscreen environment variable
#
# USAGE:
#   ./scripts/fix-opencv.sh
#
# ============================================================================

set -e

echo "🔧 Fixing OpenCV import issues..."

# Stop existing services
echo "📦 Stopping existing services..."
make services-down || true

# Rebuild services with OpenCV fixes
echo "🏗️ Rebuilding services with OpenCV fixes..."
make services-build

# Start services
echo "🚀 Starting fixed services..."
make services-up

# Test the fix
echo "🧪 Testing OpenCV import..."
sleep 10
make health

echo "✅ OpenCV fix complete!"
echo "📋 Changes made:"
echo "   - Updated to CUDA 12.4 (non-deprecated base images)"
echo "   - Added libgl1-mesa-glx to all Dockerfiles"
echo "   - Switched to opencv-python-headless"
echo "   - Added QT_QPA_PLATFORM=offscreen environment"