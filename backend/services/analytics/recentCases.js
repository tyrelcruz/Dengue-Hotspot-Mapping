const csv = require("csv-parser");
const { createReadStream } = require("fs");

async function getRecentCaseCounts(csvPath, barangayName, daysBack = 7) {
  const results = [];
  const targetBarangay = barangayName.trim().toUpperCase();

  const today = new Date();
  today.setHours(23, 59, 59, 999);
  const cutoffDate = new Date(today);
  cutoffDate.setDate(today.getDate() - daysBack);
  cutoffDate.setHours(0, 0, 0, 0);


  return new Promise((resolve, reject) => {
    createReadStream(csvPath)
      .pipe(csv())
      .on("data", (data) => {
        try {
          const admitDate = new Date(data.DAdmit);
          if (isNaN(admitDate.getTime())) {
            console.warn(`Invalid date found: ${data.DAdmit}`);
            return;
          }

          const normalizedBarangay = data.Barangay?.trim().toUpperCase();
          if (!normalizedBarangay) {
            console.warn('Empty barangay name found');
            return;
          }

          if (normalizedBarangay === targetBarangay &&
              admitDate >= cutoffDate &&
              admitDate <= today 
          ) {
            const caseCount = parseInt(data['Case Count']);
            if (isNaN(caseCount) || caseCount < 0) {
              console.warn(`Invalid case count: ${data['Case Count']}`);
              return;
            }
            
            results.push({
              date: admitDate,
              caseCount: caseCount
            });
          }
        } catch (error) {
          console.error(`Error processing row: ${error.message}`);
        }
      })
      .on("end", () => {
        const caseCounts = results.reduce((acc, row) => {
          const dateStr = row.date.toLocaleDateString('en-US', {
            month: 'long',
            day: 'numeric',
          });
          acc[dateStr] = (acc[dateStr] || 0) + row.caseCount;
          return acc;
        }, {});

        resolve(caseCounts);
      })
      .on("error", (error) => {
        reject(new Error(`Error reading CSV file: ${error.message}`));
      });
  });
}

// For testing purposes
if (require.main === module) {
  const csvPath = "data/main.csv";
  const barangayName = "San Isidro";

  getRecentCaseCounts(csvPath, barangayName)
    .then((result) => {
      console.log(result);
    })
    .catch((error) => {
      console.error("Error:", error.message);
    });
}

module.exports = {
  getRecentCaseCounts,
};
