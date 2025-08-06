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

// Add a catch-all debug log for every request to this router
router.use((req, res, next) => {
  console.log(`[DEBUG] ${req.method} ${req.originalUrl}`);
  next();
});

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
router.post("/:id/upvote", auth, upvoteReport);
router.post("/:id/downvote", auth, downvoteReport);
router.delete("/:id/upvote", auth, removeUpvote);
router.delete("/:id/downvote", auth, removeDownvote);

// Comment routes
router.post("/:postId/comments", createComment);

module.exports = router;
