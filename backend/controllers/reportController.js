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

// GET all reports (unchanged)
const getAllReports = asyncErrorHandler(async (req, res) => {
  const reports = await Report.find({})
    .sort({ createdAt: -1 })
    .populate("user", "username");
  res.status(200).json(reports);
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
  res.status(200).json(report);
});

// * UPDATED createReport with fixed ImgBB integration for express-fileupload
const createReport = asyncErrorHandler(async (req, res) => {
  console.log("REQ BODY:", req.body);  // Logs the form data
  console.log("REQ FILES:", req.files); // Logs all uploaded files

  // Check if the file is present in the request
  if (req.files && req.files.images) {
    // Ensure it's in the expected array or object format
    const imageFiles = Array.isArray(req.files.images) ? req.files.images : [req.files.images];
    
    imageFiles.forEach((file) => {
      console.log("Uploaded Image:", file.name);  // Log the name of the uploaded image
      console.log("Image Size:", file.size);     // Log the size of the uploaded image

      // You can save the image file here (e.g., using the mv method)
      const uploadPath = path.join(__dirname, 'uploads', file.name);  // Set the upload directory
      console.log('UPLOADDD'+uploadPath)
      // Move the uploaded file to the desired location
      file.mv(uploadPath, (err) => {
        if (err) {
          return res.status(500).json({ error: 'File upload failed', details: err });
        }
        console.log(`File uploaded to ${uploadPath}`);
      });
    });
  } else {
    console.log("No images found in the request.");
  }

  // Reconstruct specific_location from the form data
  const specific_location = {
    type: req.body["specific_location[type]"], 
    coordinates: [
      parseFloat(req.body["specific_location[coordinates][0]"]), 
      parseFloat(req.body["specific_location[coordinates][1]"]),
    ]
  };

  console.log("Specific Location:", specific_location);

  const userId = req.user?.userId;
  if (!userId) {
    return res.status(401).json({ error: "Unauthorized. No user ID found." });
  }

  // Validate required fields
  let emptyFields = [];
  if (!req.body.barangay) emptyFields.push("barangay");
  if (!specific_location || !specific_location.coordinates) emptyFields.push("specific_location");
  if (!req.body.date_and_time) emptyFields.push("date_and_time");
  if (!req.body.report_type) emptyFields.push("report_type");
  if (!req.body.description) emptyFields.push("description");

  if (emptyFields.length > 0) {
    return res.status(400).json({ error: "Please fill in all fields", emptyFields });
  }

  if (!isBarangayValid(req.body.barangay)) {
    return res.status(400).json({ error: `${req.body.barangay} is not a valid barangay.` });
  }

  // Continue with creating the report...
  const imageUrls = [];
  if (req.files && req.files.images) {
    const imageFiles = Array.isArray(req.files.images) ? req.files.images : [req.files.images];
    for (const file of imageFiles) {
      try {
        const imgbbResponse = await uploadToImgBB(file.data);  // Assuming `file.data` contains the image data
        imageUrls.push(imgbbResponse.url);  // Store the URL returned by ImgBB
      } catch (error) {
        console.error("ImgBB upload error:", error);
        return res.status(500).json({ error: "Image upload failed" });
      }
    }
  }

  const report = await Report.create({
    user: userId,
    barangay: req.body.barangay,
    specific_location,
    date_and_time: req.body.date_and_time,
    report_type: req.body.report_type,
    description: req.body.description,
    images: imageUrls,  // Store ImgBB URLs for images
  });

  await Notification.create({
    report: report._id,
    user: userId,
    message: `Your ${req.body.report_type} report in ${req.body.barangay} has been successfully submitted.`,
  });

  res.status(201).json({
    message: "Report has been successfully created.",
    report: {
      _id: report._id,
      barangay: report.barangay,
      report_type: report.report_type,
      images: report.images,  // Include ImgBB URLs in the response
    },
  });
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

module.exports = {
  getAllReports,
  getReport,
  createReport,
  deleteReport,
  updateReportStatus,
};
