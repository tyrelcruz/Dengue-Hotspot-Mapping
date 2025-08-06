const mongoose = require("mongoose");
const Schema = mongoose.Schema;

const recommendationTemplateSchema = new Schema({
  code: {
    type: String,
    required: true,
    unique: true
  },
  type: {
    type: String,
    enum: ['pattern'],
    required: true
  },
  conditions: {
    pattern: {
      type: String,
      enum: ["spike", "gradual_rise", "decline", "stability"],
      required: true
    }
  },
  baseRecommendation: {
    type: String,
    required: true
  },
  severity: {
    type: String,
    enum: ['low', 'medium', 'high'],
    required: true
  }
});

module.exports = mongoose.model("RecommendationTemplate", recommendationTemplateSchema); 