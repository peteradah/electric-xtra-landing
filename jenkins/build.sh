#!/bin/bash

# Electric Xtra Landing Page - Jenkins Build Script
# This script handles the build process for Jenkins

set -e  # Exit on any error

echo "🚀 Starting Electric Xtra Landing Page build process..."

# Configuration
DOCKER_IMAGE="electric-xtra-landing"
DOCKER_TAG="${BUILD_NUMBER:-latest}"
BUILD_DIR="/tmp/electric-xtra-build-${BUILD_NUMBER}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if Docker is installed and running
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed!"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running!"
        exit 1
    fi
    
    print_success "Docker is available and running"
    
    # Check if required files exist
    local required_files=(
        "templatemo_596_electric_xtra/index.html"
        "templatemo_596_electric_xtra/templatemo-electric-xtra.css"
        "templatemo_596_electric_xtra/templatemo-electric-scripts.js"
        "Dockerfile"
        "docker-compose.yml"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "Required file not found: $file"
            exit 1
        fi
    done
    
    print_success "All required files found"
}

# Function to validate files
validate_files() {
    print_status "Validating files..."
    
    # Validate HTML
    if grep -q "<!DOCTYPE html>" templatemo_596_electric_xtra/index.html; then
        print_success "HTML file appears valid"
    else
        print_error "HTML file validation failed"
        exit 1
    fi
    
    # Validate CSS
    if grep -q "body {" templatemo_596_electric_xtra/templatemo-electric-xtra.css; then
        print_success "CSS file appears valid"
    else
        print_error "CSS file validation failed"
        exit 1
    fi
    
    # Validate JavaScript
    if grep -q "function" templatemo_596_electric_xtra/templatemo-electric-scripts.js; then
        print_success "JavaScript file appears valid"
    else
        print_error "JavaScript file validation failed"
        exit 1
    fi
    
    # Validate Dockerfile
    if grep -q "FROM nginx:alpine" Dockerfile; then
        print_success "Dockerfile appears valid"
    else
        print_error "Dockerfile validation failed"
        exit 1
    fi
}

# Function to build Docker image
build_docker_image() {
    print_status "Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    
    # Copy files to build directory
    cp -r templatemo_596_electric_xtra/* "$BUILD_DIR/"
    cp Dockerfile "$BUILD_DIR/"
    cp docker-compose.yml "$BUILD_DIR/"
    cp nginx.conf "$BUILD_DIR/"
    cp .dockerignore "$BUILD_DIR/"
    
    # Build Docker image
    cd "$BUILD_DIR"
    
    if docker build -t "${DOCKER_IMAGE}:${DOCKER_TAG}" .; then
        print_success "Docker image built successfully"
    else
        print_error "Docker image build failed"
        exit 1
    fi
    
    # Tag as latest if this is main/master branch
    if [[ "$BRANCH_NAME" == "main" || "$BRANCH_NAME" == "master" ]]; then
        docker tag "${DOCKER_IMAGE}:${DOCKER_TAG}" "${DOCKER_IMAGE}:latest"
        print_success "Tagged as latest"
    fi
    
    cd - > /dev/null
}

# Function to run tests
run_tests() {
    print_status "Running tests..."
    
    # Test Docker image
    if docker run --rm "${DOCKER_IMAGE}:${DOCKER_TAG}" nginx -t; then
        print_success "Nginx configuration test passed"
    else
        print_error "Nginx configuration test failed"
        exit 1
    fi
    
    # Test container startup
    local test_container="electric-xtra-test-${BUILD_NUMBER}"
    
    if docker run -d --name "$test_container" -p 8082:80 "${DOCKER_IMAGE}:${DOCKER_TAG}"; then
        print_success "Container started successfully"
        
        # Wait for container to be ready
        sleep 5
        
        # Test HTTP response
        if curl -f -s http://localhost:8082/ > /dev/null; then
            print_success "HTTP test passed"
        else
            print_error "HTTP test failed"
            docker logs "$test_container"
            docker stop "$test_container" || true
            docker rm "$test_container" || true
            exit 1
        fi
        
        # Cleanup test container
        docker stop "$test_container" || true
        docker rm "$test_container" || true
        
    else
        print_error "Failed to start test container"
        exit 1
    fi
}

# Function to cleanup
cleanup() {
    print_status "Cleaning up..."
    
    # Remove build directory
    rm -rf "$BUILD_DIR" || true
    
    # Remove dangling images (optional)
    docker image prune -f || true
    
    print_success "Cleanup completed"
}

# Main execution
main() {
    print_status "Starting build process for Electric Xtra Landing Page"
    print_status "Build Number: ${BUILD_NUMBER:-N/A}"
    print_status "Branch: ${BRANCH_NAME:-N/A}"
    print_status "Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'N/A')"
    
    check_prerequisites
    validate_files
    build_docker_image
    run_tests
    
    print_success "Build process completed successfully!"
    print_status "Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
    
    cleanup
}

# Handle script interruption
trap cleanup EXIT

# Run main function
main "$@"
