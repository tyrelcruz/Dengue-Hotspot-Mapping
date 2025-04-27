const OTPModel = require("../models/OTP");

const saveOTPToDatabase = async (userId, hashedOTP) => {
  await OTPModel.deleteMany({ userId });

  const newOTPRecord = new OTPModel({
    userId,
    otp: hashedOTP,
    createdAt: Date.now(),
  });
  return await newOTPRecord.save();
};

module.exports = { saveOTPToDatabase };
