const mongoose = require("mongoose");

const connectDB = (url) => {
  console.log("Attempting to connect to MongoDB...");
  return mongoose
    .connect(url)
    .then(() => {
      console.log("Successfully connected to MongoDB!");
    })
    .catch((error) => {
      console.error("MongoDB connection error:", error);
      throw error;
    });
};

module.exports = connectDB;
