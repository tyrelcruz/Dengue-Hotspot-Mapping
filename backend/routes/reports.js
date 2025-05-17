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
} = require("../controllers/reportController");

const router = express.Router();

// Public route: Nearby reports (no auth)
router.post("/nearby", getNearbyReports);
router.get("/", getAllReports);
router.get("/:id", getReport);
// All routes below require authentication
router.use(auth);

router.post("/", createReport);
router.delete("/:id", deleteReport);
router.patch("/:id", updateReportStatus);

// Comment routes
router.get("/:postId/comments", getComments);
router.post("/:postId/comments", createComment);

// Vote routes
router.post("/:id/upvote", upvoteReport);
router.post("/:id/downvote", downvoteReport);

module.exports = router;
