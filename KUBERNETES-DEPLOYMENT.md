# Hands-on Kubernetes Deployment: Node.js App with Redis and MongoDB

Purpose of this hands-on training is to give students the knowledge of deploying a complete Node.js application stack with Redis and MongoDB on Kubernetes using Helm charts.

## Learning Outcomes

At the end of this hands-on training, students will be able to;

- Deploy a multi-tier Node.js application on Kubernetes
- Understand persistent volume management for databases
- Use Helm charts for complex application deployments
- Implement service discovery and inter-pod communication
- Monitor application health with readiness and liveness probes
- Manage database connections in containerized environments

## Outline

- Part 1 - Prerequisites and Environment Setup
- Part 2 - Local Development with Docker Compose
- Part 3 - Building and Pushing Container Images
- Part 4 - Kubernetes Cluster Preparation
- Part 5 - Deploying with Helm Charts
- Part 6 - Testing and Verification
- Part 7 - Monitoring and Troubleshooting
- Part 8 - Cleanup and Best Practices

## Prerequisites

1. **Docker and Docker Compose** installed locally
2. **kubectl** installed and configured
3. **Helm 3.x** installed
4. **Access to a Kubernetes cluster** (EKS, GKE, AKS, or local cluster)
5. **Container registry access** (Docker Hub, ECR, etc.)

For EKS cluster setup, refer to the [EKS installation guide](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html).

## Part 1 - Prerequisites and Environment Setup

### Install Required Tools

