const express = require("express");
const auth = require("../middleware/authentication");
const {
  getAllReports,
  getReport,
  createReport,
  deleteReport,
  updateReportStatus,
  getNearbyReports,
  getComments,
  createComment,
  upvoteReport,
  downvoteReport,
  removeUpvote,
  removeDownvote,
  deleteAllReports,
} = require("../controllers/reportController");

const router = express.Router();

// Public routes (no auth)
router.post("/nearby", getNearbyReports);
router.get("/:postId/comments", getComments);

// Protected routes (require authentication)

// Report routes
router.get("/", getAllReports);
router.get("/:id", getReport);
router.use(auth);

router.post("/", createReport);
router.delete("/all", deleteAllReports);
router.delete("/:id", deleteReport);
router.patch("/:id", updateReportStatus);

// Vote routes
router.post("/:id/upvote", upvoteReport);
router.post("/:id/downvote", downvoteReport);
router.delete("/:id/upvote", removeUpvote);
router.delete("/:id/downvote", removeDownvote);

// Comment routes
router.post("/:postId/comments", createComment);

module.exports = router;
