const express = require("express");
const {
  submitCsvFile,
  retrievePatternRecognitionResults,
  getLocationRiskLevelByWeather,
  getAllAlerts,
  getAlertsByBarangay,
  getAlertsByBarangayName,
  retrieveTrendsAndPatterns,
  analyzeInterventionEffectivity,
  getPriorityByCaseDeath,
  analyzeDengueHotspots,
  handleCrowdsourcedReportsAnalysis,
  triggerDengueCaseReportAnalysis,
} = require("../controllers/analyticsController");
const { findNeighboringBarangays } = require("../utils/geoUtils");

const router = express.Router();

// ? UPDATED
router.post("/submit-csv-file", submitCsvFile);

router.get(
  "/retrieve-pattern-recognition-results",
  retrievePatternRecognitionResults
);

// Endpoint to analyze crowdsourced reports and update barangay statuses, should be called when the admin logs in.
router.get("/analyze-crowdsourced-reports", handleCrowdsourcedReportsAnalysis);

// Endpoint to trigger dengue case report analysis from CSV data
router.get("/trigger-dengue-analysis", triggerDengueCaseReportAnalysis);

router.post("/get-barangay-weekly-trends", retrieveTrendsAndPatterns);

router.post(
  "/analyze-intervention-effectivity",
  analyzeInterventionEffectivity
);

// ! NEED TO BE UPDATED
// router.get("/get-location-weather-risk", getLocationRiskLevelByWeather);

router.get("/case-death-priority", getPriorityByCaseDeath);

router.get("/hotspots", analyzeDengueHotspots);

module.exports = router;
