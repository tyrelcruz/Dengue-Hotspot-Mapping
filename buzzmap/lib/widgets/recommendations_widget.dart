import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';

class WeatherRecommendation {
  final double temperature;
  final double relativeHumidity;
  final double rainfall;
  final String recommendation;
  final String riskLevel;

  WeatherRecommendation({
    required this.temperature,
    required this.relativeHumidity,
    required this.rainfall,
    required this.recommendation,
    required this.riskLevel,
  });

  factory WeatherRecommendation.fromJson(Map<String, dynamic> json) {
    final extractedData = json['extractedData'] ?? {};
    final temp = (extractedData['temperature'] ?? 0.0).toDouble();
    final humidity = (extractedData['relativeHumidity'] ?? 0.0).toDouble();
    final rain = (extractedData['rainfall'] ?? 0.0).toDouble();

    // Calculate risk level based on weather conditions
    String riskLevel = _calculateRiskLevel(temp, humidity, rain);

    return WeatherRecommendation(
      temperature: temp,
      relativeHumidity: humidity,
      rainfall: rain,
      recommendation: json['recommendation'] ?? 'No recommendation available',
      riskLevel: riskLevel,
    );
  }

  static String _calculateRiskLevel(double temperature, double humidity, double rainfall) {
    bool hasHeavyRain = rainfall > 7.5;
    bool hasOptimalTemp = temperature >= 25 && temperature <= 32;
    bool hasHighHumidity = humidity >= 70 && humidity <= 80;

    if (hasHeavyRain && hasOptimalTemp && hasHighHumidity) {
      return "HIGH";
    } else if (hasHeavyRain || (hasOptimalTemp && hasHighHumidity)) {
      return "MODERATE";
    } else {
      return "LOW";
    }
  }
}

class PatternRecognitionData {
  final String name;
  final String riskLevel;
  final String? alert;
  final String? lastAnalysisTime;
  final String? triggeredPattern;

  PatternRecognitionData({
    required this.name,
    required this.riskLevel,
    this.alert,
    this.lastAnalysisTime,
    this.triggeredPattern,
  });

  factory PatternRecognitionData.fromJson(Map<String, dynamic> json) {
    return PatternRecognitionData(
      name: json['name'] ?? '',
      riskLevel: json['risk_level'] ?? 'Unknown',
      alert: json['alert'],
      lastAnalysisTime: json['last_analysis_time'],
      triggeredPattern: json['triggered_pattern'],
    );
  }
}

class RecommendationsWidget extends StatefulWidget {
  final String severity;
  final Map<String, String> hazardRiskLevels;
  final double latitude;
  final double longitude;
  final String selectedBarangay;
  final Color barangayColor;

  const RecommendationsWidget({
    Key? key,
    required this.severity,
    required this.hazardRiskLevels,
    required this.latitude,
    required this.longitude,
    required this.selectedBarangay,
    required this.barangayColor,
  }) : super(key: key);

  @override
  State<RecommendationsWidget> createState() => _RecommendationsWidgetState();
}

