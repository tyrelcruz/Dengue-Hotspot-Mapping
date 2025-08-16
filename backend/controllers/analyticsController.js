const fs = require("fs");
const path = require("path");
const asyncErrorHandler = require("../middleware/asyncErrorHandler");
const Barangay = require("../models/Barangays");
const weatherAnalysis = require("../services/weatherRiskService");
const Intervention = require("../models/Interventions");
const { analyzeHotspots } = require("../services/hotspotAnalysisService");
const {
  analyzeCrowdsourcedReports,
  updateBarangayStatuses,
} = require("../services/reportAnalysisService");
const {
  analyzeDengueAlerts,
} = require("../services/analytics/patternRecognition");
const { getDeathPriorityData } = require("../services/analytics/deathPriority");
const { returnWeeklyTrends } = require("../services/analytics/weeklyTrends");
const {
  returnCaseCountsForIntervention,
} = require("../services/analytics/interventionsEffectivityAnalysis");
const {
  processCsvToSummary,
} = require("../utils/analytics/processAndWriteMasterCsv");
const extractSources = require("../utils/extractSources");

const { GoogleGenAI } = require("@google/genai");

// * FUNCTIONING, UPDATE LATER
const submitCsvFile = asyncErrorHandler(async (req, res) => {
  let storedFilePath;

  try {
    // ? VALIDATION CHECK FOR FILES
    // * Checks if there are any files.
    if (!req.files) return res.status(400).json({ error: "No file uploaded" });

    // * Following checks if there is only one file uploaded.
    const fileKeys = Object.keys(req.files);
    if (fileKeys.length > 1) {
      return res
        .status(400)
        .json({ error: "Only one file can be uploaded at a time." });
    }

    if (!req.files.file) {
      return res.status(400).json({
        error: "The file must be uploaded with the field name 'file'.",
      });
    }

    if (Array.isArray(req.files.file)) {
      return res
        .status(400)
        .json({ error: "Only one file can be uploaded at a time." });
    }

    const uploadedFile = req.files.file;

    // * Checks if the uploaded file is a CSV file.
    if (!uploadedFile.name.toLowerCase().endsWith(".csv")) {
      return res.status(400).json({ error: "Only CSV files are allowed." });
    }

    // ! Dynamic upload directory based on environment, replace as necessary when deploying to Render or Vercel.
    const uploadDir =
      process.env.NODE_ENV === "production"
        ? path.join("/tmp", "uploads") // ! Check if this is how it works on Render or Vercel
        : path.join(__dirname, "..", "uploads"); // * Local

    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }

    storedFilePath = path.join(
      uploadDir,
      //`${Date.now()}_${uploadedFile.name}`
      uploadedFile.name
    );

    await uploadedFile.mv(storedFilePath);

    // Process the uploaded CSV file using the enhanced processCsvToSummary function
    try {
      // Would there be any difference from procssing an incomplete CSV file with a yearly summary file? Because, if there isn't, then what will change is the name of the directory where the file will be stored in. Uploads to data immediately, under a yearly directory, where yearly files are named 2020.csv, 2021.csv, etc.
      // validation checks, wherein if trying to upload yearly file
      const processingResult = await processCsvToSummary(
        storedFilePath,
        path.join("data", "main.csv")
      );

      if (process.env.NODE_ENV !== "production") {
        console.log("CSV processing completed successfully");
        console.log(`Rows processed: ${processingResult.rowsRead}`);
        console.log(`Valid rows: ${processingResult.validRows}`);
        console.log(
          `Records aggregated: ${processingResult.recordsAggregated}`
        );

        if (processingResult.validationErrors.length > 0) {
          console.log(
            `Validation warnings: ${processingResult.validationErrors.length} issues found`
          );
        }
      }
    } catch (processingError) {
      if (storedFilePath && fs.existsSync(storedFilePath)) {
        await fs.promises.unlinkSync(storedFilePath);
      }

      return res.status(400).json({
        error: "CSV processing failed",
        details: processingError.message,
      });
    }

    return res.status(200).json({
      message:
        "CSV file uploaded, processed, and master CSV updated successfully!",
    });
  } catch (uploadError) {
    console.error("Error uploading file: ", uploadError);

    if (storedFilePath && fs.existsSync(storedFilePath)) {
      await fs.promises.unlinkSync(storedFilePath);
    }

    return res.status(500).json({
      error: "Error in file upload process",
      ...(process.env.NODE_ENV !== "production" && { details: error.message }),
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
        query["status.pattern"] = pattern;
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
          pattern: barangayObj.status.pattern,
          recommendation: barangayObj.recommendation,
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

// TODO: Check if this is working, especially the updateBarangayStatuses function
const triggerDengueCaseReportAnalysis = asyncErrorHandler(async (req, res) => {
  try {
    console.log("Triggering dengue case report analysis...");

    // Call the analyzeDengueAlerts function
    const patternAlerts = await analyzeDengueAlerts();

    // Call the getDeathPriorityData function
    const deathAlerts = await getDeathPriorityData("data/main.csv");

    const combinedAlerts = {};

    for (const alert of patternAlerts) {
      if (alert.barangay !== null) {
        const barangayKey = alert.barangay.toLowerCase();
        combinedAlerts[barangayKey] = {
          barangay: alert.barangay,
          pattern: alert.pattern,
          recommendation: alert.recommendation,
        };
      }
    }

    for (const alert of deathAlerts) {
      if (alert.barangay !== null) {
        const barangayKey = alert.barangay.toLowerCase();
        if (combinedAlerts[barangayKey]) {
          combinedAlerts[barangayKey].deaths = alert.deaths;
        } else {
          combinedAlerts[barangayKey] = {
            barangay: alert.barangay,
            deaths: alert.deaths,
          };
        }
      }
    }

    const allAlerts = Object.values(combinedAlerts);

    // await updateBarangayStatuses(allAlerts);

    return res.status(200).json({
      success: true,
      message: "Dengue case report analysis completed successfully",
      alerts: allAlerts,
      count: allAlerts.length,
    });
  } catch (error) {
    console.error("Error in triggerDengueCaseReportAnalysis:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to trigger dengue case report analysis",
      error: error.message,
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

  const csvPath = "data/main.csv";
  const weeksToAnalyze = number_of_weeks ? parseInt(number_of_weeks) : 4;

  try {
    console.log(
      "Retrieving weekly trends for:",
      barangay_name,
      "with",
      weeksToAnalyze,
      "weeks"
    );
    const result = await returnWeeklyTrends(
      barangay_name,
      weeksToAnalyze,
      csvPath
    );

    return res.status(200).json({
      success: true,
      message: "Weekly trends retrieved successfully!",
      data: result,
    });
  } catch (error) {
    console.error("Error retrieving weekly trends:", error);

    return res.status(500).json({
      success: false,
      error: "Failed to process weekly trends request",
      details: error.message,
    });
  }
});

// PASSED
const analyzeInterventionEffectivity = asyncErrorHandler(async (req, res) => {
  console.log("Analyzing intervention effectivity...");
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
    console.log(
      `Analyzing intervention effectivity for ${barangay} on ${formattedInterventionDate}`
    );

    const csvPath = "data/main.csv";
    const analysis = await returnCaseCountsForIntervention(
      barangay,
      formattedInterventionDate,
      csvPath
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
        specific_location:
          intervention.specific_location.coordinates || "Not specified.",
      },
      analysis: analysis,
    });
  } catch (error) {
    console.error("Error analyzing intervention effectivity:", error);
    return res.status(500).json({
      success: false,
      message: "Error processing intervention analysis",
      error: error.message,
    });
  }
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

// Heatmap functionality
// database can store the number of dengue cases per barangay per week

const generateRecommendation = asyncErrorHandler(async (req, res) => {
  const { userRole, barangay } = req.body;

  let aiPrompt = "What would you recommend";
  // let aiPrompt =
  //   "What do you recommend that we do, considering the current status of the barangay?";
  let systemInstruction =
    "You are an expert in dengue prevention and control. You are to generate a recommendation for the barangay based on the provided details.";
  // let formattingInstruction =
  //   "When responding, make the response in 3 sentences, bullet form, and concise.";
  let formattingInstruction = "Your recommendation will be a day to day plan. ";
  let detailedMessage = "";

  // * AI Settings
  const ai = new GoogleGenAI({});
  const groundingTool = {
    googleSearch: {},
  };
  const config = {
    tools: [groundingTool],
    systemInstruction: `${systemInstruction} ${formattingInstruction}`,
  };

  if (!userRole) {
    return res.status(400).json({
      message: 'Required parameters "userRole" or "barangay" are missing.',
    });
  }

  if (userRole !== "admin" && userRole !== "user") {
    return res.status(400).json({
      message: "Invalid userRole.",
    });
  }

  const barangayData = await Barangay.findOne({ name: barangay });

  if (!barangayData) {
    return res.status(404).json({
      message: `Barangay ${barangay} not found in the database.`,
    });
  }

  const patternStatus = barangayData.status.pattern;
  const reportCount = barangayData.status.crowdsourced_reports_count;
  const deathCount = barangayData.status.deaths;

  if (patternStatus === "") {
    detailedMessage = `Over the past 2 weeks up until now, there have been no identified pattern of dengue cases in Brgy. ${barangay} of Quezon City, with ${reportCount} crowdsourced reports of potential dengue breeding sites, and ${deathCount} reports of dengue case fatalities.`;
  } else {
    detailedMessage = `Over the past 2 weeks up until now, there have been an identified ${patternStatus} pattern of dengue cases in Brgy. ${barangay} of Quezon City, with ${reportCount} crowdsourced reports of potential dengue breeding sites,and ${deathCount} reports of dengue case fatalities.`;
  }

  if (userRole === "admin") {
    aiPrompt +=
      " the surveillance division to do to prevent dengue in this barangay, considering the possible dengue factors. Include a day to day action plan and the factors that you considered.";
    // aiPrompt += " Especially as a disease surveillance officer.";
  } else {
    aiPrompt +=
      " for the citizens of this barangay to do to prevent and protect themselves from dengue.";
    // aiPrompt += " Especially as a community resident.";
  }

  try {
    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      contents: `${detailedMessage} ${aiPrompt}`,
      config,
    });

    const sources = extractSources(response);

    await Barangay.findByIdAndUpdate(barangayData._id, {
      recommendation: response.text,
      last_analysis_time: new Date(),
    });

    return res.status(200).json({
      response: response.text,
      sources: sources,
      message: "Recommendation generated and saved successfully.",
    });
  } catch (error) {
    console.error("Error in generateRecommendation:", error);
    return res.status(500).json({
      message: "Failed to process AI service request",
      error: error.message,
    });
  }
});

module.exports = {
  submitCsvFile,
  retrievePatternRecognitionResults,
  retrieveTrendsAndPatterns,
  analyzeInterventionEffectivity,
  analyzeDengueHotspots,
  handleCrowdsourcedReportsAnalysis,
  triggerDengueCaseReportAnalysis,
  generateRecommendation,
};
