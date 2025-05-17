const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const commentSchema = new Schema(
  {
    content: {
      type: String,
      required: [true, "Comment content is required"],
      trim: true,
    },
    report: {
      type: Schema.Types.ObjectId,
      ref: "Report",
      required: [true, "Report ID is required"],
    },
    user: {
      type: Schema.Types.ObjectId,
      ref: "Account",
      required: [true, "User ID is required"],
    },
  },
  { timestamps: true }
);

// Create indexes for better query performance
commentSchema.index({ report: 1, createdAt: -1 });
commentSchema.index({ user: 1 });

module.exports = mongoose.model("Comment", commentSchema);
