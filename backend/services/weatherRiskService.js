const _rainfallCheck = (rainfall) => {
  return rainfall > 7.5;
};

const _temperatureCheck = (temperature) => {
  return temperature >= 25 && temperature <= 32;
};

const _humidityCheck = (relativeHumidity) => {
  return relativeHumidity >= 70 && relativeHumidity <= 80;
};

const weatherAnalysis = (rainfall, temperature, humidity) => {
  const hasHeavyRain = _rainfallCheck(rainfall);
  const hasOptimalTemp = _temperatureCheck(temperature);
  const hasHighHumidity = _humidityCheck(humidity);

  if (hasHeavyRain && hasOptimalTemp && hasHighHumidity) {
    return "HIGH";
  } else if (hasHeavyRain || (hasOptimalTemp && hasHighHumidity)) {
    return "MODERATE";
  } else {
    return "LOW";
  }
};

module.exports = weatherAnalysis;
