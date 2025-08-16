const { MongoClient } = require("mongodb");

async function updateBarangayStatuses(alerts) {
  const mongoUri = process.env.MONGO_URI;
  const dbName = process.env.MONGODB_DATABASE || "BUZZMAP-API";

  if (!mongoUri) {
    throw new Error("MONGO_URI environment variable is not set");
  }

  const client = new MongoClient(mongoUri);

  try {
    await client.connect();
    const db = client.db(dbName);
    const barangaysCollection = db.collection("barangays");

    // First get all barangay names
    const allBarangays = await barangaysCollection
      .find({}, { projection: { name: 1 } })
      .toArray();

    // Create a case-insensitive map of barangay alerts
    const alertMap = {};

    // Initialize all barangays with default values
    for (const barangay of allBarangays) {
      const barangayKey = barangay.name.toLowerCase();
      alertMap[barangayKey] = {
        barangay: barangay.name,
        status: {
          pattern: "",
          crowdsourced_reports_count: 0,
          deaths: 0
        },
        recommendation: "",
      };
    }

    // Update the map with any alerts
    for (const alert of alerts) {
      if (alert.barangay !== null) {
        const barangayKey = alert.barangay.toLowerCase();
        if (alertMap[barangayKey]) {
          if (alert.pattern) {
            alertMap[barangayKey].status.pattern = alert.pattern;
          }
          if (alert.recommendation) {
            alertMap[barangayKey].recommendation = alert.recommendation;
          }
          if (alert.deaths !== undefined) {
            alertMap[barangayKey].status.deaths = alert.deaths;
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
        "status.pattern": alertData.status.pattern,
        "status.deaths": alertData.status.deaths || 0,
        recommendation: alertData.recommendation,
        last_analysis_time: new Date(),
      };

      updates.push({
        updateOne: {
          filter: { _id: barangay._id },
          update: { $set: updateData },
        },
      });
    }

    // Execute the updates if we have any
    if (updates.length > 0) {
      try {
        const result = await barangaysCollection.bulkWrite(updates, {
          ordered: false,
        });
        console.log(`Updated ${result.modifiedCount} barangay records`);
      } catch (error) {
        console.error(`Error updating barangays: ${error.message}`);
        throw new Error(`Failed to update barangay records: ${error.message}`);
      }
    }
  } finally {
    await client.close();
  }
}

module.exports = {
  updateBarangayStatuses,
};
