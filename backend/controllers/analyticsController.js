const axios = require("axios");
const fs = require("fs");
const path = require("path");
const FormData = require("form-data");
const asyncErrorHandler = require("../middleware/asyncErrorHandler");
const Barangay = require("../models/Barangays");
const weatherAnalysis = require("../services/weatherRiskService");
const Alert = require("../models/Alerts");
const Intervention = require("../models/Interventions");
const AdminPost = require("../models/AdminPosts");
const { detectClusters } = require("../services/clusterService");

const patternRecognitionAnalysis = asyncErrorHandler(async (req, res) => {
  try {
    const pythonApiUrl = "http://localhost:8000/api/v1/pattern-recognition";
    const response = await axios.get(pythonApiUrl);
    const analysisResults = response.data;

    console.log("Received alerts from FastAPI:", analysisResults);

    // Update each barangay with its analysis results
    for (const result of analysisResults) {
      try {
        // Normalize the data structure
        const barangayData = {
          name: result.name,
          risk_level: result.risk_level || result.riskLevel || "Low",
          status_and_recommendation: {
            pattern_based: {
              status:
                result.status_and_recommendation?.pattern_based?.status ||
                result.triggered_pattern ||
                null,
              alert:
                result.status_and_recommendation?.pattern_based?.alert ||
                result.alert ||
                result.message ||
                null,
              recommendation:
                result.status_and_recommendation?.pattern_based
                  ?.recommendation || "No specific recommendation available.",
            },
            report_based: result.status_and_recommendation?.report_based || {
              count: 0,
              status: "",
              alert: "None",
              recommendation: "",
            },
            death_priority: result.status_and_recommendation
              ?.death_priority || {
              status: "",
              alert: "None",
              recommendation: "",
            },
          },
          last_analysis_time: new Date().toISOString(),
        };

        console.log("Updating barangay with data:", barangayData);

        await Barangay.findOneAndUpdate(
          { name: barangayData.name },
          barangayData,
          { upsert: true, new: true }
        );
      } catch (error) {
        console.error(`Error updating barangay ${result.name}:`, error);
      }
    }

    // Get all updated barangays
    const updatedBarangays = await Barangay.find({});
    console.log("Updated barangays:", updatedBarangays);

    res.status(200).json({
      success: true,
      data: updatedBarangays,
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
    if (!req.files) {
      return res.status(400).json({ error: "No file uploaded " });
    }

    const fileKeys = Object.keys(req.files);
    if (fileKeys.length > 1) {
      return res
        .status(400)
        .json({ error: "Only one file can be uploaded at a time." });
    }

    if (!req.files.file) {
      return res
        .status(400)
        .json({ error: "File must be uploaded with field name 'file'" });
    }

    if (Array.isArray(req.files.file)) {
      return res.status(400).json({
        error:
          "Only one file can be uploaded. Multiple files detected with field name 'file'",
      });
    }

    const uploadedFile = req.files.file;

    if (!uploadedFile.name.toLowerCase().endsWith(".csv")) {
      return res.status(400).json({ error: "Only CSV files are allowed." });
    }

    const uploadDir = path.join(__dirname, "..", "uploads");
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }

    const tempFilePath = path.join(
      uploadDir,
      `${Date.now()}_${uploadedFile.name}`
    );

    await uploadedFile.mv(tempFilePath);

    const formData = new FormData();
    formData.append("file", fs.createReadStream(tempFilePath), {
      filename: uploadedFile.name,
    });

    const contentLength = await new Promise((resolve, reject) => {
      formData.getLength((err, length) => {
        if (err) reject(err);
        else resolve(length);
      });
    });

    const response = await axios.post(
      "http://localhost:8000/api/v1/upload-csv",
      formData,
      {
        headers: {
          ...formData.getHeaders(),
          "Content-Length": contentLength,
        },
      }
    );

    fs.unlink(tempFilePath, (unlinkErr) => {
      if (unlinkErr) {
        console.error("Failed to delete uploaded file:", unlinkErr);
      }
    });

    return res.status(200).json({
      message: "CSV uploaded successfully!",
      data: response.data,
    });
  } catch (error) {
    console.error("Error uploading file:", error);

    if (req.files && req.files.file && req.files.file.tempFilePath) {
      try {
        fs.unlinkSync(req.files.file.tempFilePath);
      } catch (cleanupError) {
        console.error("Error cleaning up temp file:", cleanupError);
      }
    }

    return res.status(500).json({
      error: "Failed to process file upload.",
      details: error.message,
    });
  }
});

const getLocationRiskLevelByWeather = asyncErrorHandler(async (req, res) => {
  const { selectedLatitude, selectedLongitude } = req.body;

  if (
    selectedLatitude === undefined ||
    selectedLongitude === undefined ||
    selectedLatitude === "" ||
    selectedLongitude === ""
  ) {
    return res.status(400).json({
      status: "error",
      message: "Both latitude and longitude are required.",
    });
  }

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
        "Risk Level: HIGH.\nStay alert! Based on the analyzed weather data, your area is an optimal breeding ground for mosquitoes!";
    } else if (result === "MODERATE") {
      recommendation =
        "Risk Level: MODERATE.\nTread with caution! Based on the analyzed weather data, your area shows some potential for dengue to thrive.";
    } else {
      recommendation =
        "Risk Level: LOW.\nBased on the analyzed data, your area is safe from dengue as of the moment.";
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
        message:
          "Missing required fields: barangayIds, message, and severity are required",
      });
    }

    // Find the specified barangays
    const barangays = await Barangay.find({
      _id: { $in: barangayIds },
    });

    if (barangays.length === 0) {
      return res.status(404).json({
        success: false,
        message: "No barangays found with the provided IDs",
      });
    }

    // Create and save alert record
    const alert = await Alert.create({
      message,
      severity,
      affectedAreas,
      barangays: barangayIds,
      timestamp: new Date(),
      status: "ACTIVE",
    });

    // TODO: Implement notification system
    // For now, we'll just log the alert
    console.log(
      `Alert created: ${alert._id} for barangays: ${barangays
        .map((b) => b.name)
        .join(", ")}`
    );

    res.status(200).json({
      success: true,
      message: "Dengue alert sent successfully",
      data: {
        alert,
        affectedBarangays: barangays.map((b) => b.name),
      },
    });
  } catch (error) {
    console.error("Error sending dengue alert:", error);
    res.status(500).json({
      success: false,
      message: "Failed to send dengue alert",
      error: error.message,
    });
  }
});

