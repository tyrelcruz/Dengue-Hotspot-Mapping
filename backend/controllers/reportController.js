const jwt = require("jsonwebtoken");
const Report = require("../models/Reports");
const mongoose = require("mongoose");
const barangaysData = require("../data/barangays.json");
const asyncErrorHandler = require("../middleware/asyncErrorHandler");
const Notification = require("../models/Notifications");
const axios = require("axios");
const FormData = require("form-data");
const path = require("path");

// ImgBB Configuration
const IMGBB_API_KEY = "f9a3cbc450ac4599f046c41d84ad5799"; // Get from imgbb.com

// Helper function to upload to ImgBB
async function uploadToImgBB(fileData) {
  try {
    const form = new FormData();
    form.append("image", fileData.toString("base64"));

    const response = await axios.post(
      `https://api.imgbb.com/1/upload?key=${IMGBB_API_KEY}`,
      form,
      { headers: form.getHeaders() }
    );
    return {
      url: response.data.data.url,
      deleteUrl: response.data.data.delete_url, // For potential future deletion
    };
  } catch (error) {
    console.error("ImgBB upload error:", error);
    throw new Error("Failed to upload image to ImgBB");
  }
}

// Barangay validation (unchanged)
const list_of_barangays = barangaysData.features
  .filter((feature) => feature.properties && feature.properties.name)
  .map((feature) => feature.properties.name.toLowerCase().trim());

const isBarangayValid = (barangay) => {
  return list_of_barangays.includes(barangay.toLowerCase().trim());
};

// GET all reports (updated)
const getAllReports = asyncErrorHandler(async (req, res) => {
  const {
    barangay,
    report_type,
    status,
    startDate,
    endDate,
    sortBy = 'createdAt',
    sortOrder = 'desc',
    username,
    description,
    search
  } = req.query;

  // Build the filter object
  const filter = {};

  // Only apply filters if at least one query parameter is provided
  const hasQueryParams = barangay || report_type || status || startDate || endDate || username || description || search;
  
  if (hasQueryParams) {
    // Handle specific filters first (these take precedence)
    if (barangay) {
      const searchTerm = barangay.replace(/\s+/g, '');
      filter.barangay = { 
        $regex: new RegExp(`^${searchTerm.split('').join('\\s*')}$`, 'i') 
      };
    }

    if (username) {
      const User = mongoose.model('Account');
      const users = await User.find({ username: { $regex: username, $options: 'i' } });
      const userIds = users.map(user => user._id);
      
      // Only search by username if the report is not anonymous
      filter.$and = [
        { user: { $in: userIds } },
        { isAnonymous: false }
      ];
    }

    if (description) {
      filter.description = { $regex: description, $options: 'i' };
    }

    // Handle general search only if no specific filters are provided
    if (search && !barangay && !username && !description) {
      const searchConditions = [
        { barangay: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];

      // For username search in general search, only include non-anonymous reports
      const User = mongoose.model('Account');
      const users = await User.find({ username: { $regex: search, $options: 'i' } });
      const userIds = users.map(user => user._id);
      if (userIds.length > 0) {
        searchConditions.push({
          $and: [
            { user: { $in: userIds } },
            { isAnonymous: false }
          ]
        });
      }

      // Add anonymousId search for anonymous reports
      searchConditions.push({
        $and: [
          { isAnonymous: true },
          { anonymousId: { $regex: search, $options: 'i' } }
        ]
      });

      filter.$or = searchConditions;
    }

    // Add other filters
    if (report_type) {
      filter.report_type = report_type;
    }

    if (status) {
      filter.status = status;
    }

    if (startDate || endDate) {
      filter.date_and_time = {};
      if (startDate) {
        filter.date_and_time.$gte = new Date(startDate);
      }
      if (endDate) {
        filter.date_and_time.$lte = new Date(endDate);
      }
    }
  }

  // Validate sort parameters
  const allowedSortFields = ['createdAt', 'date_and_time', 'status', 'report_type'];
  const sortField = allowedSortFields.includes(sortBy) ? sortBy : 'createdAt';
  const sortDirection = sortOrder === 'asc' ? 1 : -1;

  const reports = await Report.find(filter)
    .sort({ [sortField]: sortDirection })
    .populate("user", "username");

  // Transform the response to show anonymousId instead of username for anonymous reports
  const transformedReports = reports.map(report => {
    const reportObj = report.toObject();
    if (report.isAnonymous) {
      // For anonymous reports, create a user object with anonymousId
      reportObj.user = { 
        _id: report._id, // Use report's _id instead of user._id
        username: report.anonymousId 
      };
    }
    return reportObj;
  });

  res.status(200).json(transformedReports);
});

// GET a specific report (unchanged)
const getReport = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(404).json({ error: "No such post!" });
  }
  const report = await Report.findById(id).populate("user", "username");
  if (!report) {
    return res.status(404).json({ error: "Post does not exist!" });
  }

  // Transform the response to show anonymousId for anonymous reports
  const reportObj = report.toObject();
  if (report.isAnonymous) {
    // Keep the original username but add anonymousId
    reportObj.anonymousId = report.anonymousId;
  }

  res.status(200).json(reportObj);
});

