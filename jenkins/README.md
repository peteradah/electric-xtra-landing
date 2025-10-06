# Jenkins CI/CD Configuration

This directory contains Jenkins configuration files for the Electric Xtra Landing Page project.

## Files Overview

### `Jenkinsfile`
The main Jenkins pipeline configuration file that defines the CI/CD process:
- **Checkout**: Gets code from GitHub
- **Validate**: Checks HTML, CSS, and JavaScript files
- **Test**: Runs validation tests
- **Build**: Creates Docker image
- **Security Scan**: Basic security checks
- **Deploy**: Deploys to staging and production environments

### `Deploy.groovy`
Groovy script with deployment functions:
- `deployToEnvironment()`: Deploys to specified environment
- `runSmokeTests()`: Runs basic health checks
- `rollbackToPreviousVersion()`: Handles rollback scenarios
- `sendNotification()`: Sends deployment notifications

### `build.sh`
Shell script for the build process:
- Prerequisites checking
- File validation
- Docker image building
- Testing
- Cleanup

### `job-config.xml`
Jenkins job configuration template for creating the pipeline job.

### `.jenkinsignore`
Specifies files and directories Jenkins should ignore during the build process.

## Setup Instructions

### 1. Install Required Jenkins Plugins
```bash
# Required plugins for this pipeline:
- Pipeline
- Docker Pipeline
- Git
- Slack Notification (optional)
- Email Extension (optional)
```

### 2. Configure Jenkins Global Tools
1. Go to **Manage Jenkins** → **Global Tool Configuration**
2. Configure Docker installation
3. Configure Git installation

### 3. Create Jenkins Credentials
1. Go to **Manage Jenkins** → **Manage Credentials**
2. Add GitHub credentials with ID: `github-credentials`
3. Add Docker registry credentials if needed

### 4. Create Pipeline Job
1. Click **New Item** in Jenkins
2. Enter job name: `electric-xtra-landing`
3. Select **Pipeline** job type
4. Configure:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: `https://github.com/peteradah/electric-xtra-landing.git`
   - **Credentials**: Select your GitHub credentials
   - **Script Path**: `Jenkinsfile`
   - **Branch Specifier**: `*/main`

### 5. Configure Build Triggers (Optional)
- **Poll SCM**: `H/5 * * * *` (every 5 minutes)
- **GitHub webhook**: For automatic builds on push

## Pipeline Stages

### 1. Checkout Stage
- Checks out code from GitHub
- Displays repository information (branch, commit, build number)

### 2. Validate Stage (Parallel)
- **HTML Validation**: Checks if HTML file exists and is valid
- **CSS Validation**: Validates CSS syntax
- **JavaScript Validation**: Validates JavaScript syntax

### 3. Test Stage
- Tests file structure and presence
- Validates Docker configuration
- Sets build status based on test results

### 4. Build Docker Image Stage
- Builds Docker image with build number tag
- Tags as `latest` for main/master branch
- Only runs on main, master, or develop branches

### 5. Security Scan Stage
- Checks for hardcoded secrets
- Basic security validation
- Reports potential security issues

### 6. Deploy to Staging Stage
- Deploys to staging environment (port 8081)
- Only runs on develop or staging branches
- Includes health checks and smoke tests

### 7. Deploy to Production Stage
- Deploys to production environment (port 8080)
- Only runs on main or master branches
- Includes rollback capability
- Optional: Push to Docker registry

## Environment Variables

Configure these in Jenkins job settings:

```bash
DOCKER_IMAGE=electric-xtra-landing
REGISTRY_URL=your-registry-url.com
NOTIFICATION_CHANNEL=#deployments
NOTIFICATION_WEBHOOK=https://hooks.slack.com/...
```

## Deployment URLs

After successful deployment:
- **Staging**: http://localhost:8081
- **Production**: http://localhost:8080

## Troubleshooting

### Common Issues

1. **Docker not found**
   - Ensure Docker is installed on Jenkins agent
   - Add Jenkins user to docker group

2. **Permission denied**
   - Check file permissions
   - Ensure Jenkins has access to Docker daemon

3. **Build fails**
   - Check build logs for specific errors
   - Verify all required files are present
   - Ensure Docker daemon is running

### Log Locations
- **Jenkins logs**: `/var/log/jenkins/jenkins.log`
- **Docker logs**: `docker logs <container-name>`
- **Build logs**: Available in Jenkins UI

## Customization

### Adding Notifications
Edit the `sendNotification()` function in `Deploy.groovy` to add:
- Slack notifications
- Email notifications
- Microsoft Teams notifications
- Custom webhooks

### Adding More Tests
Add additional test stages in the `Jenkinsfile`:
- Unit tests
- Integration tests
- Performance tests
- Security scans

### Environment-Specific Deployments
Modify the deployment stages to support:
- Multiple staging environments
- Blue-green deployments
- Canary deployments
- Multi-region deployments

## Security Considerations

1. **Credentials**: Store all sensitive data in Jenkins credentials
2. **Secrets**: Never hardcode passwords or API keys
3. **Access Control**: Limit Jenkins access to authorized users
4. **Network**: Use private networks for container communication
5. **Updates**: Keep Jenkins and plugins updated

## Monitoring

### Health Checks
The pipeline includes health checks for:
- Container startup
- HTTP response
- File accessibility
- Service availability

### Metrics
Track these metrics:
- Build success rate
- Deployment frequency
- Mean time to recovery
- Build duration

## Support

For issues or questions:
1. Check Jenkins build logs
2. Review Docker container logs
3. Verify GitHub repository access
4. Check Jenkins agent connectivity
