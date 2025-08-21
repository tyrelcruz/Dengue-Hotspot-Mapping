import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';
import 'package:url_launcher/url_launcher.dart';

class PatternRecognitionData {
  final String name;
  final String riskLevel;
  final String? alert;
  final String? lastAnalysisTime;
  final String? triggeredPattern;
  final Map<String, dynamic>? statusAndRecommendation;
  final String? userRecommendation;

  PatternRecognitionData({
    required this.name,
    required this.riskLevel,
    this.alert,
    this.lastAnalysisTime,
    this.triggeredPattern,
    this.statusAndRecommendation,
    this.userRecommendation,
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
      userRecommendation: json['status_and_recommendation']?['pattern_based']
              ?['user_recommendation'] ??
          '',
    );
  }
}

class RecommendationData {
  final String recommendation;
  final List<String> factors;
  final String summary;
  final List<Map<String, String>> sources;
  final String pattern;
  final int reports;
  final int deaths;
  final String message;

  RecommendationData({
    required this.recommendation,
    required this.factors,
    required this.summary,
    required this.sources,
    required this.pattern,
    required this.reports,
    required this.deaths,
    required this.message,
  });

  factory RecommendationData.fromJson(Map<String, dynamic> json) {
    return RecommendationData(
      recommendation: json['recommendation'] ?? '',
      factors: List<String>.from(json['factors'] ?? []),
      summary: json['summary'] ?? '',
      sources: (json['sources'] as List<dynamic>?)
              ?.map((source) => Map<String, String>.from(source))
              .toList() ??
          [],
      pattern: json['pattern'] ?? '',
      reports: json['reports'] ?? 0,
      deaths: json['deaths'] ?? 0,
      message: json['message'] ?? '',
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
  RecommendationData? _recommendationData;
  bool _isLoading = false;
  String? _error;
  bool _isDengueExpanded = false;
  bool _showSources = false;

  @override
  void initState() {
    super.initState();
    _fetchPatternData();
    _fetchRecommendationData();
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
      _fetchRecommendationData();
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
                userRecommendation: '',
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
          userRecommendation: '',
        );
      });
    }
  }

  Future<void> _fetchRecommendationData() async {
    try {
      print('Fetching recommendation data for: ${widget.selectedBarangay}');

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/api/v1/analytics/generate-recommendation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userRole': 'user',
          'barangay': widget.selectedBarangay,
        }),
      );

      print('Recommendation API Response Status: ${response.statusCode}');
      print('Recommendation API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _recommendationData = RecommendationData.fromJson(data);
        });
        print('Recommendation data loaded successfully');
      } else {
        print('Failed to fetch recommendation data: ${response.statusCode}');
        // Set default recommendation data on error
        setState(() {
          _recommendationData = RecommendationData(
            recommendation: '',
            factors: [],
            summary: 'Unable to load recommendations at this time.',
            sources: [],
            pattern: '',
            reports: 0,
            deaths: 0,
            message: 'Failed to load recommendations',
          );
        });
      }
    } catch (e) {
      print('Error fetching recommendation data: $e');
      // Set default recommendation data on error
      setState(() {
        _recommendationData = RecommendationData(
          recommendation: '',
          factors: [],
          summary: 'Unable to load recommendations at this time.',
          sources: [],
          pattern: '',
          reports: 0,
          deaths: 0,
          message: 'Error loading recommendations',
        );
      });
    }
  }

  Future<void> _launchSourceUrl(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return;
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    } catch (_) {}
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

    if (_recommendationData?.summary != null &&
        _recommendationData!.summary.isNotEmpty) {
      // Use the summary from the API as the main preventive action
      actions.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _recommendationData!.summary,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      );

      // Add additional context if available
      if (_recommendationData!.factors.isNotEmpty) {
        actions.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              'Key Factors Considered:',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        );

        for (var factor in _recommendationData!.factors.take(3)) {
          actions.add(_buildActionItem('• $factor'));
        }
      }
    } else if (_recommendationData == null) {
      // Show a single centered loading indicator under the header
      actions.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Column(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Generating AI Recommendations...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Fallback to default recommendations if no API data is available
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

  Widget _buildSourcesSection() {
    if (_recommendationData?.sources == null ||
        _recommendationData!.sources.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.source,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'Sources',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _showSources = !_showSources;
                });
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _showSources ? 'Hide' : 'Show',
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        if (_showSources) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _recommendationData!.sources.map((source) {
              final title = source['title'] ?? 'Source';
              final uri = source['uri'] ?? '';
              return ActionChip(
                label: Text(
                  title,
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: Colors.grey.shade100,
                side: BorderSide(color: Colors.grey.shade300),
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () => _launchSourceUrl(uri),
              );
            }).toList(),
          ),
        ],
      ],
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
                _fetchRecommendationData();
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
                        SizedBox(
                          height:
                              300, // Fixed height for the scrollable content
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_patternData!.triggeredPattern != null)
                                  _buildPatternCard(),
                                if (_patternData!.alert != null)
                                  _buildAlertCard(),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        _buildSourcesSection(),
                                      ],
                                    ),
                                  ),
                                ),
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
      ],
    );
  }
}
