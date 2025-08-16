const fs = require("fs").promises;
const path = require("path");
const { createReadStream } = require("fs");
const csv = require("csv-parser");
const { cleanBarangayName } = require("./processCsv");

function escapeCsvField(field) {
  if (field === null || field === undefined) return "";

  const stringField = String(field);

  if (
    stringField.includes(",") ||
    stringField.includes('"') ||
    stringField.includes("\n") ||
    stringField.includes("\r")
  ) {
    return `"${stringField.replace(/"/g, '""')}"`;
  }

  return stringField;
}

async function ensureDirectoryExists(filePath) {
  const dir = path.dirname(filePath);
  try {
    await fs.access(dir);
  } catch (error) {
    await fs.mkdir(dir, { recursive: true });
  }
}

function isValidDate(dateStr) {
  if (!dateStr || typeof dateStr !== "string") return false;

  const date = new Date(dateStr.trim());
  return (
    !isNaN(date.getTime()) &&
    date.getFullYear() > 1900 &&
    date.getFullYear() < 2100
  );
}

function validateHeaders(headers) {
  const requiredHeaders = ["DAdmit", "DOnset", "Barangay", "Outcome", "City"];
  return requiredHeaders.filter(
    (required) =>
      !headers.some(
        (header) => header.trim().toLowerCase() === required.toLowerCase()
      )
  );
}

async function readCsvFile(filePath) {
  return new Promise((resolve, reject) => {
    const rows = [];
    let headersValidated = false;

    createReadStream(filePath)
      .pipe(csv())
      .on("headers", (headers) => {
        const missing = validateHeaders(headers);
        if (missing.length > 0) {
          reject(new Error(`Missing required columns: ${missing.join(", ")}`));
          return;
        }
        headersValidated = true;
      })
      .on("data", (row) => {
        rows.push(row);
      })
      .on("end", () => {
        if (!headersValidated) {
          reject(new Error("CSV file missing headers or is empty."));
        } else {
          resolve(rows);
        }
      })
      .on("error", (err) => reject(err));
  });
}

function validateRows(rows) {
  const validRows = [];
  const validationErrors = [];

  rows.forEach((row, index) => {
    const rowNum = index + 1;
    const DAdmit = row.DAdmit?.trim();
    const DOnset = row.DOnset?.trim();
    const Barangay = row.Barangay?.trim();
    const Outcome = row.Outcome?.trim();
    const City = row.City?.trim();

    const missingFields = [];
    if (!DAdmit) missingFields.push("DAdmit");
    if (!DOnset) missingFields.push("DOnset");
    if (!Barangay) missingFields.push("Barangay");
    if (!Outcome) missingFields.push("Outcome");
    if (!City) missingFields.push("City");

    if (missingFields.length > 0) {
      validationErrors.push(
        `Row ${rowNum}: Missing required fields: ${missingFields.join(", ")}`
      );
      return;
    }

    if (!isValidDate(DAdmit)) {
      validationErrors.push(
        `Row ${rowNum}: Invalid DAdmit date format: ${DAdmit}`
      );
      return;
    }

    if (!isValidDate(DOnset)) {
      validationErrors.push(
        `Row ${rowNum}: Invalid DOnset date format: ${DOnset}`
      );
      return;
    }

    // Standardize Barangay naming
    const standardizedBarangay = cleanBarangayName(Barangay);

    validRows.push({
      DAdmit,
      DOnset,
      Barangay: standardizedBarangay,
      Outcome,
      City,
    });
  });

  return { validRows, validationErrors };
}

function aggregateRows(validRows) {
  const aggregation = {};

  for (const row of validRows) {
    const { DAdmit, Barangay, Outcome } = row;
    const key = `${DAdmit}__${Barangay}`;

    if (!aggregation[key]) {
      aggregation[key] = {
        DAdmit,
        Barangay,
        caseCount: 0,
        deaths: 0,
        recoveries: 0,
      };
    }

    aggregation[key].caseCount += 1;

    const normalizedOutcome = Outcome.toLowerCase();
    if (normalizedOutcome === "died") {
      aggregation[key].deaths += 1;
    } else if (normalizedOutcome === "alive") {
      aggregation[key].recoveries += 1;
    }
  }

  return aggregation;
}

async function writeCsvFile(aggregation, outputPath) {
  await ensureDirectoryExists(outputPath);

  const headers = ["DAdmit", "Barangay", "Case Count", "Deaths", "Recoveries"];
  const lines = [headers.map(escapeCsvField).join(",")];

  const sortedEntries = Object.values(aggregation).sort(
    (a, b) => new Date(a.DAdmit) - new Date(b.DAdmit)
  );

  for (const entry of sortedEntries) {
    const row = [
      escapeCsvField(entry.DAdmit),
      escapeCsvField(entry.Barangay),
      escapeCsvField(entry.caseCount),
      escapeCsvField(entry.deaths),
      escapeCsvField(entry.recoveries),
    ];
    lines.push(row.join(","));
  }

  const csvContent = lines.join("\n");
  await fs.writeFile(outputPath, csvContent, "utf-8");
}

async function processCsvToSummary(
  inputCsvPath,
  outputCsvPath = path.join("data", "main.csv")
) {
  try {
    await fs.access(inputCsvPath);
    const rows = await readCsvFile(inputCsvPath);
    const { validRows, validationErrors } = validateRows(rows);
    const aggregatedData = aggregateRows(validRows);
    await writeCsvFile(aggregatedData, outputCsvPath);

    console.log("Completed CSV processing.");
    console.log(`Output written to: ${outputCsvPath}`);

    if (validationErrors.length > 0) {
      console.log(`Validation errors: ${validationErrors.length}`);
      validationErrors.slice(0, 5).forEach((err) => console.log("  " + err));
      if (validationErrors.length > 5) {
        console.log(`  ...and ${validationErrors.length - 5} more`);
      }
    }

    return {
      rowsRead: rows.length,
      validRows: validRows.length,
      recordsAggregated: Object.keys(aggregatedData).length,
      validationErrors,
      outputPath: outputCsvPath,
    };
  } catch (error) {
    console.error(`Error processing CSV: ${error.message}`);
    throw error;
  }
}

module.exports = { processCsvToSummary };
