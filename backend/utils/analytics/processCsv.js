const csv = require("csv-parser");
const { createReadStream } = require("fs");
const { Readable } = require("stream");

function cleanBarangayName(name) {
  // Clean and standardize barangay names according to specific mappings.

  if (!name || name === "") {
    return name;
  }

  name = String(name).trim();
  // Normalize unicode characters
  name = name.normalize("NFKC");

  const specificMappings = {
    "BAGONG PAGASA": "BAGONG PAG-ASA",
    "QUIRINO 2A": "QUIRINO 2-A",
    "QUIRINO 2B": "QUIRINO 2-B",
    "QUIRINO 2C": "QUIRINO 2-C",
    "QUIRINO 3A": "QUIRINO 3-A",
    "SANTO NINO": "SANTO NIÑO",
    "STO. NINO": "SANTO NIÑO",
    "STO NIÑO": "SANTO NIÑO",
    "U.P. CAMPUS": "UP CAMPUS",
    PHILAM: "PHIL-AM",
    "PASONG PUTIK": "PASONG PUTIK PROPER",
    "PAGIBIG SA NAYON": "PAG-IBIG SA NAYON",
    "NEW ERA (CONSTITUTION HILLS)": "NEW ERA",
    "NS AMORANTO": "N.S. AMORANTO",
    "NS AMORANTO (GINTONG SILAHIS)": "N.S. AMORANTO",
    DUYANDUYAN: "DUYAN-DUYAN",
    "DOÑA AURORA": "DOÑA AURORA",
    "DOÑA IMELDA": "DOÑA IMELDA",
    "DOÑA JOSEFA": "DOÑA JOSEFA",
    "DOA AURORA": "DOÑA AURORA",
    "DOA IMELDA": "DOÑA IMELDA",
    "DOA JOSEFA": "DOÑA JOSEFA",
    "SAINT IGNATIUS": "ST. IGNATIUS",
    "ST. IGNATIUS": "ST. IGNATIUS",
    "PAYATAS A": "PAYATAS",
    "PAYATAS B": "PAYATAS",
  };

  if (specificMappings[name]) {
    return specificMappings[name];
  }

  const upperName = name.toUpperCase();
  for (const [key, value] of Object.entries(specificMappings)) {
    if (upperName === key) {
      return value;
    }
  }

  if (upperName.includes("AMORANTO")) {
    if (
      upperName.includes("N.S.") ||
      upperName.includes("NS") ||
      upperName.includes("N S")
    ) {
      return "N.S. AMORANTO";
    }
  }

  // Replace invalid replacement character (U+FFFD) with proper 'Ñ'
  name = name.replace("\uFFFD", "Ñ");
  // Remove extra spaces and return uppercase name
  name = name.replace(/\s+/g, " ").trim();
  return name.toUpperCase();
}

function processDengueData(csvContent) {
  return new Promise((resolve, reject) => {
    try {
      const results = [];

      // Create a readable stream from the CSV content
      const stream = Readable.from(csvContent);

      stream
        .pipe(csv())
        .on("data", (data) => {
          // Clean Barangay names
          data.Barangay = cleanBarangayName(data.Barangay);

          // Normalize Outcome column
          data.Outcome = data.Outcome
            ? data.Outcome.trim().replace(/^\w/, (c) => c.toUpperCase())
            : "";

          results.push(data);
        })
        .on("end", () => {
          try {
            // Group by DAdmit and Barangay and aggregate outcomes
            const grouped = {};

            for (const row of results) {
              const key = `${row.DAdmit}_${row.Barangay}`;

              if (!grouped[key]) {
                grouped[key] = {
                  DAdmit: row.DAdmit,
                  Barangay: row.Barangay,
                  "Case Count": 0,
                  Deaths: 0,
                  Recoveries: 0,
                };
              }

              grouped[key]["Case Count"]++;

              if (row.Outcome === "Died") {
                grouped[key].Deaths++;
              } else if (row.Outcome === "Alive") {
                grouped[key].Recoveries++;
              }
            }

            // Convert grouped data to array
            const processedData = Object.values(grouped);

            // Convert to CSV format
            const csvHeaders = [
              "DAdmit",
              "Barangay",
              "Case Count",
              "Deaths",
              "Recoveries",
            ];
            const csvRows = [csvHeaders.join(",")];

            for (const row of processedData) {
              const csvRow = [
                row.DAdmit,
                row.Barangay,
                row["Case Count"],
                row.Deaths,
                row.Recoveries,
              ].join(",");
              csvRows.push(csvRow);
            }

            resolve(csvRows.join("\n"));
          } catch (error) {
            reject(new Error(`Error processing data: ${error.message}`));
          }
        })
        .on("error", (error) => {
          reject(new Error(`Error reading CSV content: ${error.message}`));
        });
    } catch (error) {
      reject(new Error(`Error processing dengue data: ${error.message}`));
    }
  });
}

// For testing purposes
if (require.main === module) {
  const testCsvContent = `DAdmit,Barangay,Outcome
2025-01-01,San Isidro,Alive
2025-01-01,San Isidro,Died
2025-01-02,Bagong Pagasa,Alive`;

  processDengueData(testCsvContent)
    .then((result) => {
      console.log("Processed CSV:");
      console.log(result);
    })
    .catch((error) => {
      console.error("Error:", error.message);
    });
}

module.exports = {
  processDengueData,
  cleanBarangayName,
};
