const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const Schema = mongoose.Schema;

const accountSchema = new Schema({
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
    enum: ["active", "disabled", "banned", "deleted"],
    default: "active",
    validate: {
      validator: function(status) {
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
      message: props => {
        if (props.value === "banned") {
          return "Admin accounts cannot be banned";
        }
        return "User accounts cannot be disabled";
      }
    }
  },
  verified: {
    type: Boolean,
    default: false,
  }
}, {
  timestamps: true  // This will add createdAt and updatedAt fields
});

// Remove all existing indexes
accountSchema.indexes().forEach(index => {
  accountSchema.index(index[0], { unique: false });
});

// Create the new compound index
accountSchema.index(
  { email: 1, status: 1 },
  { 
    unique: true,
    partialFilterExpression: { status: { $ne: "deleted" } }
  }
);

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

module.exports = mongoose.model("Account", accountSchema);
