const mongoose = require("mongoose");
const barangaysData = require("../data/barangays.json");
const asyncErrorHandler = require("../middleware/asyncErrorHandler");
const Barangay = require("../models/Barangays");

const getAllBarangays = asyncErrorHandler(async (req, res) => {
  const barangays = await Barangay.find({});
  res.status(200).json(barangays);
});

module.exports = {
  getAllBarangays,
};
