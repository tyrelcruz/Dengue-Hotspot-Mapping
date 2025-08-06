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
      enum: ["All","Fogging", "Ovicidal-Larvicidal Trapping", "Clean-up Drive", "Education Campaign"],
      required: true,
    },
    specific_location: {
      type: {
        type: String,
        enum: ["Point"],
        required: true,
      },
      coordinates: {
        type: [Number],
        required: true,
        validate: {
          validator: function (coords) {
            return (
              coords.length === 2 &&
              coords[0] >= -180 &&
              coords[0] <= 180 &&
              coords[1] >= -90 &&
              coords[1] <= 90
            );
          },
          message: () => "Coordinates must be in [longitude, latitude] format.",
        },
      },
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

// Create a 2dsphere index for geospatial queries
interventionSchema.index({ specific_location: "2dsphere" });

module.exports = mongoose.model("Intervention", interventionSchema);
