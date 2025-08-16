import cors from "cors";

const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(",").map((o) => o.trim())
  : [];

const MOBILE_API_KEY = process.env.MOBILE_API_KEY;

const corsOptionsDelegate = (req, callback) => {
  const origin = req.header("Origin");

  if (!origin) {
    return callback(null, { origin: false });
  }

  if (allowedOrigins.includes(origin)) {
    callback(null, { origin: true });
  } else {
    callback(new Error("Not allowed by CORS"), { origin: false });
  }
};

const accessControl = (req, res, next) => {
  const origin = req.header("Origin");

  if (origin) {
    cors(corsOptionsDelegate)(req, res, (err) => {
      if (err) return res.status(403).json({ message: err.message });
      next();
    });
  } else {
    const apiKey = req.header("x-api-key");
    if (apiKey && apiKey === MOBILE_API_KEY) {
      return next();
    }
    return res.status(403).json({ message: "Forbidden: Invalid API key" });
  }
};

module.exports = accessControl;
