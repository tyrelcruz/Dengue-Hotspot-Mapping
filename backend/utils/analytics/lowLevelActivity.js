const csv = require("csv-parser");
const { createReadStream } = require("fs");
const {
  getIsoWeekBoundaries,
  calculateWeeklyTotals,
} = require("./isoWeekUtils");

async function checkLowLevelActivity(options = {}) {
  const { data, masterCsvPath = "data/main.csv" } = options;

  let processedData;

  // If no dataframe is provided, read from CSV
  if (!data) {
    try {
      processedData = await readCsvData(masterCsvPath);

      if (processedData.length === 0) {
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
  } else {
    processedData = data;
  }

  const alerts = [];

  // Get the latest date in the dataset
  const latestDate = new Date(
    Math.max(...processedData.map((row) => row.DAdmit))
  );

  // Get ISO week boundaries for the past 4 weeks
  const weekBoundaries = getIsoWeekBoundaries(latestDate, 4);

  // Get all unique barangays from the dataset
  const allBarangays = [...new Set(processedData.map((row) => row.Barangay))];

  // Process each barangay separately
  for (const barangay of allBarangays) {
    // Filter data for this barangay
    const barangayData = processedData.filter(
      (row) => row.Barangay === barangay
    );

    // Calculate weekly totals using ISO weeks
    const weeklyData = calculateWeeklyTotals(barangayData, weekBoundaries);

    // Check if all weeks have 0 or 1 cases
    if (weeklyData.every((week) => week.total <= 1)) {
      // Count weeks with exactly 1 case
      const weeksWithOneCase = weeklyData.filter(
        (week) => week.total === 1
      ).length;

      // Only trigger low-level activity if there is at least one week with 1 case
      // (all 0s would be handled by the stability pattern)
      if (weeksWithOneCase > 0) {
        const alertMsg = `Detected low level activity over the past 4 weeks, with ${weeksWithOneCase} week(s) having exactly 1 case and the rest having no cases.`;

        alerts.push({
          barangay: barangay,
          // admin_recommendation:
          //     "- No recommendation available for the identified pattern.",
          //   user_recommendation:
          //     "- No recommendation available for the identified pattern.",
          // },
          pattern: "low_level_activity",
          alert: alertMsg,
          recommendation: "Maintain routine surveillance and prevention measures. Continue community education and vector control activities to prevent escalation of cases.",
        });
      }
    }
  }

  return alerts.length > 0
    ? alerts
    : [
        {
          barangay: null,
          pattern: "",
          alert: "No low level activity detected",
          recommendation: "",
        },
      ];
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
  checkLowLevelActivity({ masterCsvPath: "data/main.csv" })
    .then((alerts) => {
      for (const alert of alerts) {
        console.log(alert);
      }
    })
    .catch((error) => {
      console.error("Error:", error.message);
    });
}

module.exports = {
  checkLowLevelActivity,
};
