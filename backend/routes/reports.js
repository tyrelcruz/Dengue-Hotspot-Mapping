const express = require('express');
const upload = require('../middleware/upload');
const {
  getAllReports,
  getReport,
  createReport,
  deleteReport,
} = require('../controllers/reportController');
// const Report = require('../models/Reports');


const router = express.Router();

// * Get all posts
router.get('/', getAllReports);

// GET a specific post
router.get('/:id', getReport);

// POST a new post
router.post('/', (req, res, next) => {
  upload.array('images', 5)(req, res, (err) => {
    if (err) {
      return res.status(400).json({ error: err.message });
    }
    next();
  });
}, createReport);


// * Should be for the admin side.
router.delete('/:id', deleteReport);

// * Could be possibly used for updating the status of a report
router.patch('/:id', (req, res) => {
  res.json({message: 'UPDATE a post'});
});



module.exports = router;