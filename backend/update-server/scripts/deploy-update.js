const fs = require("fs");
const path = require("path");
const crypto = require("crypto");

function calculateChecksum(filePath) {
  const fileBuffer = fs.readFileSync(filePath);
  const hashSum = crypto.createHash("sha256");
  hashSum.update(fileBuffer);
  return hashSum.digest("hex");
}

function getFileSize(filePath) {
  const stats = fs.statSync(filePath);
  const fileSizeInBytes = stats.size;
  const fileSizeInMB = (fileSizeInBytes / (1024 * 1024)).toFixed(2);
  return `${fileSizeInMB}MB`;
}

function updateVersionInfo(platform, updateFile, releaseNotes) {
  const versionInfoPath = path.join(__dirname, "..", "updates", "version.json");
  const versionInfo = JSON.parse(fs.readFileSync(versionInfoPath));

  const updateFilePath = path.join(__dirname, "..", "updates", updateFile);
  if (!fs.existsSync(updateFilePath)) {
    console.error(`Update file not found: ${updateFile}`);
    process.exit(1);
  }

  const version = updateFile.match(/\d+\.\d+\.\d+/)[0];

  versionInfo[platform] = {
    version,
    fileName: updateFile,
    releaseNotes: Array.isArray(releaseNotes) ? releaseNotes : [releaseNotes],
    forceUpdate: false,
    minRequiredVersion: versionInfo[platform]?.minRequiredVersion || "1.0.0",
    size: getFileSize(updateFilePath),
    checksum: calculateChecksum(updateFilePath),
    releaseDate: new Date().toISOString(),
  };

  fs.writeFileSync(versionInfoPath, JSON.stringify(versionInfo, null, 2));
  console.log(`Updated version info for ${platform}`);
}

// Get command line arguments
const platform = process.argv[2];
const updateFile = process.argv[3];
const releaseNotes = process.argv[4];

if (!platform || !updateFile) {
  console.error(
    "Usage: node deploy-update.js <platform> <update-file> [release-notes]"
  );
  process.exit(1);
}

updateVersionInfo(platform, updateFile, releaseNotes);
