require("dotenv").config();
const path = require("path");

// ^ Security
const cors = require("cors");

// ^ Errors
const errorController = require("./errors/error-controller");

const express = require("express");
const app = express();

// ^ Middleware
app.use("/uploads", express.static(path.join(__dirname, "uploads")));
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(cors({
  origin: "http://localhost:5173",
  credentials: true, // if you need to send cookies or auth headers
}));

// ^ Connect to the database
const connectDB = require("./db/connect");

// ^ Routes
const authRoutes = require("./routes/auth");
const reportsRoutes = require("./routes/reports");
// const analyticsRoutes = require("./routes/analytics");
const notificationRoutes = require("./routes/notifications");

app.use("/api/v1/auth", authRoutes);
app.use("/api/v1/reports", reportsRoutes);
// app.use("/api/v1/analytics", analyticsRoutes);
app.use("/api/v1/notifications", notificationRoutes);

app.use(errorController);

// ! FOR TESTING ONLY, UNCOMMENT WHEN NEEDED
// const testRoutes = require("./test/testRoutes");
// app.use("/api/v1/test", testRoutes);

// * Start the server
const start = async () => {
  console.log("Starting the backend server...");

  try {
    await connectDB(process.env.MONGO_URI);
    app.listen(process.env.PORT, () => {
      console.log("Connected to MongoDB.");
      console.log(`Server is up and listening on port ${process.env.PORT}`);
    });
  } catch (error) {
    console.error("Error connecting to database:", error);
  }
};

start();
