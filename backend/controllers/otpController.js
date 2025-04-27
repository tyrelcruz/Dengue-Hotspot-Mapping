const asyncErrorHandler = require("../middleware/asyncErrorHandler");
const { BadRequestError, UnauthorizedError } = require("../errors");
const Account = require("../models/Accounts");
const OTP = require("../models/OTP");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const {
  sendOTPVerificationEmail,
  sendForgotPasswordEmail,
} = require("../services/emailService");

const requestOTP = asyncErrorHandler(async (req, res) => {
  const { email, purpose } = req.body;

  if (!email) {
    throw new BadRequestError("Please provide an email input.");
  }

  if (
    !purpose ||
    !["account-verification", "password-reset"].includes(purpose)
  ) {
    throw new BadRequestError("Invalid purpose for OTP.");
  }

  const account = await Account.findOne({ email });
  if (!account) {
    return res.status(200).json({
      message: "This account does not exist!",
    });
  }

  if (purpose === "account-verification" && account.verified) {
    return res.status(200).json({
      message: "This account is already verified!",
    });
  }

  await OTP.deleteOne({ userId: account._id });

  if (purpose === "account-verification") {
    await sendOTPVerificationEmail(account);
  } else if (purpose === "password-reset") {
    await sendForgotPasswordEmail(account);
  }

  return res.status(200).json({
    message: `An OTP for ${purpose} has been sent to the indicated email.`,
  });
});

const verifyOTP = asyncErrorHandler(async (req, res) => {
  const { email, otp, purpose } = req.body;

  if (!email || !otp) {
    throw new BadRequestError("Please provide both email and OTP code.");
  }

  if (
    !purpose ||
    !["account-verification", "password-reset"].includes(purpose)
  ) {
    throw new BadRequestError(
      "Invalid or missing purpose for OTP verification."
    );
  }

  const account = await Account.findOne({ email });
  if (!account) {
    throw new BadRequestError("Account with this email does not exist.");
  }

  const otpRecord = await OTP.findOne({ userId: account._id });
  if (!otpRecord) {
    throw new BadRequestError(
      "OTP may have expired or does not exist. Request for a new one."
    );
  }

  const isValidOTP = await bcrypt.compare(otp, otpRecord.otp);
  if (!isValidOTP) {
    otpRecord.attempts += 1;

    if (otpRecord.attempts >= 3) {
      await OTP.deleteOne({ _id: otpRecord._id });
      throw new BadRequestError(
        "Too many incorrect attempts. Please request a new OTP instead."
      );
    }

    await otpRecord.save();
    throw new BadRequestError("Invalid OTP. Try again.");
  }

  await OTP.deleteOne({ _id: otpRecord._id });

  if (purpose === "account-verification") {
    account.verified = true;
    await account.save();

    return res.status(200).json({
      message: "Email has been successfully verified!",
    });
  } else if (purpose === "password-reset") {
    const resetToken = jwt.sign(
      {
        userId: account._id,
        purpose: "password-reset",
      },
      process.env.RESET_PASSWORD_TOKEN_SECRET,
      {
        expiresIn: "15m",
      }
    );

    return res.status(200).json({
      message: "OTP verified successfully.",
      resetToken,
    });
  }
});

module.exports = {
  requestOTP,
  verifyOTP,
};
