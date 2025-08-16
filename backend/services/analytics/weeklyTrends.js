const csv = require("csv-parser");
const { createReadStream } = require("fs");

function getMondayOfWeek(date) {
  const day = date.getDay();

  const daysFromMonday = day === 0 ? 6 : day - 1;
  const monday = new Date(date);
  monday.setDate(date.getDate() - daysFromMonday);
  monday.setHours(0, 0, 0, 0);
  return monday;
}

function formatDateRange(startDate, endDate) {
  return [
    startDate.toISOString().split('T')[0],
    endDate.toISOString().split('T')[0]
  ];
}

async function returnWeeklyTrends(barangayName, numberOfWeeks, csvPath) {
  return new Promise((resolve, reject) => {
    const results = [];
    const normalizedBarangayName = barangayName.trim().toLowerCase();

    createReadStream(csvPath)
      .pipe(csv())
      .on("data", (data) => {
        try {
          const admitDate = new Date(data.DAdmit);
          if (isNaN(admitDate.getTime())) {
            console.warn(`Invalid date found: ${data.DAdmit}`);
            return;
          }

          const barangay = data.Barangay?.trim().toLowerCase();
          if (!barangay) {
            console.warn(`Empty barangay name found.`);
            return;
          }

          if (barangay === normalizedBarangayName) {
            const caseCount = parseInt(data['Case Count']);
            if (isNaN(caseCount) || caseCount < 0) {
              console.warn(`Invalid case count: ${data['Case Count']}`);
              return;
            }

            results.push({
              admitDate,
              caseCount,
            });
          }
        } catch (error) {
          console.error(`Error processing row: ${error.message}`);
        }
      })
      .on("end", () => {
        try {

          if (results.length === 0) {
            const completeWeeks = {};
            for (let i = 1; i <= numberOfWeeks; i++) {
              completeWeeks[`Week ${i}`] = {
                count: 0,
                date_range: null
              };
            }

            return resolve({
              current_week: { count: 0, date_range: null },
              complete_weeks: completeWeeks,
            });
          }

          const today = new Date();
          today.setHours(23, 59, 59, 999);

          const currentWeekMonday = getMondayOfWeek(today);

          const completeWeeks = {};
          let currentWeekData = null;

          for (let i = 0; i < numberOfWeeks; i++) {
            const weekStart = new Date(currentWeekMonday);
            weekStart.setDate(currentWeekMonday.getDate() - (i * 7));

            const weekEnd = new Date(weekStart);
            weekEnd.setDate(weekStart.getDate() + 6);
            weekEnd.setHours(23, 59, 59, 999);

            if (i === 0) {
              weekEnd.setTime(Math.min(weekEnd.getTime(), today.getTime()));
            }

            const weeklyCount = results
              .filter(row => row.admitDate >= weekStart && row.admitDate <= weekEnd)
              .reduce((sum, row) => sum + row.caseCount, 0);

            const weekData = {
              count: weeklyCount,
              date_range: formatDateRange(weekStart, weekEnd)
            };

            const weekNumber = i + 1;
            completeWeeks[`Week ${weekNumber}`] = weekData;

            if (i === 0) {
              currentWeekData = weekData;
            }
          }

          resolve({
            current_week: currentWeekData,
            complete_weeks: completeWeeks,
          });
        } catch (error) {
          reject(new Error(`Error computing weekly trends: ${error.message}`));
        }
      })
      .on("error", (error) => {
        reject(new Error(`Error reading CSV file: ${error.message}`));
      });
  });
}

// For testing purposes
if (require.main === module) {
  const barangay = "San Isidro";
  const numberOfWeeks = 4;
  const csvPath = "data/main.csv";

  returnWeeklyTrends(barangay, numberOfWeeks, csvPath)
    .then((result) => {
      console.log('Weekly Trends Result:');
      console.log('Current Week:', result.current_week);
      console.log('Complete Weeks:', result.complete_weeks);
    })
    .catch((error) => {
      console.error("Error:", error.message);
    });
}

module.exports = {
  returnWeeklyTrends,
};
