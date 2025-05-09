module.exports = function (req, res, next) {
  if (req.user && req.user.role === "superadmin") {
    return next();
  }
  return res.status(403).json({ error: "Access denied. Superadmin only." });
}; 