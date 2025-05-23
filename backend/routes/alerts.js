const express = require('express');
const router = express.Router();
const {
  sendDengueAlert,
  getAllAlerts,
  getAlertsByBarangay,
  getAlertsByBarangayName,
  updateAlert,
  deleteAlert,
  deleteAllAlerts
} = require('../controllers/alertController');

// POST /api/v1/alerts
router.post('/', sendDengueAlert);

// GET /api/v1/alerts
router.get('/', getAllAlerts);

// GET /api/v1/alerts/barangay/:barangayId
router.get('/barangay/:barangayId', getAlertsByBarangay);

// DELETE /api/v1/alerts/all
router.delete('/all', deleteAllAlerts);

// GET /api/v1/alerts/:barangayName
router.get('/:barangayName', getAlertsByBarangayName);

// PATCH /api/v1/alerts/:alertId
router.patch('/:alertId', updateAlert);

// DELETE /api/v1/alerts/:alertId
router.delete('/:alertId', deleteAlert);

module.exports = router; 