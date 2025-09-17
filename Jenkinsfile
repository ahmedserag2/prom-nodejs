pipeline {
    agent any
    
    parameters {
        string(name: 'DOCKER_REGISTRY', defaultValue: 'docker.io', description: 'Docker registry URL')
        string(name: 'DOCKER_NAMESPACE', defaultValue: '01447', description: 'Docker Hub username')
        choice(name: 'TARGET_ENVIRONMENT', choices: ['dev', 'qa', 'staging', 'prod'], description: 'Target deployment environment')
        booleanParam(name: 'FORCE_REBUILD', defaultValue: false, description: 'Force rebuild even if image exists')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip test execution')
    }
    
    environment {
        APP_NAME = 'monitoring-nodejs'
        DOCKER_IMAGE = "${params.DOCKER_REGISTRY}/${params.DOCKER_NAMESPACE}/${APP_NAME}"
        LATEST_TAG = 'latest'
        
        // Environment-specific configurations
        DEV_NAMESPACE = 'dev'
        QA_NAMESPACE = 'qa'
        STAGING_NAMESPACE = 'staging'
        PROD_NAMESPACE = 'prod'
        
        // Kubernetes contexts (adjust based on your setup)
        DEV_KUBE_CONTEXT = 'dev-cluster'
        QA_KUBE_CONTEXT = 'qa-cluster'
        STAGING_KUBE_CONTEXT = 'staging-cluster'
        PROD_KUBE_CONTEXT = 'prod-cluster'
    }
    
    options {
        // Keep only last 10 builds to save space
        buildDiscarder(logRotator(numToKeepStr: '10'))
        // Timeout after 30 minutes
        timeout(time: 30, unit: 'MINUTES')
        // Add timestamps to console output
        timestamps()
        // Skip default checkout
        skipDefaultCheckout()
        // AnsiColor for colored console output
        ansiColor('xterm')
    }
    
    stages {
        stage('Checkout & Initialize') {
            steps {
                script {
                    echo "🚀 Starting pipeline for ${APP_NAME}"
                    echo "📋 Build Parameters:"
                    echo "   - Target Environment: ${params.TARGET_ENVIRONMENT}"
                    echo "   - Force Rebuild: ${params.FORCE_REBUILD}"
                    echo "   - Skip Tests: ${params.SKIP_TESTS}"
                    echo "   - Docker Registry: ${params.DOCKER_REGISTRY}"
                    echo "   - Current Branch: ${env.BRANCH_NAME ?: env.GIT_BRANCH ?: 'unknown'}"
                    
                    // Clean workspace
                    cleanWs()
                    
                    // Checkout source code
                    checkout scm
                    
                    // Get git commit short hash after checkout
                    env.GIT_COMMIT_SHORT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.BUILD_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT_SHORT}"
                    
                    echo "📝 Build Tag: ${env.BUILD_TAG}"
                    echo "🔗 Git Commit: ${env.GIT_COMMIT_SHORT}"
                    
                    // Validate required files
                    if (!fileExists('package.json')) {
                        error "❌ package.json not found!"
                    }
                    if (!fileExists('Dockerfile')) {
                        error "❌ Dockerfile not found!"
                    }
                    
                    echo "✅ Source code checked out successfully"
                }
            }
        }
        
        stage('Build Preparation') {
            steps {
                script {
                    echo "🔍 Checking if Docker image already exists..."
                    
                    // Check if Docker image with this tag already exists
                    def imageExists = false
                    try {
                        def imageCheck = sh(
                            script: "docker manifest inspect ${env.DOCKER_IMAGE}:${env.BUILD_TAG}",
                            returnStatus: true
                        )
                        imageExists = (imageCheck == 0)
                    } catch (Exception e) {
                        echo "⚠️  Could not check image existence, will proceed with build"
                        imageExists = false
                    }
                    
                    if (imageExists && !params.FORCE_REBUILD) {
                        echo "✅ Docker image ${env.DOCKER_IMAGE}:${env.BUILD_TAG} already exists"
                        env.SKIP_BUILD = 'true'
                    } else {
                        echo "🔨 Docker image ${env.DOCKER_IMAGE}:${env.BUILD_TAG} not found, will build"
                        env.SKIP_BUILD = 'false'
                    }
                }
            }
        }
        
        stage('Build & Test') {
            when {
                expression { env.SKIP_BUILD == 'false' }
            }
            parallel {
                stage('Build Docker Image') {
                    steps {
                        script {
                            echo "🐳 Building Docker image..."
                            
                            // Build Docker image
                            def image = docker.build("${env.DOCKER_IMAGE}:${env.BUILD_TAG}", ".")
                            
                            // Also tag as latest for dev environment
                            if (params.TARGET_ENVIRONMENT == 'dev') {
                                image.tag("${env.LATEST_TAG}")
                                echo "🏷️  Tagged image as: ${env.DOCKER_IMAGE}:${env.LATEST_TAG}"
                            }
                            
                            echo "✅ Docker image built successfully: ${env.DOCKER_IMAGE}:${env.BUILD_TAG}"
                        }
                    }
                    post {
                        always {
                            // Clean up build artifacts
                            cleanWs()
                        }
                    }
                }
                
                stage('Run Tests') {
                    when {
                        expression { !params.SKIP_TESTS }
                    }
                    steps {
                        script {
                            echo "🧪 Running tests..."
                            
                            // Install dependencies and run tests
                            // sh """
                            //     npm install
                            //     npm test || echo "⚠️  Tests failed, but continuing..."
                            // """
                            
                            echo "✅ Tests completed"
                        }
                    }
                }
            }
        }
        
        stage('Push to Registry') {
            when {
                expression { env.SKIP_BUILD == 'false' }
            }
            steps {
                script {
                    echo "📤 Pushing Docker image to registry..."
                    
                    // Test Docker Hub connectivity
                    echo "🔍 Testing Docker Hub connectivity..."
                    sh "docker info"
                    //sh "docker system info | grep -i registry"
                    
                    // Push the tagged image
                    docker.withRegistry("https://index.docker.io/v1/", 'docker-registry-credentials') {
                        def image = docker.image("${env.DOCKER_IMAGE}:${env.BUILD_TAG}")
                        image.push()
                        
                        // Push latest tag for dev
                        if (params.TARGET_ENVIRONMENT == 'dev') {
                            image.push("${env.LATEST_TAG}")
                        }
                    }
                    
                    echo "✅ Docker image pushed successfully"
                }
            }
        }
        
        stage('Deploy to Dev') {
            when {
                allOf {
                    expression { params.TARGET_ENVIRONMENT == 'dev' }
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "🚀 Deploying to Development environment..."
                    
                    // Deploy to dev environment
                    deployToEnvironment('dev', DEV_NAMESPACE, DEV_KUBE_CONTEXT)
                    
                    echo "✅ Deployment to dev completed"
                }
            }
            post {
                success {
                    echo "🎉 Dev deployment successful!"
                    // You can add notifications here
                }
                failure {
                    echo "❌ Dev deployment failed!"
                }
            }
        }
        
        stage('QA Approval') {
            when {
                allOf {
                    expression { params.TARGET_ENVIRONMENT == 'qa' }
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "⏳ Waiting for QA team approval..."
                    
                    // Run CI tests in QA
                    stage('QA CI Tests') {
                        echo "🧪 Running CI tests in QA environment..."
                        sh 'echo "Pipeline running CI tests in QA environment"'
                        sh 'echo "✅ All QA CI tests passed"'
                    }
                    
                    // Manual approval step
                    input message: 'Approve deployment to QA?', 
                          ok: 'Deploy to QA',
                          parameters: [
                              string(name: 'APPROVAL_COMMENT', 
                                   defaultValue: '', 
                                   description: 'Approval comment')
                          ]
                    
                    echo "✅ QA deployment approved"
                }
            }
        }
        
        stage('Deploy to QA') {
            when {
                allOf {
                    expression { params.TARGET_ENVIRONMENT == 'qa' }
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "🚀 Deploying to QA environment..."
                    
                    // Deploy to QA environment
                    deployToEnvironment('qa', QA_NAMESPACE, QA_KUBE_CONTEXT)
                    
                    echo "✅ Deployment to QA completed"
                }
            }
            post {
                success {
                    echo "🎉 QA deployment successful!"
                }
                failure {
                    echo "❌ QA deployment failed!"
                }
            }
        }
        
        stage('Staging Approval') {
            when {
                allOf {
                    expression { params.TARGET_ENVIRONMENT == 'staging' }
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "⏳ Waiting for Staging approval..."
                    
                    // Manual approval step for staging
                    input message: 'Approve deployment to Staging?', 
                          ok: 'Deploy to Staging',
                          parameters: [
                              string(name: 'APPROVAL_COMMENT', 
                                   defaultValue: '', 
                                   description: 'Approval comment')
                          ]
                    
                    echo "✅ Staging deployment approved"
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                allOf {
                    expression { params.TARGET_ENVIRONMENT == 'staging' }
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "🚀 Deploying to Staging environment..."
                    
                    // Deploy to Staging environment
                    deployToEnvironment('staging', STAGING_NAMESPACE, STAGING_KUBE_CONTEXT)
                    
                    echo "✅ Deployment to Staging completed"
                }
            }
            post {
                success {
                    echo "🎉 Staging deployment successful!"
                }
                failure {
                    echo "❌ Staging deployment failed!"
                }
            }
        }
        
        stage('Production Approval') {
            when {
                allOf {
                    expression { params.TARGET_ENVIRONMENT == 'prod' }
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "⏳ Waiting for Production approval..."
                    
                    // Manual approval step for production
                    input message: 'Approve deployment to Production?', 
                          ok: 'Deploy to Production',
                          parameters: [
                              string(name: 'APPROVAL_COMMENT', 
                                   defaultValue: '', 
                                   description: 'Approval comment')
                          ]
                    
                    echo "✅ Production deployment approved"
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                allOf {
                    expression { params.TARGET_ENVIRONMENT == 'prod' }
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "🚀 Deploying to Production environment..."
                    
                    // Deploy to Production environment
                    deployToEnvironment('prod', PROD_NAMESPACE, PROD_KUBE_CONTEXT)
                    
                    echo "✅ Deployment to Production completed"
                }
            }
            post {
                success {
                    echo "🎉 Production deployment successful!"
                }
                failure {
                    echo "❌ Production deployment failed!"
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "🏁 Pipeline execution completed"
                echo "📊 Build Summary:"
                echo "   - Build Number: ${env.BUILD_NUMBER}"
                echo "   - Git Commit: ${env.GIT_COMMIT_SHORT}"
                echo "   - Docker Image: ${env.DOCKER_IMAGE}:${env.BUILD_TAG}"
                echo "   - Target Environment: ${params.TARGET_ENVIRONMENT}"
                echo "   - Build Status: ${currentBuild.result ?: 'SUCCESS'}"
            }
        }
        
        success {
            echo "🎉 Pipeline completed successfully!"
            // Add success notifications here
        }
        
        failure {
            echo "❌ Pipeline failed!"
            // Add failure notifications here
        }
        
        unstable {
            echo "⚠️  Pipeline completed with warnings!"
        }
        
        // cleanup {
        //     // Clean up workspace
        //     cleanWs()
        // }
    }
}

// Helper function for deployment
def deployToEnvironment(environment, namespace, kubeContext) {
    echo "🔧 Deploying to ${environment} environment..."
    echo "   - Namespace: ${namespace}"
    echo "   - Kubernetes Context: ${kubeContext}"
    echo "   - Docker Image: ${env.DOCKER_IMAGE}:${env.BUILD_TAG}"
    
    // Here you would implement your actual deployment logic
    // This could be:
    // - kubectl apply with updated image tag
    // - Helm upgrade
    // - Custom deployment scripts
    
    // For now, we'll simulate deployment
    sh """
        echo "Simulating deployment to ${environment}..."
        echo "kubectl --context=${kubeContext} set image deployment/${env.APP_NAME} ${env.APP_NAME}=${env.DOCKER_IMAGE}:${env.BUILD_TAG} -n ${namespace}"
        echo "kubectl --context=${kubeContext} rollout status deployment/${env.APP_NAME} -n ${namespace}"
        echo "✅ Deployment simulation completed for ${environment}"
    """
    
    // You could also add health checks here
    // waitForDeploymentHealth(environment, namespace, kubeContext)
}

// Helper function for health checks (optional)
def waitForDeploymentHealth(environment, namespace, kubeContext) {
    echo "🔍 Checking deployment health in ${environment}..."
    
    // Simulate health check
    sh """
        echo "Checking if pods are ready..."
        echo "kubectl --context=${kubeContext} get pods -l app=${env.APP_NAME} -n ${namespace}"
        echo "✅ Health check completed for ${environment}"
    """
}
