const express = require("express");
const router = express.Router();
const { 
  addComment, 
  getComments, 
  upvoteComment, 
  downvoteComment, 
  removeUpvote, 
  removeDownvote 
} = require("../controllers/commentController");
const auth = require("../middleware/authentication");

// Base routes for comments - now works for both reports and admin posts
router.post("/:postId", auth, addComment);
router.get("/:postId", getComments);

// Voting routes for comments
router.post("/:commentId/upvote", auth, upvoteComment);
router.post("/:commentId/downvote", auth, downvoteComment);
router.delete("/:commentId/upvote", auth, removeUpvote);
router.delete("/:commentId/downvote", auth, removeDownvote);

module.exports = router; 