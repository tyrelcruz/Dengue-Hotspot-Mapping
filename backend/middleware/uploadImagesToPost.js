const { validateImageFile, maxFileSize } = require("./upload");

const uploadImagesToPost = (req, res, next) => {
  try {
    // Validate files if they exist
    if (req.files && req.files.length > 0) {
      // Validate each file
      req.files.forEach((file) => validateImageFile(file));

      // Validate total number of files
      if (req.files.length > 4) {
        throw new Error("Maximum of 4 images allowed");
      }
    }
    next();
  } catch (err) {
    return res.status(400).json({ error: err.message });
  }
};

module.exports = uploadImagesToPost;