- **Docker**: Download from [Docker official site](https://www.docker.com/products/docker-desktop)
- **kubectl**: Follow the [official installation guide](https://kubernetes.io/docs/tasks/tools/)
- **Helm**: Install from [Helm official site](https://helm.sh/docs/intro/install/)

### Verify installations

```bash
docker --version
docker-compose --version
kubectl version --client
helm version
```

### Clone the repository

```bash
git clone https://github.com/ahmedserag2/prom-nodejs.git
cd prom-nodejs
```

## Part 2 - Local Development with Docker Compose

### Understanding the Application Structure

The application consists of:
- **Node.js Express app** with Prometheus metrics
- **Redis** for caching and session storage
- **MongoDB** for persistent data storage

### Local Development Setup

- Start the complete stack locally:

```bash
docker-compose up -d
```

- Verify all services are running:

```bash
docker-compose ps
```

You should see output similar to:

```bash
NAME                IMAGE               STATUS              PORTS
nodejs-app          nodejs-app:latest   Up 2 minutes        0.0.0.0:3000->3000/tcp
redis               redis:7-alpine      Up 2 minutes        0.0.0.0:6379->6379/tcp
mongodb             mongo:7             Up 2 minutes        0.0.0.0:27017->27017/tcp
```

### Test the Application Endpoints

- **Main application**:

```bash
curl http://localhost:3000
# Expected: "Hello World! Redis and MongoDB are connected."
```

- **Health check**:

```bash
curl http://localhost:3000/health
```

- **Redis test**:

```bash
curl http://localhost:3000/redis-test
```

- **MongoDB test**:

```bash
curl http://localhost:3000/mongo-test
```

- **Prometheus metrics**:

```bash
curl http://localhost:3000/metrics
```

### Access Admin Interfaces (Optional)

- **Redis Commander**: http://localhost:8081
- **MongoDB Express**: http://localhost:8082 (admin/admin)

### Stop local development

```bash
docker-compose down
```

## Part 3 - Building and Pushing Container Images

### Build the application image

```bash
docker build -t your-registry/nodejs-app:v1.0 .
```

### Test the built image locally

```bash
docker run -p 3000:3000 your-registry/nodejs-app:v1.0
```

### Push to container registry

```bash
# For Docker Hub
docker push your-registry/nodejs-app:v1.0

# For AWS ECR (example)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
docker tag your-registry/nodejs-app:v1.0 123456789012.dkr.ecr.us-east-1.amazonaws.com/nodejs-app:v1.0
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/nodejs-app:v1.0
```

## Part 4 - Kubernetes Cluster Preparation

### Verify cluster connection

```bash
kubectl cluster-info
kubectl get nodes
```

### Create namespace for the application

```bash
kubectl create namespace nodejs-app
```



## Part 5 - Deploying with Helm Charts

### Understanding the Helm Chart Structure

The Helm chart includes:
- **Application deployment** with environment variables
- **Redis deployment** with persistent storage
- **MongoDB deployment** with authentication and persistence
- **Services** for inter-pod communication
- **Persistent Volume Claims** for data persistence

### Update Helm values

- Edit `helmchart/values.yaml` to match your environment: ** If you deploy with the current helm chart setup it will work right off the box**

```yaml
image:
  repository: your-registry/nodejs-app
  tag: v1.0
  pullPolicy: Always

redis:
  enabled: true
  persistence:
    enabled: true
    size: 1Gi
    storageClass: "gp2"  # Adjust for your cluster

mongodb:
  enabled: true
  persistence:
    enabled: true
    size: 2Gi
    storageClass: "gp2"  # Adjust for your cluster
  auth:
    rootUsername: admin
    rootPassword: "your-secure-password"
    database: nodejs_app
```

### Deploy the application

```bash
# Install the Helm chart
helm install nodejs-app ./helmchart --namespace nodejs-app

# Or upgrade if already installed
helm upgrade nodejs-app ./helmchart --namespace nodejs-app
```

### Verify the deployment

```bash
# Check all resources
kubectl get all -n nodejs-app

# Check persistent volumes
kubectl get pv,pvc -n nodejs-app

# Check pod logs
kubectl logs deployment/nodejs-app-nodejs-app -n nodejs-app
kubectl logs deployment/nodejs-app-redis -n nodejs-app
kubectl logs deployment/nodejs-app-mongodb -n nodejs-app
```

Expected output should show all pods running:

```bash
NAME                                    READY   STATUS    RESTARTS   AGE
pod/nodejs-app-mongodb-xxx              1/1     Running   0          2m
pod/nodejs-app-nodejs-app-xxx           1/1     Running   0          2m
pod/nodejs-app-redis-xxx                1/1     Running   0          2m
```

## Part 6 - Testing and Verification

### Port forward to access the application

```bash
kubectl port-forward service/nodejs-app-nodejs-app-service 3000:3000
```

### Test application endpoints

- In another terminal, test all endpoints:

```bash
# Main endpoint
curl http://localhost:3000

# Health check
curl http://localhost:3000/health

# Redis functionality
curl http://localhost:3000/redis-test

# MongoDB functionality
curl http://localhost:3000/mongo-test

# Prometheus metrics
curl http://localhost:3000/metrics
```

### Check database persistence

- Delete and recreate pods to verify data persistence:

```bash
# Delete Redis pod
kubectl delete pod -l app=redis

# Test Redis data persistence
curl http://localhost:3000/redis-test

# Delete MongoDB pod
kubectl delete pod -l app=mongodb

# Test MongoDB data persistence
curl http://localhost:3000/mongo-test
```

### Load testing (optional)

```bash
# Install Apache Bench or use curl in a loop
for i in {1..100}; do curl http://localhost:3000/redis-test; done
```

## Part 7 - Monitoring and Troubleshooting

### Check application health

```bash
# View application logs
kubectl logs -f deployment/nodejs-app-nodejs-app

# Check pod status
kubectl describe pod -l app=nodejs-app

# Check service endpoints
kubectl get endpoints
```

### Database connection troubleshooting

```bash
# Check Redis connectivity
kubectl exec -it deployment/nodejs-app-redis -- redis-cli ping

# Check MongoDB connectivity
kubectl exec -it deployment/nodejs-app-mongodb -- mongosh --eval "db.adminCommand('ping')"
```

### Common issues and solutions

1. **Pod CrashLoopBackOff**:
   ```bash
   kubectl logs <pod-name> --previous
   kubectl describe pod <pod-name>
   ```

2. **Database connection failures**:
   ```bash
   # Check service DNS resolution
   kubectl exec -it <app-pod> -- nslookup nodejs-app-redis
   kubectl exec -it <app-pod> -- nslookup nodejs-app-mongodb
   ```

3. **Persistent volume issues**:
   ```bash
   kubectl get pv,pvc
   kubectl describe pvc <pvc-name>
   ```

### Scaling the application

```bash
# Scale the Node.js application
kubectl scale deployment nodejs-app-nodejs-app --replicas=3

# Verify scaling
kubectl get pods -l app=nodejs-app
```

## Part 8 - Cleanup and Best Practices

### Uninstall the application

```bash
# Remove Helm release
helm uninstall nodejs-app --namespace nodejs-app

# Delete persistent volumes (if needed)
kubectl delete pvc --all --namespace nodejs-app

# Delete namespace
kubectl delete namespace nodejs-app
```

### Best Practices Summary

1. **Resource Management**:
   - Set appropriate resource limits and requests
   - Use horizontal pod autoscaling for the app tier

2. **Data Management**:
   - Regular database backups
   - Use appropriate storage classes
   - Monitor disk usage

3. **Monitoring**:
   - Implement comprehensive health checks
   - Use Prometheus for metrics collection
   - Set up alerting for critical failures


### Production Considerations

- **Use Kubernetes Secrets** for sensitive data:

```bash
kubectl create secret generic mongodb-auth \
  --from-literal=username=admin \
  --from-literal=password=secure-password
```


- **Set up monitoring with Prometheus and Grafana**
- **Implement backup strategies for persistent data**
- **Use Helm hooks for database migrations**

## Troubleshooting Guide

### Application Won't Start

1. Check image pull status:
   ```bash
   kubectl describe pod <pod-name>
   ```

2. Verify environment variables:
   ```bash
   kubectl exec -it <pod-name> -- env | grep -E "(REDIS|MONGO)"
   ```

### Database Connection Issues

1. Test service resolution:
   ```bash
   kubectl exec -it <app-pod> -- nslookup <service-name>
   ```

2. Check database pod logs:
   ```bash
   kubectl logs <database-pod>
   ```

### Performance Issues

1. Check resource usage:
   ```bash
   kubectl top pods
   kubectl top nodes
   ```

2. Monitor application metrics:
   ```bash
   kubectl port-forward service/nodejs-app-nodejs-app-service 3000:3000
   curl http://localhost:3000/metrics
   ```

This completes the comprehensive Kubernetes deployment guide for the Node.js application with Redis and MongoDB.
