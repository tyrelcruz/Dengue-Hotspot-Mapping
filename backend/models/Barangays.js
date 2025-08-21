const mongoose = require("mongoose");

const Schema = mongoose.Schema;

const barangaySchema = new Schema({
  name: {
    type: String,
    required: true,
    unique: true,
  },
  status_and_recommendation: {
    pattern_based: {
      status: {
        type: String,
        enum: [
          "spike",
          "gradual_rise",
          "decline",
          "stability",
          "low_level_activity",
        ],
        default: "stability",
      },
      alert: {
        type: String,
        default: "None",
      },
      admin_recommendation: {
        type: String,
        default: "None",
      },
      user_recommendation: {
        type: String,
        default: "None",
      },
    },
    report_based: {
      count: {
        type: Number,
        default: 0,
      },
      status: {
        type: String,
      },
      alert: {
        type: String,
        default: "None",
      },
      recommendation: {
        type: String,
        default: "None",
      },
    },
    death_priority: {
      count: {
        type: Number,
        default: 0,
      },
      alert: {
        type: String,
        default: "None",
      },
      recommendation: {
        type: String,
        default: "None",
      },
    },
    recommendation: {
      type: String,
      default: "None",
    },
  },
  last_analysis_time: {
    type: Date,
  },
});

module.exports = mongoose.model("Barangay", barangaySchema, "barangays");
