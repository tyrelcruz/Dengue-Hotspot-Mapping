const csv = require("csv-parser");
const { createReadStream } = require("fs");
const {
  getIsoWeekBoundaries,
  calculateWeeklyTotals,
} = require("./isoWeekUtils");

/**
 * DAILY SPIKE DETECTION ALGORITHM USING DBSCAN
 * 
 * This algorithm detects spikes by looking at daily case counts within a 2-week period.
 * It uses DBSCAN clustering to identify outliers in daily case counts, detecting when
 * a barangay experiences a sudden jump from normal daily cases (0-1) to significantly
 * higher daily cases (5+ cases in a single day).
 * 
 * Key features:
 * 1. Analyzes daily data points instead of weekly aggregates
 * 2. Uses DBSCAN to detect daily outliers
 * 3. Detects sudden daily spikes (e.g., 0-1 cases → 5-6 cases in one day)
 * 4. Considers baseline daily patterns for each barangay
 */

// Simple DBSCAN implementation for outlier detection on daily case counts
function dbscan(data, eps, minSamples) {
  const labels = new Array(data.length).fill(-1);
  let clusterId = 0;

  for (let i = 0; i < data.length; i++) {
    if (labels[i] !== -1) continue;

    const neighbors = findNeighbors(data, i, eps);

    if (neighbors.length < minSamples) {
      labels[i] = -1; // Noise point (outlier)
    } else {
      clusterId++;
      labels[i] = clusterId;
      expandCluster(data, labels, neighbors, clusterId, eps, minSamples);
    }
  }

  return labels;
}

function findNeighbors(data, pointIndex, eps) {
  const neighbors = [];
  for (let i = 0; i < data.length; i++) {
    if (i === pointIndex) continue;
    const distance = Math.abs(data[pointIndex] - data[i]);
    if (distance <= eps) {
      neighbors.push(i);
    }
  }
  return neighbors;
}

function expandCluster(data, labels, neighbors, clusterId, eps, minSamples) {
  for (let i = 0; i < neighbors.length; i++) {
    const neighborIndex = neighbors[i];

    if (labels[neighborIndex] === -1) {
      labels[neighborIndex] = clusterId;

      const newNeighbors = findNeighbors(data, neighborIndex, eps);
      if (newNeighbors.length >= minSamples) {
        neighbors.push(...newNeighbors);
      }
    }
  }
}

// Check if a daily case count represents a spike using DBSCAN
function isDailySpikeWithDBSCAN(dailyCases, options = {}) {
  const {
    minSpikeThreshold = 5,           // Minimum cases to consider a spike
    baselineThreshold = 1,            // Maximum cases considered "normal" baseline
    dbscanEps = 2,                   // DBSCAN epsilon (distance threshold)
    dbscanMinSamples = 2             // DBSCAN minimum samples for cluster
  } = options;

  // Apply DBSCAN to detect outliers in daily case counts
  const dbscanLabels = dbscan(dailyCases, dbscanEps, dbscanMinSamples);
  
  // Find the most recent day (last element)
  const mostRecentIndex = dailyCases.length - 1;
  const mostRecentCases = dailyCases[mostRecentIndex];
  
  // Check if the most recent day is an outlier (label -1) and meets spike criteria
  const isOutlier = dbscanLabels[mostRecentIndex] === -1;
  const isAboveSpikeThreshold = mostRecentCases >= minSpikeThreshold;
  const isAboveBaseline = mostRecentCases > baselineThreshold;
  
  // A spike is detected if:
  // 1. It's a DBSCAN outlier (label -1)
  // 2. It has enough cases to be considered a spike (5+ cases)
  // 3. It's above the baseline threshold (1+ cases)
  return isOutlier && isAboveSpikeThreshold && isAboveBaseline;
}

async function checkSpike(options = {}) {
  const {
    data,
    masterCsvPath = "data/main.csv",
    minSpikeThreshold = 5,
    baselineThreshold = 1,
    dbscanEps = 2,
    dbscanMinSamples = 2,
    analysisDays = 14  // 2 weeks = 14 days
  } = options;

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

  // Calculate the start date for 2-week analysis
  const startDate = new Date(latestDate);
  startDate.setDate(startDate.getDate() - analysisDays + 1);

  // Process each barangay separately
  const uniqueBarangays = [
    ...new Set(processedData.map((row) => row.Barangay)),
  ];

  for (const barangay of uniqueBarangays) {
    // Filter data for this barangay
    const barangayData = processedData.filter(
      (row) => row.Barangay === barangay
    );

    // Create a complete dataset with zero cases for missing dates
    const completeData = [];
    const currentDate = new Date(startDate);

    while (currentDate <= latestDate) {
      const existingRow = barangayData.find((row) => {
        const rowDate = new Date(row.DAdmit);
        return rowDate.toDateString() === currentDate.toDateString();
      });

      completeData.push({
        DAdmit: new Date(currentDate),
        Barangay: barangay,
        "Case Count": existingRow ? parseInt(existingRow["Case Count"]) : 0,
      });

      currentDate.setDate(currentDate.getDate() + 1);
    }

    // Extract daily case counts for the analysis period
    const dailyCases = completeData.map(day => day["Case Count"]);
    
    // Check if the daily pattern represents a spike using DBSCAN
    if (isDailySpikeWithDBSCAN(dailyCases, {
      minSpikeThreshold,
      baselineThreshold,
      dbscanEps,
      dbscanMinSamples
    })) {
      // Get baseline cases (all days except the most recent for comparison)
      const baselineCases = dailyCases.slice(0, -1);
      const mostRecentCases = dailyCases[dailyCases.length - 1];
      
      // Find the highest daily case count in the baseline for comparison
      const maxBaseline = Math.max(...baselineCases);
      
      let alertMsg;
      if (maxBaseline === 0) {
        alertMsg = `Detected a daily spike of dengue cases using DBSCAN outlier detection. Today: ${mostRecentCases} cases, Previous days: ${baselineCases.join(', ')} cases. This represents a sudden emergence of cases from zero baseline.`;
      } else {
        const increase = mostRecentCases - maxBaseline;
        alertMsg = `Detected a daily spike of dengue cases using DBSCAN outlier detection. Today: ${mostRecentCases} cases, Previous days: ${baselineCases.join(', ')} cases. This represents a sudden increase of ${increase} cases from the highest previous day.`;
      }

      alerts.push({
        barangay: barangay,
        pattern: "spike",
        alert: alertMsg,
        recommendation: "Intensify vector control measures and health promotion campaigns. Strengthen disease surveillance and consider implementing appropriate mosquito control measures. Encourage community participation in clean-up drives.",
      });
    }
  }

  return alerts.length > 0
    ? alerts
    : [
        {
          barangay: null,
          pattern: "",
          alert: "No spike detected",
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
  checkSpike({ masterCsvPath: "data/main.csv" })
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
  checkSpike,
};
