const express = require("express");
const auth = require("../middleware/authentication");
const {
  getAllReports,
  getReport,
  createReport,
  deleteReport,
  updateReportStatus,
} = require("../controllers/reportController");

const router = express.Router();

router.get("/", getAllReports);
router.get("/:id", getReport);
router.post("/", auth, createReport); // Simplified
router.delete("/:id", deleteReport);
router.patch("/:id", updateReportStatus);

module.exports = router;
