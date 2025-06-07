const Comment = require("../models/Comments");
const Report = require("../models/Reports");
const AdminPost = require("../models/AdminPosts");
const mongoose = require("mongoose");

const addComment = async (req, res) => {
  const { postId } = req.params;
  const { content } = req.body;
  const userId = req.user.userId;

  if (!content) return res.status(400).json({ error: "Content required" });

  // Validate ObjectId format
  if (!mongoose.Types.ObjectId.isValid(postId)) {
    return res.status(400).json({ error: "Invalid post ID format" });
  }

  // Check if the post exists in either Reports or AdminPosts
  const report = await Report.findById(postId);
  const adminPost = await AdminPost.findById(postId);

  if (!report && !adminPost) {
    return res.status(404).json({ error: "Post not found" });
  }

  const comment = await Comment.create({
    content,
    user: userId,
    ...(report ? { report: postId } : { adminPost: postId })
  });

  await comment.populate("user", "username");
  res.status(201).json(comment);
};

const getComments = async (req, res) => {
  const { postId } = req.params;
  
  // Validate ObjectId format
  if (!mongoose.Types.ObjectId.isValid(postId)) {
    return res.status(400).json({ error: "Invalid post ID format" });
  }

  // Query comments for both report and admin post
  const comments = await Comment.find({
    $or: [
      { report: postId },
      { adminPost: postId }
    ]
  })
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

  // Validate ObjectId format
  if (!mongoose.Types.ObjectId.isValid(commentId)) {
    return res.status(400).json({ error: "Invalid comment ID format" });
  }

  const comment = await Comment.findById(commentId);
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

  // Validate ObjectId format
  if (!mongoose.Types.ObjectId.isValid(commentId)) {
    return res.status(400).json({ error: "Invalid comment ID format" });
  }

  const comment = await Comment.findById(commentId);
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

  // Validate ObjectId format
  if (!mongoose.Types.ObjectId.isValid(commentId)) {
    return res.status(400).json({ error: "Invalid comment ID format" });
  }

  const comment = await Comment.findById(commentId);
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

  // Validate ObjectId format
  if (!mongoose.Types.ObjectId.isValid(commentId)) {
    return res.status(400).json({ error: "Invalid comment ID format" });
  }

  const comment = await Comment.findById(commentId);
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