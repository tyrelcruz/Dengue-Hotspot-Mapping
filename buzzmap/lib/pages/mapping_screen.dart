import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';
import 'package:buzzmap/pages/location_details_screen.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:buzzmap/pages/location_details_screen.dart';

class MappingScreen extends StatefulWidget {
  const MappingScreen({super.key});

  @override
  State<MappingScreen> createState() => _MappingScreenState();
}

class _MappingScreenState extends State<MappingScreen> {
  GoogleMapController? _mapController;
  String? selectedDistrict;
  String? selectedBarangay;
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  Set<Polygon> _barangayPolygons = {};
  bool _showHeatmap = true;
  bool _showBorders = true;
  bool _isLoading = true;

  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(14.6507, 121.0495),
    zoom: 12.6,
  );

  // Layer control options
  final Map<String, bool> _layerOptions = {
    'Heatmap': true,
    'Borders': true,
    'Markers': true,
  };

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

  // Dengue case data for each barangay
  final Map<String, Map<String, dynamic>> dengueData = {
    'Baesa': {'cases': 25, 'severity': 'Severe'},
    'Fairview': {'cases': 12, 'severity': 'Moderate'},
    'Bahay Toro': {'cases': 18, 'severity': 'Moderate'},
    'Balingasa': {'cases': 8, 'severity': 'Low'},
    'Damar': {'cases': 15, 'severity': 'Moderate'},
    'Katipunan': {'cases': 5, 'severity': 'Low'},
    'Mariblo': {'cases': 22, 'severity': 'Severe'},
    'Balumbato': {'cases': 10, 'severity': 'Moderate'},
    'Sangandaan': {'cases': 19, 'severity': 'Moderate'},
    'Unang Sigaw': {'cases': 7, 'severity': 'Low'},
    'Amihan': {'cases': 14, 'severity': 'Moderate'},
    'Bagbag': {'cases': 28, 'severity': 'Severe'},
    'Claro': {'cases': 3, 'severity': 'Low'},
    'Masambong': {'cases': 11, 'severity': 'Moderate'},
    'San Isidro Labrador': {'cases': 16, 'severity': 'Moderate'},
    'Bagong Lipunan': {'cases': 9, 'severity': 'Low'},
    'Dona Josefa': {'cases': 13, 'severity': 'Moderate'},
    'San Jose': {'cases': 6, 'severity': 'Low'},
    'Bagong Silangan': {'cases': 21, 'severity': 'Severe'},
    'Commonwealth': {'cases': 32, 'severity': 'Severe'},
    'Payatas': {'cases': 24, 'severity': 'Severe'},
    'Batasan Hills': {'cases': 27, 'severity': 'Severe'},
    'Holy Spirit': {'cases': 17, 'severity': 'Moderate'},
    'Matandang Balara': {'cases': 20, 'severity': 'Moderate'},
    'Pasong Tamo': {'cases': 4, 'severity': 'Low'},
  };

  // Barangay boundary data - coordinates for polygon borders
  final Map<String, List<LatLng>> barangayBoundaries = {
    'Bahay Toro': [
      LatLng(14.6572, 121.0214),
      LatLng(14.6612, 121.0254),
      LatLng(14.6592, 121.0314),
      LatLng(14.6532, 121.0284),
      LatLng(14.6532, 121.0214),
    ],
    'Balingasa': [
      LatLng(14.6482, 120.9978),
      LatLng(14.6522, 121.0018),
      LatLng(14.6492, 121.0078),
      LatLng(14.6452, 121.0048),
      LatLng(14.6442, 120.9988),
    ],
    // Other barangay boundaries remain unchanged
    // ... [For brevity, other boundaries are not repeated]
  };

  Future<void> _loadGeoJsonPolygons() async {
    try {
      final String data =
          await rootBundle.loadString('assets/geo/barangays.geojson');
      final geo = json.decode(data);

      Set<Polygon> loadedPolygons = {};

      for (final feature in geo['features']) {
        final String name = feature['properties']['name'];
        final severity = dengueData[name]?['severity'] ?? 'Unknown';

        final color = _getColorForSeverity(severity);

        final coords = feature['geometry']['coordinates'][0]
            .map<LatLng>(
                (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
            .toList();

        loadedPolygons.add(
          Polygon(
            polygonId: PolygonId(name),
            points: coords,
            strokeColor: color,
            strokeWidth: 1,
            fillColor: color.withOpacity(0.3),
          ),
        );
      }

      setState(() {
        _barangayPolygons = loadedPolygons;
        _polygons = _polygons.union(_barangayPolygons);
      });
    } catch (e) {
      print('Error loading GeoJSON: $e');
      // Continue with the hardcoded boundaries if GeoJSON fails
    }
  }

  @override
  void initState() {
    super.initState();
    // Call the GeoJSON loading function
    _loadGeoJsonPolygons();

    // Using a slight delay to ensure Google Maps is fully loaded
    Timer(const Duration(milliseconds: 500), () {
      _updateMapLayers();
      setState(() {
        _isLoading = false;
      });
    });
  }

  Color _getColorForCases(int cases) {
    if (cases >= 25) {
      return Colors.red.withOpacity(0.7);
    } else if (cases >= 15) {
      return Colors.orange.withOpacity(0.7);
    } else if (cases >= 8) {
      return Colors.yellow.withOpacity(0.6);
    } else {
      return Colors.green.withOpacity(0.5);
    }
  }

  Color _getColorForSeverity(String severity) {
    switch (severity) {
      case 'Low':
        return Colors.green;
      case 'Moderate':
        return Colors.yellow;
      case 'High':
        return Colors.orange;
      case 'Severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  double _getRadiusForCases(int cases) {
    // Base radius on case count with min and max limits
    return min(max(cases * 15.0, 150.0), 400.0);
  }

  void _updateMapLayers() {
    Set<Circle> circles = {};
    Set<Marker> markers = {};
    Set<Polygon> polygons = {};

    // Process each barangay's data
    dengueData.forEach((barangay, data) {
      final latLng = locationData[barangay];
      final cases = data['cases'] as int;
      final severity = data['severity'] as String;
      final boundaries = barangayBoundaries[barangay];

      if (latLng != null) {
        // Only add circles if heatmap is enabled
        if (_layerOptions['Heatmap']!) {
          circles.add(
            Circle(
              circleId: CircleId(barangay),
              center: latLng,
              radius: _getRadiusForCases(cases),
              fillColor: _getColorForCases(cases),
              strokeWidth: 0,
            ),
          );
        }

        // Only add markers if markers are enabled
        if (_layerOptions['Markers']!) {
          markers.add(
            Marker(
              markerId: MarkerId(barangay),
              position: latLng,
              onTap: () => _showDengueDetails(
                context,
                barangay,
                cases,
                severity,
                latLng,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _getSeverityHue(severity),
              ),
            ),
          );
        }

        // Add polygon borders if borders are enabled and we have boundary data
        if (_layerOptions['Borders']! && boundaries != null) {
          final color = _getColorForCases(cases);
          polygons.add(
            Polygon(
              polygonId: PolygonId('border_$barangay'),
              points: boundaries,
              strokeWidth: 2,
              strokeColor: Colors.black54,
              fillColor: color.withOpacity(0.5),
              consumeTapEvents: true,
              onTap: () => _showDengueDetails(
                context,
                barangay,
                cases,
                severity,
                latLng,
              ),
            ),
          );
        }
      }
    });

    // Add GeoJSON polygons if available
    if (_layerOptions['Borders']! && _barangayPolygons.isNotEmpty) {
      polygons = polygons.union(_barangayPolygons);
    }

    setState(() {
      _circles = circles;
      _markers = markers;
      _polygons = polygons;
    });
  }

  double _getSeverityHue(String severity) {
    switch (severity) {
      case 'Severe':
        return BitmapDescriptor.hueRed;
      case 'Moderate':
        return BitmapDescriptor.hueOrange;
      case 'Low':
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

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
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
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
          _buildHeatmapLegend(),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: _initialCameraPosition,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      circles: _circles,
                      markers: _markers,
                      polygons: _polygons,
                      myLocationEnabled: false,
                      zoomControlsEnabled: true,
                      mapToolbarEnabled: false,
                    ),
                    if (_isLoading)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text('Loading map data...'),
                            ],
                          ),
                        ),
                      ),
                    _buildLayerControls(),
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
                  const TextSpan(text: 'NOTE: '),
                  const TextSpan(text: 'Click on '),
                  TextSpan(
                    text: _getInteractionText(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(102, 255, 102, 1.0),
                    ),
                  ),
                  const TextSpan(text: ' to view dengue reports.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInteractionText() {
    List<String> interactionElements = [];

    if (_layerOptions['Markers']!) {
      interactionElements.add('MARKERS');
    }

    if (_layerOptions['Borders']!) {
      interactionElements.add('BORDERED AREAS');
    }

    if (_layerOptions['Heatmap']!) {
      interactionElements.add('COLORED AREAS');
    }

    if (interactionElements.isEmpty) {
      return 'the MAP';
    }

    return interactionElements.join(' or ');
  }

  Widget _buildLayerControls() {
    return Positioned(
      top: 12,
      right: 12,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.layers),
              onPressed: () {
                _showLayerOptions(context);
              },
              tooltip: 'Layer Controls',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                _showMapLegend(context);
              },
              tooltip: 'Map Legend',
            ),
          ),
        ],
      ),
    );
  }

  void _showLayerOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Layers'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLayerSwitch(
                  'Heatmap Overlay',
                  'Colored circles showing density',
                  'Heatmap',
                  setState,
                ),
                _buildLayerSwitch(
                  'Barangay Borders',
                  'Outlines of each barangay',
                  'Borders',
                  setState,
                ),
                _buildLayerSwitch(
                  'Location Markers',
                  'Pins showing barangay centers',
                  'Markers',
                  setState,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateMapLayers();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerSwitch(
    String title,
    String description,
    String optionKey,
    StateSetter setState,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(description),
      trailing: Switch(
        value: _layerOptions[optionKey]!,
        onChanged: (value) {
          setState(() {
            _layerOptions[optionKey] = value;
          });
        },
      ),
    );
  }

  void _showMapLegend(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dengue Cases Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendRow(Colors.green, 'Low', '1-7 cases'),
            _buildLegendRow(Colors.yellow, 'Moderate', '8-14 cases'),
            _buildLegendRow(Colors.orange, 'High', '15-24 cases'),
            _buildLegendRow(Colors.red, 'Severe', '25+ cases'),
            const SizedBox(height: 16),
            const Text(
              'Areas are color-coded based on the number of dengue cases reported. Click on any area to see detailed information.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String severity, String caseRange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.7),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  severity,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  caseRange,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendItem(Colors.green, 'Low (1-7)'),
            const SizedBox(width: 8),
            _legendItem(Colors.yellow, 'Moderate (8-14)'),
            const SizedBox(width: 8),
            _legendItem(Colors.orange, 'High (15-24)'),
            const SizedBox(width: 8),
            _legendItem(Colors.red, 'Severe (25+)'),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildDistrictDropdown(context, colorScheme),
          const SizedBox(width: 16),
          _buildBarangayDropdown(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildDistrictDropdown(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: 170,
      height: 34,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 1.5),
          borderRadius: BorderRadius.circular(40),
        ),
        child: DropdownButton<String>(
          isExpanded: true,
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: const Color.fromRGBO(36, 82, 97, 1),
          value: selectedDistrict,
          items: [
            DropdownMenuItem(value: null, child: Text('Select District')),
            ...districtData.keys.map((district) {
              return DropdownMenuItem(value: district, child: Text(district));
            }).toList(),
          ],
          onChanged: (value) {
            setState(() {
              selectedDistrict = value;
              selectedBarangay = null;
            });

            if (value != null) {
              _zoomToDistrict(value); // map movement logic
            }
          },
          style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          hint: Text('Select District', // No const here
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
              )),
        ),
      ),
    );
  }

  Widget _buildBarangayDropdown(BuildContext context, ColorScheme colorScheme) {
    final barangays =
        selectedDistrict != null ? districtData[selectedDistrict]! : <String>[];

    return SizedBox(
      width: 170,
      height: 34,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 1.5),
          borderRadius: BorderRadius.circular(40),
        ),
        child: DropdownButton<String>(
          isExpanded: true,
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: const Color.fromRGBO(36, 82, 97, 1),
          value: selectedBarangay,
          items: [
            if (selectedDistrict != null)
              DropdownMenuItem(value: null, child: Text('Select Barangay')),
            ...barangays.map((barangay) {
              return DropdownMenuItem(value: barangay, child: Text(barangay));
            }).toList(),
          ],
          onChanged: selectedDistrict == null
              ? null
              : (value) {
                  setState(() {
                    selectedBarangay = value;
                  });

                  if (value != null && locationData.containsKey(value)) {
                    _zoomToLocation(locationData[value]!);

                    final data = dengueData[value];
                    if (data != null) {
                      _showDengueDetails(
                        context,
                        value,
                        data['cases'] as int,
                        data['severity'] as String,
                        locationData[value]!,
                      );
                    }
                  }
                },
          style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          hint: const Text('Select Barangay',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              )),
        ),
      ),
    );
  }

  // Helper function to zoom to a district
  void _zoomToDistrict(String district) {
    if (!districtData.containsKey(district)) return;

    final barangays = districtData[district]!;
    if (barangays.isEmpty) return;

    // Calculate the center of the district
    double totalLat = 0;
    double totalLng = 0;
    int count = 0;

    for (final barangay in barangays) {
      final location = locationData[barangay];
      if (location != null) {
        totalLat += location.latitude;
        totalLng += location.longitude;
        count++;
      }
    }

    if (count > 0) {
      final center = LatLng(totalLat / count, totalLng / count);
      _zoomToLocation(center, zoom: 13.5);
    }
  }

  // Helper function to zoom to a location
  void _zoomToLocation(LatLng location, {double zoom = 14.5}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: zoom,
        ),
      ),
    );
  }

  // Implementation for _showDengueDetails
  void _showDengueDetails(
    BuildContext context,
    String barangay,
    int cases,
    String severity,
    LatLng location,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  barangay,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColorForSeverity(severity),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    severity,
                    style: TextStyle(
                      color: severity == 'Low' ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded),
                const SizedBox(width: 8),
                Text(
                  '$cases reported cases',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                Text(
                  'Coordinates: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Recommendations:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildRecommendations(severity),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationDetailsScreen(
                      location: barangay, // Correct parameter name
                      latitude:
                          location.latitude, // Extract latitude from LatLng
                      longitude:
                          location.longitude, // Extract longitude from LatLng
                      district: selectedDistrict,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('View Detailed Report'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build recommendations based on severity
  Widget _buildRecommendations(String severity) {
    List<String> recommendations;

    switch (severity) {
      case 'Severe':
        recommendations = [
          'Eliminate all standing water sources immediately',
          'Use mosquito repellent at all times',
          'Install mosquito screens on all windows',
          'Consider community fogging operations',
          'Watch for fever and other dengue symptoms'
        ];
        break;
      case 'Moderate':
        recommendations = [
          'Regularly check and empty water containers',
          'Use mosquito repellent when outdoors',
          'Wear long-sleeved clothes',
          'Be alert for dengue symptoms'
        ];
        break;
      case 'Low':
        recommendations = [
          'Keep surroundings clean',
          'Remove potential water collection points',
          'Use mosquito repellent when necessary'
        ];
        break;
      default:
        recommendations = [
          'Maintain cleanliness in your surroundings',
          'Be cautious about standing water'
        ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recommendations
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
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
