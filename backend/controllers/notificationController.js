const Notification = require("../models/Notifications");
const asyncErrorHandler = require("../middleware/asyncErrorHandler");
const User = require("../models/User");

// One-time cleanup for notifications with deleted reports
const cleanupDeletedReports = asyncErrorHandler(async (req, res) => {
  // Find all notifications where report is null (deleted)
  const result = await Notification.deleteMany({
    report: null,
  });

  res.status(200).json({
    message: `Cleaned up ${result.deletedCount} notifications with deleted reports`,
    deletedCount: result.deletedCount,
  });
});

const getNotifications = asyncErrorHandler(async (req, res) => {
  const userId = req.user.userId;

  const notifications = await Notification.find({ user: userId })
    .populate({
      path: "report",
      select:
        "report_type barangay images date_and_time status specific_location",
    })
    .sort({ createdAt: -1 }); // Sort by newest first

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

// Clean up old notifications
const cleanupNotifications = asyncErrorHandler(async (req, res) => {
  const userId = req.user.userId;

  // Delete notifications older than 30 days
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const result = await Notification.deleteMany({
    user: userId,
    createdAt: { $lt: thirtyDaysAgo },
  });

  res.status(200).json({
    message: `Cleaned up ${result.deletedCount} old notifications`,
    deletedCount: result.deletedCount,
  });
});

// Delete all notifications for a specific user
const deleteUserNotifications = asyncErrorHandler(async (req, res) => {
  const { username } = req.params;

  // Find the user by username
  const user = await User.findOne({ username });
  if (!user) {
    return res.status(404).json({ error: "User not found" });
  }

  // Delete all notifications for this user
  const result = await Notification.deleteMany({ user: user._id });

  res.status(200).json({
    message: `Deleted ${result.deletedCount} notifications for user ${username}`,
    deletedCount: result.deletedCount,
  });
});

module.exports = {
  getNotifications,
  markAsRead,
  cleanupNotifications,
  cleanupDeletedReports,
  deleteUserNotifications,
};
