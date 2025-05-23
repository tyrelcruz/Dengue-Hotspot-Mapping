require("dotenv").config();
const path = require("path");
const fileUpload = require("express-fileupload"); // Now properly installed

// Security
const cors = require("cors");
const errorController = require("./errors/error-controller");

const express = require("express");
const app = express();

// Middleware
app.use(
  cors({
    origin: "*",
    credentials: true,
  })
);

// Body parsing
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ extended: true, limit: "50mb" }));

// File upload handling
app.use(
  fileUpload({
    limits: {
      fileSize: 10 * 1024 * 1024, // 10MB
    },
    abortOnLimit: true,
    useTempFiles: false,
    createParentPath: true, // Creates upload directory if needed
  })
);

// Database connection
const connectDB = require("./db/connect");

// Routes
app.use("/api/v1/auth", require("./routes/auth"));
app.use("/api/v1/reports", require("./routes/reports"));
app.use("/api/v1/analytics", require("./routes/analytics"));
app.use("/api/v1/notifications", require("./routes/notifications"));
app.use("/api/v1/interventions", require("./routes/interventions"));
app.use("/api/v1/adminposts", require("./routes/adminPosts"));
app.use("/api/v1/alerts", require("./routes/alerts"));
app.use("/api/v1/barangays", require("./routes/barangays"));
app.use("/api/v1/accounts", require("./routes/accounts"));

// Error handling
app.use(errorController);

// Server startup
const start = async () => {
  try {
    await connectDB(process.env.MONGO_URI);
    const server = app.listen(process.env.PORT, () => {
      console.log(`Server running on port ${process.env.PORT}`);
    });

    // Handle server errors
    server.on('error', (error) => {
      if (error.code === 'EADDRINUSE') {
        console.log(`Port ${process.env.PORT} is busy, trying ${process.env.PORT + 1}`);
        server.close();
        app.listen(process.env.PORT + 1, () => {
          console.log(`Server running on port ${process.env.PORT + 1}`);
        });
      } else {
        console.error('Server error:', error);
      }
    });

  } catch (error) {
    console.error("Server startup failed:", error);
    process.exit(1);
  }
};

start();
