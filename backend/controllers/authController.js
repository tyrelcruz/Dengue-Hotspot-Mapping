const { StatusCodes } = require("http-status-codes");
const Account = require("../models/Accounts");
const {
  BadRequestError,
  UnauthenticatedError,
  UnauthorizedError,
} = require("../errors");
const asyncErrorHandler = require("../middleware/asyncErrorHandler");
const jwt = require("jsonwebtoken");
const {
  sendOTPVerificationEmail,
  sendForgotPasswordEmail,
} = require("../services/emailService");

const register = asyncErrorHandler(async (req, res) => {
  const { email, role } = req.body;

  const existingAccount = await Account.findOne({ email });

  if (existingAccount) {
    throw new BadRequestError("Account with this email already exists.");
  }

  if (!role) {
    throw new BadRequestError("Account role is required.");
  }
  const account = await Account.create(req.body);

  const result = await sendOTPVerificationEmail(account);

  if (result.status === "Failed") {
    return res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      message:
        "Account has been created but failed to send verification email.",
      error: result.message,
    });
  }

  res.status(StatusCodes.CREATED).json({
    message:
      "Account created successfully. Please check your email for verification.",
    email: account.email,
  });
});

const login = asyncErrorHandler(async (req, res) => {
  const { email, password, role } = req.body;

  if (!email || !password) {
    throw new BadRequestError(
      "Please provide both credentials for email and password."
    );
  }
  if (!role) {
    throw new BadRequestError("Please provide an account type.");
  }
  const account = await Account.findOne({ email });

  if (!account) {
    throw new UnauthenticatedError(
      "Account with inputted email does not exist."
    );
  }

  if (!account.verified) {
    throw new UnauthenticatedError(
      "Account has not been verified yet. Please check your email to resolve the registration process."
    );
  }

  // Check for disabled or banned status
  if (account.status === "disabled") {
    throw new UnauthenticatedError("This account has been disabled. Please contact the administrator.");
  }
  if (account.status === "banned") {
    throw new UnauthenticatedError("This account has been banned. Please contact the administrator.");
  }

  const isPasswordCorrect = await account.comparePassword(password);

  if (!isPasswordCorrect) {
    throw new UnauthenticatedError("Incorrect password inputted.");
  }

  // Verify that the requested role matches the account's role
  if (role && account.role !== role) {
    throw new UnauthenticatedError(
      `You are not authorized as a ${role}. Your account role is ${account.role}.`
    );
  }

  const payload = {
    userId: account._id,
    email: account.email,
    role: account.role, // Always use the role from the database
  };

  const accessToken = jwt.sign(payload, process.env.ACCESS_TOKEN_SECRET, {
    expiresIn: "24h",
  });

  res.status(StatusCodes.OK).json({
    success: true,
    user: {
      _id: account._id,
      name: account.username,
      email: account.email,
      role: account.role, // Always use the role from the database
      status: account.status // Include status in the response
    },
    accessToken,
  });
});

const googleLogin = asyncErrorHandler(async (req, res) => {
  const { email, name, googleId } = req.body;

  if (!email || !googleId) {
    throw new BadRequestError("Missing required Google account details.");
  }

  let account = await Account.findOne({ email });

  if (!account) {
    account = await Account.create({
      username: name || "Google User",
      email,
      authProvider: "google",
      verified: true,
    });
  }

  if (account.authProvider !== "google") {
    throw new UnauthenticatedError(
      "This email is registered using a different login method."
    );
  }

  const payload = {
    userId: account._id,
    email: account.email,
    role: account.role || "user",
  };

  const accessToken = jwt.sign(payload, process.env.ACCESS_TOKEN_SECRET, {
    expiresIn: "24h",
  });

  return res.status(StatusCodes.OK).json({
    success: true,
    user: {
      _id: account.id,
      name: account.username,
      email: account.email,
    },
    accessToken,
  });
});

const forgotPassword = asyncErrorHandler(async (req, res) => {
  const { email } = req.body;

  const account = await Account.findOne({ email });
  if (!account) {
    return res.status(StatusCodes.NOT_FOUND).json({
      status: "Failed",
      message: "Account does not exist!",
    });
  }

  const result = await sendForgotPasswordEmail(account);

  if (result.status === "Failed") {
    return res.status(StatusCodes.INTERNAL_SERVER_ERROR).json({
      status: "Failed",
      message: "Failed to send password reset email.",
      error: result.message,
    });
  }

  res.status(StatusCodes.OK).json({
    status: "Success",
    message: "Password reset email send successfully!",
  });
});

const resetPassword = asyncErrorHandler(async (req, res) => {
  const { resetToken, newPassword } = req.body;

  if (!resetToken || !newPassword) {
    throw new BadRequestError(
      "Please provide both the token and the new password."
    );
  }

  try {
    const decoded = jwt.verify(
      resetToken,
      process.env.RESET_PASSWORD_TOKEN_SECRET
    );

    if (decoded.purpose !== "password-reset") {
      throw new UnauthorizedError("Invalid reset token received.");
    }

    const account = await Account.findById(decoded.userId);

    if (!account) {
      throw new BadRequestError("Account not found!");
    }

    account.password = newPassword;
    await account.save();

    return res.status(StatusCodes.OK).json({
      status: "Success",
      message: "Password has been reset successfully.",
    });
  } catch (error) {
    if (
      error.name === "JsonWebTokenError" ||
      error.name === "TokenExpiredError"
    ) {
      throw new UnauthorizedError(
        "Reset token is either invalid or expired. Request a new password reset."
      );
    }
    throw error;
  }
});

module.exports = {
  register,
  login,
  forgotPassword,
  resetPassword,
  googleLogin,
};
