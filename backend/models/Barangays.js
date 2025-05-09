const mongoose = require("mongoose");

const Schema = mongoose.Schema;

const barangaySchema = new Schema({
  name: {
    type: String,
    required: true,
    unique: true,
  },
  risk_level: {
    type: String,
    enum: ["Low", "Medium", "High"],
    default: "Low",
  },
  triggered_pattern: {
    type: String,
    enum: ["stability", "spike", "decline", null],
    default: null,
  },
  alert: {
    type: String,
    default: null,
  }
});

module.exports = mongoose.model("Barangay", barangaySchema);
