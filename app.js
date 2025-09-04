const express = require('express');
const client = require('prom-client');
const redis = require('redis');
const { MongoClient } = require('mongodb');


const app = express();
const port = process.env.PORT || 3000;

// Database connection configurations
const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
const MONGO_URL = process.env.MONGO_URL || 'mongodb://localhost:27017';
const MONGO_DB_NAME = process.env.MONGO_DB_NAME || 'nodejs_app';

// Initialize Redis client
const redisClient = redis.createClient({ url: REDIS_URL });
let mongoClient;
let db;


// Prometheus metrics setup
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics();  // Collects CPU, memory, and other basic metrics automatically

// HTTP request duration histogram
const httpRequestDurationMicroseconds = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
});

// HTTP request count
const httpRequestCount = new client.Counter({
  name: 'http_request_count_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
});

// Middleware to track request metrics
app.use((req, res, next) => {
  const end = httpRequestDurationMicroseconds.startTimer();
  res.on('finish', () => {
    httpRequestCount.inc({ method: req.method, route: req.path, status_code: res.statusCode });
    end({ method: req.method, route: req.path, status_code: res.statusCode });
  });
  next();
});

// Expose metrics at /metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

// Database connection functions
async function connectDatabases() {
  try {
    // Connect to Redis
    await redisClient.connect();
    console.log('Connected to Redis');
    
    // Connect to MongoDB
    mongoClient = new MongoClient(MONGO_URL);
    await mongoClient.connect();
    db = mongoClient.db(MONGO_DB_NAME);
    console.log('Connected to MongoDB');
  } catch (error) {
    console.error('Database connection error:', error);
  }
}

// Initialize database connections
connectDatabases();

// Basic route
app.get('/', (req, res) => {
  res.send('Hello World! Redis and MongoDB are connected.');
});

// Redis demo route
app.get('/redis-test', async (req, res) => {
  try {
    const key = 'visit_count';
    const currentCount = await redisClient.get(key) || 0;
    const newCount = parseInt(currentCount) + 1;
    await redisClient.set(key, newCount);
    
    res.json({ 
      message: 'Redis test successful', 
      visit_count: newCount,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({ error: 'Redis connection failed', details: error.message });
  }
});

// MongoDB demo route
app.get('/mongo-test', async (req, res) => {
  try {
    const collection = db.collection('visits');
    const visit = {
      timestamp: new Date(),
      ip: req.ip,
      userAgent: req.get('User-Agent')
    };
    
    const result = await collection.insertOne(visit);
    const totalVisits = await collection.countDocuments();
    
    res.json({ 
      message: 'MongoDB test successful', 
      insertedId: result.insertedId,
      total_visits: totalVisits,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({ error: 'MongoDB connection failed', details: error.message });
  }
});

// Health check route
app.get('/health', async (req, res) => {
  const health = {
    status: 'OK',
    timestamp: new Date().toISOString(),
    services: {}
  };
  
  try {
    // Check Redis
    await redisClient.ping();
    health.services.redis = 'connected';
  } catch (error) {
    health.services.redis = 'disconnected';
    health.status = 'DEGRADED';
  }
  
  try {
    // Check MongoDB
    await mongoClient.db().admin().ping();
    health.services.mongodb = 'connected';
  } catch (error) {
    health.services.mongodb = 'disconnected';
    health.status = 'DEGRADED';
  }
  
  res.json(health);
});


app.get('/crash', (req, res) => {
  // Send a response before crashing
  res.send("Service is crashing...");

  // Log the crash
  console.error("Service is crashing...");

  // Option 1: Throw an uncaught error to crash the app
  // throw new Error("Intentional service crash");
  
  // Option 2: Exit the process with a non-zero code (uncomment to use this option)
  process.exit(1);
});

const server = app.listen(port, () => {
  console.log(`App listening at http://localhost:${port}`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  
  server.close(() => {
    console.log('HTTP server closed');
  });
  
  try {
    await redisClient.quit();
    console.log('Redis connection closed');
  } catch (error) {
    console.error('Error closing Redis connection:', error);
  }
  
  try {
    if (mongoClient) {
      await mongoClient.close();
      console.log('MongoDB connection closed');
    }
  } catch (error) {
    console.error('Error closing MongoDB connection:', error);
  }
  
  process.exit(0);
});

