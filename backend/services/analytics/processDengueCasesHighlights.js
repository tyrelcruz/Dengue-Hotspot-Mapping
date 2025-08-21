const csv = require("csv-parser");
const { createReadStream } = require("fs");
const fs = require("fs").promises;
const path = require("path");
const {
  getIsoWeekBoundaries,
  calculateWeeklyTotals,
} = require("../../utils/analytics/isoWeekUtils");
const { formatInTimeZone } = require("date-fns-tz");
const { isWithinInterval, parseISO } = require("date-fns");

// Set timezone for consistent date handling
const timezone = "Asia/Manila";

const processDengueCasesHighlights = async () => {
  try {
    const csvFilePath = path.join(__dirname, "../../data/main.csv");

    // Check if file exists
    try {
      await fs.access(csvFilePath);
    } catch (error) {
      throw new Error(`CSV file not found: ${csvFilePath}`);
    }

    const data = [];

    // Read and parse CSV file
    return new Promise((resolve, reject) => {
      createReadStream(csvFilePath)
        .pipe(csv())
        .on("data", (row) => {
          // Store the raw CSV row data for calculateWeeklyTotals
          data.push(row);
        })
        .on("end", () => {
          try {
            const highlights = generateDengueHighlights(data);
            resolve(highlights);
          } catch (error) {
            reject(error);
          }
        })
        .on("error", (error) => {
          reject(error);
        });
    });
  } catch (error) {
    console.error("Error processing dengue cases highlights:", error);
    throw error;
  }
};

/**
 * Generate dengue highlights from processed data
 */
const generateDengueHighlights = (data) => {
  if (!data || data.length === 0) {
    return {
      currentWeekNewCases: 0,
      dateRange: { start: null, end: null },
      cumulativeYearlyTotal: 0,
      trend: {
        direction: "no_change",
        percentageChange: 0,
        currentTwoWeeks: { cases: 0, dateRange: { start: null, end: null } },
        previousTwoWeeks: { cases: 0, dateRange: { start: null, end: null } }
      }
    };
  }

  // Sort data by date
  data.sort((a, b) => new Date(a.DAdmit) - new Date(b.DAdmit));
  
  // Get current date and calculate current ISO week boundaries
  const currentDate = new Date();
  
  const weekBoundaries = getIsoWeekBoundaries(currentDate, 1); // Just current week
  
  // Calculate current week total
  const currentWeekData = calculateWeeklyTotals(data, weekBoundaries);
  
  const currentWeek = currentWeekData[0];
  
  // Calculate cumulative yearly total
  const yearStart = new Date(currentDate.getFullYear(), 0, 1); // January 1st of current year
  const yearlyData = data.filter((row) => {
    const rowDate = new Date(row.DAdmit);
    return rowDate >= yearStart;
  });
  const yearlyTotal = yearlyData.reduce((sum, row) => sum + (parseInt(row["Case Count"]) || 0), 0);
  
  // Calculate trend analysis for current two weeks vs previous two weeks
  const trendInfo = calculateTrendAnalysis(data, currentDate);
  
  // Format date ranges using date-fns-tz
  const formatDate = (date) => {
    return date ? formatInTimeZone(date, timezone, 'yyyy-MM-dd') : null;
  };
  
  return {
    currentWeekNewCases: currentWeek.total,
    dateRange: {
      start: formatDate(currentWeek.start_date),
      end: formatDate(currentWeek.end_date),
    },
    cumulativeYearlyTotal: yearlyTotal,
    trend: trendInfo
  };
};

/**
 * Calculate trend analysis comparing current two weeks with previous two weeks
 * Uses proper ISO week boundaries regardless of data completeness
 */
const calculateTrendAnalysis = (data, currentDate) => {
  // Get ISO week boundaries for the past 4 weeks to ensure proper weekly divisions
  const weekBoundaries = getIsoWeekBoundaries(currentDate, 4);
  
  // Week 1: Most recent week (may be incomplete)
  // Week 2: Second most recent week
  // Week 3: Third most recent week  
  // Week 4: Fourth most recent week
  
  // Current two weeks: Week 1 + Week 2
  const currentTwoWeekStart = weekBoundaries[1][0]; // Start of Week 2
  const currentTwoWeekEnd = weekBoundaries[0][1];   // End of Week 1
  
  // Previous two weeks: Week 3 + Week 4
  const previousTwoWeekStart = weekBoundaries[3][0]; // Start of Week 4
  const previousTwoWeekEnd = weekBoundaries[2][1];   // End of Week 3
  
  // Helper function to calculate cases for a date range using date-fns
  const getCasesForDateRange = (startDate, endDate) => {
    return data.filter(row => {
      const rowDate = new Date(row.DAdmit);
      return isWithinInterval(rowDate, { start: startDate, end: endDate });
    }).reduce((sum, row) => sum + (parseInt(row["Case Count"]) || 0), 0);
  };
  
  // Calculate total cases for each period
  const currentTwoWeekCases = getCasesForDateRange(currentTwoWeekStart, currentTwoWeekEnd);
  const previousTwoWeekCases = getCasesForDateRange(previousTwoWeekStart, previousTwoWeekEnd);
  
  // Calculate percentage change
  let percentageChange = 0;
  let direction = "no_change";
  
  if (previousTwoWeekCases > 0) {
    percentageChange = ((currentTwoWeekCases - previousTwoWeekCases) / previousTwoWeekCases) * 100;
    
    // Simple comparison: if current cases > previous cases = increase, if < = decrease
    if (currentTwoWeekCases > previousTwoWeekCases) {
      direction = "increase";
    } else if (currentTwoWeekCases < previousTwoWeekCases) {
      direction = "decrease";
    } else {
      direction = "no_change";
    }
  } else if (currentTwoWeekCases > 0) {
    // If previous period had 0 cases and current has cases, it's an increase
    direction = "increase";
    percentageChange = 100; // Represent as 100% increase from 0
  }
  
  // Format date ranges
  const formatDate = (date) => {
    return date ? formatInTimeZone(date, timezone, 'MMM dd, yyyy') : null;
  };
  
  return {
    direction: direction,
    percentageChange: Math.round(percentageChange),
    currentTwoWeeks: {
      cases: currentTwoWeekCases,
      dateRange: {
        start: formatDate(currentTwoWeekStart),
        end: formatDate(currentTwoWeekEnd)
      },
      weekBreakdown: {
        week1: {
          start: formatDate(weekBoundaries[0][0]),
          end: formatDate(weekBoundaries[0][1]),
          cases: getCasesForDateRange(weekBoundaries[0][0], weekBoundaries[0][1])
        },
        week2: {
          start: formatDate(weekBoundaries[1][0]),
          end: formatDate(weekBoundaries[1][1]),
          cases: getCasesForDateRange(weekBoundaries[1][0], weekBoundaries[1][1])
        }
      }
    },
    previousTwoWeeks: {
      cases: previousTwoWeekCases,
      dateRange: {
        start: formatDate(previousTwoWeekStart),
        end: formatDate(previousTwoWeekEnd)
      },
      weekBreakdown: {
        week3: {
          start: formatDate(weekBoundaries[2][0]),
          end: formatDate(weekBoundaries[2][1]),
          cases: getCasesForDateRange(weekBoundaries[2][0], weekBoundaries[2][1])
        },
        week4: {
          start: formatDate(weekBoundaries[3][0]),
          end: formatDate(weekBoundaries[3][1]),
          cases: getCasesForDateRange(weekBoundaries[3][0], weekBoundaries[3][1])
        }
      }
    }
  };
};

module.exports = {
  processDengueCasesHighlights,
};
