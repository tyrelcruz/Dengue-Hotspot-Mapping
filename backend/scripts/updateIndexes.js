require("dotenv").config();  // This matches how it's used in server.js
const mongoose = require('mongoose');
const Account = require('../models/Accounts');

async function updateIndexes() {
  try {
    // Connect to your database
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Connected to database');

    // Get the collection
    const collection = Account.collection;

    // Drop all existing indexes except _id
    const indexes = await collection.indexes();
    for (const index of indexes) {
      if (index.name !== '_id_') {
        console.log(`Dropping index: ${index.name}`);
        await collection.dropIndex(index.name);
      }
    }

    // Create the new compound index
    console.log('Creating new compound index...');
    await collection.createIndex(
      { email: 1, status: 1 },
      { 
        unique: true,
        partialFilterExpression: { status: { $ne: "deleted" } }
      }
    );

    console.log('Indexes updated successfully');
    process.exit(0);
  } catch (error) {
    console.error('Error updating indexes:', error);
    process.exit(1);
  }
}

updateIndexes(); 