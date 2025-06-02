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
  final Map<String, dynamic>? statusAndRecommendation;

  PatternRecognitionData({
    required this.name,
    required this.riskLevel,
    this.alert,
    this.lastAnalysisTime,
    this.triggeredPattern,
    this.statusAndRecommendation,
  });

  factory PatternRecognitionData.fromJson(Map<String, dynamic> json) {
    return PatternRecognitionData(
      name: json['name'] ?? '',
      riskLevel: json['risk_level'] ?? 'Unknown',
      alert: json['status_and_recommendation']?['pattern_based']?['alert'] ??
          'No alerts triggered.',
      lastAnalysisTime: json['last_analysis_time'],
      triggeredPattern:
          json['status_and_recommendation']?['pattern_based']?['status'] ?? '',
      statusAndRecommendation: json['status_and_recommendation'],
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
        Uri.parse('${Config.baseUrl}/api/v1/barangays/get-all-barangays'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Pattern API Response Status: ${response.statusCode}');
      print('Pattern API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          // Find the matching barangay data
          final barangayName = widget.selectedBarangay.toLowerCase();
          print('Searching for barangay: $barangayName');

          final barangayData = data.firstWhere(
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
              _patternData = PatternRecognitionData.fromJson(barangayData);
            });
          } else {
            print('No matching barangay data found');
            // Set default pattern data if no match found
            setState(() {
              _patternData = PatternRecognitionData(
                name: barangayName,
                riskLevel: 'Low',
                alert: 'No alerts triggered.',
                lastAnalysisTime: DateTime.now().toIso8601String(),
                triggeredPattern: '',
                statusAndRecommendation: {
                  'pattern_based': {
                    'status': '',
                    'alert': 'No alerts triggered.',
                    'recommendation': ''
                  }
                },
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
          alert: 'No alerts triggered.',
          lastAnalysisTime: DateTime.now().toIso8601String(),
          triggeredPattern: '',
          statusAndRecommendation: {
            'pattern_based': {
              'status': '',
              'alert': 'No alerts triggered.',
              'recommendation': ''
            }
          },
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
      case 'stable':
      case 'stability':
      case 'stable_pattern':
        return Colors.lightBlue.shade600;
      case 'spike':
      case 'spike_pattern':
        return Colors.red.shade700;
      case 'gradual rise':
      case 'gradual_rise':
        return Colors.orange.shade500;
      case 'decline':
      case 'decline_pattern':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade700;
    }
  }

  String displayPattern(String pattern) {
    if (pattern.toLowerCase() == 'stability') return 'Stable';
    if (pattern.isEmpty) return '';
    return pattern[0].toUpperCase() + pattern.substring(1);
  }

  Widget _buildPatternCard() {
    if (_patternData!.triggeredPattern == null ||
        _patternData!.triggeredPattern!.isEmpty) {
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

    // Use displayPattern for user-facing text
    String displayPatternText = displayPattern(_patternData!.triggeredPattern!);

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
              'Pattern: $displayPatternText',
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
    if (_patternData!.alert == null || _patternData!.alert!.isEmpty) {
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
    if (_patternData!.lastAnalysisTime == null ||
        _patternData!.lastAnalysisTime!.isEmpty) {
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
                'Last analysis time not available',
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

  List<Widget> _getPreventiveActions(String riskLevel) {
    final actions = <Widget>[];

    switch (riskLevel.toLowerCase()) {
      case 'high':
        actions.addAll([
          _buildActionItem(
              '1. Conduct daily inspection and elimination of mosquito breeding sites'),
          _buildActionItem(
              '2. Use mosquito repellent and wear protective clothing'),
          _buildActionItem('3. Install window and door screens'),
          _buildActionItem(
              '4. Seek immediate medical attention if symptoms appear'),
          _buildActionItem('5. Support community-wide fogging operations'),
        ]);
        break;
      case 'moderate':
        actions.addAll([
          _buildActionItem(
              '1. Check and clean potential breeding sites weekly'),
          _buildActionItem('2. Use mosquito repellent when outdoors'),
          _buildActionItem(
              '3. Keep doors and windows closed during peak mosquito hours'),
          _buildActionItem('4. Monitor for dengue symptoms'),
          _buildActionItem('5. Participate in community clean-up drives'),
        ]);
        break;
      case 'low':
        actions.addAll([
          _buildActionItem('1. Maintain regular cleaning of surroundings'),
          _buildActionItem('2. Keep water containers covered'),
          _buildActionItem('3. Use mosquito nets if needed'),
          _buildActionItem('4. Stay informed about dengue prevention'),
          _buildActionItem('5. Report any potential breeding sites'),
        ]);
        break;
      default:
        actions.add(
          _buildActionItem(
              'No specific preventive actions available for this risk level'),
        );
    }

    return actions;
  }

  Widget _buildActionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
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
                    color: _getPatternColor(
                        _patternData!.triggeredPattern ?? 'No data'),
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
                                  color: _getPatternColor(
                                          _patternData!.triggeredPattern ??
                                              'No data')
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    'i',
                                    style: TextStyle(
                                      color: _getPatternColor(
                                          _patternData!.triggeredPattern ??
                                              'No data'),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Dengue Pattern Assessment',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
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
                        const SizedBox(height: 16),
                        // Add preventive actions based on risk level
                        Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.shield_outlined,
                                      size: 20,
                                      color: Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Preventive Actions',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ..._getPreventiveActions(
                                    _patternData!.riskLevel),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Add notes about using tabs and clicking barangays
        Card(
          elevation: 0,
          color: Colors.white,
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
                  Icons.tips_and_updates_outlined,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'For a comprehensive dengue risk assessment, check the risk levels and patterns above.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Colors.white,
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
                  Icons.touch_app_outlined,
                  size: 20,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Click on any barangay on the map to view its detailed risk assessment and recommendations.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
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
