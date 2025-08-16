const csv = require("csv-parser");
const { createReadStream } = require("fs");
const {
  getIsoWeekBoundaries,
  calculateWeeklyTotals,
} = require("./isoWeekUtils");

async function checkDecline(options = {}) {
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

  // Process each barangay separately
  const uniqueBarangays = [
    ...new Set(processedData.map((row) => row.Barangay)),
  ];

  for (const barangay of uniqueBarangays) {
    // Filter data for this barangay
    const barangayData = processedData.filter(
      (row) => row.Barangay === barangay
    );

    // Calculate weekly totals using ISO weeks
    const weeklyData = calculateWeeklyTotals(barangayData, weekBoundaries);

    // Calculate totals for current two weeks and previous two weeks
    const currentTwoWeeks = weeklyData[0].total + weeklyData[1].total;
    const previousTwoWeeks = weeklyData[2].total + weeklyData[3].total;

    // Check if there's a decrease in cases
    if (currentTwoWeeks < previousTwoWeeks) {
      const decreasePercentage =
        previousTwoWeeks > 0
          ? ((previousTwoWeeks - currentTwoWeeks) / previousTwoWeeks) * 100
          : 0;

      const alertMsg = `Case decrease percentage of ${decreasePercentage.toFixed(
        1
      )}%. Previous 2 weeks: ${previousTwoWeeks} cases. Current 2 weeks: ${currentTwoWeeks} cases.`;

      alerts.push({
        barangay: barangay,
        // admin_recommendation: `- Continue with the implementation of targeted vector control measures such as fogging, larviciding, and clean-up drive initiatives to eradicate any existing mosquito breeding grounds.\n- Encourage the public to practice the 5S strategy to help in reducing the number of dengue cases.\n- Maintain the availability of free dengue test kits as well as fever express lanes in the health centers and hospitals.`,
        //   user_recommendation: `- Remember to clean out and apply covers on any containers that may accumulate water, which could allow for mosquitoes to lay their eggs in.\n- Continue exercising Self-Protection Measures by wearing light-colored, long-sleeved clothes and pants.\n- Seek an early consultation with your nearby health facility if you're experiencing any dengue symptoms like fever, headaches or abdominal pains to receive early treatment.`,
        // },
        pattern: "decline",
        alert: alertMsg,
        recommendation: "Maintain current prevention measures and continue monitoring. The decline suggests effective control measures are working, but remain vigilant to prevent resurgence.",
      });
    }
  }

  return alerts.length > 0
    ? alerts
    : [
        {
          barangay: null,
          pattern: "",
          alert: "No decline detected",
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
  checkDecline({ masterCsvPath: "data/main.csv" })
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
  checkDecline,
};
