const express = require("express");
const {
  getNotifications,
  markAsRead,
} = require("../controllers/notificationController");
const auth = require("../middleware/authentication");

const router = express.Router();

router.get("/", auth, getNotifications);
router.patch("/:id/read", auth, markAsRead);

module.exports = router;
