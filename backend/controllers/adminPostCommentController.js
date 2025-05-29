const AdminPostComment = require("../models/AdminPostComments");
const AdminPost = require("../models/AdminPosts");

const addComment = async (req, res) => {
  const { postId } = req.params;
  const { content } = req.body;
  const userId = req.user.userId;

  if (!content) return res.status(400).json({ error: "Content required" });

  // Check if the admin post exists
  const adminPost = await AdminPost.findById(postId);
  if (!adminPost) {
    return res.status(404).json({ error: "Admin post not found" });
  }

  const comment = await AdminPostComment.create({
    content,
    adminPost: postId,
    user: userId,
  });

  await comment.populate("user", "username");
  res.status(201).json(comment);
};

const getComments = async (req, res) => {
  const { postId } = req.params;
  const comments = await AdminPostComment.find({ adminPost: postId })
    .populate("user", "username")
    .populate("upvotes", "_id")
    .populate("downvotes", "_id")
    .sort({ createdAt: -1 });
  res.json(comments);
};

// Upvote a comment
const upvoteComment = async (req, res) => {
  const { commentId } = req.params;
  const userId = req.user.userId;

  const comment = await AdminPostComment.findById(commentId);
  if (!comment) {
    return res.status(404).json({ error: "Comment not found" });
  }

  // Remove user from downvotes if they had downvoted
  comment.downvotes = comment.downvotes.filter(
    (vote) => vote.toString() !== userId
  );

  // Add user to upvotes if they haven't upvoted
  if (!comment.upvotes.includes(userId)) {
    comment.upvotes.push(userId);
  }

  await comment.save();
  res.status(200).json(comment);
};

// Downvote a comment
const downvoteComment = async (req, res) => {
  const { commentId } = req.params;
  const userId = req.user.userId;

  const comment = await AdminPostComment.findById(commentId);
  if (!comment) {
    return res.status(404).json({ error: "Comment not found" });
  }

  // Remove user from upvotes if they had upvoted
  comment.upvotes = comment.upvotes.filter(
    (vote) => vote.toString() !== userId
  );

  // Add user to downvotes if they haven't downvoted
  if (!comment.downvotes.includes(userId)) {
    comment.downvotes.push(userId);
  }

  await comment.save();
  res.status(200).json(comment);
};

// Remove upvote from a comment
const removeUpvote = async (req, res) => {
  const { commentId } = req.params;
  const userId = req.user.userId;

  const comment = await AdminPostComment.findById(commentId);
  if (!comment) {
    return res.status(404).json({ error: "Comment not found" });
  }

  // Remove user from upvotes
  comment.upvotes = comment.upvotes.filter(
    (vote) => vote.toString() !== userId
  );
  await comment.save();

  res.status(200).json(comment);
};

// Remove downvote from a comment
const removeDownvote = async (req, res) => {
  const { commentId } = req.params;
  const userId = req.user.userId;

  const comment = await AdminPostComment.findById(commentId);
  if (!comment) {
    return res.status(404).json({ error: "Comment not found" });
  }

  // Remove user from downvotes
  comment.downvotes = comment.downvotes.filter(
    (vote) => vote.toString() !== userId
  );
  await comment.save();

  res.status(200).json(comment);
};

module.exports = {
  addComment,
  getComments,
  upvoteComment,
  downvoteComment,
  removeUpvote,
  removeDownvote,
}; 