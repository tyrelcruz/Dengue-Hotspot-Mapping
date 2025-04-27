const Report = require("../models/Reports");
const {
  getDateDaysAgo,
  evaluateClusterSeverity,
} = require("../utils/clusterUtils");

const detectClusters = async () => {
  const fourteenDaysAgo = getDateDaysAgo(14);
  const barangaysWithReports = await Report.distinct("barangay", {
    createdAt: { $gte: fourteenDaysAgo },
  });

  if (barangaysWithReports.length === 0) {
    return [];
  }

  const clusters = [];

  for (const barangay of barangaysWithReports) {
    const clusterData = await processBarangayCluster(barangay, fourteenDaysAgo);
    if (clusterData) {
      clusters.push(clusterData);
    }
  }

  return clusters;
};

const processBarangayCluster = async (barangay, startDate) => {
  // Get a sample report from this barangay to use as center point
  const sampleReport = await Report.findOne({
    barangay: barangay,
    createdAt: { $gte: startDate },
  });

  if (!sampleReport?.location?.coordinates) {
    return null;
  }

  // Find cluster data
  const clusterResult = await Report.aggregate([
    {
      $geoNear: {
        near: {
          type: "Point",
          coordinates: sampleReport.location.coordinates,
        },
        distanceField: "distance",
        maxDistance: 300,
        spherical: true,
        key: "specific_location",
        query: {
          barangay: barangay,
          createdAt: { $gte: startDate },
        },
      },
    },
    {
      $count: "reportCount",
    },
  ]);

  // Check if we have enough reports for a cluster
  if (clusterResult.length > 0 && clusterResult[0].reportCount >= 5) {
    const count = clusterResult[0].reportCount;
    const { severity, intervention } = evaluateClusterSeverity(count);

    return {
      barangay,
      count,
      severity,
      intervention,
    };
  }

  return null;
};

module.exports = {
  detectClusters,
  processBarangayCluster,
};
