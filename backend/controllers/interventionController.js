// controllers/interventionController.js

const Intervention = require("../models/Interventions");
const Notification = require("../models/Notifications");
const asyncErrorHandler = require("../middleware/asyncErrorHandler");

const createIntervention = asyncErrorHandler(async (req, res) => {
  const { barangay, address, date, interventionType, personnel, status, specific_location } =
    req.body;

  if (!barangay || !date || !interventionType || !personnel || !specific_location) {
    return res
      .status(400)
      .json({ error: "Please provide all required fields, including specific_location." });
  }

  // Validate specific_location coordinates
  if (specific_location.coordinates.length !== 2 || 
      specific_location.coordinates[0] < -180 || 
      specific_location.coordinates[0] > 180 ||
      specific_location.coordinates[1] < -90 || 
      specific_location.coordinates[1] > 90) {
    return res.status(400).json({ 
      error: "Invalid coordinates", 
      message: "Coordinates must be in [longitude, latitude] format with valid ranges."
    });
  }

  if (req.user.role !== "admin") {
    return res
      .status(403)
      .json({ error: "You are not authorized to create posts." });
  }
  const adminId = req.user.userId;
  const intervention = await Intervention.create({
    barangay,
    address,
    date,
    interventionType,
    personnel,
    status,
    specific_location,
    adminId,
  });

  // Optionally notify the user
  await Notification.create({
    report: intervention._id,
    user: req.user.userId, // Assuming `req.user.userId` is available after authentication
    message: `A new intervention (${interventionType}) has been scheduled in ${barangay}.`,
  });

  res.status(201).json({
    message: "Intervention created successfully.",
    intervention,
  });
});

const getAllInterventions = asyncErrorHandler(async (req, res) => {
  const interventions = await Intervention.find({}).sort({ createdAt: -1 });

  res.status(200).json(interventions);
});

const getIntervention = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;

  const intervention = await Intervention.findById(id);

  if (!intervention) {
    return res.status(404).json({ error: "Intervention not found." });
  }

  res.status(200).json(intervention);
});

const updateIntervention = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;
  const { status, personnel, date, interventionType, barangay, address, specific_location } =
    req.body;

  const allowedStatuses = ["Scheduled", "Ongoing", "Complete"];
  if (status && !allowedStatuses.includes(status)) {
    return res.status(400).json({ message: "Invalid status." });
  }
  
  // Validate specific_location coordinates if provided
  if (specific_location && (specific_location.coordinates.length !== 2 || 
      specific_location.coordinates[0] < -180 || 
      specific_location.coordinates[0] > 180 ||
      specific_location.coordinates[1] < -90 || 
      specific_location.coordinates[1] > 90)) {
    return res.status(400).json({ 
      error: "Invalid coordinates", 
      message: "Coordinates must be in [longitude, latitude] format with valid ranges."
    });
  }

  const updatedIntervention = await Intervention.findByIdAndUpdate(
    id,
    { barangay, address, status, personnel, date, interventionType, specific_location },
    { new: true }
  );

  if (!updatedIntervention) {
    return res.status(404).json({ message: "Intervention not found." });
  }

  res.status(200).json({
    message: "Intervention updated successfully.",
    updatedIntervention,
  });
});

const deleteIntervention = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;

  const intervention = await Intervention.findByIdAndDelete(id);

  if (!intervention) {
    return res.status(404).json({ message: "Intervention not found." });
  }

  res.status(200).json({ message: "Intervention deleted successfully." });
});

const getBarangayInterventionsInProgress = asyncErrorHandler(async (req, res) => {
  let { barangay } = req.params;
  if (!barangay || typeof barangay !== "string" || barangay.trim() === "") {
    return res.status(400).json({ error: "Barangay is required as a URL parameter." });
  }
  // Normalize: lowercase, remove spaces, replace ñ with n
  const normalizedBarangay = barangay.replace(/\s+/g, '').toLowerCase().replace(/ñ/g, 'n');

  const interventions = await Intervention.aggregate([
    {
      $addFields: {
        normalizedBarangay: {
          $replaceAll: {
            input: {
              $replaceAll: {
                input: { $toLower: "$barangay" },
                find: "ñ",
                replacement: "n"
              }
            },
            find: " ",
            replacement: ""
          }
        }
      }
    },
    {
      $match: {
        normalizedBarangay: normalizedBarangay,
        status: { $in: ["Scheduled", "Ongoing"] }
      }
    },
    { $sort: { date: 1 } }
  ]);
  res.status(200).json(interventions);
});

const deleteAllInterventions = asyncErrorHandler(async (req, res) => {
  // Check if user is admin
  if (req.user.role !== "admin") {
    return res.status(403).json({ error: "Only administrators can delete all interventions." });
  }

  const result = await Intervention.deleteMany({});
  
  res.status(200).json({ 
    message: `Successfully deleted ${result.deletedCount} interventions.`,
    deletedCount: result.deletedCount
  });
});

module.exports = {
  createIntervention,
  getAllInterventions,
  getIntervention,
  updateIntervention,
  deleteIntervention,
  getBarangayInterventionsInProgress,
  deleteAllInterventions,
};
