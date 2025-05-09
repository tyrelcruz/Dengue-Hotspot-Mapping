// controllers/interventionController.js

const Intervention = require("../models/Interventions");
const Notification = require("../models/Notifications");
const asyncErrorHandler = require("../middleware/asyncErrorHandler");

const createIntervention = asyncErrorHandler(async (req, res) => {
  const { barangay, address, date, interventionType, personnel, status } =
    req.body;

  if (!barangay || !date || !interventionType || !personnel) {
    return res
      .status(400)
      .json({ error: "Please provide all required fields." });
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
  const { status, personnel, date, interventionType, barangay, address } =
    req.body;

  const allowedStatuses = ["Scheduled", "Ongoing", "Complete"];
  if (status && !allowedStatuses.includes(status)) {
    return res.status(400).json({ message: "Invalid status." });
  }

  const updatedIntervention = await Intervention.findByIdAndUpdate(
    id,
    { barangay, address, status, personnel, date, interventionType },
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

module.exports = {
  createIntervention,
  getAllInterventions,
  getIntervention,
  updateIntervention,
  deleteIntervention,
};
