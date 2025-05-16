const express = require("express");
const auth = require("../middleware/authentication");
const {
  getAllReports,
  getReport,
  createReport,
  deleteReport,
  updateReportStatus,
  getNearbyReports,
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

module.exports = router;
