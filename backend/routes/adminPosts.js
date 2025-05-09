const express = require("express");
const {
  createAdminPost,
  getAllAdminPosts,
  getAdminPost,
  updateAdminPost,
  deleteAdminPost,
} = require("../controllers/adminPostController");

const auth = require("../middleware/authentication"); // Import auth middleware

const router = express.Router();

// Create a new AdminPost (requires authentication)
router.post("/", auth, createAdminPost);

// Get all AdminPosts (requires authentication)
router.get("/", auth, getAllAdminPosts); // Added auth middleware here

// Get a single AdminPost by ID (requires authentication)
router.get("/:id", auth, getAdminPost); // Added auth middleware here

// Update an AdminPost (requires authentication)
router.patch("/:id", auth, updateAdminPost);

// Delete an AdminPost (requires authentication)
router.delete("/:id", auth, deleteAdminPost);

module.exports = router;
