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
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buzzmap/widgets/recommendations_widget.dart';
import 'package:geocoding/geocoding.dart';
import 'package:buzzmap/services/notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:buzzmap/auth/config.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:buzzmap/errors/flushbar.dart';

class MappingScreen extends StatefulWidget {
  const MappingScreen({super.key});

  @override
  State<MappingScreen> createState() => _MappingScreenState();
}

class _MappingScreenState extends State<MappingScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  String? selectedDistrict;
  String? selectedBarangay;
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  Set<Polygon> _barangayPolygons = {};
  String? selectedSeverity;

  Map<String, String> hazardRiskLevels = {};

  PolygonId? _selectedPolygonId;

  Map<String, LatLng> _barangayCentroids = {};
  bool _isCardVisible = false; // 🔥 control floating card visibility

  bool _isLoading = true;
  MapType _currentMapType = MapType.normal;

  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(14.6760, 121.0437),
    zoom: 11.4,
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
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  // Barangay boundary data - coordinates for polygon borders
  final Map<String, List<LatLng>> barangayBoundaries = {
    // Other barangay boundaries remain unchanged
    // ... [For brevity, other boundaries are not repeated]
  };

  // Add these new properties
  Position? _currentPosition;
  bool _isInQuezonCity = false;
  Timer? _locationCheckTimer;

  // Add this property to track previous state
  bool _previousIsInQuezonCity = true; // Default to true to avoid initial notification

  @override
  void initState() {
    super.initState();

    // Initialize the default layer to show Markers initially
    _layerOptions['Markers'] = false;

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );

    // Call the GeoJSON loading function for borders
    _loadGeoJsonPolygons();

    // Initialize location services with a slight delay
    Future.delayed(const Duration(seconds: 1), () {
      _initializeLocationServices();
    });

    // Using a slight delay to ensure Google Maps is fully loaded
    Timer(const Duration(milliseconds: 500), () {
      _updateMapLayers();
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _initializeLocationServices() async {
    // First check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Location Services Disabled'),
              content: const Text(
                'Please enable location services to use this feature.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Settings'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Geolocator.openLocationSettings();
                  },
                ),
              ],
            );
          },
        );
      }
      return;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          AppFlushBar.showError(
            context,
            message: 'Location permissions are required to use this feature.',
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Location Permission Required'),
              content: const Text(
                'Location permissions are permanently denied. Please enable them in app settings.',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Settings'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Geolocator.openAppSettings();
                  },
                ),
              ],
            );
          },
        );
      }
      return;
    }

    // Start periodic location check with a longer interval
    _locationCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkCurrentLocation();
    });

    // Initial location check
    _checkCurrentLocation();
  }

  Future<void> _checkCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      
      if (!mounted) return;

      // Check if the location is within Quezon City bounds
      const double qcMinLat = 14.4;
      const double qcMaxLat = 14.9;
      const double qcMinLng = 120.8;
      const double qcMaxLng = 121.3;

      bool isInQC = position.latitude >= qcMinLat &&
          position.latitude <= qcMaxLat &&
          position.longitude >= qcMinLng &&
          position.longitude <= qcMaxLng;

      // Only show notification if the status has changed
      if (isInQC != _previousIsInQuezonCity) {
        if (!mounted) return;
        
        if (!isInQC) {
          AppFlushBar.showCustom(
            context,
            title: 'Location Alert',
            message: 'You are currently outside Quezon City. Please select a location within Quezon City.',
            backgroundColor: const Color(0xFFB8585B),
            duration: const Duration(seconds: 4),
          );
        }

        // Update both current and previous states
        setState(() {
          _isInQuezonCity = isInQC;
          _previousIsInQuezonCity = isInQC;
        });
      } else {
        // Just update the current position without showing notification
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        AppFlushBar.showError(
          context,
          message: 'Unable to get your location. Please check your location settings.',
        );
      }
    }
  }

  // Call this function when Markers layer is enabled
  void _loadVerifiedReportMarkers() async {
    if (!_layerOptions['Markers']!)
      return; // Ensure it's only called when Markers are enabled

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/reports'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> reports = jsonDecode(response.body);
        final verifiedReports = reports.where(
          (r) => r['status']?.toString().toLowerCase() == 'validated',
        );

        Set<Marker> reportMarkers = {};

        for (var report in verifiedReports) {
          final coords = report['specific_location']?['coordinates'];
          if (coords == null || coords.length != 2) continue;

          final position = LatLng(coords[1], coords[0]);
          final barangay = report['barangay'] ?? 'Unknown';

          reportMarkers.add(
            Marker(
              markerId: MarkerId(report['_id']),
              position: position,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
              onTap: () {
                _showDengueDetails(context, barangay, 1, 'Verified', position);
              },
            ),
          );
        }

        setState(() {
          _markers = reportMarkers; // Only validated reports will show
        });
      } else {
        print('❌ Failed to fetch reports: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in _loadVerifiedReportMarkers: $e');
    }
  }

  double _estimateBarangaySize(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    double area = 0.0;

    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      area += (p1.longitude * p2.latitude) - (p2.longitude * p1.latitude);
    }

    return area.abs() / 2.0; // approximate size
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

        loadedPolygons.add(Polygon(
          polygonId: PolygonId(name),
          points: coords,
          strokeColor:
              _selectedPolygonId == PolygonId(name) ? Colors.redAccent : color,
          strokeWidth: _selectedPolygonId == PolygonId(name) ? 4 : 2,
          fillColor: color.withOpacity(0.3),
          consumeTapEvents: true,
          onTap: () {
            _onBarangayPolygonTapped(name);
          },
        ));
        barangayBoundaries[name] = coords;
      }

      setState(() {
        _barangayPolygons = loadedPolygons;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading GeoJSON: \$e');
    }
  }

  String _convertSeverityToRisk(String severity) {
    switch (severity) {
      case 'Severe':
      case 'High':
        return 'HIGH';
      case 'Moderate':
        return 'MODERATE';
      case 'Low':
        return 'LOW';
      default:
        return 'UNKNOWN';
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

  void _onBarangayPolygonTapped(String barangayName) {
    final data = dengueData[barangayName];

    if (data != null) {
      setState(() {
        selectedBarangay = barangayName;
        selectedSeverity = data['severity'] as String;
        _selectedPolygonId = PolygonId(barangayName);
        _isCardVisible = true;

        // 👉 Add hazard levels setup
        hazardRiskLevels = {
          'Mosquito Breeding Risk': _convertSeverityToRisk(data['severity']),
          'Dengue Infection Risk': _convertSeverityToRisk(data['severity']),
          'Home Safety Status': _convertSeverityToRisk(data['severity']),
        };
      });

      final boundaryPoints = barangayBoundaries[barangayName];
      if (boundaryPoints != null && boundaryPoints.isNotEmpty) {
        print(
            'Zooming to $barangayName with ${boundaryPoints.length} points'); // Debug
        _fitPolygonToScreen(boundaryPoints);
      } else {
        print('No boundary points found for $barangayName'); // Debug
        // Fallback to centroid if no boundaries
        final centroid = _barangayCentroids[barangayName];
        if (centroid != null) {
          _zoomToLocation(centroid, barangay: barangayName);
        }
      }
    }
  }

  void _fitPolygonToScreen(List<LatLng> points) {
    if (points.isEmpty) return;

    // First pass to find min/max
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }

    // Handle edge case where all points might be the same
    if (minLat == maxLat) {
      minLat -= 0.001;
      maxLat += 0.001;
    }
    if (minLng == maxLng) {
      minLng -= 0.001;
      maxLng += 0.001;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Add some padding and animate
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100), // Increased padding to 100
    );
  }

  void _updateMapLayers() {
    Set<Circle> circles = {};
    Set<Polygon> polygons = {};

    // Check if Heatmap is enabled and add circles
    if (_layerOptions['Heatmap']!) {
      dengueData.forEach((barangay, data) {
        final latLng = _barangayCentroids[barangay];
        final cases = data['cases'] as int;

        if (latLng != null) {
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
      });
    }

    // Add polygons only if Borders are enabled
    if (_layerOptions['Borders']!) {
      polygons = polygons.union(_barangayPolygons);
      // Disable Markers when Borders are enabled
      _layerOptions['Markers'] = false; // Disable markers
    }

    // Add markers only if Markers are enabled
    if (_layerOptions['Markers']!) {
      _loadVerifiedReportMarkers(); // Only validated markers should be shown
      // Disable Borders when Markers are enabled
      _layerOptions['Borders'] = false; // Disable borders
    }

    // Apply the layers to the map
    setState(() {
      _circles = circles;
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
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // 1. Google Map
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

                    // 2. Loading indicator
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

                    // 3. Map layer controls
                    _buildLayerControls(),

// 4. Floating Dengue Intervention Card (Always visible)
                    if (_isCardVisible)
                      Positioned(
                        bottom: 10,
                        left: 20,
                        right: 20,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            height: 300, // 🔥 Fixed height so body can scroll
                            child: Column(
                              children: [
                                // Top Header (Logo + Text + Arrow)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            SvgPicture.asset(
                                              'assets/icons/logo_ligthbg.svg',
                                              width: 45,
                                              height: 45,
                                              fit: BoxFit.contain,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: RichText(
                                                textAlign: TextAlign.center,
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontFamily: 'Koulen',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    height: 1.2,
                                                    letterSpacing: 1.0,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          'Broad Urban Zone and Zeroing\n',
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          'Metropolitan Active Prevention',
                                                      style: TextStyle(
                                                        color: Color(
                                                            0xFF4AA8C7), // 🔥 Your primary color hardcoded (or whatever you want)
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.keyboard_arrow_down),
                                        onPressed: () {
                                          setState(() {
                                            _isCardVisible = false;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                // Divider line
                                Container(
                                  height: 1,
                                  color: Colors.grey[300],
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                ),

                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Dengue Situation Overview',
                                          style: TextStyle(
                                            fontFamily: 'Koulen',
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Recent dengue cases are rising. Follow health precautions.',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 12),

                                        // Call the method to get recommendations based on severity
                                        buildRecommendations(
                                            selectedSeverity ?? 'Unknown',
                                            hazardRiskLevels),
                                        // Prescriptive logic here
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // 5. Minimized FAB button if hidden
                    if (!_isCardVisible)
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _bounceAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                    0,
                                    -_bounceAnimation
                                        .value), // 🔥 moves up and down
                                child: FloatingActionButton(
                                  mini: true,
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  onPressed: () {
                                    setState(() {
                                      _isCardVisible = true;
                                    });
                                  },
                                  child: const Icon(Icons.keyboard_arrow_up),
                                ),
                              );
                            },
                          ),
                        ),
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

    // if (_layerOptions['Markers']!) {
    //   interactionElements.add('MARKERS');
    // }

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
                  'Pins showing user reports',
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
              _updateMapLayers(); // Apply the layer settings
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

            // When one option is toggled on, the other one will be toggled off automatically
            if (optionKey == 'Borders') {
              _layerOptions['Markers'] =
                  false; // Disable Markers when Borders are enabled
            } else if (optionKey == 'Markers') {
              _layerOptions['Borders'] =
                  false; // Disable Borders when Markers are enabled
            }
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

            if (value != null && _barangayCentroids.containsKey(value)) {
              _zoomToLocation(_barangayCentroids[value]!, barangay: value);

              final data = dengueData[value];
              if (data != null) {
                selectedSeverity = data['severity'] as String;

                // 🔥 ADD THESE:
                hazardRiskLevels = {
                  'Mosquito Breeding Risk':
                      _convertSeverityToRisk(data['severity']),
                  'Dengue Infection Risk':
                      _convertSeverityToRisk(data['severity']),
                  'Home Safety Status':
                      _convertSeverityToRisk(data['severity']),
                };
                _isCardVisible = true; // 🔥 show the card when user selects
              }
            }
          });
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
    double zoomLevel = 16.0; // default for small areas

    if (barangay != null && barangayBoundaries.containsKey(barangay)) {
      final size = _estimateBarangaySize(barangayBoundaries[barangay]!);

      if (size > 2.5) {
        zoomLevel = 13.5; // Big barangay
      } else if (size > 1.0) {
        zoomLevel = 14.5; // Medium barangay
      } else {
        zoomLevel = 15.5; // Small barangay 🔥 (NOT 16)
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

  void _showDengueDetails(
    BuildContext context,
    String barangay,
    int cases,
    String severity,
    LatLng location,
  ) async {
    // 🔥 Reverse geocode to get street name
    String streetName = '';
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        streetName = placemarks.first.street ?? '';
      }
    } catch (e) {
      print('Reverse geocoding failed: $e');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white, // or any color you want

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔥 Clean Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        streetName.isNotEmpty ? streetName : barangay,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${barangay.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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

            // Cases
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
            const SizedBox(height: 12),

            // Coordinates
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
            const SizedBox(height: 20),

            // Recommendations
            const Text(
              'Recommendations:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            buildRecommendations(severity, hazardRiskLevels),

            const SizedBox(height: 20), // 🔥 SMALL controlled space

            // View Detailed Report Button - flows after recommendations naturally
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationDetailsScreen(
                        location: barangay,
                        streetName: streetName, // from reverse geocoding
                        latitude: location.latitude,
                        longitude: location.longitude,
                        cases: dengueData[barangay]!['cases'],
                        severity: dengueData[barangay]!['severity'],
                        district: selectedDistrict,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View Detailed Report'),
              ),
            ),
            const SizedBox(height: 8), // small bottom space
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _locationCheckTimer?.cancel();
    super.dispose();
  }
}
