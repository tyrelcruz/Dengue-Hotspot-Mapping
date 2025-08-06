const mongoose = require("mongoose");

// Assuming the Accounts model is in 'models/Accounts.js'
const Account = require("./Accounts"); // Import Accounts model

const adminPostSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
    },
    content: {
      type: String,
      required: true,
    },
    publishDate: {
      type: Date,
      required: true,
    },
    category: {
      type: String,
      enum: ["news", "tip", "announcement"],
      required: true,
    },
    images: [{ type: String }],
    references: {
      type: String,
      default: "",
    },
    adminId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Account", // Reference to the 'Account' model where admin details are stored
      required: true,
    },
    upvotes: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: "Account"
    }],
    downvotes: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: "Account"
    }],
    status: {
      type: String,
      enum: ["active", "archived", "deleted"],
      default: "active"
    }
  },
  { timestamps: true }
);

const AdminPost = mongoose.model("AdminPost", adminPostSchema);

module.exports = AdminPost;
