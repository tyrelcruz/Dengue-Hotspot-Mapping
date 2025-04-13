const otpGenerator = require("otp-generator");
const OTP = require("../models/otpModel");
const Account = require("../models/Accounts");

exports.sendOTP = async (req, res) => {
  try {
    const { email } = req.body;
    const checkAccountPresent = await Account.findOne({ email });

    if (checkAccountPresent) {
      return res.status(401);
    }
  } catch (error) {}
};
