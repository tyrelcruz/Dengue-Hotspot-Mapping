const Account = require("../models/Accounts");
const { BadRequestError, NotFoundError } = require("../errors");
const mongoose = require("mongoose");
const { sendOTPVerificationEmail } = require("../services/emailService");

const ALLOWED_ROLES = ["admin", "user", "superadmin"];
const EMAIL_REGEX = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
const ALLOWED_UPDATE_FIELDS = ["username", "email", "password", "role"];

// Get all accounts (excluding deleted ones by default)
const getAllAccounts = async (req, res) => {
  try {
    const accounts = await Account.find({})
      .select('_id username email role verified authProvider status createdAt updatedAt')
      .sort({ createdAt: -1 });
    res.status(200).json(accounts);
  } catch (error) {
    console.error('Error in getAllAccounts:', error);
    res.status(500).json({ error: 'Internal server error', details: error.message });
  }
};

// Get accounts by role/type (excluding deleted ones)
const getAccountsByType = async (req, res) => {
  const { role } = req.params;
  const accounts = await Account.find({ 
    role,
    status: { $ne: "deleted" }
  })
    .select('_id username email role verified authProvider status createdAt updatedAt')
    .sort({ createdAt: -1 });
  res.status(200).json(accounts);
};

// Create a new account
const createAccount = async (req, res) => {
  const { username, email, password, role, authProvider = "local" } = req.body;
  
  // Validate username
  if (!username || typeof username !== "string" || username.trim() === "") {
    return res.status(400).json({ error: "Username is required and must be a non-empty string." });
  }
  
  // Validate email
  if (!email || typeof email !== "string" || !EMAIL_REGEX.test(email)) {
    return res.status(400).json({ error: "A valid email is required." });
  }
  
  // Validate password (only required for local auth)
  if (authProvider === "local" && (!password || typeof password !== "string" || password.length < 8)) {
    return res.status(400).json({ error: "Password is required and must be at least 8 characters for local authentication." });
  }
  
  // Validate role
  if (!role || !ALLOWED_ROLES.includes(role)) {
    return res.status(400).json({ error: "Invalid role value. Allowed roles: admin, user, superadmin." });
  }

  // Validate authProvider
  if (!["local", "google"].includes(authProvider)) {
    return res.status(400).json({ error: "Invalid auth provider. Must be either 'local' or 'google'." });
  }

  // Check for existing account that is not deleted
  const existing = await Account.findOne({ 
    email,
    status: { $ne: "deleted" }
  });
  
  if (existing) {
    return res.status(400).json({ error: "Account with this email already exists." });
  }

  // Create account with explicit timestamps and status
  const now = new Date();
  const account = await Account.create({
    username,
    email,
    password: authProvider === "local" ? password : undefined,
    role,
    authProvider,
    status: "active",
    verified: authProvider === "google",
    createdAt: now,
    updatedAt: now
  });

  // Only send OTP for local authentication
  if (authProvider === "local") {
    const result = await sendOTPVerificationEmail(account);

    if (result.status === "Failed") {
      return res.status(201).json({
        message: "Account created but failed to send verification email. Please request a new OTP.",
        account: await Account.findById(account._id)
          .select('_id username email role verified authProvider status createdAt updatedAt')
      });
    }
  }

  // Return account without password
  const accountWithoutPassword = await Account.findById(account._id)
    .select('_id username email role verified authProvider status createdAt updatedAt');
  
  res.status(201).json({
    message: authProvider === "local" 
      ? "Account created successfully. Please check your email for verification."
      : "Account created successfully.",
    account: accountWithoutPassword
  });
};

