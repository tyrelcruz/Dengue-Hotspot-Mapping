const axios = require("axios");
const Report = require("../models/Reports");
const asyncErrorHandler = require("../middleware/asyncErrorHandler");
const { detectClusters } = require("../services/clusterService");
const Barangay = require("../models/Barangays");
const weatherAnalysis = require("../services/weatherRiskService");
const Alert = require('../models/Alerts');

const patternRecognitionAnalysis = asyncErrorHandler(async (req, res) => {
  try {
    const pythonApiUrl = "http://localhost:8000/api/v1/pattern-recognition";
    const response = await axios.get(pythonApiUrl);
    const analysisResults = response.data;

    console.log("Received alerts from FastAPI:", analysisResults);

    res.status(200).json({
      success: true,
      data: analysisResults,
    });
  } catch (error) {
    console.error("Error calling FastAPI:", error.message);
    res.status(500).json({
      success: false,
      message: "Failed to fetch pattern recognition analysis.",
    });
  }
});

const retrievePatternRecognitionResults = asyncErrorHandler(
  async (req, res) => {
    const { barangay_name, pattern, risk_level, topCheck } = req.query;

    try {
      const query = {};

      if (barangay_name) {
        query.name = { $regex: new RegExp(barangay_name, "i") };
      }

      if (pattern) {
        query.triggered_pattern = pattern;
      }

      if (risk_level) {
        query.risk_level = risk_level;
      }

      let results;
      if (topCheck) {
        results = await Barangay.find(query).limit(parseInt(topCheck));
      } else {
        results = await Barangay.find(query);
      }

      res.status(200).json({
        success: true,
        count: results.length,
        data: results,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: `Server Error: ${error}`,
      });
    }
  }
);

const detectReportedClusters = asyncErrorHandler(async (req, res) => {
  const clusters = await detectClusters();

  res.status(200).json({
    message:
      clusters.length > 0
        ? "Clusters detected:"
        : "No significant clusters found",
    clusters,
  });
});

const submitCsvFile = asyncErrorHandler(async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: "No file uploaded" });
    }

    const formData = new FormData();
    formData.append("file", fs.createReadStream(req.file.path), {
      filename: req.file.filename,
    });

    const response = await axios.post(
      "http://localhost:8000/api/v1/upload-csv",
      formData,
      {
        headers: {
          ...formData.getHeaders(),
        },
      }
    );

    fs.unlinkSync(req.file.path);

    return res.status(200).json({
      message: "CSV uploaded successfully!",
      data: response.data,
    });
  } catch (error) {
    console.error("Error uploading file:", error);
    return res.status(500).json({
      error: "Failed to process file upload.",
      details: error.message,
    });
  }
});

const getLocationRiskLevelByWeather = asyncErrorHandler(async (req, res) => {
  const { selectedLatitude, selectedLongitude } = req.body;
  // Throw to Google Maps Weather API, then process here in Node, send the updated data to both the DB and front end

  try {
    const weatherDataResponse = await axios.get(
      "https://weather.googleapis.com/v1/currentConditions:lookup",
      {
        params: {
          key: process.env.GOOGLE_MAPS_WEATHER_API_KEY,
          "location.latitude": selectedLatitude,
          "location.longitude": selectedLongitude,
        },
      }
    );

    const weatherData = weatherDataResponse.data;

    const extractedData = {
      temperature: weatherData.temperature.degrees,
      relativeHumidity: weatherData.relativeHumidity,
      rainfall: weatherData.precipitation.qpf.quantity,
    };

    const result = await weatherAnalysis(
      extractedData.rainfall,
      extractedData.temperature,
      extractedData.relativeHumidity
    );

    let recommendation;

    if (result === "HIGH") {
      recommendation =
        "Stay alert! Based on the analyzed weather data, your area is an optimal breeding ground for mosquitoes!";
    } else if (result === "MODERATE") {
      recommendation =
        "Tread with caution! Based on the analyzed weather data, your area shows some promises for dengue to thrive.";
    } else {
      recommendation =
        "Based on the analyzed data, your area is safe from dengue as of the moment.";
    }
    res.status(200).json({
      status: "success",
      data: {
        extractedData,
        recommendation,
      },
    });
  } catch (error) {
    console.error(
      "Error fetching weather data: ",
      error.response?.data || error.message
    );
    return res.status(500).json({
      status: "error",
      message: "Failed to fetch weather data",
    });
  }
});

const sendDengueAlert = asyncErrorHandler(async (req, res) => {
  const { barangayIds, message, severity, affectedAreas } = req.body;

  try {
    // Validate input
    if (!barangayIds || !message || !severity) {
      return res.status(400).json({
        success: false,
        message: "Missing required fields: barangayIds, message, and severity are required"
      });
    }

    // Find the specified barangays
    const barangays = await Barangay.find({
      _id: { $in: barangayIds }
    });

    if (barangays.length === 0) {
      return res.status(404).json({
        success: false,
        message: "No barangays found with the provided IDs"
      });
    }

    // Create and save alert record
    const alert = await Alert.create({
      message,
      severity,
      affectedAreas,
      barangays: barangayIds,
      timestamp: new Date(),
      status: 'ACTIVE'
    });

    // TODO: Implement notification system
    // For now, we'll just log the alert
    console.log(`Alert created: ${alert._id} for barangays: ${barangays.map(b => b.name).join(', ')}`);

    res.status(200).json({
      success: true,
      message: "Dengue alert sent successfully",
      data: {
        alert,
        affectedBarangays: barangays.map(b => b.name)
      }
    });
  } catch (error) {
    console.error("Error sending dengue alert:", error);
    res.status(500).json({
      success: false,
      message: "Failed to send dengue alert",
      error: error.message
    });
  }
});

const getAllAlerts = asyncErrorHandler(async (req, res) => {
  const alerts = await Alert.find()
    .populate('barangays', 'name')
    .sort({ timestamp: -1 });

  res.status(200).json({
    success: true,
    count: alerts.length,
    data: alerts
  });
});

const getAlertsByBarangay = asyncErrorHandler(async (req, res) => {
  const { barangayId } = req.params;
  
  const alerts = await Alert.find({ barangays: barangayId })
    .populate('barangays', 'name')
    .sort({ timestamp: -1 });

  res.status(200).json({
    success: true,
    count: alerts.length,
    data: alerts
  });
});

const getAlertsByBarangayName = asyncErrorHandler(async (req, res) => {
  const { name } = req.query;
  
  if (!name) {
    return res.status(400).json({
      success: false,
      message: "Barangay name is required"
    });
  }

  const barangay = await Barangay.findOne({ 
    name: { $regex: new RegExp(name, 'i') } 
  });

  if (!barangay) {
    return res.status(404).json({
      success: false,
      message: "Barangay not found"
    });
  }

  const alerts = await Alert.find({ barangays: barangay._id })
    .populate('barangays', 'name')
    .sort({ timestamp: -1 });

  res.status(200).json({
    success: true,
    count: alerts.length,
    data: alerts
  });
});

module.exports = {
  patternRecognitionAnalysis,
  detectReportedClusters,
  submitCsvFile,
  retrievePatternRecognitionResults,
  getLocationRiskLevelByWeather,
  sendDengueAlert,
  getAllAlerts,
  getAlertsByBarangay,
  getAlertsByBarangayName,
};
