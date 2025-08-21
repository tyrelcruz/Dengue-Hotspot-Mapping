const Barangay = require("../../models/Barangays");

async function updateBarangayStatuses(alerts) {
  // First get all barangay names via Mongoose
  const allBarangays = await Barangay.find({}, { name: 1 }).lean();

  // Create a case-insensitive map of barangay alerts
  const alertMap = {};

  // Initialize all barangays with default values
  for (const barangay of allBarangays) {
    const barangayKey = barangay.name.toLowerCase();
    alertMap[barangayKey] = {
      barangay: barangay.name,
      status_and_recommendation: {
        pattern_based: {
          status: "",
          alert: "None",
          admin_recommendation: "None",
          user_recommendation: "None",
        },
        report_based: {
          count: 0,
          status: "",
          alert: "None",
          recommendation: "",
        },
        death_priority: {
          count: 0,
          alert: "None",
          recommendation: "",
        },
        recommendation: "",
      },
    };
  }

  // Update the map with any alerts
  for (const alert of alerts) {
    if (alert.barangay !== null) {
      const barangayKey = alert.barangay.toLowerCase();
      if (alertMap[barangayKey]) {
        if (alert.pattern) {
          alertMap[barangayKey].status_and_recommendation.pattern_based.status = alert.pattern;
          alertMap[barangayKey].status_and_recommendation.pattern_based.alert = alert.alert;
        }
        if (alert.death_priority) {
          alertMap[barangayKey].status_and_recommendation.death_priority.count = alert.death_priority.count || 0;
          alertMap[barangayKey].status_and_recommendation.death_priority.alert = alert.death_priority.alert;
          alertMap[barangayKey].status_and_recommendation.death_priority.recommendation = alert.death_priority.recommendation;
        }
      }
    }
  }

  const updates = [];
  // Create updates for all barangays
  for (const barangay of allBarangays) {
    const barangayKey = barangay.name.toLowerCase();
    const alertData = alertMap[barangayKey];

    const updateData = {
      "status_and_recommendation.pattern_based.status": alertData.status_and_recommendation.pattern_based.status,
      "status_and_recommendation.pattern_based.alert": alertData.status_and_recommendation.pattern_based.alert,
      "status_and_recommendation.death_priority.count": alertData.status_and_recommendation.death_priority.count || 0,
      "status_and_recommendation.death_priority.alert": alertData.status_and_recommendation.death_priority.alert,
      "status_and_recommendation.death_priority.recommendation": alertData.status_and_recommendation.death_priority.recommendation,
      last_analysis_time: new Date(),
    };

    updates.push({
      updateOne: {
        filter: { _id: barangay._id },
        update: { $set: updateData },
      },
    });
  }

  // Execute the updates if we have any via Mongoose Model
  if (updates.length > 0) {
    try {
      await Barangay.bulkWrite(updates, { ordered: false });
    } catch (error) {
      console.error(`Error updating barangays: ${error.message}`);
      throw new Error(`Failed to update barangay records: ${error.message}`);
    }
  }
}

module.exports = {
  updateBarangayStatuses,
};
