const mongoose = require("mongoose");
const barangays = require("../data/barangays");

const Schema = mongoose.Schema;

// Extract barangay names from barangays.features and normalize them, adding validation for undefined values
const list_of_barangays = barangays.features
  .filter((feature) => feature.properties && feature.properties.name) // Ensure properties and name exist
  .map((feature) => feature.properties.name.toLowerCase().trim()); // Normalize barangay names

const reportSchema = new Schema(
  {
    // No Report ID, yet, or never
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Account",
      required: true,
    },
    barangay: {
      type: String,
      required: true,
      validate: {
        validator: function (value) {
          // Normalize and check against the list of barangays
          return list_of_barangays.includes(value.toLowerCase().trim());
        },
        message: (props) => `${props.value} is not a valid barangay.`,
      },
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
    date_and_time: {
      type: Date,
      required: true,
    },
    report_type: {
      type: String,
      required: true,
      enum: [
        "Breeding Site",
        "Suspected Case",
        "Standing Water",
        "Infestation",
      ],
    },
    description: { type: String },
    images: [{ type: String }],
    status: {
      type: String,
      default: "Pending",
      enum: ["Pending", "Rejected", "Validated"],
    },
  },
  { timestamps: true }
);

// Create a 2dsphere index for geospatial queries
reportSchema.index({ specific_location: "2dsphere" });

// Export the Report model
module.exports = mongoose.model("Report", reportSchema);
