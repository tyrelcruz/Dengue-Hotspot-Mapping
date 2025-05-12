import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';

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
  PatternRecognitionData? _patternData;
  bool _isLoading = false;
  String? _error;
  bool _isDengueExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchPatternData();
  }

  @override
  void didUpdateWidget(RecommendationsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.selectedBarangay != widget.selectedBarangay) {
      print(
          'Location changed: ${widget.selectedBarangay} (${widget.latitude}, ${widget.longitude})');
      _fetchPatternData();
    }
  }

  Future<void> _fetchPatternData() async {
    try {
      print('Fetching pattern recognition data');
      print('Selected barangay: ${widget.selectedBarangay}');

      final response = await http.get(
        Uri.parse(
            '${Config.baseUrl}/api/v1/analytics/retrieve-pattern-recognition-results'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Pattern API Response Status: ${response.statusCode}');
      print('Pattern API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true &&
            data['data'] != null &&
            data['data'].isNotEmpty) {
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
                triggeredPattern:
                    barangayData['triggered_pattern'] ?? 'No data',
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
          color: _getPatternColor(_patternData!.triggeredPattern!)
              .withOpacity(0.3),
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
            Expanded(
              child: Text(
                'Last Analyzed: ${_formatDate(_patternData!.lastAnalysisTime!)}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
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
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateString;
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
                _fetchPatternData();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_patternData == null) {
      return const Center(child: Text('No data available'));
    }

    return Column(
      children: [
        // Dengue Risk Assessment Card
        GestureDetector(
          onTap: () {
            setState(() {
              _isDengueExpanded = !_isDengueExpanded;
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
                                  color: _getRiskColor(_patternData!.riskLevel)
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    'i',
                                    style: TextStyle(
                                      color: _getRiskColor(
                                          _patternData!.riskLevel),
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
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRiskColor(_patternData!.riskLevel)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getRiskColor(_patternData!.riskLevel)
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                _patternData!.riskLevel.toUpperCase(),
                                style: TextStyle(
                                  color: _getRiskColor(_patternData!.riskLevel),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_isDengueExpanded) ...[
                        const SizedBox(height: 16),
                        if (_patternData!.triggeredPattern != null)
                          _buildPatternCard(),
                        if (_patternData!.alert != null) _buildAlertCard(),
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
      ],
    );
  }
}
