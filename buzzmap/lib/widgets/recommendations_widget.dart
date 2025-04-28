import 'package:flutter/material.dart';

Widget buildRecommendations(
    String severity, Map<String, String> hazardRiskLevels) {
  List<String> recommendations;

  if (severity == 'Severe') {
    recommendations = [
      'Eliminate all standing water sources immediately',
      'Use mosquito repellent at all times',
      'Install mosquito screens on all windows',
      'Consider community fogging operations',
      'Watch for fever and other dengue symptoms'
    ];
  } else if (severity == 'Moderate') {
    recommendations = [
      'Regularly check and empty water containers',
      'Use mosquito repellent when outdoors',
      'Wear long-sleeved clothes',
      'Be alert for dengue symptoms'
    ];
  } else if (severity == 'Low') {
    recommendations = [
      'Keep surroundings clean',
      'Remove potential water collection points',
      'Use mosquito repellent when necessary'
    ];
  } else {
    recommendations = [
      'Maintain cleanliness in your surroundings',
      'Be cautious about standing water'
    ];
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Recommendation List
      ...recommendations
          .map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(rec)),
                  ],
                ),
              ))
          .toList(),

      const SizedBox(height: 16), // Space

      // Dynamic Hazard Cards
      _buildDengueHazardCards(hazardRiskLevels),
    ],
  );
}

Widget _buildDengueHazardCards(Map<String, String> hazardRiskLevels) {
  final dengueHazardData = [
    {
      'icon': Icons.bug_report,
      'title': 'Mosquito Breeding Risk',
    },
    {
      'icon': Icons.local_hospital,
      'title': 'Dengue Infection Risk',
    },
    {
      'icon': Icons.home,
      'title': 'Home Safety Status',
    },
  ];

  return Column(
    children: dengueHazardData.map((hazard) {
      final title = hazard['title'] as String;
      final riskLevel = hazardRiskLevels[title] ?? 'UNKNOWN';
      final riskColor = _getRiskColor(riskLevel);

      return InkWell(
        onTap: () {
          debugPrint('Tapped on $title');
        },
        child: Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 5,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      hazard['icon'] as IconData,
                      size: 36,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            riskLevel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: riskColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.info_outline, color: Colors.black),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}

Color _getRiskColor(String riskLevel) {
  switch (riskLevel.toUpperCase()) {
    case 'HIGH':
      return Colors.red;
    case 'MODERATE':
      return Colors.orange;
    case 'LOW':
      return Colors.green;
    default:
      return Colors.grey;
  }
}
