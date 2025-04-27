const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const OTPSchema = new Schema({
  userId: {
    type: Schema.Types.ObjectId,
    ref: "Account",
    required: true,
  },
  otp: {
    type: String,
    required: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
    expires: 300,
  },
  attempts: {
    type: Number,
    default: 0,
  },
});

OTPSchema.index({ userId: 1 });

module.exports = mongoose.model("OTP", OTPSchema);
