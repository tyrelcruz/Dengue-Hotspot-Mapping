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
    },
    adminPost: {
      type: Schema.Types.ObjectId,
      ref: "AdminPost",
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

// Add validation to ensure either report or adminPost is provided
commentSchema.pre('save', function(next) {
  if (!this.report && !this.adminPost) {
    next(new Error('Either report or adminPost must be provided'));
  }
  if (this.report && this.adminPost) {
    next(new Error('Cannot provide both report and adminPost'));
  }
  next();
});

// Create indexes for better query performance
commentSchema.index({ report: 1, createdAt: -1 });
commentSchema.index({ adminPost: 1, createdAt: -1 });
commentSchema.index({ user: 1 });

module.exports = mongoose.model("Comment", commentSchema);
