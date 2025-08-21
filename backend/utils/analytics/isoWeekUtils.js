const {
  startOfISOWeek,
  endOfISOWeek,
  subWeeks,
  isWithinInterval,
  parseISO,
  format,
} = require("date-fns");

function toSafeInteger(value, rowIndex) {
  const num = Number(value);
  if (Number.isNaN(num)) {
    console.warn(
      `Invalid Case Count "${value}" at row ${rowIndex}. Defaulting to 0.`
    );
    return 0;
  }
  return num;
}
function getIsoWeekBoundaries(date, numWeeks) {
  // Returns a list of (week_start, week_end) tuples for ISO calendar weeks.
  // Each week starts on Monday and ends on Sunday.

  // Get the Monday of the week containing the reference date
  const currentWeekStart = startOfISOWeek(date);

  const boundaries = [];
  for (let i = 0; i < numWeeks; i++) {
    const weekStart = subWeeks(currentWeekStart, i);
    const weekEnd = endOfISOWeek(weekStart);

    boundaries.push([weekStart, weekEnd]);
  }

  return boundaries;
}

function calculateWeeklyTotals(data, weekBoundaries) {
  // Calculate weekly totals for a given set of ISO week boundaries.
  const weeklyData = [];

  for (const [weekStart, weekEnd] of weekBoundaries) {
    const weekMask = data.filter((row) => {
      let rowDate;
      
      // Handle both Date objects and string dates
      if (row.DAdmit instanceof Date) {
        rowDate = row.DAdmit;
      } else if (typeof row.DAdmit === 'string' && row.DAdmit.trim()) {
        // Parse MM/DD/YYYY format from CSV
        const splitResult = row.DAdmit.split('/');
        if (!splitResult || splitResult.length !== 3) {
          console.warn(`Invalid date format in DAdmit: ${row.DAdmit}, expected MM/DD/YYYY, skipping row`);
          return false;
        }
        const [month, day, year] = splitResult;
        if (!month || !day || !year) {
          console.warn(`Invalid date components in DAdmit: ${row.DAdmit}, skipping row`);
          return false;
        }
        rowDate = new Date(parseInt(year), parseInt(month) - 1, parseInt(day));
      } else if (row.DAdmit === undefined || row.DAdmit === null) {
        console.warn(`DAdmit is undefined or null, skipping row:`, row);
        return false;
      } else {
        console.warn(`Invalid DAdmit value: ${row.DAdmit} (type: ${typeof row.DAdmit}), skipping row`);
        return false;
      }
      
      // Validate the parsed date
      if (isNaN(rowDate.getTime())) {
        console.warn(`Invalid parsed date from DAdmit: ${row.DAdmit}, skipping row`);
        return false;
      }
      
      return isWithinInterval(rowDate, { start: weekStart, end: weekEnd });
    });

    const weekTotal = weekMask.reduce(
      (sum, row, idx) => sum + toSafeInteger(row["Case Count"], idx),
      0
    );

    weeklyData.push({
      start_date: weekStart,
      end_date: weekEnd,
      total: weekTotal,
    });
  }

  return weeklyData;
}

module.exports = {
  getIsoWeekBoundaries,
  calculateWeeklyTotals,
};
