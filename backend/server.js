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

// ^ Routes
const authRoutes = require("./routes/auth");
const reportsRoutes = require("./routes/reports");
const analyticsRoutes = require("./routes/analytics");
const notificationRoutes = require("./routes/notifications");
const interventionRoutes = require("./routes/interventions");
const adminPostRoutes = require("./routes/adminPosts");

app.use("/api/v1/auth", authRoutes);
app.use("/api/v1/reports", reportsRoutes);
app.use("/api/v1/analytics", analyticsRoutes);
app.use("/api/v1/notifications", notificationRoutes);
app.use("/api/v1/interventions", interventionRoutes);
app.use("/api/v1/adminposts", adminPostRoutes);

// Routes
app.use("/api/v1/auth", require("./routes/auth"));
app.use("/api/v1/reports", require("./routes/reports"));
app.use("/api/v1/analytics", require("./routes/analytics"));
app.use("/api/v1/notifications", require("./routes/notifications"));
app.use("/api/v1/barangays", require("./routes/barangays"));

// Error handling
app.use(errorController);

// Server startup
const start = async () => {
  try {
    await connectDB(process.env.MONGO_URI);
    app.listen(process.env.PORT, () => {
      console.log(`Server running on port ${process.env.PORT}`);
    });
  } catch (error) {
    console.error("Server startup failed:", error);
    process.exit(1);
  }
};

start();
