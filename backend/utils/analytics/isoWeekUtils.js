function getIsoWeekBoundaries(date, numWeeks) {
  // Returns a list of (week_start, week_end) tuples for ISO calendar weeks.
  // Each week starts on Monday and ends on Sunday.

  // Get the Monday of the week containing the reference date
  const daysSinceMonday = date.getDay();
  const currentWeekMonday = new Date(date);
  currentWeekMonday.setDate(date.getDate() - daysSinceMonday);

  const boundaries = [];
  for (let i = 0; i < numWeeks; i++) {
    const weekStart = new Date(currentWeekMonday);
    weekStart.setDate(currentWeekMonday.getDate() - i * 7);

    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekStart.getDate() + 6); // Sunday

    boundaries.push([weekStart, weekEnd]);
  }

  return boundaries;
}

function calculateWeeklyTotals(data, weekBoundaries) {
  // Calculate weekly totals for a given set of ISO week boundaries.

  const weeklyData = [];

  for (const [weekStart, weekEnd] of weekBoundaries) {
    const weekMask = data.filter((row) => {
      const rowDate = new Date(row.DAdmit);
      return rowDate >= weekStart && rowDate <= weekEnd;
    });

    const weekTotal = weekMask.reduce(
      (sum, row) => sum + parseInt(row["Case Count"]),
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
