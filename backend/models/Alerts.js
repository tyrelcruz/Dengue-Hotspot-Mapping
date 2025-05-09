const mongoose = require('mongoose');

const alertSchema = new mongoose.Schema({
  messages: [{
    type: String,
    required: [true, 'Alert message is required'],
    trim: true
  }],
  severity: {
    type: String,
    enum: ['HIGH', 'MODERATE', 'LOW'],
    default: 'MODERATE'
  },
  affectedAreas: [{
    name: String,
    coordinates: {
      latitude: Number,
      longitude: Number
    }
  }],
  barangays: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Barangay',
    required: true
  }],
  timestamp: {
    type: Date,
    default: Date.now
  },
  status: {
    type: String,
    enum: ['ACTIVE', 'RESOLVED', 'ARCHIVED'],
    default: 'ACTIVE'
  }
});

// Remove the message field if it exists
alertSchema.pre('save', function(next) {
  if (this.isModified('message')) {
    delete this.message;
  }
  next();
});

module.exports = mongoose.model('Alert', alertSchema); 