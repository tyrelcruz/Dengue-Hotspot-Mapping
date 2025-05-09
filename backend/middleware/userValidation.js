const { body, validationResult } = require("express-validator");

const validateRegisterInputs = [
  body("username")
    .notEmpty()
    .withMessage("Please do not leave the username field to be blank."),
  body("email").isEmail().withMessage("Please provide a valid email."),
  body("password")
    .isLength({ min: 8 })
    .withMessage("Password must be at least a minimum of 8 characters long")
    .matches(/[a-zA-Z]/)
    .withMessage("Password must contain at least a letter")
    .matches(/\d/)
    .withMessage("Password must contain at least a number."),
  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      const errorMessages = errors.array().map((error) => error.msg);
      return res.status(400).json({ errors: errorMessages });
    }
    next();
  },
];

const validateLoginInputs = [
  body("email").isEmail().withMessage("Please provide a valid email."),
  body("password").notEmpty().withMessage("A password is required."),

  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      const errorMessages = errors.array().map((error) => error.msg);
      return res.status(400).json({ errors: errorMessages });
    }
    next();
  },
];

module.exports = {
  validateRegisterInputs,
  validateLoginInputs,
};
