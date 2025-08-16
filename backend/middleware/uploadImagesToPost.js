const path = require("path");

// Validation functions for express-fileupload
const maxFileSize = 10 * 1024 * 1024; // 10MB

const validateImageFile = (file) => {
  const allowedTypes = /jpeg|jpg|png/;
  const ext = path.extname(file.name).toLowerCase();
  
  if (!allowedTypes.test(ext)) {
    throw new Error("Only .png and .jpg/.jpeg formats are allowed!");
  }
  
  // Check file size (10MB limit)
  if (file.size > maxFileSize) {
    throw new Error("File size exceeds 10MB limit!");
  }
  
  return true;
};

const uploadImagesToPost = (req, res, next) => {
  try {
    // Validate files if they exist
    if (req.files && req.files.images) {
      const imageFiles = Array.isArray(req.files.images)
        ? req.files.images
        : [req.files.images];
      
      // Validate each file
      imageFiles.forEach((file) => validateImageFile(file));

      // Validate total number of files
      if (imageFiles.length > 4) {
        throw new Error("Maximum of 4 images allowed");
      }
    }
    next();
  } catch (err) {
    return res.status(400).json({ error: err.message });
  }
};

module.exports = uploadImagesToPost;