class _RecommendationsWidgetState extends State<RecommendationsWidget> {
  WeatherRecommendation? _weatherData;
  PatternRecognitionData? _patternData;
  bool _isLoading = false;
  String? _error;
  bool _isDengueExpanded = false;
  bool _isWeatherExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
    _fetchPatternData();
  }

  @override
  void didUpdateWidget(RecommendationsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude || 
        oldWidget.longitude != widget.longitude ||
        oldWidget.selectedBarangay != widget.selectedBarangay) {
      print('Location changed: ${widget.selectedBarangay} (${widget.latitude}, ${widget.longitude})');
      _fetchWeatherData();
      _fetchPatternData();
    }
  }

  Future<void> _fetchWeatherData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Fetching weather data for coordinates: ${widget.latitude}, ${widget.longitude}');
      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/analytics/get-location-weather-risk'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'selectedLatitude': widget.latitude.toString(),
          'selectedLongitude': widget.longitude.toString(),
        }),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _weatherData = WeatherRecommendation.fromJson(data['data']);
            _isLoading = false;
          });
          return;
        }
      }
      throw Exception('Failed to load weather data');
    } catch (e) {
      print('Error fetching weather data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPatternData() async {
    try {
      print('Fetching pattern recognition data');
      print('Selected barangay: ${widget.selectedBarangay}');
      
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/analytics/retrieve-pattern-recognition-results'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Pattern API Response Status: ${response.statusCode}');
      print('Pattern API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null && data['data'].isNotEmpty) {
          // Find the matching barangay data
          final barangayName = widget.selectedBarangay.toLowerCase();
          print('Searching for barangay: $barangayName');
          
          final barangayData = data['data'].firstWhere(
            (item) {
              final itemName = item['name']?.toString().toLowerCase() ?? '';
              print('Comparing with: $itemName');
              return itemName == barangayName;
            },
            orElse: () {
              print('No matching barangay found');
              return null;
            },
          );

          if (barangayData != null) {
            print('Found matching barangay data: $barangayData');
            setState(() {
              _patternData = PatternRecognitionData(
                name: barangayData['name'] ?? '',
                riskLevel: barangayData['risk_level'] ?? 'Unknown',
                alert: barangayData['alert'] ?? 'No data available',
                lastAnalysisTime: barangayData['last_analysis_time'],
                triggeredPattern: barangayData['triggered_pattern'] ?? 'No data',
              );
            });
          } else {
            print('No matching barangay data found');
            // Set default pattern data if no match found
            setState(() {
              _patternData = PatternRecognitionData(
                name: barangayName,
                riskLevel: 'Low',
                alert: 'No recent data available',
                lastAnalysisTime: DateTime.now().toIso8601String(),
                triggeredPattern: 'No data',
              );
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching pattern data: $e');
      // Set default pattern data on error
      setState(() {
        _patternData = PatternRecognitionData(
          name: widget.selectedBarangay,
          riskLevel: 'Low',
          alert: 'Error fetching data',
          lastAnalysisTime: DateTime.now().toIso8601String(),
          triggeredPattern: 'No data',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _fetchWeatherData();
                _fetchPatternData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_weatherData == null || _patternData == null) {
      return const Center(child: Text('No data available'));
    }

    return Column(
      children: [
        // Dengue Risk Assessment Card
        GestureDetector(
          onTap: () {
            setState(() {
              _isDengueExpanded = !_isDengueExpanded;
              if (_isDengueExpanded) _isWeatherExpanded = false;
            });
          },
          child: Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _getRiskColor(_patternData!.riskLevel),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _getRiskColor(_patternData!.riskLevel).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    'i',
                                    style: TextStyle(
                                      color: _getRiskColor(_patternData!.riskLevel),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Dengue Risk Assessment',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getRiskColor(_patternData!.riskLevel).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getRiskColor(_patternData!.riskLevel).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _patternData!.riskLevel.toUpperCase(),
                              style: TextStyle(
                                color: _getRiskColor(_patternData!.riskLevel),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_isDengueExpanded) ...[
                        const SizedBox(height: 16),
                        if (_patternData!.triggeredPattern != null)
                          _buildPatternCard(),
                        if (_patternData!.alert != null)
                          _buildAlertCard(),
                        if (_patternData!.lastAnalysisTime != null)
                          _buildLastAnalyzedCard(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Weather Conditions Card
        GestureDetector(
          onTap: () {
            setState(() {
              _isWeatherExpanded = !_isWeatherExpanded;
              if (_isWeatherExpanded) _isDengueExpanded = false;
            });
          },
          child: Card(
            color: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade200,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                'i',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Weather Conditions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (_isWeatherExpanded) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildWeatherInfo(
                              Icons.thermostat,
                              'Temperature',
                              '${_weatherData!.temperature.toStringAsFixed(1)}°C',
                              _weatherData!.temperature >= 25 && _weatherData!.temperature <= 32,
                            ),
                            _buildWeatherInfo(
                              Icons.water_drop,
                              'Humidity',
                              '${_weatherData!.relativeHumidity.toStringAsFixed(0)}%',
                              _weatherData!.relativeHumidity >= 70 && _weatherData!.relativeHumidity <= 80,
                            ),
                            _buildWeatherInfo(
                              Icons.water,
                              'Rainfall',
                              '${_weatherData!.rainfall.toStringAsFixed(2)}mm',
                              _weatherData!.rainfall > 7.5,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Weather-based Recommendation:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _weatherData!.recommendation,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatternCard() {
    if (_patternData!.triggeredPattern == 'No data') {
      return Card(
        elevation: 0,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'No pattern data available',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getPatternColor(_patternData!.triggeredPattern!).withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.trending_up,
              size: 20,
              color: _getPatternColor(_patternData!.triggeredPattern!),
            ),
            const SizedBox(width: 8),
            Text(
              'Pattern: ${_patternData!.triggeredPattern!.toUpperCase()}',
              style: TextStyle(
                color: _getPatternColor(_patternData!.triggeredPattern!),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard() {
    if (_patternData!.alert == 'No data available') {
      return Card(
        elevation: 0,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'No alert data available',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.blue.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alert:',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _patternData!.alert!,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastAnalyzedCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 20,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              'Last Analyzed: ${_formatDate(_patternData!.lastAnalysisTime!)}',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getRiskColor(String riskLevel) {
    if (riskLevel == 'Unknown' || riskLevel == 'No data') {
      return Colors.grey.shade700;
    }
    return widget.barangayColor;
  }

  Color _getPatternColor(String pattern) {
    if (pattern == 'No data') {
      return Colors.grey.shade700;
    }
    switch (pattern.toLowerCase()) {
      case 'stability':
        return Colors.blue.shade600;
      case 'spike':
        return Colors.deepOrange.shade600;
      case 'decline':
        return Colors.lightGreen.shade600;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildWeatherInfo(IconData icon, String label, String value, bool isOptimal) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: isOptimal ? Colors.green : Colors.blue,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isOptimal ? Colors.green : Colors.black,
          ),
        ),
      ],
    );
  }
}
