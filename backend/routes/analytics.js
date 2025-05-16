const express = require("express");
const {
  patternRecognitionAnalysis,
  submitCsvFile,
  retrievePatternRecognitionResults,
  getLocationRiskLevelByWeather,
  getAllAlerts,
  getAlertsByBarangay,
  getAlertsByBarangayName,
  retrieveTrendsAndPatterns,
  analyzeInterventionEffectivity,
  getPriorityByCaseDeath,
} = require("../controllers/analyticsController");
const { detectClustersToday } = require("../services/clusterService");

const router = express.Router();

router.get("/pattern-recognition", patternRecognitionAnalysis);

router.get("/cluster-check", async (req, res) => {
  try {
    const clusters = await detectClustersToday();
    res.json({ clusters_detected: clusters });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to detect clusters." });
  }
});

router.post("/submit-csv-file", submitCsvFile);

router.get(
  "/retrieve-pattern-recognition-results",
  retrievePatternRecognitionResults
);

router.post("/get-location-weather-risk", getLocationRiskLevelByWeather);

router.post("/get-barangay-weekly-trends", retrieveTrendsAndPatterns);

router.post(
  "/analyze-intervention-effectivity",
  analyzeInterventionEffectivity
);

router.get("/case-death-priority", getPriorityByCaseDeath);

module.exports = router;
