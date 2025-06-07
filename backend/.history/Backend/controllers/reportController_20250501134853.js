const jwt = require("jsonwebtoken");
const Report = require("../models/Reports");
const mongoose = require("mongoose");
const barangaysData = require("../data/barangays.json");
const asyncErrorHandler = require("../middleware/asyncErrorHandler");
const Notification = require("../models/Notifications");
const path = require("path");
// const geojson = require("geojson");
// Extract barangay names from barangays.features and normalize them, adding validation for undefined values
const list_of_barangays = barangaysData.features
  .filter((feature) => feature.properties && feature.properties.name) // Ensure properties and name exist
  .map((feature) => feature.properties.name.toLowerCase().trim()); // Convert to lowercase and trim

const isBarangayValid = (barangay) => {
  console.log(list_of_barangays.includes(barangay.toLowerCase().trim()));

  // Normalize both input and list names for comparison
  return list_of_barangays.includes(barangay.toLowerCase().trim());
};


// * GET all reports
const getAllReports = asyncErrorHandler(async (req, res) => {
  // ? find could be modified to look for posts with specific properties.
  // ? createdAt: -1 - newest at the top, could be good for Latest tab
  const reports = await Report.find({})
    .sort({ createdAt: -1 })  
    .populate("user", "username");

  res.status(200).json(reports);
});

// * GET a specific report
const getReport = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;

  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(404).json({ error: "No such post!" });
  }

  const report = await Report.findById(id).populate("user", "username");
  if (!report) {
    return res.status(404).json({ error: "Post does not exist!" });
  }

  res.status(200).json(report);
});

// * POST a new post
const createReport = asyncErrorHandler(async (req, res) => {
  const {
    barangay,
    specific_location_type,
    specific_location_coordinates,
    date_and_time,
    report_type,
    description,
  } = req.body;

  // 🔥 FIRST: Parse specific_location string if needed
  if (typeof req.body.specific_location === "string") {
    req.body.specific_location = JSON.parse(req.body.specific_location);
  }

  const userId = req.user?.userId;

  if (!userId) {
    return res.status(401).json({ error: "Unauthorized. No user ID found." });
  }

  let emptyFields = [];
  if (!barangay) emptyFields.push("barangay");
  if (!req.body.specific_location) emptyFields.push("specific_location");
  if (!date_and_time) emptyFields.push("date_and_time");
  if (!report_type) emptyFields.push("report_type");
  if (!description) emptyFields.push("description");

  if (emptyFields.length > 0) {
    return res
      .status(400)
      .json({ error: "Please fill in all fields", emptyFields });
  }

  if (!isBarangayValid(barangay)) {
    return res
      .status(400)
      .json({ error: `${barangay} is not a valid barangay.` });
  }

  // ✅ NOW: After parsing, create the real specific_location object
  const specific_location = {
    type: req.body.specific_location.type || "Point",
    coordinates: req.body.specific_location.coordinates,
  };

  const imagePaths = req.files
    ? req.files.map((file) => path.join("uploads", file.filename))
    : [];

  const report = await Report.create({
    user: userId,
    barangay,
    specific_location,
    date_and_time,
    report_type,
    description,
    images: imagePaths,
  });

  await Notification.create({
    report: report._id,
    user: userId,
    message: `Your ${report_type} report in ${barangay} has been successfully submitted.`,
  });

  res.status(201).json({
    message: "Report has been successfully created.",
    report: {
      _id: report._id,
      barangay: report.barangay,
      report_type: report.report_type,
    },
  });
});

// ! DELETE a post - ADMIN side
const deleteReport = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;

  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(404).json({ error: "No such post!" });
  }

  const report = await Report.findOneAndDelete({ _id: id });

  if (!report) {
    return res.status(404).json({ error: "No such post exists!" });
  }

  res.status(200).json(report);
});

const updateReportStatus = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
 
  const allowedStatuses = ["Pending", "Rejected", "Validated"];
  if (!allowedStatuses.includes(status)) {
    return res.status(400).json({ message: "Invalid status value." });
  }
 
  const updatedReport = await Report.findByIdAndUpdate(
    id,
    { status: status },
    { new: true }
  );
 
  if (!updatedReport) {
    return res.status(404).json({ mesage: "Report not found." });
  }
 
  res.status(200).json({
    message: "Report status updated successfully.",
  });
});

module.exports = {
  getAllReports,
  getReport,
  createReport,
  deleteReport,
  updateReportStatus
};