const getAllAlerts = asyncErrorHandler(async (req, res) => {
  const alerts = await Alert.find()
    .populate("barangays", "name")
    .sort({ timestamp: -1 });

  res.status(200).json({
    success: true,
    count: alerts.length,
    data: alerts,
  });
});

const getAlertsByBarangay = asyncErrorHandler(async (req, res) => {
  const { barangayId } = req.params;

  const alerts = await Alert.find({ barangays: barangayId })
    .populate("barangays", "name")
    .sort({ timestamp: -1 });

  res.status(200).json({
    success: true,
    count: alerts.length,
    data: alerts,
  });
});

const getAlertsByBarangayName = asyncErrorHandler(async (req, res) => {
  const { name } = req.query;

  if (!name) {
    return res.status(400).json({
      success: false,
      message: "Barangay name is required",
    });
  }

  const barangay = await Barangay.findOne({
    name: { $regex: new RegExp(name, "i") },
  });

  if (!barangay) {
    return res.status(404).json({
      success: false,
      message: "Barangay not found",
    });
  }

  const alerts = await Alert.find({ barangays: barangay._id })
    .populate("barangays", "name")
    .sort({ timestamp: -1 });

  res.status(200).json({
    success: true,
    count: alerts.length,
    data: alerts,
  });
});

