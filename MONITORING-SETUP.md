# Monitoring Setup: Prometheus Stack with Grafana

This guide will help you deploy the complete monitoring stack for your Node.js application with Redis and MongoDB using Prometheus and Grafana.

## Overview

The monitoring setup includes:
- **Prometheus** for metrics collection and storage
- **Grafana** for visualization and dashboards
- **Redis Exporter** for Redis metrics
- **MongoDB Exporter** for MongoDB metrics
- **ServiceMonitors** for automatic service discovery
- **Pre-built dashboards** for all services

## Prerequisites

1. Kubernetes cluster with Helm 3.x installed
2. Node.js application deployed (from previous guide)
3. Sufficient resources (recommend 4GB+ memory for monitoring stack)

## Part 1 - Deploy Prometheus Stack

### Add Prometheus Community Helm Repository

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### Create Monitoring Namespace

```bash
kubectl create namespace monitoring
```

### Deploy kube-prometheus-stack

```bash
# Install the prometheus stack
helm install prom-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values monitoring/prometheus-stack-values.yaml \
  --wait

# Verify deployment
kubectl get pods -n monitoring
```

Expected output should show all pods running:
```bash
NAME                                                   READY   STATUS    RESTARTS   AGE
alertmanager-prom-stack-kube-prometheus-alertmanager   2/2     Running   0          2m
prom-stack-grafana-xxx                                 3/3     Running   0          2m
prom-stack-kube-prometheus-operator-xxx                1/1     Running   0          2m
prom-stack-kube-state-metrics-xxx                      1/1     Running   0          2m
prom-stack-prometheus-node-exporter-xxx                1/1     Running   0          2m
prometheus-prom-stack-kube-prometheus-prometheus-0     2/2     Running   0          2m
```

### Access Grafana

Grafana is exposed via NodePort, so no port forwarding is needed:

```bash
# Get your node IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
if [ -z "$NODE_IP" ]; then
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
fi
echo "Grafana URL: http://${NODE_IP}:30002"
```

- **URL**: http://NODE_IP:30002
- **Username**: admin
- **Password**: admin123

## Part 2 - Deploy Application with Monitoring

### Update and Deploy Application

```bash
# Deploy/upgrade the application with monitoring enabled
helm upgrade --install nodejs-app ./helmchart --namespace nodejs-app

# Verify all services are running
kubectl get pods -n nodejs-app
```

### Verify ServiceMonitors

```bash
# Check that ServiceMonitors are created
kubectl get servicemonitor -n nodejs-app

# Expected output:
# NAME                   AGE
# nodejs-app-mongodb     1m
# nodejs-app-nodejs-app  1m
# nodejs-app-redis       1m
```



## Part 3 - Import Grafana Dashboards

### you can import them through garfana dashboards
- lookup the name of your exporter and the image and import the dashboard



## Part 4 - Generate Test Traffic

### Generate Application Traffic

```bash
# Port forward to application
kubectl port-forward service/nodejs-app-nodejs-app-service 3000:3000 -n nodejs-app

# In another terminal, generate traffic
for i in {1..100}; do
  curl http://localhost:3000
  curl http://localhost:3000/health
  curl http://localhost:3000/redis-test
  curl http://localhost:3000/mongo-test
  sleep 1
done
```

### Load Testing Script

Create a simple load testing script:

```bash
# Create load test script
cat > load-test.sh << 'EOF'
#!/bin/bash
echo "Starting load test..."
for i in {1..1000}; do
  curl -s http://localhost:3000 > /dev/null &
  curl -s http://localhost:3000/redis-test > /dev/null &
  curl -s http://localhost:3000/mongo-test > /dev/null &
  
  if [ $((i % 10)) -eq 0 ]; then
    echo "Completed $i requests"
    sleep 1
  fi
done
wait
echo "Load test completed!"
EOF

chmod +x load-test.sh
./load-test.sh
```

## Part 5 - Monitoring and Dashboards

### Node.js Application Dashboard

**Key Metrics:**
- HTTP request rate and duration
- Memory usage (RSS, Heap)
- CPU usage
- Active handles and requests

**Queries:**
```promql
# Request rate
rate(http_request_count_total[5m])

# 95th percentile response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# Memory usage
process_resident_memory_bytes
```

### Redis Dashboard

**Key Metrics:**
- Connected clients
- Memory usage
- Commands per second
- Cache hit ratio
- Key count by database

**Queries:**
```promql
# Connected clients
redis_connected_clients

# Hit rate
redis_keyspace_hits_total / (redis_keyspace_hits_total + redis_keyspace_misses_total) * 100

# Commands per second
rate(redis_commands_processed_total[5m])
```

### MongoDB Dashboard

**Key Metrics:**
- Active connections
- Operations per second
- Memory usage
- Document operations (CRUD)
- Network traffic

**Queries:**
```promql
# Current connections
mongodb_connections{state="current"}

# Operations per second
rate(mongodb_op_counters_total[5m])

# Memory usage
mongodb_memory{type="resident"}
```





### Useful Commands

```bash
# Check all monitoring resources
kubectl get all -n monitoring
kubectl get all -n nodejs-app

# Get node IP for accessing services
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
if [ -z "$NODE_IP" ]; then
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
fi
echo "Access URLs:"
echo "Grafana: http://${NODE_IP}:30002"
echo "Prometheus: http://${NODE_IP}:30003"

# Check ServiceMonitor status
kubectl describe servicemonitor -n nodejs-app

# View metrics from exporters
kubectl port-forward svc/nodejs-app-redis 9121:9121 -n nodejs-app
curl http://localhost:9121/metrics | grep redis_connected_clients

kubectl port-forward svc/nodejs-app-mongodb 9216:9216 -n nodejs-app
curl http://localhost:9216/metrics | grep process_virtual_memory_max_bytes
```

## Part 8 - Cleanup

### Remove Monitoring Stack

```bash
# Uninstall Prometheus stack
helm uninstall prom-stack -n monitoring

# Remove monitoring namespace
kubectl delete namespace monitoring

# Remove alert rules
kubectl delete -f monitoring/alert-rules.yaml
```

### Remove Application Monitoring

```bash
# Disable monitoring in application
helm upgrade nodejs-app ./helmchart --namespace nodejs-app --set monitoring.enabled=false

# Or completely remove application
helm uninstall nodejs-app -n nodejs-app
kubectl delete namespace nodejs-app
```

### reference:
https://apgapg.medium.com/creating-a-service-monitor-in-kubernetes-c0941a63c227

