const axios = require("axios");
const Report = require("../models/Reports");
const asyncErrorHandler = require("../middleware/asyncErrorHandler");
const { detectClusters } = require("../services/clusterService");

const getInterventions = asyncErrorHandler(async (req, res) => {
  try {
    // Today's range (full day)
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0); // Start of today (midnight)

    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999); // End of today

    // Past 6 days
    const sevenDaysAgo = new Date(todayStart);
    sevenDaysAgo.setDate(todayStart.getDate() - 6); // 6 days before today

    const yesterdayEnd = new Date(todayStart);
    yesterdayEnd.setMilliseconds(-1); // End of yesterday (just before today started)

    console.log("Date ranges:");
    console.log("- Today:", todayStart, "to", todayEnd);
    console.log("- Past 6 days:", sevenDaysAgo, "to", yesterdayEnd);

    // Check what data we have in each range
    const todayDocs = await Report.countDocuments({
      date_and_time: { $gte: todayStart, $lte: todayEnd },
    });
    console.log("Documents for today:", todayDocs);

    const pastDocs = await Report.countDocuments({
      date_and_time: { $gte: sevenDaysAgo, $lte: yesterdayEnd },
    });
    console.log("Documents for past 6 days:", pastDocs);

    const reports = await Report.aggregate([
      {
        $facet: {
          // TODAY'S COUNTS
          today: [
            {
              $match: {
                date_and_time: { $gte: todayStart, $lte: todayEnd },
              },
            },
            {
              $group: {
                _id: {
                  barangay: "$barangay",
                  report_type: "$report_type",
                },
                today_total: { $sum: 1 },
              },
            },
          ],
          // PAST 6-DAY AVERAGE (excluding today)
          past: [
            {
              $match: {
                date_and_time: { $gte: sevenDaysAgo, $lte: yesterdayEnd },
              },
            },
            {
              $group: {
                _id: {
                  barangay: "$barangay",
                  report_type: "$report_type",
                },
                past_total: { $sum: 1 },
              },
            },
            {
              $project: {
                _id: 1,
                past_avg: { $divide: ["$past_total", 6] },
              },
            },
          ],
        },
      },
      // Combine the results
      {
        $project: {
          all_data: {
            $concatArrays: [
              { $ifNull: ["$today", []] },
              { $ifNull: ["$past", []] },
            ],
          },
        },
      },
      { $unwind: "$all_data" },
      {
        $group: {
          _id: {
            barangay: "$all_data._id.barangay",
            report_type: "$all_data._id.report_type",
          },
          today_count: { $max: { $ifNull: ["$all_data.today_total", 0] } },
          past_average: { $max: { $ifNull: ["$all_data.past_avg", 0] } },
        },
      },
      {
        $group: {
          _id: "$_id.barangay",
          report_data: {
            $push: {
              report_type: "$_id.report_type",
              today_count: "$today_count",
              past_average: "$past_average",
            },
          },
        },
      },
      {
        $project: {
          _id: 0,
          barangay: "$_id",
          report_counts_today: {
            $arrayToObject: {
              $map: {
                input: "$report_data",
                as: "data",
                in: { k: "$$data.report_type", v: "$$data.today_count" },
              },
            },
          },
          report_7day_avg: {
            $arrayToObject: {
              $map: {
                input: "$report_data",
                as: "data",
                in: { k: "$$data.report_type", v: "$$data.past_average" },
              },
            },
          },
        },
      },
    ]);

    console.log("Reports Data:", JSON.stringify(reports, null, 2));

    const response = await axios.post("http://localhost:8000/api/v1/analyze", {
      data: reports,
    });

    res.json({ recommendations: response.data });
  } catch (error) {
    console.error("Error in getInterventions:", error);
    res.status(500).send("Error fetching data.");
  }
});

const patternRecognitionAnalysis = asyncErrorHandler(async (req, res) => {
  try {
    // Send the fetched report data to the Python prescriptive analytics API
    const pythonApiUrl = "http://localhost:8000/api/v1/pattern-recognition";
    const response = await axios.get(pythonApiUrl);
    const analysisResults = response.data;

    console.log("Received alerts from FastAPI:", analysisResults);

    res.status(200).json({
      success: true,
      data: analysisResults,
    });
  } catch (error) {
    console.error(
      "Error in patternRecognitionAnalysis calling FastAPI:",
      error.message
    );
    res.status(500).json({
      success: false,
      message: "Failed to fetch pattern recognition analysis.",
    });
  }
});

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
      message: "CSV file uploaded successfully!",
      data: response.data,
    });
  } catch (error) {
    console.error("Error uploading file:", error);
    return res.status(500).json({
      error: "Failed to process file upload.",
      message: error.message,
    });
  }
});

module.exports = {
  getInterventions,
  patternRecognitionAnalysis,
  detectReportedClusters,
};
