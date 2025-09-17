# Jenkins Pipeline Setup Guide

This document provides comprehensive instructions for setting up and using the Jenkins pipeline for the Node.js application.

## Overview

The Jenkins pipeline follows industry best practices and implements a robust CI/CD workflow with the following features:

- **Conditional Build**: Only builds Docker images if they don't already exist
- **Multi-Environment Deployment**: Supports dev, qa, staging, and prod environments
- **Approval Gates**: Manual approvals required for qa, staging, and prod deployments
- **CI Testing**: Automated testing in QA environment
- **Best Practices**: Proper error handling, logging, and cleanup

## Pipeline Features

### 1. Build Once Strategy
- The pipeline checks if a Docker image with the current tag already exists
- If the image exists and `FORCE_REBUILD` is false, it skips the build stage
- This prevents unnecessary rebuilds and saves time

### 2. Environment Promotion Cycle
- **Dev**: Automatic deployment (no approval required)
- **QA**: Requires manual approval + runs CI tests
- **Staging**: Requires manual approval
- **Prod**: Requires manual approval

### 3. Docker Tag Strategy
- Images are tagged with: `{BUILD_NUMBER}-{GIT_COMMIT_SHORT}`
- Dev environment also gets a `latest` tag
- Example: `your-registry.com/nodejs-app/nodejs-app:123-a1b2c3d`

## Prerequisites

### Jenkins Setup
1. **Required Plugins**:
   - Pipeline Plugin
   - Docker Pipeline Plugin
   - Kubernetes CLI Plugin
   - AnsiColor Plugin
   - Build Timeout Plugin

2. **Credentials**:
   - Docker registry credentials (ID: `docker-registry-credentials`)
   - Kubernetes cluster access credentials

3. **Tools**:
   - Docker installed on Jenkins agents
   - kubectl configured for target clusters
   - Node.js (if running tests locally)

### Docker Registry Setup
1. Configure your Docker registry URL in the pipeline parameters
2. Ensure Jenkins has push/pull permissions to the registry
3. Set up the `docker-registry-credentials` in Jenkins

### Kubernetes Clusters
Configure access to your target Kubernetes clusters:
- `dev-cluster`
- `qa-cluster`
- `staging-cluster`
- `prod-cluster`

## Pipeline Parameters

When running the pipeline, you can configure:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `DOCKER_REGISTRY` | `your-registry.com` | Docker registry URL |
| `DOCKER_NAMESPACE` | `nodejs-app` | Docker image namespace |
| `TARGET_ENVIRONMENT` | `dev` | Target deployment environment |
| `FORCE_REBUILD` | `false` | Force rebuild even if image exists |
| `SKIP_TESTS` | `false` | Skip test execution |

## Usage Examples

### 1. Deploy to Development
```bash
# Trigger pipeline with default parameters
# This will:
# - Check if image exists
# - Build if needed
# - Deploy to dev automatically
```

### 2. Deploy to QA with Tests
```bash
# Set parameters:
# - TARGET_ENVIRONMENT: qa
# - SKIP_TESTS: false
# - FORCE_REBUILD: false
```

### 3. Force Rebuild and Deploy to Staging
```bash
# Set parameters:
# - TARGET_ENVIRONMENT: staging
# - FORCE_REBUILD: true
# - SKIP_TESTS: false
```

## Pipeline Stages

### 1. Checkout & Initialize
- Cleans workspace
- Checks out source code
- Validates required files (`package.json`, `Dockerfile`)

### 2. Build Preparation
- Checks if Docker image already exists
- Sets `SKIP_BUILD` flag accordingly

### 3. Build & Test (Parallel)
- **Build Docker Image**: Builds image if needed
- **Run Tests**: Executes npm tests (if not skipped)

### 4. Push to Registry
- Pushes Docker image to registry
- Tags as `latest` for dev environment

### 5. Environment-Specific Deployment
- **Dev**: Automatic deployment
- **QA**: Deployment + CI tests + approval
- **Staging**: Deployment + approval
- **Prod**: Deployment + approval

## Approval Gates

### QA Approval
- Runs CI tests with echo commands
- Requires manual approval before proceeding
- Allows approval comments

### Staging Approval
- Requires manual approval
- Allows approval comments

### Production Approval
- Requires manual approval
- Allows approval comments

## Environment Configuration

### Development
- **Namespace**: `dev`
- **Kubernetes Context**: `dev-cluster`
- **Auto-deployment**: Yes
- **Approval Required**: No

### QA
- **Namespace**: `qa`
- **Kubernetes Context**: `qa-cluster`
- **Auto-deployment**: No
- **Approval Required**: Yes
- **CI Tests**: Yes

### Staging
- **Namespace**: `staging`
- **Kubernetes Context**: `staging-cluster`
- **Auto-deployment**: No
- **Approval Required**: Yes

### Production
- **Namespace**: `prod`
- **Kubernetes Context**: `prod-cluster`
- **Auto-deployment**: No
- **Approval Required**: Yes

## Customization

### Adding New Environments
1. Add new environment parameters to the pipeline
2. Create new deployment stage
3. Add approval gate if needed
4. Update environment configuration section

### Modifying CI Tests
Replace the echo commands in the QA stage with actual test commands:
```groovy
stage('QA CI Tests') {
    echo "🧪 Running CI tests in QA environment..."
    sh 'npm run test:integration'
    sh 'npm run test:e2e'
    sh 'echo "✅ All QA CI tests passed"'
}
```

### Custom Deployment Logic
Modify the `deployToEnvironment` function to implement your specific deployment strategy:
- Helm charts
- Kubernetes manifests
- Custom deployment scripts

## Troubleshooting

### Common Issues

1. **Docker Registry Authentication**
   - Verify `docker-registry-credentials` exists in Jenkins
   - Check registry URL format

2. **Kubernetes Access**
   - Verify kubectl contexts are configured
   - Check cluster connectivity

3. **Build Failures**
   - Check Dockerfile syntax
   - Verify all required files exist
   - Review build logs

4. **Deployment Failures**
   - Verify target namespace exists
   - Check resource quotas
   - Review deployment manifests

### Debug Mode
Enable debug logging by adding to the pipeline:
```groovy
environment {
    DEBUG = 'true'
}
```

## Security Considerations

1. **Credentials Management**
   - Use Jenkins credential store
   - Rotate credentials regularly
   - Limit credential scope

2. **Registry Security**
   - Use private registries
   - Implement image scanning
   - Use non-root containers

3. **Approval Gates**
   - Ensure proper approval workflows
   - Log approval decisions
   - Implement RBAC

## Monitoring and Notifications

### Build Notifications
The pipeline includes post-build actions for:
- Success notifications
- Failure notifications
- Build summaries

### Integration Options
- Slack notifications
- Email alerts
- Webhook notifications
- Integration with monitoring tools

## Best Practices

1. **Version Control**
   - Store Jenkinsfile in source control
   - Use branch-specific pipelines
   - Implement pull request validation

2. **Resource Management**
   - Set build timeouts
   - Clean up workspaces
   - Limit concurrent builds

3. **Error Handling**
   - Implement proper error handling
   - Use meaningful error messages
   - Add retry mechanisms where appropriate

4. **Documentation**
   - Keep pipeline documentation updated
   - Document environment-specific configurations
   - Maintain troubleshooting guides

## Support

For issues or questions:
1. Check Jenkins build logs
2. Review pipeline documentation
3. Consult with DevOps team
4. Check Kubernetes cluster status
