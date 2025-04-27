const sendEmail = require("../utils/email");
const { generateOTP, hashOTP } = require("../utils/otp");
const { saveOTPToDatabase } = require("./otpService");

const _sendOTPEmail = async (account, { subject, heading, bodyText }) => {
  try {
    const otp = generateOTP();
    const hashedOTP = await hashOTP(otp);

    await saveOTPToDatabase(account._id, hashedOTP);

    const emailContent = `
      <div style="font-family: Arial, sans-serif; line-height: 1.6;">
        <h2>${heading}</h2>
        <p>Your OTP code is <b>${otp}</b>.</p>
        <p>${bodyText}</p>
        <p style="color: #666; font-size: 0.9em;">
          Please note that this code will expire after 5 minutes.
        </p>
      </div>
    `;
    await sendEmail(account.email, subject, emailContent);

    return {
      status: "Success",
      message: "OTP email has been sent successfully.",
    };
  } catch (error) {
    console.error("Failed to send the OTP email:", error.message);
    return {
      status: "Failed",
      message: "Failed to send OTP email.",
      error: error.message,
    };
  }
};

const sendOTPVerificationEmail = async (account) => {
  if (account.verified) {
    return {
      status: "Failed",
      message: "Account is already verified.",
    };
  }

  return _sendOTPEmail(account, {
    subject: "Verify Your Email",
    heading: "Email Verification",
    bodyText:
      "Enter this code in the application to verify your email and complete the registration process.",
  });
};

const sendForgotPasswordEmail = async (account) => {
  return _sendOTPEmail(account, {
    subject: "Reset Your Password",
    heading: "Password Reset",
    bodyText:
      "We have received a request from you for resetting your password. Enter the above OTP to continue with the password reset process.",
  });
};

module.exports = { sendOTPVerificationEmail, sendForgotPasswordEmail };
