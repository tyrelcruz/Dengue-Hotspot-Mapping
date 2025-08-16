module.exports = (error, req, res, next) => {
  console.error("Error occurred:", {
    message: error.message,
    stack: error.stack,
    path: req.path,
    method: req.method,
    body: req.body,
    params: req.params,
    query: req.query
  });

  error.statusCode = error.statusCode || 500;
  error.status = error.status || "error";
  
  const response = {
    status: error.status,
    message: error.message,
  };

  // Add stack trace in development/debugging
  if (process.env.NODE_ENV !== 'production') {
    response.stack = error.stack;
  }

  res.status(error.statusCode).json(response);
};
