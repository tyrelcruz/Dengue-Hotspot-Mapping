const csv = require("csv-parser");
const { createReadStream } = require("fs");
const {
  getIsoWeekBoundaries,
  calculateWeeklyTotals,
} = require("./isoWeekUtils");

// Simple DBSCAN implementation for outlier detection
function dbscan(data, eps, minSamples) {
  const labels = new Array(data.length).fill(-1);
  let clusterId = 0;

  for (let i = 0; i < data.length; i++) {
    if (labels[i] !== -1) continue;

    const neighbors = findNeighbors(data, i, eps);

    if (neighbors.length < minSamples) {
      labels[i] = -1; // Noise point
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

async function checkSpike(options = {}) {
  const {
    data,
    masterCsvPath = "data/main.csv",
    dbscanEps = 2,
    dbscanMinSamples = 2,
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

  // Get ISO week boundaries for the past 2 weeks
  const weekBoundaries = getIsoWeekBoundaries(latestDate, 2);

  // Get the complete date range for the 2-week period
  const startDate = weekBoundaries[1][0]; // Start of previous week
  const endDate = weekBoundaries[0][1]; // End of current week

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

    while (currentDate <= endDate) {
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

    // Calculate weekly totals using the complete dataset
    const weeklyData = calculateWeeklyTotals(completeData, weekBoundaries);

    // Get weekly totals for current and previous week
    const currentWeekTotal = weeklyData[0].total;
    const previousWeekTotal = weeklyData[1].total;

    // Calculate percentage increase from previous week
    const pctIncrease =
      previousWeekTotal > 0
        ? ((currentWeekTotal - previousWeekTotal) / previousWeekTotal) * 100
        : 0;

    // Apply DBSCAN to detect outliers in the two weeks
    const weeklyTotals = [currentWeekTotal, previousWeekTotal];
    const dbscanLabels = dbscan(weeklyTotals, dbscanEps, dbscanMinSamples);

    // Check if current week (index 0) is an outlier (label -1)
    const isSpike =
      dbscanLabels[0] === -1 && currentWeekTotal > previousWeekTotal;

    if (isSpike) {
      let alertMsg;
      if (previousWeekTotal === 0) {
        alertMsg = `Detected a spike of dengue cases in the current 2-week period. Current week dengue case count of ${currentWeekTotal} cases, Previous week dengue case count of ${previousWeekTotal} cases, showing a sudden jump from zero cases.`;
      } else {
        alertMsg = `Detected a spike of dengue cases in the current 2-week period. Current week dengue case count of ${currentWeekTotal} cases, Previous week dengue case count of ${previousWeekTotal} cases, a ${Math.round(
          pctIncrease
        )}% increase from the previous week.`;
      }

      alerts.push({
        barangay: barangay,
        // admin_recommendation: `- Intensify health promotion, advocacy, and information campaigns to help raise public awareness.\n- Ensure the continuous and intensified disease surveillance by the QCESD with immediate feedback to the barangay officials for appropriate action.\n- Strengthen the conduct of onsite monitoring visits to assist of mentor LGU partners.\n- Strongly consider the implementation of appropriate vector control measures for this location due to the detected increased risk of transmission.\n- Encourage the community to join the clean-up drive efforts to help reduce the risk of mosquito breeding.\n`,
        //   user_recommendation: `- Be very vigilant in your surroundings. Aedes mosquitoes are most active during early morning and late afternoon times, but they can bite at night in well-lit areas.\n- Protect yourself by wearing light-colored, long-sleeved clothes and pants.\n- Conduct some cleaning on your household surroundings and remove any potential breeding sites for mosquitoes.\n- Seek early consultation with your local health facility immediately if you're experiencing any dengue symptoms, as many fatalities to this disease are caused by delayed treatment.\n- Join your local clean-up drive efforts to help reduce the risk of mosquito breeding.`,
        // },
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
