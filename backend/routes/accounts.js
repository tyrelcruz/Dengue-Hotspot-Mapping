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
  addTimestampsToExistingAccounts,
  toggleAccountStatus,
  deleteAllAccounts,
} = require("../controllers/accountsController");

// Protect all routes with auth and superadmin check
router.use(auth, authorizeSuperadmin);

// Get all accounts
router.get("/", getAllAccounts);

// Get accounts by role/type
router.get("/role/:role", getAccountsByType);

// Create a new account
router.post("/", createAccount);

// Update an account
router.patch("/:id", updateAccount);

// Delete all accounts
router.delete("/delete-all", deleteAllAccounts);

// Delete an account
router.delete("/:id", deleteAccount);

// Add this route
router.post("/add-timestamps", addTimestampsToExistingAccounts);

// Add this new route
router.patch("/:id/toggle-status", toggleAccountStatus);

module.exports = router;
