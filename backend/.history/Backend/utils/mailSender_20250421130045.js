const nodemailer = require("nodemailer");
const bcrypt = require("bcryptjs");
const OTPModel = require("../models/OTP");
const crypto = require("crypto");

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD,
  },
});

const sendEmail = async (email, subject, html) => {
  console.log(process.env.GMAIL_USER);
  console.log(process.env.GMAIL_APP_PASSWORD);

  try {
    const info = await transporter.sendMail({
      from: `"BuzzMap" <${process.env.GMAIL_USER}>`,
      to: email,
      subject,
      html,
    });
    console.log(
      `Verification email has been sent to ${email}: ${info.messageId}`
    );
    return info;
  } catch (error) {
    console.error("Failed to send email:", error.message);
    throw error;
  }
};

const sendOTPVerificationEmail = async (account) => {
  try {
    if (account.verified) {
      return {
        status: "Failed",
        message: "Account is already verified.",
      };
    }

    const otp = crypto.randomInt(1000, 9999).toString();
    const hashedOTP = await bcrypt.hash(otp, 10);

    await OTPModel.deleteMany({ userId: account._id });

    const newOTPRecord = new OTPModel({
      userId: account._id,
      otp: hashedOTP,
      createdAt: Date.now(),
    });
    await newOTPRecord.save();

    const emailContent = `
      <div style="font-family: Arial, sans-serif; line-height: 1.6;">
        <h2>Email Verification</h2>
        <p>Your OTP code is <b>${otp}</b>.</p>
        <p>Enter this code in the application to verify your email and complete the registration process.</p>
        <p style="color: #666; font-size: 0.9em;">
          Please note that this code will expire after 5 minutes.
        </p>
      </div>
    `;

    await sendEmail(account.email, "Verify Your Email", emailContent);
    return true;
  } catch (error) {
    console.error("Failed to send the OTP email:", error.message);
    throw error;
  }
};

module.exports = { sendOTPVerificationEmail };
