const express = require("express");
const {
  getInterventions,
  patternRecognitionAnalysis,
} = require("../controllers/analyticsController");
const { detectClustersToday } = require("../services/clusterService");
const router = express.Router();

router.post("/interventions", getInterventions);

router.post("/pattern-recognition", patternRecognitionAnalysis);

router.get("/cluster-check", async (req, res) => {
  try {
    const clusters = await detectClustersToday();
    res.json({ clusters_detected: clusters });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to detect clusters." });
  }
});

module.exports = router;
