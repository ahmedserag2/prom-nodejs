// MongoDB initialization script
// This script runs when the MongoDB container starts for the first time

db = db.getSiblingDB('nodejs_app');

// Create a collection for visits
db.createCollection('visits');

// Insert a sample document
db.visits.insertOne({
  message: 'MongoDB initialized successfully',
  timestamp: new Date(),
  type: 'initialization'
});

print('Database nodejs_app initialized with visits collection');
