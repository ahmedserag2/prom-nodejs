#!/bin/bash

set -e

echo "🚀 Deploying Complete Monitoring Stack for Node.js Application"
echo "=============================================================="

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

# Check prerequisites
print_status "Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    print_error "helm is not installed or not in PATH"
    exit 1
fi

# Check cluster connection
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

print_success "Prerequisites check passed"

# Step 1: Add Helm repositories
print_status "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
print_success "Helm repositories updated"

# Step 2: Create namespaces
print_status "Creating namespaces..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace nodejs-app --dry-run=client -o yaml | kubectl apply -f -
print_success "Namespaces created"

# Step 3: Deploy Prometheus Stack
print_status "Deploying Prometheus Stack..."
helm upgrade --install prom-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values monitoring/prometheus-stack-values.yaml \
  --wait \
  --timeout=600s

print_success "Prometheus Stack deployed"

# Step 4: Deploy Node.js Application with monitoring
print_status "Deploying Node.js application with monitoring..."
helm upgrade --install nodejs-app ./helmchart --namespace nodejs-app --wait

print_success "Node.js application deployed"

# Step 5: Wait for all pods to be ready
print_status "Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod --all -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod --all -n nodejs-app --timeout=300s

print_success "All pods are ready"

# Step 6: Create Grafana dashboard ConfigMaps
print_status "Creating Grafana dashboard ConfigMaps..."

kubectl create configmap nodejs-dashboard \
  --from-file=monitoring/grafana-dashboards/nodejs-dashboard.json \
  -n monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create configmap redis-dashboard \
  --from-file=monitoring/grafana-dashboards/redis-dashboard.json \
  -n monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl create configmap mongodb-dashboard \
  --from-file=monitoring/grafana-dashboards/mongodb-dashboard.json \
  -n monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

# Label them for Grafana to discover
kubectl label configmap nodejs-dashboard grafana_dashboard=1 -n monitoring --overwrite
kubectl label configmap redis-dashboard grafana_dashboard=1 -n monitoring --overwrite
kubectl label configmap mongodb-dashboard grafana_dashboard=1 -n monitoring --overwrite

print_success "Grafana dashboards configured"

# Step 7: Restart Grafana to pick up dashboards
print_status "Restarting Grafana to load dashboards..."
kubectl rollout restart deployment prom-stack-grafana -n monitoring
kubectl rollout status deployment prom-stack-grafana -n monitoring --timeout=120s

print_success "Grafana restarted"

# Step 8: Verify deployment
print_status "Verifying deployment..."

echo ""
echo "📊 Monitoring Stack Status:"
kubectl get pods -n monitoring
echo ""
echo "🚀 Application Status:"
kubectl get pods -n nodejs-app
echo ""
echo "🔍 ServiceMonitors:"
kubectl get servicemonitor -n nodejs-app

# Step 9: Get node IP for access
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
if [ -z "$NODE_IP" ]; then
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
fi

# Step 10: Display access information
echo ""
echo "🎉 Deployment Complete!"
echo "======================="
echo ""
echo "📱 Access Information:"
echo "  • Grafana: http://${NODE_IP}:30002 (admin/admin123)"
echo "    No port forwarding needed!"
echo ""
echo "  • Prometheus: http://${NODE_IP}:30003"
echo "    No port forwarding needed!"
echo ""
echo "  • AlertManager: kubectl port-forward service/prom-stack-kube-prometheus-alertmanager 9093:9093 -n monitoring"
echo "    URL: http://localhost:9093"
echo ""
echo "  • Node.js App: kubectl port-forward service/nodejs-app-nodejs-app-service 3000:3000 -n nodejs-app"
echo "    URL: http://localhost:3000"
echo ""
echo "🧪 Generate Test Traffic:"
echo "  Run: ./generate-traffic.sh"
echo ""
echo "📚 For detailed instructions, see: MONITORING-SETUP.md"

# Create traffic generation script
cat > generate-traffic.sh << 'EOF'
#!/bin/bash
echo "🚀 Starting traffic generation..."
echo "Make sure to run: kubectl port-forward service/nodejs-app-nodejs-app-service 3000:3000 -n nodejs-app"
echo ""

for i in {1..100}; do
  curl -s http://localhost:3000 > /dev/null &
  curl -s http://localhost:3000/health > /dev/null &
  curl -s http://localhost:3000/redis-test > /dev/null &
  curl -s http://localhost:3000/mongo-test > /dev/null &
  
  if [ $((i % 10)) -eq 0 ]; then
    echo "✅ Completed $i requests"
    sleep 2
  fi
done

wait
echo "🎉 Traffic generation completed!"
EOF

chmod +x generate-traffic.sh

print_success "Monitoring stack deployment completed successfully!"
