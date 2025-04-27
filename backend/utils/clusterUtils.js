const getDateDaysAgo = (days) => {
  const date = new Date();
  date.setDate(date.getDate() - days);
  return date;
};

const evaluateClusterSeverity = (count) => {
  if (count <= 5) {
    return {
      severity: "minor",
      intervention:
        "Minor Cluster detected - Recommended targeted cleanup and awareness campaign.",
    };
  } else if (count <= 10) {
    return {
      severity: "major",
      intervention:
        "Moderate Cluster detected - Recommended immediate visit to the area with targeted cleanup campaign and community engagement session.",
    };
  } else {
    return {
      severity: "severe",
      intervention:
        "Major Cluster detected - High priority intervention needed! Recommended coordinated multi-agency response with extensive cleanup, enforcement, and public education efforts.",
    };
  }
};

module.exports = {
  getDateDaysAgo,
  evaluateClusterSeverity,
};
