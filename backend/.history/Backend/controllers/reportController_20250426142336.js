const jwt = require("jsonwebtoken");
const Report = require("../models/Reports");
const mongoose = require("mongoose");
const barangays = require('../data/barangays.json');
const asyncErrorHandler = require("../middleware/asyncErrorHandler");
const Notification = require("../models/Notifications");
const path = require("path");
// const geojson = require("geojson");

let list_of_barangays = barangays.features.map(
  (feature) => feature.properties.name
);

const isBarangayValid = (barangay) => {
  console.log(barangay)
  console.log(list_of_barangays.includes(barangay))
  return list_of_barangays.includes(barangay);
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
  // console.log(req.body)
  const {
    barangay,
    specific_location,
    date_and_time,
    report_type,
    description,
  } = req.body;

  const userId = req.user?.userId;
  // console.log(userId)
  if (!userId) {
    return res.status(401).json({ error: "Unauthorized. No user ID found." });
  }

  let emptyFields = [];
  if (!barangay) emptyFields.push("barangay");
  // console.log(barangay)
  if (!specific_location) emptyFields.push("specific_location");
  // console.log(specific_location)

  if (!date_and_time) emptyFields.push("date_and_time");
  // console.log(date_and_time)

  if (!report_type) emptyFields.push("report_type");
  // console.log(report_type)

  if (!description) emptyFields.push("description");
  // console.log(description)


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
  // console.log('req.files:', req.files);  // This will show the actual object structure
  // console.log('req.files JSON:', JSON.stringify(req.files, null, 2));  // Stringified version
  
  const imagePaths = req.files
    ? req.files.map((file) => {
        // console.log('Processing file:', file);  // Log each file object
        return path.join("uploads", file.filename);
      })
    : [];
  
  console.log('Generated imagePaths:', imagePaths);

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
  console.log('"Your has been successfully submitted.')
  res.status(201).json({
    message: "Report has been successfully created.",
    report: {
      _id: report._id,
      barangay: report.barangay,
      report_type: report.report_type,
    },
  });
  console.log('Report has been successfully created')

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

module.exports = {
  getAllReports,
  getReport,
  createReport,
  deleteReport,
};
