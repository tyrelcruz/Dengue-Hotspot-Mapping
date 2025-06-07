const OTPModel = require("../models/OTP");

const saveOTPToDatabase = async (userId, hashedOTP, purpose, initialLastResendTime = null) => {
  // Find existing OTP to preserve resend attempts
  const existingOTP = await OTPModel.findOne({ userId });
  const resendAttempts = existingOTP ? existingOTP.resendAttempts : 0;
  // Use provided initialLastResendTime for new OTPs, otherwise preserve existing
  const lastResendTime = existingOTP ? existingOTP.lastResendTime : initialLastResendTime;

  // Delete existing OTP
  await OTPModel.deleteMany({ userId });

  const newOTPRecord = new OTPModel({
    userId,
    otp: hashedOTP,
    purpose,
    createdAt: Date.now(),
    resendAttempts,
    lastResendTime
  });

  console.log('Creating/Updating OTP record:', {
    userId,
    purpose,
    resendAttempts,
    lastResendTime
  });

  return await newOTPRecord.save();
};

const canResendOTP = async (userId) => {
  const existingOTP = await OTPModel.findOne({ userId });
  console.log('Checking existing OTP:', existingOTP);
  
  if (!existingOTP) {
    console.log('No existing OTP found');
    return { canResend: true };
  }

  // Check if user has exceeded maximum resend attempts (5 attempts)
  if (existingOTP.resendAttempts >= 5) {
    console.log('Max attempts reached:', existingOTP.resendAttempts);
    return {
      canResend: false,
      error: "Maximum resend attempts reached. Please try again after some time."
    };
  }

  // Check if enough time has passed since last resend (1 minute cooldown)
  if (existingOTP.lastResendTime) {
    const timeSinceLastResend = Date.now() - existingOTP.lastResendTime;
    const oneMinute = 60 * 1000;
    console.log('Time since last resend (ms):', timeSinceLastResend);
    
    if (timeSinceLastResend < oneMinute) {
      const remainingTime = Math.ceil((oneMinute - timeSinceLastResend) / 1000);
      console.log('Cooldown active, remaining seconds:', remainingTime);
      return {
        canResend: false,
        error: `Please wait ${remainingTime} seconds before requesting another OTP.`
      };
    }
  }

  return { canResend: true };
};

const updateResendAttempts = async (userId) => {
  const otpRecord = await OTPModel.findOne({ userId });
  console.log('Before update - OTP record:', otpRecord);
  
  if (otpRecord) {
    otpRecord.resendAttempts += 1;
    otpRecord.lastResendTime = new Date();
    await otpRecord.save();
    console.log('After update - OTP record:', {
      userId: otpRecord.userId,
      resendAttempts: otpRecord.resendAttempts,
      lastResendTime: otpRecord.lastResendTime
    });
  } else {
    console.log('No OTP record found to update');
  }
};

module.exports = { 
  saveOTPToDatabase,
  canResendOTP,
  updateResendAttempts
};
