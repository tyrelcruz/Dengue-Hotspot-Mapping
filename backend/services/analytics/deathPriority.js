const csv = require("csv-parser");
const { createReadStream } = require("fs");
const fs = require("fs").promises;

function createDefaultResponse(alert, barangay = null) {
  return {
    barangay,
    deaths: 0,
    alert,
    recommendation: 'No recommendations available. Continue monitoring and surveillance practices.',
  };
}

async function getDeathPriorityData(filePath) {
  try {
    await fs.access(filePath);
  } catch (error) {
    return [createDefaultResponse('Dataset not found.')];
  }

  return new Promise((resolve, reject) => {

    const results = [];
    
    const today = new Date();
    today.setHours(23, 59, 59, 999);
    const twoWeeksAgo = new Date(today);
    twoWeeksAgo.setDate(today.getDate() - 14);
    twoWeeksAgo.setHours(0, 0, 0, 0);


    createReadStream(filePath)
      .pipe(csv())
      .on("data", (data) => {
        try {
          const admitDate = new Date(data.DAdmit);
          if (isNaN(admitDate.getTime())) {
            console.warn(`Invalid date found: ${data.DAdmit}`);
            return;
          }

          const barangay = data.Barangay?.trim();
          if (!barangay) {
            console.warn('Empty barangay name found.');
            return;
          }

          const deaths = parseInt(data.Deaths);
          if (isNaN(deaths)) {
            console.warn(`Invalid deaths count: ${data.Deaths}`);
            return;
          }

          if (admitDate >= twoWeeksAgo && admitDate <= today) {
            results.push({
              barangay,
              admitDate,
              deaths,
            });
          }
        } catch (error) {
          console.error(`Error processing row: ${error.message}`);
        }
      })
      .on("end", () => {
        try {
          if (results.length === 0) {
            return resolve([createDefaultResponse('No recent data available for analysis.')]);
          }

          // Get all unique barangays first
          const allBarangays = [...new Set(results.map(row => row.Barangay))];

          // Create initial alerts for all barangays with no deaths
          const barangayAlerts = {};
          for (const barangay of allBarangays) {
            barangayAlerts[barangay] = {
              barangay,
              deaths: 0,
              alert: "No deaths reported.",
              recommendation: "No recommendations available. Continue monitoring and surveillance practices.",
            };
          }

          // * Process death statistics
          const deathStats = {};
          for (const row of results) {
            if (row.deaths > 0) {
              if (!deathStats[row.barangay]) {
                deathStats[row.barangay] = {
                  totalDeaths: 0,
                  mostRecentDate: row.admitDate
                };
              }

              deathStats[row.barangay].totalDeaths += row.deaths;
              if (row.admitDate > deathStats[row.barangay].mostRecentDate) {
                deathStats[row.barangay].mostRecentDate = row.admitDate;
              }
            }
          }

          // If no deaths were found, return default responses
          if (Object.keys(deathStats).length === 0) {
            return resolve(Object.values(barangayAlerts));
          }

          const highestDeathCount = Math.max(
            ...Object.values(deathStats).map(stats => stats.totalDeaths)
          );

            // Update only the barangays that have deaths
          for (const [barangay, stats] of Object.entries(deathStats)) {
            const { totalDeaths } = stats;

            // Determine recommendation based on death count
            let recommendation;
            if (highestDeathCount === 1) {
              recommendation =
                "Due to a detected dengue-related death in this barangay, conduct a visit to this area to investigate and enforce some interventions.";
            } else if (totalDeaths === highestDeathCount) {
              recommendation =
                "Due to the high number of deaths recorded in this barangay, it is recommended for your team to prioritize visiting this area immediately to investigate and conduct some necessary interventions.";
            } else {
              recommendation =
                "Due to a recorded number of death(s) in this barangay, conduct a visit to this area to investigate and enforce some interventions.";
            }

            barangayAlerts[barangay] = {
              barangay,
              deaths: totalDeaths,
              alert: `${barangay} has a recorded number of ${totalDeaths} death(s) due to dengue in the last 2 weeks.`,
              recommendation: recommendation,
            };
          }

          resolve(Object.values(barangayAlerts));
        } catch (error) {
          reject(new Error(`Error processing death priority data: ${error.message}`));
        }
      })
      .on("error", (error) => {
        reject(new Error(`Error reading CSV file: ${error.message}`));
      });
  });
}

// For testing purposes
if (require.main === module) {
  getDeathPriorityData("data/main.csv")
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
  getDeathPriorityData,
};
