#!/bin/bash

echo "🚀 Starting Node.js App with Redis and MongoDB locally..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Start the services
echo "📦 Starting Docker Compose services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check service health
echo "🔍 Checking service health..."

echo "Testing Node.js app..."
curl -s http://localhost:3000 || echo "❌ Node.js app not responding"

echo "Testing health endpoint..."
curl -s http://localhost:3000/health || echo "❌ Health endpoint not responding"

echo "Testing Redis connection..."
curl -s http://localhost:3000/redis-test || echo "❌ Redis connection failed"

echo "Testing MongoDB connection..."
curl -s http://localhost:3000/mongo-test || echo "❌ MongoDB connection failed"

echo ""
echo "✅ Local development environment is ready!"
echo ""
echo "📱 Available endpoints:"
echo "   • Main app: http://localhost:3000"
echo "   • Health check: http://localhost:3000/health"
echo "   • Redis test: http://localhost:3000/redis-test"
echo "   • MongoDB test: http://localhost:3000/mongo-test"
echo "   • Metrics: http://localhost:3000/metrics"

echo ""
echo "🛑 To stop: docker-compose down"
