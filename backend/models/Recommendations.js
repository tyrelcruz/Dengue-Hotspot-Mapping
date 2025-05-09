const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const recommendationSchema = new Schema({
  barangay: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Account",
    required: true,
  },
  date: {
    type: Date,
    required: true,
  },
  recommendation: {
    type: String,
    required: true,
  },
});

module.exports = mongoose.model("Barangay", barangaySchema);
