const express = require("express");
const uploadImagesToPost = require("../middleware/uploadImagesToPost");
const auth = require("../middleware/authentication");
const {
  getAllReports,
  getReport,
  createReport,
  deleteReport,
  updateReportStatus
} = require("../controllers/reportController");
// const Report = require('../models/Reports');

const router = express.Router();

// * Get all posts
router.get("/", getAllReports);

// GET a specific post
router.get("/:id", getReport);

// POST a new post
router.post("/", auth, uploadImagesToPost, createReport);

// * Should be for the admin side.
router.delete("/:id", deleteReport);

// * Could be possibly used for updating the status of a report
router.patch("/:id", updateReportStatus);

module.exports = router;
