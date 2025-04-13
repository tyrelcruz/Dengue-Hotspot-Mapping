const multer = require('multer');
const path = require('path');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/');
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  }
});


const fileFilter = (req, file, cb) => {
  // ? Maybe account for how iPhones would store images in x file format
  const allowedTypes = /jpeg|jpg|png/;
  const ext = path.extname(file.originalname).toLowerCase();

  if(allowedTypes.test(ext)) {
    cb(null, true);
  } else {
    cb(new Error('Only .png and .jpg/.jpeg formats are allowed!'), false);
  }
};

const upload = multer({
  storage,
  limits: { 
    fileSize: 5000000   // 5 MB limit, might change
  },
  fileFilter
});

module.exports = upload