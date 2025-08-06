const express = require("express");
const router = express.Router();
const auth = require("../middleware/authentication");
const authorizeSuperadmin = require("../middleware/authorizeSuperadmin");
const {
  getAllAccounts,
  getAccountsByType,
  createAccount,
  updateAccount,
  deleteAccount,
  restoreAccount,
  addTimestampsToExistingAccounts,
  toggleAccountStatus,
  deleteAllAccounts,
  getDeletedAccounts,
  getAccountActivity,
  getAccountsByStatus,
  getAccountStats,
  permanentlyDeleteAccount,
  updateProfilePhoto,
  updateUserBio,
  getUserProfile,
  getBasicProfile,
  getAllBasicProfiles,
} = require("../controllers/accountsController");

// Profile photo upload (auth required, not superadmin)
router.post("/profile-photo", auth, updateProfilePhoto);

// Update user bio (auth required)
router.patch("/:id/bio", auth, updateUserBio);

// Get basic profile info (no auth required)
router.get("/basic", getAllBasicProfiles);
router.get("/basic/:id", getBasicProfile);

// Get user profile (auth required)
router.get("/profile/:id", auth, getUserProfile);

// Protect all routes with auth and superadmin check
router.use(auth, authorizeSuperadmin);

// Get all accounts
router.get("/", getAllAccounts);

// Get accounts by type
router.get("/type/:type", getAccountsByType);

// Get accounts by status
router.get("/status/:status", getAccountsByStatus);

// Get deleted accounts
router.get("/deleted", getDeletedAccounts);

// Get account statistics
router.get("/stats", getAccountStats);

// Get account activity
router.get("/:id/activity", getAccountActivity);

// Create a new account
router.post("/", createAccount);

// Update an account
router.put("/:id", updateAccount);

// Delete all accounts
router.delete("/", deleteAllAccounts);

// Delete an account (soft delete)
router.delete("/:id", deleteAccount);

// Permanently delete an account
router.delete("/:id/permanent", permanentlyDeleteAccount);

// Restore a deleted account
router.post("/:id/restore", restoreAccount);

// Add timestamps to existing accounts
router.post("/add-timestamps", addTimestampsToExistingAccounts);

// Toggle account status
router.patch("/:id/toggle-status", toggleAccountStatus);

module.exports = router;
