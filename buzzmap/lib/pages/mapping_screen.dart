import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';
import 'package:buzzmap/pages/location_details_screen.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:buzzmap/data/dengue_data.dart';
import 'package:dropdown_search/dropdown_search.dart';

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

  Map<String, LatLng> _barangayCentroids = {};

  bool _isLoading = true;
  MapType _currentMapType = MapType.normal;

  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(14.6700, 121.0437),
    zoom: 11.8,
  );

  // Layer control options
  final Map<String, bool> _layerOptions = {
    'Heatmap': false,
    'Borders': true,
    'Markers': false,
  };

  final Map<String, List<String>> districtData = {
    'District I': [
      'Alicia',
      'Apollonio Samson',
      'Bahay Toro',
      'Balingasa',
      'Damar',
      'Del Monte',
      'Lourdes',
      'Maharlika',
      'Manresa',
      'Mariblo',
      'N.S. Amoranto',
      'Paltok',
      'Paraiso',
      'Salvacion',
      'San Antonio',
      'San Isidro Labrador',
      'Santa Cruz',
      'Sienna',
      'Sta. Teresita',
      'Sto. Cristo',
      'Sto. Domingo',
      'Talayan',
      'Vasra',
      'Veterans Village',
    ],
    'District II': [
      'Baesa',
      'Bagong Pag-asa',
      'Balumbato',
      'Culiat',
      'Kaligayahan',
      'New Era',
      'Pasong Putik Proper',
      'San Bartolome',
      'Sangandaan',
      'Sauyo',
      'Talipapa',
      'Unang Sigaw',
    ],
    'District III': [
      'Amihan',
      'Botocan',
      'Claro',
      'Duyan-Duyan',
      'E. Rodriguez Sr.',
      'Escopa I',
      'Escopa II',
      'Escopa III',
      'Escopa IV',
      'Kalusugan',
      'Kristong Hari',
      'Loyola Heights',
      'Marilag',
      'Masagana',
      'Matandang Balara',
      'Milagrosa',
      'Pansol',
      'Quirino 2-A',
      'Quirino 2-B',
      'Quirino 2-C',
      'Quirino 3-A',
      'San Vicente',
      'Silangan',
      'Tagumpay',
      'Villa Maria Clara',
      'White Plains',
    ],
    'District IV': [
      'Bagong Lipunan ng Crame',
      'Damayang Lagi',
      'Doña Aurora',
      'Doña Imelda',
      'Doña Josefa',
      'Horseshoe',
      'Immaculate Concepcion',
      'Kamuning',
      'Kaunlaran',
      'Laging Handa',
      'Obrero',
      'Old Capitol Site',
      'Paligsahan',
      'Roxas',
      'Sacred Heart',
      'San Martin de Porres',
      'South Triangle',
      'West Triangle',
    ],
    'District V': [
      'Bagong Silangan',
      'Capri',
      'Commonwealth',
      'Greater Lagro',
      'Gulod',
      'Holy Spirit',
      'Nagkaisang Nayon',
      'North Fairview',
      'Payatas',
      'San Agustin',
      'Santa Lucia',
      'Santa Monica',
      'Tandang Sora',
      'Fairview',
    ],
    'District VI': [
      'Batasan Hills',
      'Blue Ridge A',
      'Blue Ridge B',
      'Camp Aguinaldo',
      'Central',
      'Cubao',
      'East Kamias',
      'Libis',
      'Mangga',
      'Pinagkaisahan',
      'Project 6',
      'San Roque',
      'Sikatuna Village',
      'Socorro',
      'UP Campus',
      'UP Village',
      'Ugong Norte',
      'West Kamias',
      'Teachers Village East',
      'Teachers Village West',
      'Pasong Tamo',
    ],
  };

  // Barangay boundary data - coordinates for polygon borders
  final Map<String, List<LatLng>> barangayBoundaries = {
    // Other barangay boundaries remain unchanged
    // ... [For brevity, other boundaries are not repeated]
  };
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

  double _estimateBarangaySize(List<LatLng> points) {
    double maxDistance = 0;
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final d = _distanceBetween(points[i], points[j]);
        if (d > maxDistance) maxDistance = d;
      }
    }
    return maxDistance;
  }

  double _distanceBetween(LatLng a, LatLng b) {
    const double earthRadius = 6371; // km
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final aVal = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(aVal), sqrt(1 - aVal));
    return earthRadius * c;
  }

  double _degToRad(double degree) => degree * pi / 180;

  Future<void> _loadGeoJsonPolygons() async {
    try {
      final String data =
          await rootBundle.loadString('assets/geojson/barangays.geojson');
      final geo = json.decode(data);

      Set<Polygon> loadedPolygons = {};
      for (final feature in geo['features']) {
        final properties = feature['properties'];
        final geometry = feature['geometry'];

        if (properties == null ||
            geometry == null ||
            geometry['type'] != 'Polygon') continue;

        final name = properties['name'] ?? properties['NAME_3'];
        if (name == null) continue;

        final severity = dengueData[name]?['severity'] ?? 'Unknown';
        final color = _getColorForSeverity(severity);

        final coords = geometry['coordinates'][0]
            .map<LatLng>(
                (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
            .toList();

        _barangayCentroids[name] = _getPolygonCentroid(coords);

        loadedPolygons.add(
          Polygon(
            polygonId: PolygonId(name),
            points: coords,
            strokeColor: color,
            strokeWidth: 2,
            fillColor: color.withOpacity(0.3),
          ),
        );
      }

      setState(() {
        _barangayPolygons = loadedPolygons;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading GeoJSON: \$e');
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

  LatLng _getPolygonCentroid(List<LatLng> points) {
    double latitude = 0;
    double longitude = 0;

    for (var point in points) {
      latitude += point.latitude;
      longitude += point.longitude;
    }

    int totalPoints = points.length;
    return LatLng(latitude / totalPoints, longitude / totalPoints);
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
      final latLng = _barangayCentroids[barangay];
      final cases = data['cases'] as int;
      final severity = data['severity'] as String;

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
        if (_layerOptions['Borders']! && _barangayPolygons.isNotEmpty) {
          polygons = polygons.union(_barangayPolygons);
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
          const SizedBox(height: 9),
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
                      mapType: _currentMapType,
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
            decoration: _buttonStyle(),
            child: IconButton(
              icon: const Icon(Icons.layers),
              onPressed: () => _showLayerOptions(context),
              tooltip: 'Layer Controls',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: _buttonStyle(),
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showMapLegend(context),
              tooltip: 'Map Legend',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: _buttonStyle(),
            child: IconButton(
              icon: const Icon(Icons.map),
              onPressed: () {
                setState(() {
                  _currentMapType = _currentMapType == MapType.normal
                      ? MapType.satellite
                      : MapType.normal;
                });
              },
              tooltip: 'Toggle Map/Satellite View',
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buttonStyle() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      );

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
          Expanded(
            child: _buildBarangayDropdown(context, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildBarangayDropdown(BuildContext context, ColorScheme colorScheme) {
    final allBarangays = _barangayCentroids.keys.toList()..sort();

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: DropdownSearch<String>(
        items: allBarangays,
        selectedItem: selectedBarangay,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: "Select Barangay",
            labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
        ),
        popupProps: const PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            style: TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: "Search barangay...",
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        dropdownButtonProps: const DropdownButtonProps(
          icon: Icon(Icons.arrow_drop_down, color: Colors.white),
        ),
        onChanged: (value) {
          setState(() {
            selectedBarangay = value;
          });

          if (value != null && _barangayCentroids.containsKey(value)) {
            _zoomToLocation(_barangayCentroids[value]!, barangay: value);

            final data = dengueData[value];
            if (data != null) {
              _showDengueDetails(
                context,
                value,
                data['cases'] as int,
                data['severity'] as String,
                _barangayCentroids[value]!,
              );
            }
          }
        },
        dropdownBuilder: (context, selectedItem) {
          return Text(
            selectedItem ?? 'Quezon City',
            style: const TextStyle(color: Colors.white),
          );
        },
      ),
    );
  }

  void _zoomToLocation(LatLng location, {String? barangay}) {
    double zoomLevel = 14.5;

    if (barangay != null && barangayBoundaries.containsKey(barangay)) {
      final size = _estimateBarangaySize(barangayBoundaries[barangay]!);

      if (size > 2.5) {
        zoomLevel = 13.5; // Large barangays
      } else if (size > 1.0) {
        zoomLevel = 14.5; // Medium
      } else {
        zoomLevel = 17.5; // Small, zoom in tighter
      }
    }

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: zoomLevel,
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
