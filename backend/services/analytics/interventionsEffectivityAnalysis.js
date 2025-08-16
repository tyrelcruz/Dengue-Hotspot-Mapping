const csv = require("csv-parser");
const { createReadStream } = require("fs");

function calculatePercentageChange(initialValue, finalValue) {
  // Calculate percentage change using average as the base when starting from zero
  if (initialValue === 0) {
    if (finalValue === 0) {
      return 0;
    }

    return finalValue > 0 ? 100 : - 100;
  }
  
  const percentageChange = ((finalValue - initialValue) / initialValue) * 100;
  return Math.round(percentageChange * 100) / 100;
}

function getMondayOfWeek(date) {
  const day = date.getDay();

  const daysFromMonday = day === 0 ? 6 : day - 1;
  const monday = new Date(date);
  monday.setDate(date.getDate() - daysFromMonday);
  monday.setHours(0, 0, 0, 0);
  return monday;
}

function getIsoWeekBoundaries(date, numWeeks, isBefore = true) {
  // Returns a list of (week_start, week_end) tuples for ISO calendar weeks.
  // For before period: returns weeks ending at the start of the intervention's week
  // For after period: returns weeks starting from the intervention's week

  // Get the Monday of the week containing the intervention date
  const interventionWeekMonday = getMondayOfWeek(date);
  const boundaries = [];

  if (isBefore) {
    // For before period, we want weeks ending at the start of intervention week
    const endDate = new Date(interventionWeekMonday);
    const startDate = new Date(endDate);
    startDate.setDate(endDate.getDate() - numWeeks * 7);

    let currentDate = new Date(startDate);
    while (currentDate < endDate) {
      const weekStart = new Date(currentDate);
      weekStart.setHours(0, 0, 0, 0);

      const weekEnd = new Date(currentDate);
      weekEnd.setDate(currentDate.getDate() + 6); // Sunday
      weekEnd.setHours(23, 59, 59, 999);

      boundaries.push([weekStart, weekEnd]);
      currentDate.setDate(currentDate.getDate() + 7);
    }
  } else {
    // For after period, we want weeks starting from intervention week
    const startDate = new Date(interventionWeekMonday);
    const endDate = new Date(startDate);
    endDate.setDate(startDate.getDate() + numWeeks * 7);

    let currentDate = new Date(startDate);
    while (currentDate < endDate) {
      const weekStart = new Date(currentDate);
      weekStart.setHours(0, 0, 0, 0);

      const weekEnd = new Date(currentDate);
      weekEnd.setDate(currentDate.getDate() + 6); // Sunday
      weekEnd.setHours(23, 59, 59, 999);

      boundaries.push([weekStart, weekEnd]);
      currentDate.setDate(currentDate.getDate() + 7);
    }
  }

  return boundaries;
}

async function returnCaseCountsForIntervention(barangay, interventionDate, csvPath) {

  const interventionDateObj = new Date(interventionDate);
  if (isNaN(interventionDateObj.getTime())) {
    throw new Error(`Invalid intervention date: ${interventionDate}`);
  }

  const normalizedBarangay = barangay.trim().toUpperCase();

  const beforeWeeks = getIsoWeekBoundaries(interventionDateObj, 8, true);
  const afterWeeks = getIsoWeekBoundaries(interventionDateObj, 8, false);

  return new Promise((resolve, reject) => {
    const cases = [];

    createReadStream(csvPath)
      .pipe(csv())
      .on("data", (row) => {
        try {
          const rowBarangay = row.Barangay?.trim().toUpperCase();
          if (!rowBarangay) {
            console.warn('Empty barangay name found');
            return;
          }

          if (rowBarangay === normalizedBarangay) {
            const caseDate = new Date(row.DAdmit);
            if (isNaN(caseDate.getTime())) {
              console.warn(`Invalid date found: ${row.DAdmit}`);
              return;
            }

            const caseCount = parseInt(row["Case Count"]);
            if (isNaN(caseCount) || caseCount < 0) {
              console.warn(`Invalid case count: ${row['Case Count']}`);
              return;
            }

            cases.push({ date: caseDate, count: caseCount });
          }
        } catch (error) {
          console.error(`Error processing row: ${error.message}`);
        }
      })
      .on("end", () => {
        try {
          const beforeCaseCounts = {};
          const afterCaseCounts = {};

          // Process before intervention period
          for (let weekNum = 0; weekNum < beforeWeeks.length; weekNum++) {
            const [weekStart, weekEnd] = beforeWeeks[weekNum];
            const weekTotal = cases
              .filter(caseRecord => caseRecord.date >= weekStart && caseRecord.date <= weekEnd)
              .reduce((sum, caseRecord) => sum + caseRecord.count, 0);
            beforeCaseCounts[`week_${weekNum + 1}`] = weekTotal;
          }

          // Process after intervention period
          for (let weekNum = 0; weekNum < afterWeeks.length; weekNum++) {
            const [weekStart, weekEnd] = afterWeeks[weekNum];
            const weekTotal = cases
              .filter(caseRecord => caseRecord.date >= weekStart && caseRecord.date <= weekEnd)
              .reduce((sum, caseRecord) => sum + caseRecord.count, 0);
            afterCaseCounts[`week_${weekNum + 1}`] = weekTotal;
          }

          // Calculate percentage change using total cases for each period
          const initialCases = Object.values(beforeCaseCounts).reduce(
            (sum, count) => sum + count,
            0
          );
          const finalCases = Object.values(afterCaseCounts).reduce(
            (sum, count) => sum + count,
            0
          );
          const percentageChange = calculatePercentageChange(initialCases, finalCases);

          resolve({
            before: beforeCaseCounts,
            after: afterCaseCounts,
            percentage_change: percentageChange,
            summary: {
              total_before: initialCases,
              total_after: finalCases,
              intervention_date: interventionDate,
              barangay: barangay
            }
          });
        } catch (error) {
          reject(new Error(`Error processing intervention data: ${error.message}`));
        }
      })
      .on("error", (error) => {
        reject(new Error(`Error reading CSV file: ${error.message}`));
      });
  });
}

// For testing purposes
if (require.main === module) {
  const barangay = "APOLONIO SAMSON";
  const interventionDate = "2025-01-21"; // Example intervention date
  const csvPath = "data/main.csv"; // Adjust this path to match your actual CSV file location

  returnCaseCountsForIntervention(barangay, interventionDate, csvPath)
    .then((results) => {
      console.log(`\nIntervention Analysis for ${results.summary.barangay}`);
      console.log(`Intervention date: ${results.summary.intervention_date}`);
      console.log(`\nSummary:`);
      console.log(`Total cases before: ${results.summary.total_before}`);
      console.log(`Total cases after: ${results.summary.total_after}`);
      console.log(`Percentage change: ${results.percentage_change}%`);
      
      console.log("\nBefore intervention (8 weeks):");
      for (const [week, count] of Object.entries(results.before)) {
        console.log(`  ${week}: ${count} cases`);
      }

      console.log("\nAfter intervention (8 weeks):");
      for (const [week, count] of Object.entries(results.after)) {
        console.log(`  ${week}: ${count} cases`);
      }
    })
    .catch((error) => {
      console.error(`Error: ${error.message}`);
    });
}

module.exports = {
  returnCaseCountsForIntervention,
};
