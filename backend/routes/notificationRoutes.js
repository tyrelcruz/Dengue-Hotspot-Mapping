const express = require("express");
const router = express.Router();
const { protect } = require("../middleware/authMiddleware");
const {
  getNotifications,
  markAsRead,
  cleanupNotifications,
  cleanupDeletedReports
} = require("../controllers/notificationController");

router.get("/", protect, getNotifications);
router.put("/:id", protect, markAsRead);
router.delete("/cleanup", protect, cleanupNotifications);
router.delete("/cleanup-deleted", protect, cleanupDeletedReports);

module.exports = router; 