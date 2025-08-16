const AdminPost = require("../models/AdminPosts");
const asyncErrorHandler = require("../middleware/asyncErrorHandler");
const axios = require("axios");
const FormData = require("form-data");
const Notification = require("../models/Notifications");
const path = require("path");
const AdminPostComment = require("../models/AdminPostComments");

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

// Create a new Admin Post
const createAdminPost = asyncErrorHandler(async (req, res) => {
  const { title, content, publishDate, category, references, images } = req.body;
  
  console.log("REQ BODY:", req.body); // Logs the form data
  console.log("REQ FILES:", req.files);

  if (req.user.role !== "admin") {
    return res
      .status(403)
      .json({ error: "You are not authorized to create posts." });
  }
  
  const adminId = req.user.userId;

  // Validate required fields
  const missingFields = [];

  if (!title) missingFields.push("title");
  if (!content) missingFields.push("content");
  if (!publishDate) missingFields.push("publishDate");
  if (!category) missingFields.push("category");

  if (missingFields.length > 0) {
    return res.status(400).json({
      error: `Please provide the following required fields: ${missingFields.join(", ")}`,
    });
  }

  // Handle image uploads to ImgBB
  const imageUrls = [];
  if (req.files && req.files.images) {
    console.log("Processing images for upload to ImgBB...");
    
    const imageFiles = Array.isArray(req.files.images)
      ? req.files.images
      : [req.files.images];

    for (const file of imageFiles) {
      try {
        console.log(`Uploading ${file.name} to ImgBB...`);
        const imgbbResponse = await uploadToImgBB(file.data);
        imageUrls.push(imgbbResponse.url);
        console.log(`Successfully uploaded ${file.name} to ImgBB: ${imgbbResponse.url}`);
      } catch (error) {
        console.error("ImgBB upload error:", error);
        return res.status(500).json({ 
          error: "Image upload failed", 
          details: error.message 
        });
      }
    }
  } else {
    console.log("No images found in the request.");
  }

  // Create the admin post
  const adminPost = await AdminPost.create({
    title,
    content,
    publishDate,
    category,
    images: imageUrls, // Store ImgBB URLs
    references,
    adminId,
  });

  res.status(201).json({
    message: "Admin Post created successfully.",
    post: adminPost,
    uploadedImages: imageUrls.length
  });
});

// Get all AdminPosts
const getAllAdminPosts = asyncErrorHandler(async (req, res) => {
  const adminPosts = await AdminPost.find({}).sort({ createdAt: -1 });
  console.log("Found admin posts:", adminPosts.length);
  console.log(
    "Posts:",
    adminPosts.map((post) => ({
      id: post._id,
      title: post.title,
      status: post.status,
    }))
  );
  res.status(200).json(adminPosts);
});

// Get a single AdminPost by ID
const getAdminPost = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;

  const adminPost = await AdminPost.findById(id);

  if (!adminPost) {
    return res.status(404).json({ error: "AdminPost not found." });
  }

  // Get comments for this post
  const comments = await AdminPostComment.find({ adminPost: id })
    .populate("user", "username")
    .populate("upvotes", "_id")
    .populate("downvotes", "_id")
    .sort({ createdAt: -1 });

  // Add comments to the response
  const response = {
    ...adminPost.toObject(),
    comments,
  };

  res.status(200).json(response);
});

// Update an AdminPost
const updateAdminPost = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;
  const { title, content, publishDate, category, imageUrl, references } =
    req.body;

  // Find the existing AdminPost by ID
  const existingAdminPost = await AdminPost.findById(id);

  if (!existingAdminPost) {
    return res.status(404).json({ message: "AdminPost not found." });
  }
  if (req.user.role !== "admin") {
    return res
      .status(403)
      .json({ error: "You are not authorized to create posts." });
  }

  // Only update the fields that are provided in the request body
  const updatedData = {};

  if (title) updatedData.title = title;
  if (content) updatedData.content = content;
  if (publishDate) updatedData.publishDate = publishDate;
  if (category) updatedData.category = category;
  if (imageUrl) updatedData.imageUrl = imageUrl;
  if (references) updatedData.references = references;

  // Update the AdminPost
  const updatedAdminPost = await AdminPost.findByIdAndUpdate(id, updatedData, {
    new: true,
  });

  res.status(200).json({
    message: "AdminPost updated successfully.",
    updatedAdminPost,
  });
});

