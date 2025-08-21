const express = require("express");
const {
  submitCsvFile,
  retrievePatternRecognitionResults,
  retrieveTrendsAndPatterns,
  analyzeInterventionEffectivity,
  analyzeDengueHotspots,
  handleCrowdsourcedReportsAnalysis,
  triggerDengueCaseReportAnalysis,
  generateRecommendation,
  supplyDengueHighlightsData,
} = require("../controllers/analyticsController");

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

router.get("/hotspots", analyzeDengueHotspots);

router.post("/generate-recommendation", generateRecommendation);

router.get("/dengue-highlights", supplyDengueHighlightsData);

module.exports = router;
