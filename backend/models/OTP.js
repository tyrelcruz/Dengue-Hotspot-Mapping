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
  resendAttempts: {
    type: Number,
    default: 0,
  },
  lastResendTime: {
    type: Date,
    default: null
  },
  purpose: {
    type: String,
    enum: ["account-verification", "password-reset"],
    required: true
  }
});

OTPSchema.index({ userId: 1 });

module.exports = mongoose.model("OTP", OTPSchema);