// Update an account
const updateAccount = async (req, res) => {
  const { id } = req.params;
  const updates = req.body;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(400).json({ error: "Invalid account ID format." });
  }
  // Only allow updates to allowed fields
  const updateFields = Object.keys(updates);
  const invalidFields = updateFields.filter((field) => !ALLOWED_UPDATE_FIELDS.includes(field));
  if (invalidFields.length > 0) {
    return res.status(400).json({ error: `Invalid update fields: ${invalidFields.join(", ")}` });
  }
  // Validate each field if present
  if (updates.username !== undefined && (typeof updates.username !== "string" || updates.username.trim() === "")) {
    return res.status(400).json({ error: "Username must be a non-empty string." });
  }
  if (updates.email !== undefined && (typeof updates.email !== "string" || !EMAIL_REGEX.test(updates.email))) {
    return res.status(400).json({ error: "Email must be valid." });
  }
  if (updates.password !== undefined && (typeof updates.password !== "string" || updates.password.length < 8)) {
    return res.status(400).json({ error: "Password must be at least 8 characters." });
  }
  if (updates.role !== undefined && !ALLOWED_ROLES.includes(updates.role)) {
    return res.status(400).json({ error: "Invalid role value. Allowed roles: admin, user, superadmin." });
  }
  const account = await Account.findByIdAndUpdate(id, updates, { 
    new: true,
    select: '_id username email role verified authProvider createdAt updatedAt'
  });
  if (!account) {
    return res.status(404).json({ error: "Account not found." });
  }
  res.status(200).json(account);
};

// Delete an account (soft delete)
const deleteAccount = async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(400).json({ error: "Invalid account ID format." });
  }

  const account = await Account.findByIdAndDelete(id);

  if (!account) {
    return res.status(404).json({ error: "Account not found." });
  }

  res.status(200).json({
    message: "Account permanently deleted.",
    account
  });
};

// Add this new function
const addTimestampsToExistingAccounts = async (req, res) => {
  try {
    const accounts = await Account.find({});
    const updatePromises = accounts.map(account => {
      if (!account.createdAt) {
        const creationDate = account._id.getTimestamp();
        return Account.findByIdAndUpdate(account._id, {
          createdAt: creationDate,
          updatedAt: creationDate
        }, { new: true });
      }
    });
    
    await Promise.all(updatePromises.filter(Boolean));
    res.status(200).json({ message: "Timestamps added to existing accounts" });
  } catch (error) {
    console.error('Error adding timestamps:', error);
    res.status(500).json({ error: 'Failed to add timestamps' });
  }
};

// Toggle account status (active/disabled/banned)
const toggleAccountStatus = async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(400).json({ error: "Invalid account ID format." });
  }

  // First get the account to check its role
  const account = await Account.findById(id);
  if (!account) {
    return res.status(404).json({ error: "Account not found." });
  }

  // Validate status based on role
  if (account.role === "user" && status === "disabled") {
    return res.status(400).json({ error: "User accounts cannot be disabled. Use 'banned' instead." });
  }
  if ((account.role === "admin" || account.role === "superadmin") && status === "banned") {
    return res.status(400).json({ error: "Admin accounts cannot be banned. Use 'disabled' instead." });
  }

  if (!["active", "disabled", "banned"].includes(status)) {
    return res.status(400).json({ error: "Invalid status. Must be either 'active', 'disabled', or 'banned'." });
  }

  const updatedAccount = await Account.findByIdAndUpdate(
    id,
    { 
      status,
      updatedAt: new Date()
    },
    { 
      new: true,
      select: '_id username email role verified authProvider status createdAt updatedAt'
    }
  );

  res.status(200).json({
    message: `Account ${status === 'active' ? 'enabled' : status} successfully`,
    account: updatedAccount
  });
};

// Add this new function
const deleteAllAccounts = async (req, res) => {
  try {
    await Account.deleteMany({});
    res.status(200).json({ message: "All accounts have been deleted successfully" });
  } catch (error) {
    console.error('Error deleting all accounts:', error);
    res.status(500).json({ error: 'Failed to delete all accounts' });
  }
};

module.exports = {
  getAllAccounts,
  getAccountsByType,
  createAccount,
  updateAccount,
  deleteAccount,
  addTimestampsToExistingAccounts,
  toggleAccountStatus,
  deleteAllAccounts
}; 