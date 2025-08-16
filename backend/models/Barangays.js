const mongoose = require("mongoose");

const Schema = mongoose.Schema;

const barangaySchema = new Schema({
  name: {
    type: String,
    required: true,
    unique: true,
  },
  status: {
    pattern: {
      type: String,
      enum: ["spike", "gradual_rise", "decline", "stability", "low_level_activity"],
      default: "stability",
    },
    crowdsourced_reports_count: {
      type: Number,
      default: 0,
    },
    deaths: {
      type: Number,
      default: 0,
    },
  },
  recommendation: {
    type: String,
    default: "None",
  },
  // status_and_recommendation: {
  //   pattern_based: {
  //     status: {
  //       type: String,
  //       enum: ["spike", "gradual_rise", "decline", "stability"],
  //       default: "stability",
  //     },
  //     alert: {
  //       type: String,
  //       default: "None",
  //     },
  //   },
  //   report_based: {
  //     count: {
  //       type: Number,
  //       default: 0,
  //     },
  //     status: {
  //       type: String,
  //     },
  //     alert: {
  //       type: String,
  //       default: "None",
  //     },
  //   },
  //   death_priority: {
  //     status: {
  //       type: String,
  //     },
  //     alert: {
  //       type: String,
  //       default: "None",
  //     },
  //   },
  //   recommendation: {
  //     type: String,
  //     default: "None",
  //   },
  // },
  last_analysis_time: {
    type: Date,
  },
});

module.exports = mongoose.model("Barangay", barangaySchema, "barangays");
