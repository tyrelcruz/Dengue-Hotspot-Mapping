const express = require("express");
const router = express.Router();
const { addComment, getComments } = require("../controllers/commentController");
const auth = require("../middleware/authentication");

router.post("/:reportId", auth, addComment);
router.get("/:reportId", getComments);

module.exports = router; 