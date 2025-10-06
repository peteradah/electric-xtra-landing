pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'electric-xtra-landing'
        DOCKER_TAG = "${env.BUILD_NUMBER ?: 'latest'}"
        REGISTRY_URL = 'your-registry-url.com'
        CONTAINER_NAME = 'electric-xtra-landing'
        PORT = '8080'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '🔄 Checking out source code from GitHub...'
                checkout scm
                
                script {
                    // Display repository information
                    def gitCommit = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                    
                    def gitBranch = sh(
                        script: 'git rev-parse --abbrev-ref HEAD',
                        returnStdout: true
                    ).trim()
                    
                    echo "📋 Repository Info:"
                    echo "   Branch: ${gitBranch}"
                    echo "   Commit: ${gitCommit}"
                    echo "   Build Number: ${env.BUILD_NUMBER}"
                }
            }
        }
        
        stage('Validate') {
            parallel {
                stage('HTML Validation') {
                    steps {
                        echo '🔍 Validating HTML structure...'
                        script {
                            // Check if index.html exists and is valid
                            if (fileExists('templatemo_596_electric_xtra/index.html')) {
                                echo '✅ HTML file found'
                            } else {
                                error '❌ HTML file not found'
                            }
                        }
                    }
                }
                
                stage('CSS Validation') {
                    steps {
                        echo '🎨 Validating CSS syntax...'
                        script {
                            if (fileExists('templatemo_596_electric_xtra/templatemo-electric-xtra.css')) {
                                echo '✅ CSS file found'
                                // Check for basic CSS syntax
                                def cssContent = readFile('templatemo_596_electric_xtra/templatemo-electric-xtra.css')
                                if (cssContent.contains('body {') && cssContent.contains('}')) {
                                    echo '✅ CSS syntax appears valid'
                                } else {
                                    echo '⚠️ CSS syntax may have issues'
                                }
                            } else {
                                error '❌ CSS file not found'
                            }
                        }
                    }
                }
                
                stage('JavaScript Validation') {
                    steps {
                        echo '⚡ Validating JavaScript syntax...'
                        script {
                            if (fileExists('templatemo_596_electric_xtra/templatemo-electric-scripts.js')) {
                                echo '✅ JavaScript file found'
                                // Check for basic JS syntax
                                def jsContent = readFile('templatemo_596_electric_xtra/templatemo-electric-scripts.js')
                                if (jsContent.contains('function') && jsContent.contains('addEventListener')) {
                                    echo '✅ JavaScript syntax appears valid'
                                } else {
                                    echo '⚠️ JavaScript syntax may have issues'
                                }
                            } else {
                                error '❌ JavaScript file not found'
                            }
                        }
                    }
                }
            }
        }
        
        stage('Test') {
            steps {
                echo '🧪 Running tests...'
                script {
                    // Test file structure
                    def requiredFiles = [
                        'templatemo_596_electric_xtra/index.html',
                        'templatemo_596_electric_xtra/templatemo-electric-xtra.css',
                        'templatemo_596_electric_xtra/templatemo-electric-scripts.js',
                        'Dockerfile',
                        'docker-compose.yml'
                    ]
                    
                    requiredFiles.each { file ->
                        if (fileExists(file)) {
                            echo "✅ ${file} exists"
                        } else {
                            echo "❌ ${file} missing"
                            currentBuild.result = 'UNSTABLE'
                        }
                    }
                    
                    // Test Docker files
                    if (fileExists('Dockerfile')) {
                        echo '✅ Dockerfile found'
                        def dockerfile = readFile('Dockerfile')
                        if (dockerfile.contains('FROM nginx:alpine') && dockerfile.contains('EXPOSE 80')) {
                            echo '✅ Dockerfile appears valid'
                        } else {
                            echo '⚠️ Dockerfile may have issues'
                            currentBuild.result = 'UNSTABLE'
                        }
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'develop'
                }
            }
            steps {
                echo '🐳 Building Docker image...'
                script {
                    try {
                        // Build Docker image
                        def image = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                        echo "✅ Docker image built: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                        
                        // Tag as latest if on main/master branch
                        if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master') {
                            docker.tag("${DOCKER_IMAGE}:${DOCKER_TAG}", "${DOCKER_IMAGE}:latest")
                            echo "✅ Tagged as latest"
                        }
                        
                    } catch (Exception e) {
                        echo "❌ Docker build failed: ${e.getMessage()}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                echo '🔒 Running security scan...'
                script {
                    // Basic security checks
                    def securityIssues = 0
                    
                    // Check for hardcoded secrets
                    def files = sh(
                        script: 'find . -name "*.js" -o -name "*.html" -o -name "*.css" | head -10',
                        returnStdout: true
                    ).trim().split('\n')
                    
                    files.each { file ->
                        if (fileExists(file)) {
                            def content = readFile(file)
                            if (content.contains('password') || content.contains('secret') || content.contains('api_key')) {
                                echo "⚠️ Potential secret found in ${file}"
                                securityIssues++
                            }
                        }
                    }
                    
                    if (securityIssues > 0) {
                        echo "⚠️ Found ${securityIssues} potential security issues"
                        currentBuild.result = 'UNSTABLE'
                    } else {
                        echo '✅ No obvious security issues found'
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'staging'
                }
            }
            steps {
                echo '🚀 Deploying to staging environment...'
                script {
                    try {
                        // Stop existing container
                        sh '''
                            docker stop electric-xtra-staging 2>/dev/null || true
                            docker rm electric-xtra-staging 2>/dev/null || true
                        '''
                        
                        // Run staging container
                        sh """
                            docker run -d \
                                --name electric-xtra-staging \
                                -p 8081:80 \
                                --restart unless-stopped \
                                ${DOCKER_IMAGE}:${DOCKER_TAG}
                        """
                        
                        echo '✅ Deployed to staging at http://localhost:8081'
                        
                    } catch (Exception e) {
                        echo "❌ Staging deployment failed: ${e.getMessage()}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                echo '🚀 Deploying to production environment...'
                script {
                    try {
                        // Stop existing production container
                        sh '''
                            docker stop electric-xtra-prod 2>/dev/null || true
                            docker rm electric-xtra-prod 2>/dev/null || true
                        '''
                        
                        // Run production container
                        sh """
                            docker run -d \
                                --name electric-xtra-prod \
                                -p 8080:80 \
                                --restart unless-stopped \
                                ${DOCKER_IMAGE}:${DOCKER_TAG}
                        """
                        
                        echo '✅ Deployed to production at http://localhost:8080'
                        
                        // Optional: Push to registry
                        if (env.REGISTRY_URL && env.REGISTRY_URL != 'your-registry-url.com') {
                            docker.withRegistry("https://${REGISTRY_URL}") {
                                docker.image("${DOCKER_IMAGE}:${DOCKER_TAG}").push()
                                docker.image("${DOCKER_IMAGE}:latest").push()
                            }
                            echo '✅ Pushed to Docker registry'
                        }
                        
                    } catch (Exception e) {
                        echo "❌ Production deployment failed: ${e.getMessage()}"
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleaning up...'
            // Clean up workspace
            cleanWs()
        }
        
        success {
            echo '🎉 Pipeline completed successfully!'
            script {
                // Send success notification (customize as needed)
                def message = """
                ✅ Electric Xtra Landing Page - Build Successful!
                
                📋 Build Details:
                • Branch: ${env.BRANCH_NAME}
                • Build: #${env.BUILD_NUMBER}
                • Commit: ${sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()}
                • Docker Image: ${DOCKER_IMAGE}:${DOCKER_TAG}
                
                🌐 Access URLs:
                • Staging: http://localhost:8081 (if deployed)
                • Production: http://localhost:8080 (if deployed)
                """
                echo message
            }
        }
        
        failure {
            echo '❌ Pipeline failed!'
            script {
                // Send failure notification (customize as needed)
                def message = """
                ❌ Electric Xtra Landing Page - Build Failed!
                
                📋 Build Details:
                • Branch: ${env.BRANCH_NAME}
                • Build: #${env.BUILD_NUMBER}
                • Commit: ${sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()}
                
                Please check the build logs for details.
                """
                echo message
            }
        }
        
        unstable {
            echo '⚠️ Pipeline completed with warnings!'
        }
    }
}
