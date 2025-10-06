@echo off
REM Electric Xtra Landing Page - Docker Deployment Script for Windows

echo 🚀 Deploying Electric Xtra Landing Page with Docker...

REM Build the Docker image
echo 📦 Building Docker image...
docker build -t electric-xtra-landing .

REM Stop and remove existing container if it exists
echo 🛑 Stopping existing container...
docker stop electric-xtra-landing 2>nul
docker rm electric-xtra-landing 2>nul

REM Run the new container
echo 🏃 Starting new container...
docker run -d --name electric-xtra-landing -p 8080:80 --restart unless-stopped electric-xtra-landing

REM Check if container is running
docker ps | findstr electric-xtra-landing >nul
if %errorlevel% == 0 (
    echo ✅ Deployment successful!
    echo 🌐 Your landing page is now running at: http://localhost:8080
    echo 📊 Container status:
    docker ps | findstr electric-xtra-landing
) else (
    echo ❌ Deployment failed!
    echo 📋 Container logs:
    docker logs electric-xtra-landing
)

pause
