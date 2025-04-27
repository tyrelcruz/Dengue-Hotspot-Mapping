const nodemailer = require("nodemailer");

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD,
  },
});

const sendEmail = async (email, subject, html) => {
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

module.exports = sendEmail;
