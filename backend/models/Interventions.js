// models/Interventions.js

const mongoose = require("mongoose");

const interventionSchema = new mongoose.Schema(
  {
    barangay: {
      type: String,
      required: true,
    },
    address: {
      type: String,
    },
    date: {
      type: Date,
      required: true,
    },
    interventionType: {
      type: String,
      enum: ["Fogging", "Larviciding", "Clean-up Drive", "Education Campaign"],
      required: true,
    },
    personnel: {
      type: String,
      required: true,
    },
    status: {
      type: String,
      enum: ["Scheduled", "Ongoing", "Complete"],
      default: "Scheduled",
    },
    adminId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Account", // Reference to the 'Account' model where admin details are stored
      required: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Intervention", interventionSchema);
