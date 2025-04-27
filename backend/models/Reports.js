const mongoose = require("mongoose");
const barangaysData = require("../data/barangays.json");

let list_of_barangays = barangaysData.features.map(
  (feature) => feature.properties.name
);

const Schema = mongoose.Schema;

const reportSchema = new Schema(
  {
    // ! No Report ID, yet, or never
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
          return list_of_barangays.includes(value);
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

reportSchema.index({ specific_location: "2dsphere" });

module.exports = mongoose.model("Report", reportSchema);
