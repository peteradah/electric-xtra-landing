#!/bin/bash

# Electric Xtra Landing Page - Docker Deployment Script

echo "🚀 Deploying Electric Xtra Landing Page with Docker..."

# Build the Docker image
echo "📦 Building Docker image..."
docker build -t electric-xtra-landing .

# Stop and remove existing container if it exists
echo "🛑 Stopping existing container..."
docker stop electric-xtra-landing 2>/dev/null || true
docker rm electric-xtra-landing 2>/dev/null || true

# Run the new container
echo "🏃 Starting new container..."
docker run -d \
  --name electric-xtra-landing \
  -p 8080:80 \
  --restart unless-stopped \
  electric-xtra-landing

# Check if container is running
if docker ps | grep -q electric-xtra-landing; then
    echo "✅ Deployment successful!"
    echo "🌐 Your landing page is now running at: http://localhost:8080"
    echo "📊 Container status:"
    docker ps | grep electric-xtra-landing
else
    echo "❌ Deployment failed!"
    echo "📋 Container logs:"
    docker logs electric-xtra-landing
fi
