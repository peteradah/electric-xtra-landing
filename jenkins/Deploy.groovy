// Jenkins Deploy Script for Electric Xtra Landing Page
// This script can be used in Jenkins Pipeline or as a standalone script

def deployToEnvironment(environment, port) {
    echo "🚀 Deploying to ${environment} environment on port ${port}..."
    
    def containerName = "electric-xtra-${environment}"
    def imageTag = "${env.BUILD_NUMBER ?: 'latest'}"
    
    try {
        // Stop existing container
        sh """
            docker stop ${containerName} 2>/dev/null || true
            docker rm ${containerName} 2>/dev/null || true
        """
        
        // Run new container
        sh """
            docker run -d \\
                --name ${containerName} \\
                -p ${port}:80 \\
                --restart unless-stopped \\
                --health-cmd="wget --quiet --tries=1 --spider http://localhost/ || exit 1" \\
                --health-interval=30s \\
                --health-timeout=10s \\
                --health-retries=3 \\
                electric-xtra-landing:${imageTag}
        """
        
        // Wait for container to be healthy
        sh """
            timeout 60 bash -c 'until docker ps --filter "name=${containerName}" --filter "health=healthy" | grep -q ${containerName}; do sleep 5; done'
        """
        
        echo "✅ Successfully deployed to ${environment} at http://localhost:${port}"
        
        // Optional: Run smoke tests
        runSmokeTests(port)
        
    } catch (Exception e) {
        echo "❌ Deployment to ${environment} failed: ${e.getMessage()}"
        throw e
    }
}

def runSmokeTests(port) {
    echo "🧪 Running smoke tests on port ${port}..."
    
    try {
        // Test if the application is responding
        def response = sh(
            script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:${port}/",
            returnStdout: true
        ).trim()
        
        if (response == "200") {
            echo "✅ Smoke test passed - application is responding"
        } else {
            echo "❌ Smoke test failed - HTTP response code: ${response}"
            throw new Exception("Smoke test failed")
        }
        
        // Test if main CSS file is accessible
        def cssResponse = sh(
            script: "curl -s -o /dev/null -w '%{http_code}' http://localhost:${port}/templatemo-electric-xtra.css",
            returnStdout: true
        ).trim()
        
        if (cssResponse == "200") {
            echo "✅ CSS file is accessible"
        } else {
            echo "⚠️ CSS file may not be accessible - HTTP response code: ${cssResponse}"
        }
        
    } catch (Exception e) {
        echo "❌ Smoke tests failed: ${e.getMessage()}"
        throw e
    }
}

def rollbackToPreviousVersion(environment) {
    echo "🔄 Rolling back ${environment} to previous version..."
    
    def containerName = "electric-xtra-${environment}"
    
    try {
        // Stop current container
        sh "docker stop ${containerName} || true"
        sh "docker rm ${containerName} || true"
        
        // Get previous image tag
        def previousTag = sh(
            script: "docker images electric-xtra-landing --format '{{.Tag}}' | grep -v latest | head -1",
            returnStdout: true
        ).trim()
        
        if (previousTag) {
            def port = environment == "prod" ? "8080" : "8081"
            
            sh """
                docker run -d \\
                    --name ${containerName} \\
                    -p ${port}:80 \\
                    --restart unless-stopped \\
                    electric-xtra-landing:${previousTag}
            """
            
            echo "✅ Rolled back to version: ${previousTag}"
        } else {
            echo "❌ No previous version found for rollback"
            throw new Exception("Rollback failed - no previous version")
        }
        
    } catch (Exception e) {
        echo "❌ Rollback failed: ${e.getMessage()}"
        throw e
    }
}

def sendNotification(status, environment, details) {
    echo "📧 Sending ${status} notification for ${environment}..."
    
    def message = """
    ${status == 'success' ? '✅' : '❌'} Electric Xtra Landing Page - ${status.toUpperCase()}
    
    📋 Deployment Details:
    • Environment: ${environment}
    • Build: #${env.BUILD_NUMBER ?: 'N/A'}
    • Branch: ${env.BRANCH_NAME ?: 'N/A'}
    • Commit: ${sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()}
    • Timestamp: ${new Date()}
    
    ${details}
    """
    
    echo message
    
    // Add your notification logic here (Slack, email, etc.)
    // Example for Slack:
    // slackSend channel: '#deployments', message: message, color: status == 'success' ? 'good' : 'danger'
}

return this
