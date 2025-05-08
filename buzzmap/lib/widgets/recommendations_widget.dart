import 'package:flutter/material.dart';

Widget buildRecommendations(
    String severity, Map<String, String> hazardRiskLevels) {
  List<String> recommendations = [];
  String pattern = hazardRiskLevels['Pattern']?.toLowerCase() ?? '';
  String riskLevel = severity.toLowerCase();

  // Base recommendations based on risk level
  if (riskLevel == 'high') {
    recommendations = [
      '🚨 URGENT COMMUNITY ACTIONS NEEDED',
      '• Check and clean ALL water containers daily',
      '• Cover water storage containers tightly',
      '• Clean roof gutters and drains regularly',
      '• Use mosquito nets while sleeping',
      '• Apply mosquito repellent when outdoors',
      '• Wear long-sleeved clothes and pants',
      '• Keep doors and windows closed during peak mosquito hours',
      '• Organize community clean-up drives',
      '• Share dengue prevention tips with neighbors',
      '• Monitor family members for dengue symptoms',
    ];
  } else if (riskLevel == 'moderate') {
    recommendations = [
      '⚠️ INCREASE PREVENTION MEASURES',
      '• Check water containers every 2-3 days',
      '• Clean and scrub water storage containers',
      '• Remove or cover items that can collect water',
      '• Use mosquito repellent when going outside',
      '• Wear protective clothing during peak hours',
      '• Keep your surroundings clean and dry',
      '• Join community awareness programs',
      '• Share prevention tips with family and friends',
    ];
  } else if (riskLevel == 'low') {
    recommendations = [
      '✅ MAINTAIN PREVENTION HABITS',
      '• Weekly check of water containers',
      '• Keep containers covered when not in use',
      '• Maintain clean surroundings',
      '• Use mosquito repellent when needed',
      '• Stay informed about dengue prevention',
      '• Participate in community clean-up activities',
      '• Share prevention knowledge with others',
    ];
  } else if (riskLevel == 'no data') {
    recommendations = [
      'ℹ️ GENERAL PREVENTION TIPS',
      '• Regularly check for standing water',
      '• Keep water containers covered',
      '• Maintain clean surroundings',
      '• Use mosquito repellent when outdoors',
      '• Stay updated on local dengue situation',
      '• Share prevention tips with community',
    ];
  }

  // Add pattern-specific recommendations
  if (pattern == 'stability') {
    recommendations.addAll([
      '📊 MAINTAINING STABLE CONDITIONS',
      '• Continue your current prevention routine',
      '• Keep community awareness active',
      '• Share successful prevention methods',
      '• Stay connected with neighbors for updates',
    ]);
  } else if (pattern == 'spike') {
    recommendations.addAll([
      '📈 RESPONDING TO INCREASED RISK',
      '• Increase frequency of water container checks',
      '• Organize immediate community clean-up',
      '• Share urgent prevention tips with neighbors',
      '• Monitor family health more closely',
      '• Stay updated with local health advisories',
    ]);
  } else if (pattern == 'decline') {
    recommendations.addAll([
      '📉 MAINTAINING IMPROVEMENT',
      '• Continue your prevention practices',
      '• Share successful prevention methods',
      '• Keep community awareness high',
      '• Document what worked for future reference',
    ]);
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Recommendation List
      ...recommendations.map((rec) {
        if (rec.startsWith('•')) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(rec.substring(2))),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            child: Text(
              rec,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          );
        }
      }).toList(),

      const SizedBox(height: 16),

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
      'iconColor': Colors.red.shade700,
    },
    {
      'icon': Icons.local_hospital,
      'title': 'Dengue Infection Risk',
      'iconColor': Colors.red.shade700,
    },
    {
      'icon': Icons.home,
      'title': 'Home Safety Status',
      'iconColor': Colors.blue.shade600,
    },
  ];

  final pattern = hazardRiskLevels['Pattern']?.toLowerCase() ?? '';
  final riskLevel = hazardRiskLevels['RiskLevel']?.toLowerCase() ?? 'no data';

  return Column(
    children: dengueHazardData.map((hazard) {
      final title = hazard['title'] as String;
      Color riskColor;
      String displayStatus;

      // If no data is available
      if (riskLevel == 'no data') {
        riskColor = Colors.grey.shade700;
        displayStatus = 'NO DATA';
      }
      // If high risk
      else if (riskLevel == 'high') {
        riskColor = Colors.red.shade700;
        displayStatus = 'HIGH';
      }
      // If low risk, check pattern
      else if (riskLevel == 'low') {
        if (pattern == 'stability') {
          riskColor = Colors.blue.shade600;
          displayStatus = 'STABLE';
        } else if (pattern == 'spike') {
          riskColor = Colors.orange.shade600;
          displayStatus = 'SPIKE';
        } else if (pattern == 'decline') {
          riskColor = Colors.green.shade600;
          displayStatus = 'DECLINE';
        } else {
          riskColor = Colors.green.shade600;
          displayStatus = 'LOW';
        }
      }
      // For moderate risk
      else if (riskLevel == 'moderate') {
        if (pattern == 'spike') {
          riskColor = Colors.orange.shade600;
          displayStatus = 'SPIKE';
        } else {
          riskColor = Colors.orange.shade500;
          displayStatus = 'MODERATE';
        }
      } else {
        riskColor = Colors.grey.shade400;
        displayStatus = 'UNKNOWN';
      }

      final iconColor = hazard['iconColor'] as Color;

      return InkWell(
        onTap: () {
          debugPrint('Tapped on $title');
        },
        child: Card(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: riskColor.withOpacity(0.3),
              width: 1,
            ),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        hazard['icon'] as IconData,
                        size: 28,
                        color: iconColor,
                      ),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: riskColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: riskColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              displayStatus,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: riskColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.info_outline,
                      color: riskColor.withOpacity(0.7),
                    ),
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
