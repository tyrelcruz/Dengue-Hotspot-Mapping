const express = require("express");
const router = express.Router();

const {
  register,
  login,
  googleLogin,
  forgotPassword,
  resetPassword,
} = require("../controllers/authController");

const { requestOTP, verifyOTP, resendOTP } = require("../controllers/otpController");
const {
  validateRegisterInputs,
  validateLoginInputs,
} = require("../middleware/userValidation");

// * Standard Registration and Login
router.post("/register", validateRegisterInputs, register);
router.post("/login", validateLoginInputs, login);
router.post("/google-login", googleLogin);

// * OTP-related
router.post("/request-otp", requestOTP);
router.post("/verify-otp", verifyOTP);
router.post("/resend-otp", resendOTP);

// * Password-related
router.post("/forgot-password", forgotPassword);
router.post("/reset-password", resetPassword);
  
module.exports = router;
