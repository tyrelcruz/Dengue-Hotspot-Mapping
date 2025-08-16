const mongoose = require("mongoose");
const barangaysData = require("../data/barangays.json");
const asyncErrorHandler = require("../middleware/asyncErrorHandler");
const Barangay = require("../models/Barangays");
const RecommendationTemplate = require("../models/RecommendationTemplates");
const { getRecentCaseCounts } = require("../services/analytics/recentCases");

const getAllBarangays = asyncErrorHandler(async (req, res) => {
  const barangays = await Barangay.find({});

  res.status(200).json(barangays);
});


// TODO: Check if this is working
const getRecentReportsForBarangay = asyncErrorHandler(async (req, res) => {
  const { barangay_name } = req.body;

  if (!barangay_name) {
    return res.status(400).json({ message: "Barangay name is required." });
  }

  try {
    const csvPath = "data/main.csv";
    const caseCounts = await getRecentCaseCounts(csvPath, barangay_name);

    return res.status(200).json({
      barangay: barangay_name,
      reports: caseCounts,
    });
  } catch (error) {
    console.error("Error getting recent case counts:", error.message);
    return res
      .status(500)
      .json({ message: "Failed to retrieve reports for the barangay." });
  }
});

const retrieveSpecificBarangayInfo = asyncErrorHandler(async (req, res) => {
  const barangay_name = req.query.barangay;

  if (!barangay_name) {
    return res.status(400).json({ message: "Barangay name is required." });
  }

  try {
    const response = await axios.get(
      `${process.env.PYTHON_URL}/api/v1/specific-barangay-info?barangay_name=${encodeURIComponent(
        barangay_name
      )}`
    );

    // Get barangay data with enhanced recommendation
    const barangay = await Barangay.findOne({ name: barangay_name });

    return res.status(200).json({
      ...response.data,
      barangay_details: barangay,
    });
  } catch (error) {
    console.error("Error calling FastAPI service:", error.message);
    return res
      .status(500)
      .json({ message: "Failed to retrieve barangay information." });
  }
});

module.exports = {
  getAllBarangays,
  getRecentReportsForBarangay,
  retrieveSpecificBarangayInfo,
};
