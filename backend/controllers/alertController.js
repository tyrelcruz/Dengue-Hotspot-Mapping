const asyncErrorHandler = require("../middleware/asyncErrorHandler");
const Barangay = require("../models/Barangays");
const Alert = require('../models/Alerts');

const sendDengueAlert = asyncErrorHandler(async (req, res) => {
  const { barangayIds, message, messages, severity, affectedAreas } = req.body;

  try {
    // Validate input
    if (!barangayIds || (!message && !messages)) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields: barangayIds and message/messages are required"
      });
    }

    // Convert single message to array if needed
    const messageArray = messages || [message];

    // Find the specified barangays
    const barangays = await Barangay.find({
      _id: { $in: barangayIds }
    });

    if (barangays.length === 0) {
      return res.status(404).json({
        success: false,
        message: "No barangays found with the provided IDs"
      });
    }

    // Create and save alert record
    const alert = await Alert.create({
      messages: messageArray,
      severity: severity || 'MODERATE', // Use provided severity or default to MODERATE
      affectedAreas,
      barangays: barangayIds,
      timestamp: new Date(),
      status: 'ACTIVE'
    });

    // TODO: Implement notification system
    console.log(`Alert created: ${alert._id} for barangays: ${barangays.map(b => b.name).join(', ')}`);

    res.status(200).json({
      success: true,
      message: "Dengue alert sent successfully",
      data: {
        alert,
        affectedBarangays: barangays.map(b => b.name)
      }
    });
  } catch (error) {
    console.error("Error sending dengue alert:", error);
    res.status(500).json({
      success: false,
      message: "Failed to send dengue alert",
      error: error.message
    });
  }
});

const getAllAlerts = asyncErrorHandler(async (req, res) => {
  const alerts = await Alert.find()
    .populate('barangays', 'name')
    .sort({ timestamp: -1 });

  res.status(200).json({
    success: true,
    count: alerts.length,
    data: alerts
  });
});

const getAlertsByBarangay = asyncErrorHandler(async (req, res) => {
  const { barangayId } = req.params;
  
  const alerts = await Alert.find({ barangays: barangayId })
    .populate('barangays', 'name')
    .sort({ timestamp: -1 });

  res.status(200).json({
    success: true,
    count: alerts.length,
    data: alerts
  });
});

const getAlertsByBarangayName = asyncErrorHandler(async (req, res) => {
  console.log('\n=== Alert Search by Barangay Name ===');
  console.log('Request Params:', req.params);
  const { barangayName } = req.params;
  
  console.log('Original barangay name:', barangayName);
  
  if (!barangayName) {
    console.log('Error: No name provided in params');
    return res.status(400).json({
      success: false,
      message: "Barangay name is required"
    });
  }

  try {
    // Normalize the barangay name - more aggressive normalization
    const normalizedName = barangayName
      .toLowerCase()
      .replace(/[ñÑ]/g, 'n')  // Replace ñ/Ñ with n
      .replace(/\s+/g, '')    // Remove all whitespace
      .replace(/[^a-z0-9]/g, ''); // Remove all special characters

    console.log('Normalized name:', normalizedName);

    // Let's first check what barangays exist in the database
    const allBarangays = await Barangay.find({}, 'name');
    console.log('All available barangays:', allBarangays.map(b => b.name));

    // First find the barangay using multiple conditions
    const searchQuery = {
      $or: [
        // Match the normalized version of the stored name
        { 
          $expr: {
            $regexMatch: {
              input: { 
                $replaceAll: { 
                  input: { 
                    $replaceAll: {
                      input: { $toLower: "$name" },
                      find: "ñ",
                      replacement: "n"
                    }
                  },
                  find: " ",
                  replacement: ""
                }
              },
              regex: normalizedName,
              options: "i"
            }
          }
        },
        // Match the original name (case-insensitive)
        { name: { $regex: new RegExp(barangayName, 'i') } },
        // Match the normalized name
        { name: { $regex: new RegExp(normalizedName, 'i') } },
        // Match with ñ/n variations
        { 
          name: { 
            $regex: new RegExp(
              barangayName.replace(/[ñÑ]/g, 'n').replace(/\s+/g, ''),
              'i'
            )
          }
        }
      ]
    };

    console.log('Search query:', JSON.stringify(searchQuery, null, 2));

    const barangay = await Barangay.findOne(searchQuery);

    console.log('Barangay search result:', {
      found: !!barangay,
      id: barangay?._id,
      name: barangay?.name
    });

    if (!barangay) {
      console.log('No barangay found with name:', barangayName);
      return res.status(404).json({
        success: false,
        message: "Barangay not found"
      });
    }

    console.log('Found barangay:', {
      id: barangay._id,
      name: barangay.name
    });

    // Then find alerts using the barangay's _id
    console.log('Searching for alerts with barangay ID:', barangay._id);
    const alerts = await Alert.find({ 
      barangays: barangay._id
    })
    .populate('barangays', 'name')
    .sort({ timestamp: -1 });

    console.log('Found alerts:', {
      count: alerts.length,
      alerts: alerts.map(alert => ({
        id: alert._id,
        message: alert.message,
        severity: alert.severity,
        barangays: alert.barangays.map(b => b.name)
      }))
    });

    res.status(200).json({
      success: true,
      count: alerts.length,
      data: alerts
    });
  } catch (error) {
    console.error('\n=== Error in getAlertsByBarangayName ===');
    console.error('Error message:', error.message);
    console.error('Error stack:', error.stack);
    console.error('Request details:', {
      params: req.params,
      body: req.body
    });
    
    res.status(500).json({
      success: false,
      message: "Error finding alerts",
      error: error.message
    });
  }
});

const updateAlert = asyncErrorHandler(async (req, res) => {
  const { alertId } = req.params;
  const { messages, severity, affectedAreas, status } = req.body;

  try {
    // Find the alert
    const alert = await Alert.findById(alertId);
    
    if (!alert) {
      return res.status(404).json({
        success: false,
        message: "Alert not found"
      });
    }

    // Update only the fields that are provided
    if (messages) alert.messages = messages;
    if (severity) alert.severity = severity;
    if (affectedAreas) alert.affectedAreas = affectedAreas;
    if (status) alert.status = status;

    // Save the updated alert
    await alert.save();

    res.status(200).json({
      success: true,
      message: "Alert updated successfully",
      data: alert
    });
  } catch (error) {
    console.error("Error updating alert:", error);
    res.status(500).json({
      success: false,
      message: "Failed to update alert",
      error: error.message
    });
  }
});

const deleteAlert = asyncErrorHandler(async (req, res) => {
  const { alertId } = req.params;

  try {
    // Find and delete the alert
    const alert = await Alert.findByIdAndDelete(alertId);
    
    if (!alert) {
      return res.status(404).json({
        success: false,
        message: "Alert not found"
      });
    }

    res.status(200).json({
      success: true,
      message: "Alert deleted successfully",
      data: alert
    });
  } catch (error) {
    console.error("Error deleting alert:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete alert",
      error: error.message
    });
  }
});

const deleteAllAlerts = async (req, res) => {
  try {
    await Alert.deleteMany({});
    res.json({ message: "All alerts have been deleted successfully" });
  } catch (error) {
    console.error("Error deleting alerts:", error);
    res.status(500).json({ error: "Failed to delete alerts" });
  }
};

module.exports = {
  sendDengueAlert,
  getAllAlerts,
  getAlertsByBarangay,
  getAlertsByBarangayName,
  updateAlert,
  deleteAlert,
  deleteAllAlerts
}; 