const fs = require("fs").promises;
const csv = require("csv-parser");
const { createReadStream } = require("fs");
const { checkSpike } = require("../../utils/analytics/spikeDetection");
const { checkGradualRise } = require("../../utils/analytics/gradualRise");
const { checkDecline } = require("../../utils/analytics/declineCheck");
const { checkStable } = require("../../utils/analytics/stabilityCheck");
const {
  checkLowLevelActivity,
} = require("../../utils/analytics/lowLevelActivity");

async function analyzeDengueAlerts(masterCsvPath = "data/main.csv") {
  let data;

  try {
    // Read the data
    data = await readCsvData(masterCsvPath);

    if (data.length === 0) {
      return [
        {
          barangay: null,
          pattern: "",
          alert: "No data available for analysis",
          recommendation: "",
        },
      ];
    }
  } catch (error) {
    return [
      {
        barangay: null,
        pattern: "",
        alert: `Error reading data: ${error.message}`,
        recommendation: "",
      },
    ];
  }

  const alerts = [];

  // Pass the data to each subfunction
  alerts.push(...(await checkSpike({ data })));
  alerts.push(...(await checkGradualRise({ data })));
  alerts.push(...(await checkDecline({ data })));
  alerts.push(...(await checkLowLevelActivity({ data })));
  alerts.push(...(await checkStable({ data })));

  // Get all unique barangays from the dataset
  const allBarangays = [...new Set(data.map((row) => row.Barangay))];

  // Create a dictionary to store alerts by barangay
  const barangayAlerts = {};

  // Initialize all barangays with no alert status
  for (const barangay of allBarangays) {
    barangayAlerts[barangay] = {
      barangay: barangay,
      pattern: "",
      alert: "No alerts triggered.",
      recommendation: "",
    };
  }

  const patternPriority = {
    spike: 5,
    low_level_activity: 4,
    gradual_rise: 3,
    decline: 2,
    stability: 1,
    "": 0, // Empty status has lowest priority
  };

  // Update alerts for barangays with detected patterns
  for (const alert of alerts) {
    const barangay = alert.barangay;
    const currentPattern = alert.pattern;

    if (barangay && barangayAlerts[barangay]) {
      const currentPriority = patternPriority[currentPattern] || 0;
      const existingPriority =
        patternPriority[barangayAlerts[barangay].pattern] || 0;
      if (currentPriority > existingPriority) {
        barangayAlerts[barangay] = alert;
      }
    }
  }

  return Object.values(barangayAlerts);
}

// Helper function to read CSV data
function readCsvData(filePath) {
  return new Promise((resolve, reject) => {
    const results = [];
    createReadStream(filePath)
      .pipe(csv())
      .on("data", (data) => {
        // Parse DAdmit as Date
        data.DAdmit = new Date(data.DAdmit);
        results.push(data);
      })
      .on("end", () => resolve(results))
      .on("error", (error) => reject(error));
  });
}

// For testing purposes
if (require.main === module) {
  (async () => {
    const alerts = await analyzeDengueAlerts("data/main.csv");

    // Group alerts by pattern type
    const patternGroups = {
      spike: [],
      gradual_rise: [],
      decline: [],
      low_level_activity: [],
      stability: [],
      no_alert: [],
    };

    for (const alert of alerts) {
      const status = alert.pattern;
      if (patternGroups[status]) {
        patternGroups[status].push(alert);
      } else {
        patternGroups["no_alert"].push(alert);
      }
    }

    // Print alerts by pattern type with breaks
    console.log("\n=== SPIKE DETECTIONS ===");
    for (const alert of patternGroups["spike"]) {
      console.log(alert);
    }

    console.log("\n=== GRADUAL RISE DETECTIONS ===");
    for (const alert of patternGroups["gradual_rise"]) {
      console.log(alert);
    }

    console.log("\n=== DECLINE DETECTIONS ===");
    for (const alert of patternGroups["decline"]) {
      console.log(alert);
    }

    console.log("\n=== LOW LEVEL ACTIVITY DETECTIONS ===");
    for (const alert of patternGroups["low_level_activity"]) {
      console.log(alert);
    }

    console.log("\n=== STABILITY DETECTIONS ===");
    for (const alert of patternGroups["stability"]) {
      console.log(alert);
    }

    console.log("\n=== NO ALERTS ===");
    for (const alert of patternGroups["no_alert"]) {
      console.log(alert);
    }
  })();
}

module.exports = {
  analyzeDengueAlerts,
};
