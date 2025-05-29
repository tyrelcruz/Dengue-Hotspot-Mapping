const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const adminPostCommentSchema = new Schema(
  {
    content: {
      type: String,
      required: [true, "Comment content is required"],
      trim: true,
    },
    adminPost: {
      type: Schema.Types.ObjectId,
      ref: "AdminPost",
      required: [true, "Admin Post ID is required"],
    },
    user: {
      type: Schema.Types.ObjectId,
      ref: "Account",
      required: [true, "User ID is required"],
    },
    upvotes: [{
      type: Schema.Types.ObjectId,
      ref: "Account"
    }],
    downvotes: [{
      type: Schema.Types.ObjectId,
      ref: "Account"
    }]
  },
  { timestamps: true }
);

// Create indexes for better query performance
adminPostCommentSchema.index({ adminPost: 1, createdAt: -1 });
adminPostCommentSchema.index({ user: 1 });

module.exports = mongoose.model("AdminPostComment", adminPostCommentSchema); 