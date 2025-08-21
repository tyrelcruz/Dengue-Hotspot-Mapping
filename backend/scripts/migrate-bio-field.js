require("dotenv").config();
const mongoose = require("mongoose");
const Account = require("../models/Accounts");

async function migrateBioField() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGO_URI);
    console.log("Connected to MongoDB");

    // Update all accounts that don't have a bio field
    const result = await Account.updateMany(
      { bio: { $exists: false } },
      { $set: { bio: "" } }
    );

    console.log(`Migration completed: ${result.modifiedCount} documents updated`);

    // Also check for null bio values
    const nullBioResult = await Account.updateMany(
      { bio: null },
      { $set: { bio: "" } }
    );

    console.log(`Null bio migration: ${nullBioResult.modifiedCount} documents updated`);
    
    process.exit(0);
  } catch (error) {
    console.error("Migration failed:", error);
    process.exit(1);
  }
}

if (require.main === module) {
  migrateBioField();
}

module.exports = migrateBioField; 