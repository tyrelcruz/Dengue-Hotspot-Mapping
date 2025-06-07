const axios = require("axios");
const fs = require("fs");
const path = require("path");
const FormData = require("form-data");
const asyncErrorHandler = require("../middleware/asyncErrorHandler");
const Barangay = require("../models/Barangays");
const weatherAnalysis = require("../services/weatherRiskService");
const Intervention = require("../models/Interventions");
const { analyzeHotspots } = require("../services/hotspotAnalysisService");
const {
  analyzeCrowdsourcedReports,
} = require("../services/reportAnalysisService");

console.log(process.env.PYTHON_URL);
// Function to validate CSV content
const validateCsvContent = (filePath) => {
  return new Promise((resolve, reject) => {
    const fileContent = fs.readFileSync(filePath, "utf-8");
    const lines = fileContent.split("\n").filter((line) => line.trim());

    if (lines.length < 2) {
      reject(
        new Error(
          "CSV file must contain at least a header row and one data row"
        )
      );
      return;
    }

    // Check header
    const headers = lines[0].split(",").map((h) => h.trim());
    const requiredHeaders = [
      "DAdmit",
      "Barangay",
      "Case Count",
      "Deaths",
      "Recoveries",
    ];
    const missingHeaders = requiredHeaders.filter((h) => !headers.includes(h));

    if (missingHeaders.length > 0) {
      reject(
        new Error(`Missing required columns: ${missingHeaders.join(", ")}`)
      );
      return;
    }

    // Validate data rows
    const errors = [];
    for (let i = 1; i < lines.length; i++) {
      const values = lines[i].split(",").map((v) => v.trim());

      // Check if we have all required values
      if (values.length !== headers.length) {
        errors.push(`Row ${i}: Invalid number of columns`);
        continue;
      }

      // Validate date format (YYYY-MM-DD)
      const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
      if (!dateRegex.test(values[0])) {
        errors.push(
          `Row ${i}: Invalid date format for DAdmit. Expected YYYY-MM-DD`
        );
      }

      // Validate numeric fields
      const numericFields = ["Case Count", "Deaths", "Recoveries"];
      numericFields.forEach((field, index) => {
        const value = values[headers.indexOf(field)];
        if (isNaN(value) || value === "") {
          errors.push(`Row ${i}: ${field} must be a number`);
        }
      });
    }

    if (errors.length > 0) {
      reject(new Error(`CSV validation failed:\n${errors.join("\n")}`));
      return;
    }

    resolve(true);
  });
};

