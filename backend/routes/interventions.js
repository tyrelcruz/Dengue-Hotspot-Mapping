// routes/interventionRoutes.js

const express = require("express");
const {
  createIntervention,
  getAllInterventions,
  getIntervention,
  updateIntervention,
  deleteIntervention,
} = require("../controllers/interventionController");

const auth = require("../middleware/authentication"); // Import auth middleware

const router = express.Router();

// Create a new intervention (requires authentication)
router.post("/", auth, createIntervention);

// Get all interventions (requires authentication)
router.get("/", auth, getAllInterventions); // Added auth middleware here

// Get a single intervention by ID (requires authentication)
router.get("/:id", auth, getIntervention); // Added auth middleware here

// Update an intervention (requires authentication)
router.patch("/:id", auth, updateIntervention);

// Delete an intervention (requires authentication)
router.delete("/:id", auth, deleteIntervention);

module.exports = router;
