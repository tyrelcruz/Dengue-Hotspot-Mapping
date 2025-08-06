const Report = require("../models/Reports");
const Barangay = require("../models/Barangays");

const determineStatusInfo = (count, barangayName) => {
  if (count <= 3) {
    return {
      status: "low",
      alert: `There are currently ${count} breeding site reports under ${barangayName}.`,
      recommendation: "No immediate action needed."
    };
  } else if (count <= 9) {
    return {
      status: "medium",
      alert: `Caution. There are currently ${count} reports of breeding sites here in ${barangayName}.`,
      recommendation: "Monitor situation closely."
    };
  } else {
    return {
      status: "high",
      alert: `Warning. A high number of ${count} breeding sites have been reported in ${barangayName}.`,
      recommendation: "Immediate action is required."
    };
  }
};

const getBarangayReportCounts = async () => {
  return await Report.aggregate([
    {
      $match: {
        status: "Validated"  // Only count validated reports
      }
    },
    {
      $group: {
        _id: "$barangay",
        count: { $sum: 1 }
      }
    },
    {
      $sort: { count: -1 }  // Sort by count in descending order
    }
  ]);
};

const updateBarangayStatuses = async (reportCounts) => {
  const bulkOperations = reportCounts.map(({ _id: barangayName, count }) => {
    const statusInfo = determineStatusInfo(count, barangayName);
    
    return {
      updateOne: {
        filter: { name: barangayName },
        update: {
          $set: {
            "status_and_recommendation.report_based.status": statusInfo.status,
            "status_and_recommendation.report_based.count": count,
            "status_and_recommendation.report_based.alert": statusInfo.alert,
            "status_and_recommendation.report_based.recommendation": statusInfo.recommendation
          }
        }
      }
    };
  });

  if (bulkOperations.length > 0) {
    return await Barangay.bulkWrite(bulkOperations);
  }
  return null;
};

const analyzeCrowdsourcedReports = async () => {
  const reportCounts = await getBarangayReportCounts();
  const result = await updateBarangayStatuses(reportCounts);

  return {
    success: true,
    data: {
      totalBarangaysUpdated: result?.modifiedCount || 0,
      reportCounts
    }
  };
};

module.exports = {
  analyzeCrowdsourcedReports,
  getBarangayReportCounts,
  updateBarangayStatuses,
  determineStatusInfo
}; 