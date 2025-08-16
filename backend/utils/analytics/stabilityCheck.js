const csv = require("csv-parser");
const { createReadStream } = require("fs");
const {
  getIsoWeekBoundaries,
  calculateWeeklyTotals,
} = require("./isoWeekUtils");

// Simple linear regression implementation
function linearRegression(x, y) {
  const n = x.length;
  if (n !== y.length || n === 0) {
    throw new Error("Invalid data for linear regression");
  }

  let sumX = 0;
  let sumY = 0;
  let sumXY = 0;
  let sumX2 = 0;

  for (let i = 0; i < n; i++) {
    sumX += x[i];
    sumY += y[i];
    sumXY += x[i] * y[i];
    sumX2 += x[i] * x[i];
  }

  const slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  const intercept = (sumY - slope * sumX) / n;

  return { slope, intercept };
}

async function checkStable(options = {}) {
  const { data, masterCsvPath = "data/main.csv", slopeThreshold = 0 } = options;

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

    // Prepare data for linear regression
    const x = Array.from({ length: weeklyData.length }, (_, i) => i);
    const y = weeklyData.map((week) => week.total);

    try {
      // Fit linear regression model
      const { slope } = linearRegression(x, y);

      // Check if the slope indicates perfect stability (exactly 0)
      if (Math.abs(slope) === slopeThreshold) {
        // Check if all weeks have zero cases
        if (y.every((total) => total === 0)) {
          const alertMsg = "No dengue cases reported over the past 4 weeks.";

          alerts.push({
            barangay: barangay,
            // admin_recommendation:
            //     "- Implement and exercise zero case reporting even if no cases have been found.",
            //   user_recommendation:
            //     "- Maintain the cleanliness of your household surroundings by cleaning up and clearing out any potential mosquito breeding sites.\n- If you are experiencing any dengue-related symptoms, seek for consultation and early treatment at your nearby health facilities.",
            // },
            pattern: "stability",
            alert: alertMsg,
            recommendation: "Continue routine surveillance and prevention measures. Maintain current vector control strategies and community education programs to sustain the stable situation.",
          });
        } else {
          const alertMsg = `A consistent reporting of ${y[0]} case(s) per week was detected over the past 4 weeks.`;

          alerts.push({
            barangay: barangay,
            // admin_recommendation:
            //     "- Implement and exercise zero case reporting even if no cases have been found.",
            //   user_recommendation:
            //     "- Maintain the cleanliness of your household surroundings by cleaning up and clearing out any potential mosquito breeding sites.\n- If you are experiencing any dengue-related symptoms, seek for consultation and early treatment at your nearby health facilities.",
            // },
            pattern: "stability",
            alert: alertMsg,
            recommendation: "Continue routine surveillance and prevention measures. Maintain current vector control strategies and community education programs to sustain the stable situation.",
          });
        }
      }
    } catch (error) {
      // Skip this barangay if linear regression fails
      console.warn(
        `Linear regression failed for barangay ${barangay}: ${error.message}`
      );
    }
  }

  return alerts.length > 0
    ? alerts
    : [
        {
          barangay: null,
          pattern: "",
          alert: "No stability detected",
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
  checkStable({ masterCsvPath: "data/main.csv" })
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
  checkStable,
};
