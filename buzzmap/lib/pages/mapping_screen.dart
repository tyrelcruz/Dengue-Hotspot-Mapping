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
  double _mapRotation = 0.0;

  String? selectedDistrict;
  String? selectedBarangay;

  // District and barangay data
  final Map<String, List<String>> districtData = {
    'District I': ['Bahay Toro', 'Balingasa', 'Damar', 'Katipunan', 'Mariblo'],
    'District II': ['Baesa', 'Balumbato', 'Sangandaan', 'Unang Sigaw'],
    'District III': [
      'Amihan',
      'Bagbag',
      'Claro',
      'Masambong',
      'San Isidro Labrador'
    ],
    'District IV': ['Bagong Lipunan', 'Dona Josefa', 'Mariblo', 'San Jose'],
    'District V': ['Bagong Silangan', 'Commonwealth', 'Fairview', 'Payatas'],
    'District VI': [
      'Batasan Hills',
      'Holy Spirit',
      'Matandang Balara',
      'Pasong Tamo'
    ],
  };

  final Map<String, LatLng> locationData = {
    'Bahay Toro': LatLng(14.6572, 121.0214),
    'Balingasa': LatLng(14.6482, 120.9978),
    'Damar': LatLng(14.6523, 121.0112),
    'Katipunan': LatLng(14.6392, 121.0744),
    'Mariblo': LatLng(14.6581, 121.0045),
    'Baesa': LatLng(14.6743, 121.0131),
    'Balumbato': LatLng(14.6760, 121.0437),
    'Sangandaan': LatLng(14.6556, 121.0053),
    'Unang Sigaw': LatLng(14.6611, 121.0172),
    'Amihan': LatLng(14.6467, 121.0491),
    'Bagbag': LatLng(14.7000, 121.0500),
    'Claro': LatLng(14.6512, 121.0367),
    'Masambong': LatLng(14.6461, 121.0133),
    'San Isidro Labrador': LatLng(14.6437, 121.0231),
    'Bagong Lipunan': LatLng(14.6386, 121.0376),
    'Dona Josefa': LatLng(14.6413, 121.0416),
    'San Jose': LatLng(14.6288, 121.0343),
    'Bagong Silangan': LatLng(14.6731, 121.1067),
    'Commonwealth': LatLng(14.6903, 121.0819),
    'Fairview': LatLng(14.6300, 121.0400),
    'Payatas': LatLng(14.7015, 121.0965),
    'Batasan Hills': LatLng(14.6831, 121.0912),
    'Holy Spirit': LatLng(14.6694, 121.0777),
    'Matandang Balara': LatLng(14.6574, 121.0823),
    'Pasong Tamo': LatLng(14.6499, 121.0693),
  };

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
                  color: Colors.white,
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
                        color: Color.fromRGBO(102, 255, 102, 1.0)),
                  ),
                  const TextSpan(text: 'to view reports.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// Method to build the district and barangay dropdowns in a row
  Widget _buildLocationSelector(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 56.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDistrictDropdown(context, colorScheme),
          const SizedBox(width: 16), // Add space between the dropdowns
          _buildBarangayDropdown(context, colorScheme),
        ],
      ),
    );
  }

  // Method to build the district dropdown
  Widget _buildDistrictDropdown(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: 150,
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
          value: selectedDistrict, // Display the selected district
          items: districtData.keys.map((district) {
            return DropdownMenuItem<String>(
              value: district,
              child: Text(district),
            );
          }).toList(),
          onChanged: (selectedDistrict) {
            setState(() {
              this.selectedDistrict = selectedDistrict;
              this.selectedBarangay =
                  null; // Reset barangay when district changes
            });
          },
          hint: const Text(
            'Select District',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  // Method to build the barangay dropdown
  Widget _buildBarangayDropdown(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: 150,
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
          value: selectedBarangay, // Display the selected barangay
          items: selectedDistrict != null
              ? districtData[selectedDistrict]!.map((barangay) {
                  return DropdownMenuItem<String>(
                    value: barangay,
                    child: Text(barangay),
                  );
                }).toList()
              : [],
          onChanged: (selectedBarangay) {
            setState(() {
              this.selectedBarangay = selectedBarangay;
              // Navigate to location details screen if both are selected
              if (selectedDistrict != null && selectedBarangay != null) {
                final coordinates = locationData[selectedBarangay];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationDetailsScreen(
                      location: selectedBarangay!,
                      latitude: coordinates!.latitude,
                      longitude: coordinates.longitude,
                    ),
                  ),
                );
              }
            });
          },
          hint: const Text(
            'Select Barangay',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  // Method to show details (remains unchanged)
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
                // Navigate to the location details screen when 'Show More' is clicked
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationDetailsScreen(
                      location: location,
                      latitude: coordinates.latitude,
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
  }

  // Build marker (remains unchanged)
  Marker _buildMarker(BuildContext context, LatLng position, String location,
      int caseCount, String highestSeverity, double mapRotation) {
    return Marker(
      width: 50.0,
      height: 50.0,
      point: position,
      child: Transform.rotate(
        angle: mapRotation,
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
