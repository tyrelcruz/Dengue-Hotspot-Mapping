const express = require("express");
const router = express.Router();
const { MongoClient } = require("mongodb");

require("dotenv").config();

const { getAllBarangays } = require("../controllers/barangayController");

router.get("/get-all-barangays", getAllBarangays);

module.exports = router;
