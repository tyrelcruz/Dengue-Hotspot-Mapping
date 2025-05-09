const express = require('express');
const app = express();
const alertRoutes = require('./routes/alerts');

// Make sure you have these middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/v1/alerts', alertRoutes);

// ... rest of your code ... 