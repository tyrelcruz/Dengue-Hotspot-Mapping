const mongoose = require("mongoose");

// Cache the database connection
let cached = global.mongoose;

if (!cached) {
  cached = global.mongoose = { conn: null, promise: null };
}

const connectDB = async (url) => {
  try {
    console.log("Checking MongoDB connection...");

    // If we have a cached connection, check if it's still alive
    if (cached.conn) {
      // Check if connection is still valid
      if (mongoose.connection.readyState === 1) {
        console.log("Using existing MongoDB connection");
        return cached.conn;
      } else {
        console.log("Cached connection is stale, clearing...");
        cached.conn = null;
        cached.promise = null;
      }
    }

    // If we don't have a connection promise, create one
    if (!cached.promise) {
      const opts = {
        bufferCommands: false, // Disable buffering to prevent timeouts
        serverSelectionTimeoutMS: 15000, // Increase to 15s
        socketTimeoutMS: 45000,
        connectTimeoutMS: 15000, // Connection timeout
        maxPoolSize: 1,
        minPoolSize: 0,
        maxIdleTimeMS: 30000,
        retryWrites: true,
        retryReads: true,
        // Connection validation
        heartbeatFrequencyMS: 10000,
      };

      console.log("Creating new MongoDB connection...");
      cached.promise = mongoose.connect(url, opts).then((mongoose) => {
        console.log("Successfully connected to MongoDB!");

        // Handle connection events for better monitoring
        mongoose.connection.on("error", (err) => {
          console.error("MongoDB connection error:", err);
          cached.conn = null;
          cached.promise = null;
        });

        mongoose.connection.on("disconnected", () => {
          console.log("MongoDB disconnected");
          cached.conn = null;
          cached.promise = null;
        });

        return mongoose;
      });
    }

    // Wait for the connection promise to resolve
    cached.conn = await cached.promise;

    // Additional validation - ensure connection is actually ready
    if (mongoose.connection.readyState !== 1) {
      throw new Error("MongoDB connection not ready after connection attempt");
    }

    return cached.conn;
  } catch (error) {
    console.error("MongoDB connection error:", error);
    cached.promise = null; // Clear the promise on error
    throw error;
  }
};

// Graceful shutdown function for Vercel
const closeConnection = async () => {
  if (cached.conn) {
    try {
      await mongoose.connection.close();
      console.log("MongoDB connection closed gracefully");
      cached.conn = null;
      cached.promise = null;
    } catch (error) {
      console.error("Error closing MongoDB connection:", error);
    }
  }
};

module.exports = { connectDB, closeConnection };
