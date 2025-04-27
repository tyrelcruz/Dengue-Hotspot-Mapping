const upload = require("./upload");

const uploadImages = upload.array("images", 4);

const uploadImagesToPost = (req, res, next) => {
  uploadImages(req, res, (err) => {
    if (err) {
      return res.status(400).json({ error: err.message });
    }
    next();
  });
};

module.exports = uploadImagesToPost;
