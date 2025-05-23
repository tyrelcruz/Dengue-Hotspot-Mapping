const Comment = require("../models/Comments");

const addComment = async (req, res) => {
  const { reportId } = req.params;
  const { content } = req.body;
  const userId = req.user.userId;

  if (!content) return res.status(400).json({ error: "Content required" });

  const comment = await Comment.create({
    content,
    report: reportId,
    user: userId,
  });

  res.status(201).json(comment);
};

const getComments = async (req, res) => {
  const { reportId } = req.params;
  const comments = await Comment.find({ report: reportId })
    .populate("user", "username")
    .sort({ createdAt: -1 });
  res.json(comments);
};

module.exports = {
  addComment,
  getComments,
}; 