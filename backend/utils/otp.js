const bcrypt = require("bcryptjs");
const crypto = require("crypto");

const generateOTP = () => {
  return crypto.randomInt(1000, 9999).toString();
};

const hashOTP = async (otp) => {
  return await bcrypt.hash(otp, 10);
};

module.exports = { generateOTP, hashOTP };
