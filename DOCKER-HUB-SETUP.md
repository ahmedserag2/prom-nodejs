# Docker Hub Configuration for Jenkins Pipeline

## 🔧 **Docker Hub Parameter Configuration**

For Docker Hub, configure your Jenkins pipeline parameters as follows:

### **Pipeline Parameters:**
```groovy
parameters {
    string(name: 'DOCKER_REGISTRY', defaultValue: 'docker.io', description: 'Docker registry URL')
    string(name: 'DOCKER_NAMESPACE', defaultValue: 'your-dockerhub-username', description: 'Docker Hub username')
    // ... other parameters
}
```

### **Environment Variables:**
```groovy
environment {
    APP_NAME = 'nodejs-app'
    DOCKER_IMAGE = "${params.DOCKER_REGISTRY}/${params.DOCKER_NAMESPACE}/${APP_NAME}"
    // This creates: docker.io/your-username/nodejs-app
}
```

## 🐳 **Docker Hub Examples**

### **Example 1: Your Docker Hub Username**
If your Docker Hub username is `johnsmith`:
- **DOCKER_REGISTRY**: `docker.io`
- **DOCKER_NAMESPACE**: `johnsmith`
- **Resulting Image**: `docker.io/johnsmith/nodejs-app:123-abc123`

### **Example 2: Organization Account**
If you're using an organization `mycompany`:
- **DOCKER_REGISTRY**: `docker.io`
- **DOCKER_NAMESPACE**: `mycompany`
- **Resulting Image**: `docker.io/mycompany/nodejs-app:123-abc123`

## 🔐 **Docker Hub Credentials Setup**

### **Step 1: Create Access Token**
1. Go to [Docker Hub](https://hub.docker.com)
2. **Account Settings** → **Security** → **New Access Token**
3. Create token with **Read, Write, Delete** permissions
4. Copy the token (you won't see it again!)

### **Step 2: Add Credentials in Jenkins**
1. **Jenkins Dashboard** → **Manage Jenkins** → **Manage Credentials**
2. **Global** → **Add Credentials** → **Username with password**
3. **Configuration:**
   ```
   Kind: Username with password
   Scope: Global
   Username: your-dockerhub-username
   Password: your-access-token
   ID: docker-registry-credentials
   Description: Docker Hub Credentials
   ```

## 🚀 **Docker Commands Generated**

Your pipeline will generate these Docker commands:

### **Build:**
```bash
docker build -t docker.io/your-username/nodejs-app:123-abc123 .
```

### **Push:**
```bash
docker push docker.io/your-username/nodejs-app:123-abc123
docker push docker.io/your-username/nodejs-app:latest  # (for dev only)
```

## 📋 **Complete Configuration Example**

### **For Username: `mycompany`**
```groovy
parameters {
    string(name: 'DOCKER_REGISTRY', defaultValue: 'docker.io', description: 'Docker registry URL')
    string(name: 'DOCKER_NAMESPACE', defaultValue: 'mycompany', description: 'Docker Hub username')
    choice(name: 'TARGET_ENVIRONMENT', choices: ['dev', 'qa', 'staging', 'prod'], description: 'Target deployment environment')
    booleanParam(name: 'FORCE_REBUILD', defaultValue: false, description: 'Force rebuild even if image exists')
    booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip test execution')
}
```

### **Resulting Images:**
- **Dev**: `docker.io/mycompany/nodejs-app:latest`
- **QA**: `docker.io/mycompany/nodejs-app:123-abc123`
- **Staging**: `docker.io/mycompany/nodejs-app:123-abc123`
- **Production**: `docker.io/mycompany/nodejs-app:123-abc123`

## 🔍 **Testing Your Configuration**

### **Test Docker Login:**
```bash
docker login -u your-username -p your-access-token
```

### **Test Image Push:**
```bash
docker tag your-local-image docker.io/your-username/nodejs-app:test
docker push docker.io/your-username/nodejs-app:test
```

## ⚠️ **Important Notes**

1. **Use Access Tokens**: Never use your Docker Hub password in Jenkins
2. **Token Permissions**: Ensure your token has Read, Write, Delete permissions
3. **Registry URL**: Keep `docker.io` as the registry URL
4. **Namespace**: Use your Docker Hub username or organization name
5. **Image Names**: Docker Hub image names must be lowercase

## 🛠️ **Troubleshooting**

### **Common Issues:**

1. **Authentication Failed**
   - Check username and access token
   - Verify token permissions
   - Test login manually

2. **Push Denied**
   - Check if repository exists on Docker Hub
   - Verify namespace (username) is correct
   - Ensure you have write permissions

3. **Image Not Found**
   - Verify the image was built successfully
   - Check the image tag format
   - Confirm the registry URL is correct

### **Debug Commands:**
```bash
# Check if you're logged in
docker system info | grep -i registry

# List local images
docker images | grep nodejs-app

# Test push manually
docker push docker.io/your-username/nodejs-app:test
```

This configuration will work perfectly with Docker Hub!
