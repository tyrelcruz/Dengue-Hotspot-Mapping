const express = require('express');
const router = express.Router();
const AdminPost = require('../models/AdminPosts');
const Alert = require('../models/Alerts');
const Intervention = require('../models/Interventions');
const Account = require('../models/Accounts');
const Report = require('../models/Reports');
const Notification = require('../models/Notifications');
const Comment = require('../models/Comments');
const AdminPostComment = require('../models/AdminPostComments');
const asyncErrorHandler = require('../middleware/asyncErrorHandler');

// Delete all admin posts
router.delete('/adminposts', asyncErrorHandler(async (req, res) => {
    await AdminPost.deleteMany({});
    res.status(200).json({ message: 'All admin posts deleted successfully' });
}));

// Delete all alerts
router.delete('/alerts', asyncErrorHandler(async (req, res) => {
    await Alert.deleteMany({});
    res.status(200).json({ message: 'All alerts deleted successfully' });
}));

// Delete all interventions
router.delete('/interventions', asyncErrorHandler(async (req, res) => {
    await Intervention.deleteMany({});
    res.status(200).json({ message: 'All interventions deleted successfully' });
}));

// Delete all reports
router.delete('/reports', asyncErrorHandler(async (req, res) => {
    await Report.deleteMany({});
    res.status(200).json({ message: 'All reports deleted successfully' });
}));

// Delete all notifications
router.delete('/notifications', asyncErrorHandler(async (req, res) => {
    await Notification.deleteMany({});
    res.status(200).json({ message: 'All notifications deleted successfully' });
}));

// Delete all comments
router.delete('/comments', asyncErrorHandler(async (req, res) => {
    await Comment.deleteMany({});
    res.status(200).json({ message: 'All comments deleted successfully' });
}));

// Delete all admin post comments
router.delete('/adminpostcomments', asyncErrorHandler(async (req, res) => {
    await AdminPostComment.deleteMany({});
    res.status(200).json({ message: 'All admin post comments deleted successfully' });
}));

// Delete all accounts (except superadmin)
router.delete('/accounts', asyncErrorHandler(async (req, res) => {
    await Account.deleteMany({ role: { $ne: 'superadmin' } });
    res.status(200).json({ message: 'All accounts (except superadmin) deleted successfully' });
}));

// Delete everything (except superadmin accounts)
router.delete('/all', asyncErrorHandler(async (req, res) => {
    await Promise.all([
        AdminPost.deleteMany({}),
        Alert.deleteMany({}),
        Intervention.deleteMany({}),
        Report.deleteMany({}),
        Notification.deleteMany({}),
        Comment.deleteMany({}),
        AdminPostComment.deleteMany({}),
        Account.deleteMany({ role: { $ne: 'superadmin' } })
    ]);
    res.status(200).json({ message: 'All data cleared successfully (except superadmin accounts)' });
}));

module.exports = router; 