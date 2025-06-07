const mongoose = require("mongoose");

// Cache the database connection
let cached = global.mongoose;

if (!cached) {
  cached = global.mongoose = { conn: null, promise: null };
}

const connectDB = async (url) => {
  try {
    console.log("Checking MongoDB connection...");
    
    // If we have a cached connection, return it
    if (cached.conn) {
      console.log("Using cached MongoDB connection");
      return cached.conn;
    }

    // If we don't have a connection promise, create one
    if (!cached.promise) {
      const opts = {
        bufferCommands: true, // Enable buffering
        serverSelectionTimeoutMS: 5000, // Timeout after 5s instead of 30s
        socketTimeoutMS: 45000, // Close sockets after 45s of inactivity
      };

      console.log("Creating new MongoDB connection...");
      cached.promise = mongoose.connect(url, opts).then((mongoose) => {
        console.log("Successfully connected to MongoDB!");
        return mongoose;
      });
    }

    // Wait for the connection promise to resolve
    cached.conn = await cached.promise;
    return cached.conn;
  } catch (error) {
    console.error("MongoDB connection error:", error);
    cached.promise = null; // Clear the promise on error
    throw error;
  }
};

module.exports = connectDB;
