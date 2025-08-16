const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const Schema = mongoose.Schema;

const accountSchema = new Schema(
  {
    username: {
      type: String,
      required: [true, "Please provide a username"],
    },
    email: {
      type: String,
      lowercase: true,
      required: [true, "Please provide an email address"],
      match: [
        /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/,
        "Please provide a valid email",
      ],
    },
    password: {
      type: String,
      required: [true, "Please provide a password"],
      minLength: 8,
    },
    authProvider: {
      type: String,
      enum: ["local", "google"],
      required: true,
      default: "local",
    },
    role: {
      type: String,
      required: true,
      enum: ["admin", "user", "superadmin"],
      default: "user",
    },
    status: {
      type: String,
      enum: [
        "pending", // Account created but awaiting activation
        "active", // Account is activated and can be used
        "disabled", // Account temporarily disabled (admin accounts)
        "banned", // Account banned (user accounts)
        "deleted", // Account soft deleted
      ],
      default: "pending",
      validate: {
        validator: function (status) {
          // If role is admin/superadmin, status can't be "banned"
          if (this.role === "admin" || this.role === "superadmin") {
            return status !== "banned";
          }
          // If role is user, status can't be "disabled"
          if (this.role === "user") {
            return status !== "disabled";
          }
          return true;
        },
        message: (props) => {
          if (props.value === "banned") {
            return "Admin accounts cannot be banned";
          }
          return "User accounts cannot be disabled";
        },
      },
    },
    deletedAt: {
      type: Date,
      default: null,
    },
    lastLoginAt: {
      type: Date,
      default: null,
    },
    loginAttempts: {
      type: Number,
      default: 0,
    },
    lockUntil: {
      type: Date,
      default: null,
    },
    profilePhotoUrl: {
      type: String,
      default: "",
    },
    bio: {
      type: String,
      default: "",
      maxLength: [500, "Bio cannot exceed 500 characters"],
      set: function(value) {
        // Ensure bio is always a string, never null or undefined
        return value == null ? "" : value;
      }
    },
  },
  {
    timestamps: true, // This will add createdAt and updatedAt fields
  }
);

// Remove all existing indexes
accountSchema.indexes().forEach((index) => {
  accountSchema.index(index[0], { unique: false });
});

// Create the new compound index
accountSchema.index(
  { email: 1, status: 1 },
  {
    unique: true,
    partialFilterExpression: { status: { $ne: "deleted" } },
  }
);

// Add index for deletedAt
accountSchema.index({ deletedAt: 1 });

// Add index for lastLoginAt
accountSchema.index({ lastLoginAt: 1 });

accountSchema.pre("save", async function (next) {
  if (this.authProvider !== "local" || !this.isModified("password")) {
    return next();
  }

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

accountSchema.methods.comparePassword = async function (candidatePassword) {
  if (this.authProvider !== "local" || !this.password) return false;

  return await bcrypt.compare(candidatePassword, this.password);
};

// Add method to check if account is locked
accountSchema.methods.isLocked = function () {
  return this.lockUntil && this.lockUntil > Date.now();
};

// Add method to increment login attempts
accountSchema.methods.incrementLoginAttempts = async function () {
  // If we have a previous lock that has expired, restart at 1
  if (this.lockUntil && this.lockUntil < Date.now()) {
    return await this.updateOne({
      $set: { loginAttempts: 1, lockUntil: null },
    });
  }
  // Otherwise increment
  const updates = { $inc: { loginAttempts: 1 } };
  // Lock the account if we've reached max attempts
  if (this.loginAttempts + 1 >= 5) {
    updates.$set = { lockUntil: Date.now() + 2 * 60 * 60 * 1000 }; // 2 hours
  }
  return await this.updateOne(updates);
};

// Add method to reset login attempts
accountSchema.methods.resetLoginAttempts = async function () {
  return await this.updateOne({
    $set: { loginAttempts: 0, lockUntil: null },
  });
};

module.exports = mongoose.model("Account", accountSchema);