// * UPDATED createReport with fixed ImgBB integration for express-fileupload
const ALLOWED_REPORT_TYPES = ["Breeding Site", "Standing Water", "Infestation"];
const createReport = asyncErrorHandler(async (req, res) => {
  console.log("[DEBUG] REQ BODY:", req.body);
  console.log("[DEBUG] REQ FILES:", req.files);

  // Get userId if user is authenticated
  const userId = req.user?.userId;
  if (!userId) {
    return res.status(401).json({ error: "Authentication required to submit reports" });
  }

  // Reconstruct specific_location from the form data
  const specific_location = {
    type: req.body["specific_location[type]"],
    coordinates: [
      parseFloat(req.body["specific_location[coordinates][0]"]),
      parseFloat(req.body["specific_location[coordinates][1]"]),
    ]
  };

  // Validate required fields based on the Report model schema
  let emptyFields = [];
  
  // Check required fields
  if (!req.body.barangay) emptyFields.push("barangay");
  if (!specific_location || !specific_location.coordinates) emptyFields.push("specific_location");
  if (!req.body.date_and_time) emptyFields.push("date_and_time");
  if (!req.body.report_type) emptyFields.push("report_type");
  if (!req.body.description) emptyFields.push("description");

  if (emptyFields.length > 0) {
    return res.status(400).json({ 
      error: "Please fill in all required fields", 
      emptyFields,
      message: `The following fields are required: ${emptyFields.join(", ")}`
    });
  }

  // Validate barangay
  if (!isBarangayValid(req.body.barangay)) {
    return res.status(400).json({ 
      error: "Invalid barangay", 
      message: `${req.body.barangay} is not a valid barangay.`
    });
  }

  // Validate report type
  if (!ALLOWED_REPORT_TYPES.includes(req.body.report_type)) {
    return res.status(400).json({ 
      error: "Invalid report type", 
      message: `Invalid report_type. Allowed values: ${ALLOWED_REPORT_TYPES.join(", ")}.`
    });
  }

  // Validate specific_location coordinates
  if (specific_location.coordinates.length !== 2 || 
      specific_location.coordinates[0] < -180 || 
      specific_location.coordinates[0] > 180 ||
      specific_location.coordinates[1] < -90 || 
      specific_location.coordinates[1] > 90) {
    return res.status(400).json({ 
      error: "Invalid coordinates", 
      message: "Coordinates must be in [longitude, latitude] format with valid ranges."
    });
  }

  // Handle image uploads
  const imageUrls = [];
  if (req.files && req.files.images) {
    const imageFiles = Array.isArray(req.files.images) ? req.files.images : [req.files.images];
    for (const file of imageFiles) {
      try {
        const imgbbResponse = await uploadToImgBB(file.data);
        console.log("[DEBUG] ImgBB Response:", imgbbResponse);
        imageUrls.push(imgbbResponse.url);
      } catch (error) {
        console.error("[DEBUG] ImgBB upload error:", error);
        return res.status(500).json({ 
          error: "Image upload failed", 
          message: "Failed to upload image to ImgBB"
        });
      }
    }
  }

  const reportData = {
    user: userId,
    barangay: req.body.barangay,
    specific_location,
    date_and_time: req.body.date_and_time,
    report_type: req.body.report_type,
    description: req.body.description,
    images: imageUrls,
    isAnonymous: req.body.isAnonymous || false,
  };

  try {
    const report = await Report.create(reportData);

    // Create notification only if report is not anonymous
    if (!reportData.isAnonymous) {
      await Notification.create({
        report: report._id,
        user: userId,
        message: `Your ${req.body.report_type} report in ${req.body.barangay} has been successfully submitted.`,
      });
    }

    res.status(201).json({
      message: "Report has been successfully created.",
      report: {
        _id: report._id,
        barangay: report.barangay,
        report_type: report.report_type,
        images: report.images,
        isAnonymous: report.isAnonymous,
        anonymousId: report.anonymousId
      },
    });
  } catch (error) {
    // Handle mongoose validation errors
    if (error.name === 'ValidationError') {
      const validationErrors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({ 
        error: "Validation Error", 
        message: "Invalid report data",
        details: validationErrors
      });
    }
    throw error; // Let the error handler middleware handle other errors
  }
});

