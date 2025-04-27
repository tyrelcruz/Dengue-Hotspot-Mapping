const Notification = require("../models/Notifications");
const asyncErrorHandler = require("../middleware/asyncErrorHandler");

const getNotifications = asyncErrorHandler(async (req, res) => {
  const userId = req.user.userId;

  const notifications = await Notification.find({ user: userId }).populate(
    "report",
    "report_type barangay"
  );

  res.status(200).json(notifications);
});

const markAsRead = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;

  const notification = await Notification.findByIdAndUpdate(
    id,
    { isRead: true },
    { new: true }
  );

  if (!notification) {
    return res.status(404).json({ error: "No such notification exists!" });
  }

  res.status(200).json(notification);
});

module.exports = {
  getNotifications,
  markAsRead,
};
