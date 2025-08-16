const express = require("express");
const {
  createAdminPost,
  getAllAdminPosts,
  getAdminPost,
  updateAdminPost,
  deleteAdminPost,
  deleteAllAdminPosts,
  upvoteAdminPost,
  downvoteAdminPost,
  removeUpvote,
  removeDownvote
} = require("../controllers/adminPostController");

const auth = require("../middleware/authentication"); // Import auth middleware
const uploadImagesToPost = require("../middleware/uploadImagesToPost");

const router = express.Router();

// Create a new AdminPost (requires authentication)
router.post("/", auth, uploadImagesToPost, createAdminPost);

// Get all AdminPosts (requires authentication)
router.get("/", getAllAdminPosts); // Added auth middleware here

// Delete all AdminPosts (requires authentication)
router.delete("/all", auth, deleteAllAdminPosts);  // Move this BEFORE the /:id routes

// Get a single AdminPost by ID (requires authentication)
router.get("/:id", getAdminPost); // Added auth middleware here

// Update an AdminPost (requires authentication)
router.patch("/:id", auth, updateAdminPost);

// Delete an AdminPost (requires authentication)
router.delete("/:id", auth, deleteAdminPost);

// Voting routes
router.post("/:id/upvote", auth, upvoteAdminPost);
router.post("/:id/downvote", auth, downvoteAdminPost);
router.delete("/:id/upvote", auth, removeUpvote);
router.delete("/:id/downvote", auth, removeDownvote);

module.exports = router;
