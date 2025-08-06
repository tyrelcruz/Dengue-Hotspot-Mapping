const express = require("express");
const router = express.Router();

const {
  getAllBarangays,
  getRecentReportsForBarangay,
  retrieveSpecificBarangayInfo,
} = require("../controllers/barangayController");

router.get("/get-all-barangays", getAllBarangays);

router.post("/get-recent-reports-for-barangay", getRecentReportsForBarangay);

router.get("/specific-barangay-info", retrieveSpecificBarangayInfo);

module.exports = router;
