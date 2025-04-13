const { StatusCodes } = require("http-status-codes");
const Account = require("../models/Accounts");
const { BadRequestError, UnauthenticatedError } = require("../errors");
const asyncErrorHandler = require("../middleware/asyncErrorHandler");

const register = asyncErrorHandler(async (req, res) => {
  const { email } = req.body;

  const existingAccount = await Account.findOne({ email });

  if (existingAccount) {
    throw new BadRequestError("Account with this email already exists.");
  }

  const account = await Account.create(req.body);

  res.status(StatusCodes.CREATED).json(account);
});

const login = asyncErrorHandler(async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    throw new BadRequestError(
      "Please provide both credentials for email and password."
    );
  }
  const account = await Account.findOne({ email });

  if (!account) {
    throw new UnauthenticatedError(
      "Account with inputted email does not exist."
    );
  }

  const isPasswordCorrect = await account.comparePassword(password);

  if (!isPasswordCorrect) {
    throw new UnauthenticatedError("Incorrect password inputted.");
  }

  res.status(StatusCodes.OK).json(account);
});

module.exports = { register, login };
