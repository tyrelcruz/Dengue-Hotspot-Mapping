const Report = require("../models/Reports");
// const Counter = require('../models/Counter');
const mongoose = require("mongoose");

// * GET all reports
const getAllReports = async (req, res) => {
  // ? find could be modified to look for posts with specific properties.
  // ? createdAt: -1 - newest at the top, could be good for Latest tab
  const reports = await Report.find({}).sort({ createdAt: -1 });

  res.status(200).json(reports);
};

// * GET a specific report
const getReport = async (req, res) => {
  const { id } = req.params;

  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(404).json({ error: "No such post!" });
  }
  const report = await Report.findById(id);

  if (!report) {
    return res.status(404).json({ error: "Post does not exist!" });
  }

  res.status(200).json(report);
};

// * POST a new post
const createReport = async (req, res) => {
  const {
    district,
    barangay,
    specific_location,
    date_and_time,
    report_type,
    description,
  } = req.body;

  let emptyFields = [];

  // if(!report_id) {
  //   emptyFields.push('report_id');
  // }
  if (!district) {
    emptyFields.push("district");
  }
  if (!barangay) {
    emptyFields.push("barangay");
  }
  if (!specific_location) {
    emptyFields.push("specific_location");
  }
  if (!date_and_time) {
    emptyFields.push("date_and_time");
  }
  if (!report_type) {
    emptyFields.push("report_type");
  }
  if (!description) {
    emptyFields.push("description");
  }
  if (emptyFields.length > 0) {
    return res
      .status(400)
      .json({ error: "Please fill in all fields", emptyFields });
  }

  const imagePaths = req.files
    ? req.files.map((file) => `/uploads/${file.filename}`)
    : [];

  try {
    // // * Updates the counter
    // Counter.findOneAndUpdate(
    //   {id: "autoval"},
    //   {"$inc": { "seq": 1 }},
    //   {new: true},
    //   (err, cd) => {
    //     if(cd == null) {
    //       const newVal = new Counter({
    //         id: "autoval",
    //         seq: 1
    //       })
    //       newVal.save();
    //     }
    //   }
    // )

    const report = await Report.create({
      district,
      barangay,
      specific_location,
      date_and_time,
      report_type,
      description,
      images: imagePaths,
    });

    res
      .status(201)
      .json({ message: "Report has been successfully created.", report });
    console.log("testing... complete.");
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ! DELETE a post - ADMIN side
const deleteReport = async (req, res) => {
  const { id } = req.params;

  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(404).json({ error: "No such post!" });
  }

  const report = await Report.findOneAndDelete({ _id: id });

  if (!report) {
    return res.status(404).json({ error: "No such post exists!" });
  }

  res.status(200).json(report);
};

// const validateReport = async (req, res) => {
//
// }

module.exports = {
  getAllReports,
  getReport,
  createReport,
  deleteReport,
};