// Delete an AdminPost (Soft Delete)
const deleteAdminPost = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;

  const adminPost = await AdminPost.findById(id);

  if (!adminPost) {
    return res.status(404).json({ message: "AdminPost not found." });
  }

  // Update status to archived instead of deleting
  adminPost.status = "archived";
  await adminPost.save();

  res.status(200).json({
    message: "AdminPost has been archived successfully.",
    post: adminPost,
  });
});

// Delete all AdminPosts (Soft Delete)
const deleteAllAdminPosts = async (req, res) => {
  try {
    // Update all posts to archived status
    await AdminPost.updateMany({ status: "active" }, { status: "archived" });
    res.json({
      message: "All active admin posts have been archived successfully",
    });
  } catch (error) {
    console.error("Error archiving admin posts:", error);
    res.status(500).json({ error: "Failed to archive admin posts" });
  }
};

// Upvote an admin post
const upvoteAdminPost = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.userId;

  console.log(
    `[ADMIN UPVOTE] Attempting to upvote admin post ${id} by user ${userId}`
  );

  const adminPost = await AdminPost.findById(id);
  if (!adminPost) {
    console.log(`[ADMIN UPVOTE] Admin post not found: ${id}`);
    return res.status(404).json({ error: "Admin post not found" });
  }

  // Remove user from downvotes if they had downvoted
  adminPost.downvotes = adminPost.downvotes.filter(
    (vote) => vote.toString() !== userId
  );

  // Add user to upvotes if they haven't upvoted
  if (!adminPost.upvotes.includes(userId)) {
    adminPost.upvotes.push(userId);
  }

  await adminPost.save();

  // Return consistent data structure
  res.status(200).json({
    _id: adminPost._id,
    upvotes: adminPost.upvotes,
    downvotes: adminPost.downvotes,
    upvoteCount: adminPost.upvotes.length,
    downvoteCount: adminPost.downvotes.length,
  });
});

// Downvote an admin post
const downvoteAdminPost = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.userId;

  console.log(
    `[ADMIN DOWNVOTE] Attempting to downvote admin post ${id} by user ${userId}`
  );

  const adminPost = await AdminPost.findById(id);
  if (!adminPost) {
    console.log(`[ADMIN DOWNVOTE] Admin post not found: ${id}`);
    return res.status(404).json({ error: "Admin post not found" });
  }

  // Remove user from upvotes if they had upvoted
  adminPost.upvotes = adminPost.upvotes.filter(
    (vote) => vote.toString() !== userId
  );

  // Add user to downvotes if they haven't downvoted
  if (!adminPost.downvotes.includes(userId)) {
    adminPost.downvotes.push(userId);
  }

  await adminPost.save();

  // Return consistent data structure
  res.status(200).json({
    _id: adminPost._id,
    upvotes: adminPost.upvotes,
    downvotes: adminPost.downvotes,
    upvoteCount: adminPost.upvotes.length,
    downvoteCount: adminPost.downvotes.length,
  });
});

// Remove upvote from an admin post
const removeUpvote = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.userId;

  const adminPost = await AdminPost.findById(id);
  if (!adminPost) {
    return res.status(404).json({ error: "Admin post not found" });
  }

  // Remove user from upvotes
  adminPost.upvotes = adminPost.upvotes.filter(
    (vote) => vote.toString() !== userId
  );
  await adminPost.save();

  // Return consistent data structure
  res.status(200).json({
    _id: adminPost._id,
    upvotes: adminPost.upvotes,
    downvotes: adminPost.downvotes,
    upvoteCount: adminPost.upvotes.length,
    downvoteCount: adminPost.downvotes.length,
  });
});

// Remove downvote from an admin post
const removeDownvote = asyncErrorHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.userId;

  const adminPost = await AdminPost.findById(id);
  if (!adminPost) {
    return res.status(404).json({ error: "Admin post not found" });
  }

  // Remove user from downvotes
  adminPost.downvotes = adminPost.downvotes.filter(
    (vote) => vote.toString() !== userId
  );
  await adminPost.save();

  // Return consistent data structure
  res.status(200).json({
    _id: adminPost._id,
    upvotes: adminPost.upvotes,
    downvotes: adminPost.downvotes,
    upvoteCount: adminPost.upvotes.length,
    downvoteCount: adminPost.downvotes.length,
  });
});

module.exports = {
  createAdminPost,
  getAllAdminPosts,
  getAdminPost,
  updateAdminPost,
  deleteAdminPost,
  deleteAllAdminPosts,
  upvoteAdminPost,
  downvoteAdminPost,
  removeUpvote,
  removeDownvote,
};
