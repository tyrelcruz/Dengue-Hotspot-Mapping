import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';
import 'package:buzzmap/pages/location_details_screen.dart';

class MappingScreen extends StatefulWidget {
  const MappingScreen({super.key});

  @override
  State<MappingScreen> createState() => _MappingScreenState();
}

class _MappingScreenState extends State<MappingScreen> {
  final MapController _mapController = MapController();
  double _mapRotation = 0.0; // Track the map's rotation

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          key: Key('mapping_appbar'),
          title: 'Mapping',
          currentRoute: '/mapping',
          themeMode: 'dark',
        ),
      ),
      body: Column(
        children: [
          Column(
            children: [
              const Text(
                'CHECK YOUR PLACE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Koulen',
                  fontSize: 46,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const Text(
                'Stay Protected. Look out for Dengue Outbreaks.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              _buildLocationSelector(context, colorScheme),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.67,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(14.6507, 121.0495),
                    initialZoom: 12.6,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    ),
                    MarkerLayer(
                      markers: [
                        _buildMarker(
                          context,
                          LatLng(14.674376, 121.013138),
                          'Baesa',
                          25,
                          'Severe',
                          _mapRotation,
                        ),
                        _buildMarker(
                          context,
                          LatLng(14.6760, 121.0437),
                          'Fairview',
                          12,
                          'Moderate',
                          _mapRotation,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white, // Default text color
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  const TextSpan(
                    text: 'NOTE: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: 'Click on the '),
                  TextSpan(
                    text: 'GREEN LOCATION ICON. ',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(102, 255, 102, 1.0) // Fixed here
                        ),
                  ),
                  const TextSpan(text: 'to view reports.'),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Marker _buildMarker(BuildContext context, LatLng position, String location,
      int caseCount, String highestSeverity, double mapRotation) {
    return Marker(
      width: 50.0,
      height: 50.0,
      point: position,
      child: Transform.rotate(
        angle: mapRotation, // Apply the map's rotation to the marker
        child: GestureDetector(
          onTap: () => _showDengueDetails(
              context, location, caseCount, highestSeverity, position),
          child: Image.asset(
            'assets/images/Marker.png',
            width: 50,
            height: 50,
          ),
        ),
      ),
    );
  }
}

void _showDengueDetails(BuildContext context, String location, int caseCount,
    String highestSeverity, LatLng coordinates) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Dengue Alert: $location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 Location: $location'),
            Text('🔢 Cases Reported: $caseCount'),
            Text('⚠️ Highest Severity: $highestSeverity'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LocationDetailsScreen(
                    location: location,
                    latitude: coordinates.latitude, // Ensure this is passed
                    longitude: coordinates.longitude,
                  ),
                ),
              );
            },
            child: const Text('Show More'),
          ),
        ],
      );
    },
  );

  Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(
              text: 'NOTE: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: 'Click on the '),
            TextSpan(
              text: 'GREEN LOCATION ICON.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' to view reports.'),
          ],
        ),
      ));
}

Widget _buildLocationSelector(BuildContext context, ColorScheme colorScheme) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 56.0),
    child: SizedBox(
      width: 262,
      height: 34,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
        ),
        child: DropdownButton<String>(
          isExpanded: true,
          padding: EdgeInsets.zero,
          dropdownColor: const Color.fromRGBO(36, 82, 97, 1),
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          iconSize: 24,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontFamily: 'Inter',
          ),
          items: <String>[
            'Baesa',
            'Balombato',
            'Bagbag',
            'Fairview',
            'Sangandaan'
          ].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (selectedLocation) {
            if (selectedLocation != null) {
              final locationData = {
                'Baesa': LatLng(14.6507, 121.0495),
                'Balumbato': LatLng(14.645264, 120.990118),
                'Fairview': LatLng(14.6760, 121.0437),
                'Bagbag': LatLng(14.7000, 121.0500),
                'Sangandaan': LatLng(14.6300, 121.0400),
              };

              final coordinates = locationData[selectedLocation];

              if (coordinates != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationDetailsScreen(
                      location: selectedLocation,
                      latitude: coordinates.latitude,
                      longitude: coordinates.longitude,
                    ),
                  ),
                );
              }
            }
          },
          hint: const Text(
            'Quezon City',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    ),
  );
}
