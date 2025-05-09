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

// Delete an account
router.delete("/:id", deleteAccount);

module.exports = router;
