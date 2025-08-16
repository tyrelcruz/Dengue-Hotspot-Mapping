const csv = require("csv-parser");
const { createReadStream } = require("fs");
const {
  getIsoWeekBoundaries,
  calculateWeeklyTotals,
} = require("./isoWeekUtils");

async function checkGradualRise(options = {}) {
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

    // Check for upward trend
    if (currentTwoWeeks > previousTwoWeeks) {
      const pctIncrease =
        previousTwoWeeks > 0
          ? ((currentTwoWeeks - previousTwoWeeks) / previousTwoWeeks) * 100
          : 0;

      const alertMsg = `Case increase percentage of ${pctIncrease.toFixed(
        1
      )}%. Previous 2 weeks: ${previousTwoWeeks} cases. Current 2 weeks: ${currentTwoWeeks} cases.`;

      alerts.push({
        barangay: barangay,
        // admin_recommendation: `- Carry out vector control measures such as dengue spraying, fogging, clean-up drives, and the installation of larvae traps.\n- Conduct some information drives / dengue lectures in the community to help educate the residents about dengue and proper preventive measures for it. Distribute some dengue flyers if available.\n- Encourage and mobilize the barangay to conduct search and destroy operations to stop the reproduction of dengue-carrying mosquitoes.\n- Enforce sanitation regulations such as proper waste segragation and disposal.`,
        //   user_recommendation: `- Protect yourself by using anti-mosquito sprays or mosquito repellent lotions.\n- Wear light-colored, long-sleeved clothes and pants to protect your skin from mosquito bites. Use a mosquito net (kulambo) while sleeping.\n- Maintain the cleanliness of your household surroundings by cleaning up and clearing out any potential mosquito breeding sites.\n- If you're experiencing any dengue-related symptoms, like high fever, severe headaches, or joint pain, seek an early consultation with your local health facility.`,
        // },
        pattern: "gradual_rise",
        alert: alertMsg,
        recommendation: "Implement vector control measures including spraying, fogging, and clean-up drives. Conduct information campaigns and encourage community participation in search and destroy operations.",
      });
    }
  }

  return alerts.length > 0
    ? alerts
    : [
        {
          barangay: null,
          pattern: "",
          alert: "No gradual rise detected",
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
  checkGradualRise({ masterCsvPath: "data/main.csv" })
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
  checkGradualRise,
};