// * UPDATED deleteReport to handle ImgBB URLs
const deleteReport = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;

  if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(404).json({ error: "No such post!" });
  }

  // Find and delete the report
  const report = await Report.findOneAndDelete({ _id: id });

  if (!report) {
    return res.status(404).json({ error: "No such post exists!" });
  }

  // Note: ImgBB doesn't provide API for deletion in free tier
  // If you need to delete images, you'll need to:
  // 1. Store delete URLs when uploading (see uploadToImgBB helper)
  // 2. Implement deletion logic here using those URLs

  res.status(200).json({
    message: "Report deleted successfully",
    deletedReport: report,
  });
});

// updateReportStatus remains unchanged
const updateReportStatus = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  const allowedStatuses = ["Pending", "Rejected", "Validated"];
  if (!allowedStatuses.includes(status)) {
    return res.status(400).json({ message: "Invalid status value." });
  }

  const updatedReport = await Report.findByIdAndUpdate(
    id,
    { status: status },
    { new: true }
  );

  if (!updatedReport) {
    return res.status(404).json({ mesage: "Report not found." });
  }

  res.status(200).json({
    message: "Report status updated successfully.",
  });
});

const getNearbyReports = asyncErrorHandler(async (req, res) => {
  // Accept reportId, status, and radius from the POST body
  const { reportId, status, radius = 2 } = req.body; // radius in km, default 2km

  // Validate report id
  if (!mongoose.Types.ObjectId.isValid(reportId)) {
    return res.status(400).json({ error: "Invalid report ID." });
  }

  // Find the reference report
  const referenceReport = await Report.findById(reportId);
  if (!referenceReport) {
    return res.status(404).json({ error: "Reference report not found." });
  }

  // Ensure the report has a valid location
  if (
    !referenceReport.specific_location ||
    !Array.isArray(referenceReport.specific_location.coordinates) ||
    referenceReport.specific_location.coordinates.length !== 2
  ) {
    return res.status(400).json({ error: "Reference report does not have a valid location." });
  }

  // Build the query
  const geoQuery = {
    specific_location: {
      $near: {
        $geometry: {
          type: "Point",
          coordinates: referenceReport.specific_location.coordinates,
        },
        $maxDistance: Number(radius) * 1000, // convert km to meters
      },
    },
    _id: { $ne: referenceReport._id }, // Exclude the reference report itself
  };

  if (status) {
    geoQuery.status = status;
  }

  const nearbyReports = await Report.find(geoQuery).populate("user", "username");

  // Transform for anonymous
  const transformedReports = nearbyReports.map(report => {
    const reportObj = report.toObject();
    if (report.isAnonymous) {
      reportObj.user = {
        _id: report.user?._id,
        username: report.anonymousId,
      };
    }
    return reportObj;
  });

  // Include the count in the response
  res.status(200).json({
    count: transformedReports.length,
    reports: transformedReports,
  });
});

module.exports = {
  getAllReports,
  getReport,
  createReport,
  deleteReport,
  updateReportStatus,
  getNearbyReports,
};
