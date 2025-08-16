function extractSources(response) {
  const chunks =
    response.candidates[0]?.groundingMetadata?.groundingChunks || [];
  return chunks
    .map((chunk) => ({
      title: chunk?.web?.title,
      uri: chunk?.web?.uri,
    }))
    .filter((item) => item.uri);
}

module.exports = extractSources;
