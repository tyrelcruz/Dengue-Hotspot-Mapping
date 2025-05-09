const Account = require("../models/Accounts");
const { BadRequestError, NotFoundError } = require("../errors");
const mongoose = require("mongoose");

const ALLOWED_ROLES = ["admin", "user", "superadmin"];
const EMAIL_REGEX = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
const ALLOWED_UPDATE_FIELDS = ["username", "email", "password", "role"];

// Get all accounts
const getAllAccounts = async (req, res) => {
  const accounts = await Account.find({});
  res.status(200).json(accounts);
};

// Get accounts by role/type
const getAccountsByType = async (req, res) => {
  const { role } = req.params;
  const accounts = await Account.find({ role });
  res.status(200).json(accounts);
};

// Create a new account
const createAccount = async (req, res) => {
  const { username, email, password, role } = req.body;
  // Validate username
  if (!username || typeof username !== "string" || username.trim() === "") {
    return res.status(400).json({ error: "Username is required and must be a non-empty string." });
  }
  // Validate email
  if (!email || typeof email !== "string" || !EMAIL_REGEX.test(email)) {
    return res.status(400).json({ error: "A valid email is required." });
  }
  // Validate password
  if (!password || typeof password !== "string" || password.length < 8) {
    return res.status(400).json({ error: "Password is required and must be at least 8 characters." });
  }
  // Validate role
  if (!role || !ALLOWED_ROLES.includes(role)) {
    return res.status(400).json({ error: "Invalid role value. Allowed roles: admin, user, superadmin." });
  }
  const existing = await Account.findOne({ email });
  if (existing) {
    return res.status(400).json({ error: "Account with this email already exists." });
  }
  const account = await Account.create({ username, email, password, role });
  res.status(201).json(account);
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
  const account = await Account.findByIdAndUpdate(id, updates, { new: true });
  if (!account) {
    return res.status(404).json({ error: "Account not found." });
  }
  res.status(200).json(account);
};

// Delete an account
const deleteAccount = async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(400).json({ error: "Invalid account ID format." });
  }
  const account = await Account.findByIdAndDelete(id);
  if (!account) {
    return res.status(404).json({ error: "Account not found." });
  }
  res.status(200).json({ message: "Account deleted successfully." });
};

module.exports = {
  getAllAccounts,
  getAccountsByType,
  createAccount,
  updateAccount,
  deleteAccount,
}; 