// Controller function for allowing the admin to upload a CSV file, and that file being submitted to the Python backend for processing
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

    // Validate CSV content before proceeding
    try {
      await validateCsvContent(tempFilePath);
    } catch (validationError) {
      // Clean up the temporary file
      fs.unlinkSync(tempFilePath);
      return res.status(400).json({
        error: "CSV validation failed",
        details: validationError.message,
      });
    }

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

    // Upload CSV to Python backend
    const pythonUploadUrl = process.env.PYTHON_URL + "/api/v1/upload-csv";
    console.log("Uploading CSV to:", pythonUploadUrl);
    const uploadResponse = await axios.post(
      pythonUploadUrl,
      formData,
      {
        headers: {
          ...formData.getHeaders(),
          "Content-Length": contentLength,
        },
      }
    );

    // Clean up the temporary file
    fs.unlink(tempFilePath, (unlinkErr) => {
      if (unlinkErr) {
        console.error("Failed to delete uploaded file:", unlinkErr);
      }
    });

    return res.status(200).json({
      message: "CSV file uploaded successfully",
      upload_data: uploadResponse.data,
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

// PASSED
const retrievePatternRecognitionResults = asyncErrorHandler(
  async (req, res) => {
    const { barangay, pattern, topCheck } = req.query;

    try {
      const query = {};

      if (barangay) {
        query.name = { $regex: new RegExp(barangay, "i") };
      }

      if (pattern) {
        query["status_and_recommendation.pattern_based.status"] = pattern;
      }

      let barangays;
      if (topCheck) {
        barangays = await Barangay.find(query).limit(parseInt(topCheck));
      } else {
        barangays = await Barangay.find(query);
      }

      // Enhance barangay data with simplified results
      const enhancedResults = barangays.map((barangay) => {
        const barangayObj = barangay.toObject();

        // Create a filtered result object with only the required fields
        return {
          name: barangayObj.name,
          pattern: barangayObj.status_and_recommendation.pattern_based.status,
          alert: barangayObj.status_and_recommendation.pattern_based.alert,
          recommendation:
            barangayObj.status_and_recommendation.pattern_based.recommendation,
        };
      });

      res.status(200).json({
        success: true,
        count: enhancedResults.length,
        data: enhancedResults,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: `Server Error: ${error}`,
      });
    }
  }
);

// PASSED
const triggerDengueCaseReportAnalysis = asyncErrorHandler(async (req, res) => {
  try {
    const analyzePatternsUrl = process.env.PYTHON_URL + "/api/v1/analyze-patterns";
    console.log("Triggering pattern analysis at:", analyzePatternsUrl);
    const response = await axios.get(analyzePatternsUrl);

    return res.status(200).json({
      success: true,
      message: response.data.message,
    });
  } catch (error) {
    console.error("Error in triggerDengueCaseReportAnalysis:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to trigger dengue case report analysis",
      error: error.response?.data?.detail || error.message,
    });
  }
});

// DIDN'T CHECK CUZ WASN'T USED
const getLocationRiskLevelByWeather = asyncErrorHandler(async (req, res) => {
  const { selectedLatitude, selectedLongitude } = req.query;

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

// PASSED
const retrieveTrendsAndPatterns = asyncErrorHandler(async (req, res) => {
  const { barangay_name, number_of_weeks } = req.body;

  if (!barangay_name) {
    return res.status(400).json({
      success: false,
      error: "Barangay name is required in request body",
    });
  }

  // Validate number_of_weeks if provided
  if (number_of_weeks && (isNaN(number_of_weeks) || number_of_weeks < 1)) {
    return res.status(400).json({
      success: false,
      error: "number_of_weeks must be a positive number",
    });
  }

  try {
    const weeklyTrendsUrl = process.env.PYTHON_URL + "/api/v1/weekly-trends";
    console.log("Retrieving weekly trends from:", weeklyTrendsUrl);
    const response = await axios.post(
      weeklyTrendsUrl,
      {
        barangay_name,
        number_of_weeks: number_of_weeks
          ? parseInt(number_of_weeks)
          : undefined,
      }
    );

    return res.status(200).json({
      success: true,
      message: "Weekly trends retrieved successfully!",
      data: response.data,
    });
  } catch (error) {
    console.error("Error retrieving weekly trends:", error);

    if (error.response) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx
      return res.status(error.response.status).json({
        success: false,
        error: "Failed to retrieve weekly trends",
        details: error.response.data,
      });
    } else if (error.request) {
      // The request was made but no response was received
      return res.status(503).json({
        success: false,
        error: "Analysis service is not responding",
        details: "Could not connect to weekly trends service",
      });
    } else {
      // Something happened in setting up the request that triggered an Error
      return res.status(500).json({
        success: false,
        error: "Failed to process weekly trends request",
        details: error.message,
      });
    }
  }
});

// PASSED
const analyzeInterventionEffectivity = asyncErrorHandler(async (req, res) => {
  console.log("Analyzing intervention effectivityyyyy");
  const { intervention_id } = req.body;

  if (!intervention_id) {
    return res.status(400).json({
      success: false,
      message: "intervention_id is required in request body",
    });
  }

  const intervention = await Intervention.findById(intervention_id).populate(
    "adminId",
    "username"
  );

  if (!intervention) {
    return res.status(404).json({
      success: false,
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
      success: false,
      message: `Intervention is too recent for analysis. Please wait ${daysToWait} more day${
        daysToWait === 1 ? "" : "s"
      } before analyzing.`,
      daysToWait,
    });
  }

  const formattedInterventionDate = interventionDate
    .toISOString()
    .split("T")[0];

  try {
    const interventionEffectivityUrl = process.env.PYTHON_URL + "/api/v1/analyze-intervention-effectivity";
    console.log("Analyzing intervention effectivity at:", interventionEffectivityUrl);
    const response = await axios.post(
      interventionEffectivityUrl,
      {
        barangay,
        intervention_date: formattedInterventionDate,
      }
    );

    return res.status(200).json({
      success: true,
      message: "Intervention analysis completed successfully",
      intervention: {
        id: intervention._id,
        barangay: intervention.barangay,
        date: intervention.date,
        type: intervention.interventionType,
        personnel: intervention.personnel,
        status: intervention.status,
        address: intervention.address,
        admin_name: intervention.adminId?.username || "Unknown Admin",
        specific_location: intervention.specific_location.coordinates || "Not specified."
      },
      analysis: response.data,
    });
  } catch (error) {
    // Handle different types of errors from the FastAPI service
    if (error.response) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx
      return res.status(error.response.status).json({
        success: false,
        message: "Error analyzing intervention effectivity",
        error: error.response.data.detail || error.response.data,
      });
    } else if (error.request) {
      // The request was made but no response was received
      return res.status(503).json({
        success: false,
        message: "FastAPI service is not responding",
        error: "Could not connect to analysis service",
      });
    } else {
      // Something happened in setting up the request that triggered an Error
      return res.status(500).json({
        success: false,
        message: "Error processing intervention analysis",
        error: error.message,
      });
    }
  }
});

// HAVEN'T CHECKED YET
const getPriorityByCaseDeath = asyncErrorHandler(async (req, res) => {
  const sortBy = req.query.sortBy || "case_count";

  const validSortOptions = ["case_count", "recent_date", "alphabetical"];
  if (!validSortOptions.includes(sortBy)) {
    return res.status(400).json({
      error: `Invalid sortBy option requested.`,
    });
  }

  const fastApiUrl = process.env.PYTHON_URL + "/api/v1/death-priority";
  console.log("Getting death priority from:", fastApiUrl);
  const { data } = await axios.get(fastApiUrl);

  res.status(200).json({
    message: `Sorted by: ${sortBy}`,
    data,
  });
});

// DIDN'T CHECK CUZ WASN'T USED
const analyzeDengueHotspots = asyncErrorHandler(async (req, res) => {
  try {
    const analysisParams = {
      start_date: req.query.start_date,
      end_date: req.query.end_date,
      threshold: parseInt(req.query.threshold) || 5, // Default threshold of 5 cases
      region: req.query.region,
    };

    // Validate required parameters
    if (
      !analysisParams.start_date ||
      !analysisParams.end_date ||
      !analysisParams.region
    ) {
      return res.status(400).json({
        error: "Missing required parameters",
        message: "start_date, end_date, and region are required",
      });
    }

    const result = await analyzeHotspots(analysisParams);
    res.json(result);
  } catch (error) {
    console.error("Hotspot analysis error:", error);
    res.status(500).json({
      error: "Failed to complete hotspot analysis",
      message: error.message,
    });
  }
});

// const getBreedingSitesAnalytics = asyncErrorHandler(async (req, res) => {
//   // send a trigger to python backend to retrieve from the monthly??? count of reports per barangay and check to see if the count is greater than something something
//   // set up a 2-week basis of reports with the valid status, then tally up for each barangay that has a report, calendar-basis, not by rolling window
//   // add to barangay collection a field of the count of these reports
//   // go for a low, medium, high basis of counts for the reports, so 0 - 3, 4 - 9, 10+
//   // recommendations field in barangay
//   // subfields are: pattern_based, report_based, death_based

// });

// PASSED
const handleCrowdsourcedReportsAnalysis = asyncErrorHandler(
  async (req, res) => {
    try {
      const result = await analyzeCrowdsourcedReports();

      return res.status(200).json({
        success: true,
        message:
          result.data.totalBarangaysUpdated > 0
            ? `Successfully updated ${result.data.totalBarangaysUpdated} barangay report statuses`
            : "No barangay report statuses needed updating",
        data: result.data,
      });
    } catch (error) {
      console.error("Error in analyzeCrowdsourcedReports:", error);
      return res.status(500).json({
        success: false,
        message: "Failed to update barangay report statuses",
        error: error.message,
      });
    }
  }
);

// Check if rightly modified to be a GET request
// Might be outdated, check instead for getRecentReportsForBarangay in barangayController.js
const retrieveRecentReports = asyncErrorHandler(async (req, res) => {
  const { barangay } = req.query;

  if (!barangay) {
    return res.status(400).json({
      error: "Barangay name is required",
    });
  }

  try {
    const recentReportsUrl = process.env.PYTHON_URL + "/api/v1/recent-reports";
    console.log("Retrieving recent reports from:", recentReportsUrl);
    const response = await axios.get(
      recentReportsUrl,
      {
        params: {
          barangay: barangay,
        },
      }
    );

    return res.status(200).json({
      success: true,
      message: "Recent reports retrieved successfully",
      data: response.data,
    });
  } catch (error) {
    console.error("Error retrieving recent reports:", error);
    return res.status(500).json({
      error: "Failed to retrieve recent reports",
      details: error.response?.data || error.message,
    });
  }
});

module.exports = {
  submitCsvFile,
  retrievePatternRecognitionResults,
  getLocationRiskLevelByWeather,
  retrieveTrendsAndPatterns,
  analyzeInterventionEffectivity,
  getPriorityByCaseDeath,
  analyzeDengueHotspots,
  handleCrowdsourcedReportsAnalysis,
  triggerDengueCaseReportAnalysis,
  retrieveRecentReports,
};
