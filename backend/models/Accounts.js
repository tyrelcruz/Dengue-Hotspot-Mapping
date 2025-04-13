const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const Schema = mongoose.Schema

const accountSchema = new Schema({
  // ? Should we use _id instead of account_id?
  // account_id: {
  //   type: String,
  //   required: true,
  //   unique: true
  // },
  username: {
    type: String,
    required: [true, 'Please provide a username']
  },
  email: {
    type: String,
    lowercase: true,
    required: [true, 'Please provide an email address'],
    match: [
      /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/,
      "Please provide a valid email",
    ],
    unique: true
  },
  password: {
    type: String,
    required: [true, 'Please provide a password'],
    minLength: 8
  },
  role: {
    type: String,
    required: true,
    enum: ['admin', 'user'],
    default: 'user',
  },
});

accountSchema.pre('save', async function (next) {
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

accountSchema.methods.comparePassword = async function (candidatePassword) {
  const isMatch = await bcrypt.compare(candidatePassword, this.password);
  return isMatch;
}

module.exports = mongoose.model('Account', accountSchema);