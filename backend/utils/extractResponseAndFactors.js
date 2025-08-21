function extractResponseAndFactors(text) {
  const [recommendation, jsonBlock] = text
    .split(/```json|```/)
    .map((t) => t.trim());

  let factors = null;
  let summary = null;
  let weatherDetails = null;

  if (jsonBlock) {
    try {
      const parsedData = JSON.parse(jsonBlock);

      // Extract factors and summary from the parsed JSON
      if (parsedData.factors && Array.isArray(parsedData.factors)) {
        factors = parsedData.factors;
      }

      if (parsedData.summary && typeof parsedData.summary === "string") {
        summary = parsedData.summary;
      }

      // Extract factors and summary from the parsed JSON
      if (
        parsedData.weather_details &&
        Array.isArray(parsedData.weather_details)
      ) {
        weatherDetails = parsedData.weather_details;
      }

      // For backward compatibility, if the old format is used (just factors array)
      if (
        !factors &&
        !summary &&
        !weatherDetails &&
        Array.isArray(parsedData)
      ) {
        factors = parsedData;
      }
    } catch (error) {
      console.error("Failed to parse JSON block: ", error);
    }
  }

  return { recommendation, factors, summary, weatherDetails };
}

module.exports = extractResponseAndFactors;
