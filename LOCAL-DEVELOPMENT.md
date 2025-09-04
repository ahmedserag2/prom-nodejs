# Local Development Guide

This guide will help you set up and run the Node.js application with Redis and MongoDB locally using Docker Compose.

## Prerequisites

- Docker and Docker Compose installed
- Git (to clone the repository)

## Quick Start

1. **Clone the repository and navigate to the project directory**:
   ```bash
   git clone <your-repo-url>
   cd nodejs-app
   ```

2. **Start the development environment**:
   ```bash
   # Make the script executable (Linux/Mac)
   chmod +x start-local.sh
   ./start-local.sh
   
   # Or manually with Docker Compose
   docker-compose up -d
   ```

3. **Test the application**:
   - Main app: http://localhost:3000
   - Health check: http://localhost:3000/health
   - Redis test: http://localhost:3000/redis-test
   - MongoDB test: http://localhost:3000/mongo-test

## Available Services

### Application Services
- **Node.js App**: Port 3000
- **Redis**: Port 6379
- **MongoDB**: Port 27017

### Admin Interfaces
- **Redis Commander**: http://localhost:8081
- **MongoDB Express**: http://localhost:8082 (username: admin, password: admin)

## Development Workflow

### Making Code Changes

1. **For Node.js app changes**:
   ```bash
   # Stop the app container
   docker-compose stop nodejs-app
   
   # Rebuild and start
   docker-compose up -d --build nodejs-app
   ```

2. **View logs**:
   ```bash
   # All services
   docker-compose logs -f
   
   # Specific service
   docker-compose logs -f nodejs-app
   docker-compose logs -f redis
   docker-compose logs -f mongodb
   ```

### Database Management

1. **Access Redis CLI**:
   ```bash
   docker-compose exec redis redis-cli
   ```

2. **Access MongoDB shell**:
   ```bash
   docker-compose exec mongodb mongosh -u admin -p password
   ```

3. **Reset data**:
   ```bash
   # Stop services and remove volumes
   docker-compose down -v
   
   # Start fresh
   docker-compose up -d
   ```

## Troubleshooting

### Common Issues

1. **Port already in use**:
   ```bash
   # Check what's using the port
   lsof -i :3000
   
   # Stop the process or change ports in docker-compose.yml
   ```

2. **Services not connecting**:
   ```bash
   # Check service status
   docker-compose ps
   
   # Check networks
   docker network ls
   docker network inspect nodejs-app_app-network
   ```

3. **Database connection issues**:
   ```bash
   # Check database logs
   docker-compose logs redis
   docker-compose logs mongodb
   
   # Verify environment variables
   docker-compose exec nodejs-app env | grep -E "(REDIS|MONGO)"
   ```

### Cleanup

```bash
# Stop all services
docker-compose down

# Stop and remove volumes (deletes data)
docker-compose down -v

# Remove images
docker-compose down --rmi all
```

## Environment Variables

You can customize the setup by creating a `.env` file:

```env
# Application
PORT=3000

# Redis
REDIS_URL=redis://redis:6379

# MongoDB
MONGO_URL=mongodb://mongodb:27017
MONGO_DB_NAME=nodejs_app
MONGO_USERNAME=admin
MONGO_PASSWORD=password
```

## Testing Endpoints

### Health Check
```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "OK",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "services": {
    "redis": "connected",
    "mongodb": "connected"
  }
}
```

### Redis Test
```bash
curl http://localhost:3000/redis-test
```

### MongoDB Test
```bash
curl http://localhost:3000/mongo-test
```

### Metrics
```bash
curl http://localhost:3000/metrics
```
