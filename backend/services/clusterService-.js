const Report = require("../models/Reports");
const axios = require("axios");

async function detectClustersToday() {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const reportsToday = await Report.find({ date_and_time: { $gte: today } });

  const uniqueCenters = [];
  const seenCenters = new Set();

  const clusters = [];

  for (const report of reportsToday) {
    const coord = report.specific_location.coordinates;
    const coordKey = coord.join(",");

    if (seenCenters.has(coordKey)) continue;

    seenCenters.add(coordKey);

    const nearby = await Report.aggregate([
      {
        $geoNear: {
          near: {
            type: "Point",
            coordinates: coord,
          },
          distanceField: "distance",
          maxDistance: 200,
          spherical: true,
          query: {
            date_and_time: { $gte: today },
            report_type: report.report_type,
            barangay: report.barangay,
          },
        },
      },
    ]);

    if (nearby.length >= 5) {
      clusters.push({
        barangay: report.barangay,
        center: coord,
        report_type: report.report_type,
        count: nearby.length,
      });
    }
  }

  const recommendations = await Promise.all(
    clusters.map(
      (cluster) => axios.post("http://localhost:8000/api/v1/analyze-cluster", cluster)
    )
  );

  return clusters.map((cluster, i) => ({
    ...cluster,
    recommendation: recommendations[i].data.recommendation,
  }));
}

module.exports = {
  detectClustersToday,
};