const retrieveTrendsAndPatterns = asyncErrorHandler(async (req, res) => {
  const { barangay_name, number_of_weeks } = req.body;

  try {
    const response = await axios.post(
      "http://localhost:8000/api/v1/weekly-trends",
      {
        barangay_name,
        number_of_weeks,
      }
    );

    return res.status(200).json({
      message: "Weekly trends retrieved successfully!",
      data: response.data,
    });
  } catch (error) {
    console.error("Error retrieving weekly trends:", error);
    return res.status(500).json({
      error: "Failed to retrieve weekly trends",
      details: error.message,
    });
  }
});

const analyzeInterventionEffectivity = asyncErrorHandler(async (req, res) => {
  const { intervention_id } = req.body;

  const intervention = await Intervention.findById(intervention_id).populate(
    "adminId",
    "name"
  ); // Populate admin details

  if (!intervention) {
    return res.status(404).json({
      message: "Intervention not found",
    });
  }

  const { date, barangay } = intervention;

  const interventionDate = new Date(date);
  const currentDate = new Date();

  const daysSinceIntervention = Math.floor(
    (currentDate - interventionDate) / (1000 * 60 * 60 * 24)
  );

  if (daysSinceIntervention < 30) {
    const daysToWait = 30 - daysSinceIntervention;
    return res.status(422).json({
      message: `Intervention is too recent for analysis. Please wait ${daysToWait} more day${
        daysToWait === 1 ? "" : "s"
      } before analyzing.`,
      daysToWait,
    });
  }

  const formattedInterventionDate = interventionDate
    .toISOString()
    .split("T")[0];

  const requestData = {
    barangay,
    intervention_date: formattedInterventionDate,
  };

  try {
    const response = await axios.post(
      "http://localhost:8000/api/v1/analyze-intervention-effectivity",
      requestData
    );

    return res.status(200).json({
      message: "Intervention analysis completed successfully",
      intervention: {
        id: intervention._id,
        barangay: intervention.barangay,
        date: intervention.date,
        type: intervention.interventionType,
        personnel: intervention.personnel,
        status: intervention.status,
        address: intervention.address,
        admin_name: intervention.adminId.name,
      },
      analysis: {
        barangay: response.data.barangay,
        intervention_date: response.data.intervention_date,
        case_counts: {
          before: response.data.before_intervention,
          after: response.data.after_intervention,
        },
      },
    });
  } catch (error) {
    return res.status(500).json({
      message: "Error sending intervention data to FastAPI",
      error: error.message,
    });
  }
});

const deleteAllAlerts = async (req, res) => {
  try {
    await Alert.deleteMany({});
    res.json({ message: "All alerts have been deleted successfully" });
  } catch (error) {
    console.error("Error deleting alerts:", error);
    res.status(500).json({ error: "Failed to delete alerts" });
  }
};

const deleteAllAdminPosts = async (req, res) => {
  try {
    await AdminPost.deleteMany({});
    res.json({ message: "All admin posts have been deleted successfully" });
  } catch (error) {
    console.error("Error deleting admin posts:", error);
    res.status(500).json({ error: "Failed to delete admin posts" });
  }
};

const getPriorityByCaseDeath = asyncErrorHandler(async (req, res) => {
  const sortBy = req.query.sortBy || "case_count";

  const validSortOptions = ["case_count", "recent_date", "alphabetical"];
  if (!validSortOptions.includes(sortBy)) {
    return res.status(400).json({
      error: `Invalid sortBy option requested.`,
    });
  }

  const fastApiUrl = "http://localhost:8000/api/v1/death-priority";
  const { data } = await axios.get(fastApiUrl);

  res.status(200).json({
    message: `Sorted by: ${sortBy}`,
    data,
  });
});

module.exports = {
  patternRecognitionAnalysis,
  detectReportedClusters,
  submitCsvFile,
  retrievePatternRecognitionResults,
  getLocationRiskLevelByWeather,
  retrieveTrendsAndPatterns,
  analyzeInterventionEffectivity,
  getAllAlerts,
  getAlertsByBarangay,
  getAlertsByBarangayName,
  sendDengueAlert,
  deleteAllAlerts,
  deleteAllAdminPosts,
  getPriorityByCaseDeath,
};
