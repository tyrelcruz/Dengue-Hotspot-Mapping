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
import 'package:buzzmap/widgets/location_notification.dart';
import 'package:buzzmap/services/alert_service.dart';

class MappingScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final double? initialZoom;
  final String? reportId;

  const MappingScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialZoom,
    this.reportId,
  });

  @override
  State<MappingScreen> createState() => _MappingScreenState();
}

class _MappingScreenState extends State<MappingScreen>
    with SingleTickerProviderStateMixin {
  late GoogleMapController _mapController;
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
    target: LatLng(14.6760, 121.0437), // Center of Quezon City
    zoom: 11.4,
  );

  // Layer control options
  final Map<String, bool> _layerOptions = {
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
  bool _previousIsInQuezonCity =
      true; // Default to true to avoid initial notification

  // Add these maps to store API data
  Map<String, String> _barangayRiskLevels = {};
  Map<String, String> _barangayPatterns = {};
  Map<String, String> _barangayAlerts = {};

  Map<String, dynamic> _dengueData = {};
  bool _isLoadingData = true;

  final AlertService _alertService = AlertService();

  @override
  void initState() {
    super.initState();

    // Initialize the default layer to show Risk Levels initially
    _layerOptions['Borders'] = true; // Set to true by default
    _layerOptions['Markers'] =
        widget.reportId != null; // Enable markers if coming from notification

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
    _loadGeoJSON();

    // Fetch risk levels from API
    _fetchRiskLevels();

    // Initialize location services with a slight delay
    Future.delayed(const Duration(seconds: 1), () {
      _initializeLocationServices();
    });

    // If we have initial coordinates from a notification, add a marker
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('notification-marker'),
            position: LatLng(widget.initialLatitude!, widget.initialLongitude!),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      });
    }

    // Using a slight delay to ensure Google Maps is fully loaded
    Timer(const Duration(milliseconds: 500), () {
      _updateMapLayers();
      setState(() {
        _isLoading = false;
      });
    });

    _fetchDengueData();

    // Start polling for alerts
    _alertService.startPolling();
  }

  @override
  void dispose() {
    // Cancel the location check timer
    _locationCheckTimer?.cancel();
    _locationCheckTimer = null;

    // Dispose the map controller
    _mapController.dispose();

    // Dispose the bounce controller
    _bounceController.dispose();

    // Clear any existing notifications
    LocationNotificationService.dismiss();

    _alertService.dispose();

    super.dispose();
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
          LocationNotificationService.show(
            context: context,
            title: 'Location Error',
            message: 'Location permissions are required to use this feature.',
            backgroundColor: const Color(0xFFB8585B),
            duration: const Duration(seconds: 4),
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
      if (mounted) {
        // Only check location if the widget is still mounted
        _checkCurrentLocation();
      } else {
        timer.cancel(); // Cancel the timer if the widget is disposed
      }
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

      // Find which barangay the user is in
      String? currentBarangay = _findBarangayFromLocation(position);

      // Only show notification if we're in QC and found a barangay
      // AND if no barangay is currently selected by the user
      if (isInQC && currentBarangay != null && selectedBarangay == null) {
        // Only show notification if we've moved to a different barangay
        if (currentBarangay != selectedBarangay) {
          final riskLevel =
              _barangayRiskLevels[currentBarangay]?.toLowerCase() ?? 'unknown';
          final pattern =
              _barangayPatterns[currentBarangay]?.toLowerCase() ?? 'no data';
          final color = _getColorForBarangay(currentBarangay);

          print('Showing notification for barangay: $currentBarangay');
          print('Risk Level: $riskLevel, Pattern: $pattern');

          LocationNotificationService.show(
            context: context,
            title: 'Location Detected: $currentBarangay',
            message:
                'Risk Level: ${riskLevel.toUpperCase()}\nPattern: ${pattern.toUpperCase()}',
            backgroundColor: color,
            duration: const Duration(seconds: 5),
          );

          // Update the selected barangay only if none is selected
          setState(() {
            selectedBarangay = currentBarangay;
          });
        }
      } else if (!isInQC && isInQC != _previousIsInQuezonCity) {
        // Only show outside QC notification when status changes
        LocationNotificationService.show(
          context: context,
          title: 'Location Alert',
          message:
              'You are currently outside Quezon City. Please select a location within Quezon City.',
          backgroundColor: const Color(0xFFB8585B),
          duration: const Duration(seconds: 4),
        );
      }

      // Update states
      setState(() {
        _isInQuezonCity = isInQC;
        _previousIsInQuezonCity = isInQC;
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        LocationNotificationService.show(
          context: context,
          title: 'Location Error',
          message:
              'Unable to get your location. Please check your location settings.',
          backgroundColor: const Color(0xFFB8585B),
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  String? _findBarangayFromLocation(Position position) {
    for (var entry in barangayBoundaries.entries) {
      if (_isPointInPolygon(position, entry.value)) {
        return entry.key;
      }
    }
    return null;
  }

  bool _isPointInPolygon(Position point, List<LatLng> polygon) {
    bool isInside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].latitude > point.latitude) !=
              (polygon[j].latitude > point.latitude) &&
          (point.longitude <
              (polygon[j].longitude - polygon[i].longitude) *
                      (point.latitude - polygon[i].latitude) /
                      (polygon[j].latitude - polygon[i].latitude) +
                  polygon[i].longitude)) {
        isInside = !isInside;
      }
      j = i;
    }

    return isInside;
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

  Future<void> _loadGeoJSON() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/geojson/barangays.geojson');
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> features = jsonData['features'];

      List<Polygon> loadedPolygons = [];

      for (var feature in features) {
        final properties = feature['properties'];
        final geometry = feature['geometry'];

        if (properties == null ||
            geometry == null ||
            geometry['type'] != 'Polygon') continue;

        final name = properties['name'] ?? properties['NAME_3'];
        if (name == null) continue;

        final severity = _dengueData[name]?['severity'] ?? 'Unknown';
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
        _barangayPolygons = loadedPolygons.toSet();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading GeoJSON: $e');
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
    switch (severity.toLowerCase()) {
      case 'stability':
        return Colors.green;
      case 'low':
        return Colors.amber;
      case 'decline':
        return Colors.lightGreen;
      case 'moderate':
        return Colors.orange;
      case 'spike':
        return Colors.deepOrange;
      case 'high':
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
    final riskLevel =
        _barangayRiskLevels[barangayName]?.toLowerCase() ?? 'no data';
    final pattern = _barangayPatterns[barangayName]?.toLowerCase() ?? '';

    setState(() {
      selectedBarangay = barangayName;
      selectedSeverity = riskLevel;
      _selectedPolygonId = PolygonId(barangayName);
      _isCardVisible = true;

      // Update hazard levels based on risk level and pattern
      hazardRiskLevels = {
        'Mosquito Breeding Risk': riskLevel.toUpperCase(),
        'Dengue Infection Risk': riskLevel.toUpperCase(),
        'Home Safety Status': riskLevel.toUpperCase(),
        'Pattern': pattern.toUpperCase(),
        'RiskLevel': riskLevel.toUpperCase(),
      };
    });

    final boundaryPoints = barangayBoundaries[barangayName];
    if (boundaryPoints != null && boundaryPoints.isNotEmpty) {
      _fitPolygonToScreen(boundaryPoints);
    } else {
      final centroid = _barangayCentroids[barangayName];
      if (centroid != null) {
        _zoomToLocation(centroid, barangay: barangayName);
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
      minLng = max(maxLng, point.longitude);
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
    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100), // Increased padding to 100
    );
  }

  void _updateMapLayers() {
    Set<Polygon> polygons = {};
    Set<Marker> markers = {};

    // Add polygons if Borders is enabled or if Markers is enabled
    if (_layerOptions['Borders']! || _layerOptions['Markers']!) {
      if (_layerOptions['Markers']!) {
        // When markers are enabled, show all polygons in green
        for (var polygon in _barangayPolygons) {
          polygons.add(Polygon(
            polygonId: polygon.polygonId,
            points: polygon.points,
            strokeColor: const Color(0xFF388E3C), // Lighter green border
            strokeWidth: 2,
            fillColor: const Color(0xFF4CAF50).withOpacity(0.3),
            consumeTapEvents: false,
          ));
        }
      } else {
        // When only borders are enabled, show polygons with their risk level colors
        polygons = polygons.union(_barangayPolygons);
      }
    }

    // Add markers if Markers is enabled
    if (_layerOptions['Markers']!) {
      _loadVerifiedReportMarkers();
    } else {
      // Clear markers when Markers layer is disabled
      markers = {};
    }

    // Apply the layers to the map
    setState(() {
      _polygons = polygons;
      _markers = markers;
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
      body: Stack(
        children: [
          Column(
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        GoogleMap(
                          mapType: _currentMapType,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              widget.initialLatitude ?? 14.6760,
                              widget.initialLongitude ?? 121.0437,
                            ),
                            zoom: widget.initialZoom ?? 11.4,
                          ),
                          onMapCreated: (controller) =>
                              _mapController = controller,
                          circles: _circles,
                          markers: _markers,
                          polygons: _polygons,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
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
                                    offset: Offset(0, -_bounceAnimation.value),
                                    child: FloatingActionButton(
                                      mini: true,
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      onPressed: () {
                                        setState(() {
                                          _isCardVisible = true;
                                        });
                                      },
                                      child:
                                          const Icon(Icons.keyboard_arrow_up),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5),
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
                  height: 300,
                  child: Column(
                    children: [
                      // Top Header (Logo + Text + Arrow)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                              color: Color(0xFF4AA8C7),
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
                              icon: const Icon(Icons.keyboard_arrow_down),
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
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              RecommendationsWidget(
                                severity: selectedSeverity ?? 'Unknown',
                                hazardRiskLevels: hazardRiskLevels,
                                latitude:
                                    _barangayCentroids[selectedBarangay ?? '']
                                            ?.latitude ??
                                        14.6760,
                                longitude:
                                    _barangayCentroids[selectedBarangay ?? '']
                                            ?.longitude ??
                                        121.0437,
                                selectedBarangay: selectedBarangay ?? '',
                                barangayColor: _getColorForBarangay(
                                    selectedBarangay ?? ''),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getInteractionText() {
    List<String> interactionElements = [];

    if (_layerOptions['Borders'] == true) {
      interactionElements.add('BORDERED AREAS');
    }

    if (_layerOptions['Markers'] == true) {
      interactionElements.add('REPORT MARKERS');
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
                  'Risk Levels',
                  'Shows risk levels of each barangay',
                  'Borders',
                  setState,
                ),
                _buildLayerSwitch(
                  'Report Markers',
                  'Shows locations of reported cases',
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
            // If turning on this option, turn off all others
            if (value) {
              _layerOptions.forEach((key, _) {
                _layerOptions[key] = key == optionKey;
              });
            } else {
              // If turning off the last active option, don't allow it
              if (_layerOptions.values.where((v) => v).length <= 1) {
                // Instead of preventing the turn off, turn on a default layer
                _layerOptions['Heatmap'] = true;
                _layerOptions[optionKey] = false;
              } else {
                _layerOptions[optionKey] = false;
              }
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
        title: const Text('Dengue Risk Levels & Patterns'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendRow(
                Colors.grey, 'No Data', 'Information not available'),
            const SizedBox(height: 8),
            _buildLegendRow(Colors.green, 'Stable', 'No significant change'),
            _buildLegendRow(
                Colors.lightBlue, 'Decline Pattern', 'Decreasing trend'),
            const SizedBox(height: 8),
            _buildLegendRow(
                Colors.orange, 'Moderate Risk', 'Slight increase in cases'),
            _buildLegendRow(
                Colors.deepOrange, 'Spike Pattern', 'Sudden increase'),
            const SizedBox(height: 8),
            _buildLegendRow(Colors.red, 'High Risk', 'Critical situation'),
            const SizedBox(height: 16),
            const Text(
              'Areas are color-coded based on risk levels and patterns. Click on any area to see detailed information.',
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
            _legendItem(Colors.grey, 'No Data'),
            const SizedBox(width: 8),
            _legendItem(Colors.green, 'Stable'),
            const SizedBox(width: 8),
            _legendItem(Colors.orange, 'Moderate'),
            const SizedBox(width: 8),
            _legendItem(Colors.red, 'High'),
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

              final data = _dengueData[value];
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
    _mapController.animateCamera(
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
            RecommendationsWidget(
              severity: severity,
              hazardRiskLevels: hazardRiskLevels,
              latitude: location.latitude,
              longitude: location.longitude,
              selectedBarangay: barangay,
              barangayColor: _getColorForBarangay(barangay),
            ),

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
                        cases: _dengueData[barangay]?['cases'] as int,
                        severity: _dengueData[barangay]?['severity'] as String,
                        district: selectedDistrict,
                        source: 'maps',
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

  Future<void> _fetchRiskLevels() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Config.baseUrl}/api/v1/analytics/retrieve-pattern-recognition-results'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _barangayRiskLevels = {};
            _barangayPatterns = {};
            _barangayAlerts = {};

            for (var item in data['data'] as List) {
              final name = item['name'];
              if (item['risk_level'] != null) {
                _barangayRiskLevels[name] =
                    item['risk_level'].toString().toLowerCase();
              }
              if (item['triggered_pattern'] != null) {
                _barangayPatterns[name] =
                    item['triggered_pattern'].toString().toLowerCase();
              }
              if (item['alert'] != null) {
                _barangayAlerts[name] = item['alert'].toString();
              }
            }
          });
          // Update polygons with new risk levels and patterns
          _updatePolygonsWithRiskLevels();
        }
      } else {
        if (mounted) {
          LocationNotificationService.show(
            context: context,
            title: 'API Error',
            message:
                'Failed to fetch risk levels. Status code: ${response.statusCode}',
            backgroundColor: const Color(0xFFB8585B),
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      print('Error fetching risk levels: $e');
      if (mounted) {
        LocationNotificationService.show(
          context: context,
          title: 'Connection Error',
          message:
              'Unable to connect to the server. Please check your internet connection and try again.',
          backgroundColor: const Color(0xFFB8585B),
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  Color _getColorForBarangay(String barangayName) {
    final riskLevel = _barangayRiskLevels[barangayName]?.toLowerCase();
    final pattern = _barangayPatterns[barangayName]?.toLowerCase();

    // If no data is available, return gray
    if (riskLevel == null || pattern == null) return Colors.grey.shade700;

    // If high risk, always return red
    if (riskLevel == 'high') return Colors.red.shade700;

    // If low risk, check pattern
    if (riskLevel == 'low') {
      if (pattern == 'stability') return Colors.green.shade600;
      if (pattern == 'spike') return Colors.deepOrange.shade600;
      if (pattern == 'decline') return Colors.lightBlue.shade600;
      return Colors.green.shade600; // Default for low risk without pattern
    }

    // For moderate risk
    if (riskLevel == 'moderate') {
      if (pattern == 'spike') return Colors.deepOrange.shade600;
      return Colors.orange.shade500; // Default for moderate risk
    }

    return Colors.grey.shade700; // Default fallback
  }

  void _updatePolygonsWithRiskLevels() {
    Set<Polygon> updatedPolygons = {};

    for (var polygon in _barangayPolygons) {
      final barangayName = polygon.polygonId.value;
      final riskLevel = _barangayRiskLevels[barangayName]?.toLowerCase();
      final pattern = _barangayPatterns[barangayName]?.toLowerCase();

      Color polygonColor;
      Color borderColor;

      // If no data is available, use gray
      if (riskLevel == null || pattern == null) {
        polygonColor = Colors.grey.shade700;
        borderColor = Colors.grey.shade800;
      }
      // If high risk, always use red
      else if (riskLevel == 'high') {
        polygonColor = Colors.red.shade700;
        borderColor = Colors.red.shade900;
      }
      // If low risk, check pattern
      else if (riskLevel == 'low') {
        if (pattern == 'stability') {
          polygonColor = Colors.green.shade600;
          borderColor = Colors.green.shade800;
        } else if (pattern == 'spike') {
          polygonColor = Colors.deepOrange.shade600;
          borderColor = Colors.deepOrange.shade800;
        } else if (pattern == 'decline') {
          polygonColor = Colors.lightBlue.shade600;
          borderColor = Colors.lightBlue.shade800;
        } else {
          polygonColor = Colors.green.shade600;
          borderColor = Colors.green.shade800;
        }
      }
      // For moderate risk
      else if (riskLevel == 'moderate') {
        if (pattern == 'spike') {
          polygonColor = Colors.deepOrange.shade600;
          borderColor = Colors.deepOrange.shade800;
        } else {
          polygonColor = Colors.orange.shade500;
          borderColor = Colors.orange.shade700;
        }
      }
      // Default fallback
      else {
        polygonColor = Colors.grey.shade700;
        borderColor = Colors.grey.shade800;
      }

      updatedPolygons.add(Polygon(
        polygonId: polygon.polygonId,
        points: polygon.points,
        strokeColor: _selectedPolygonId == polygon.polygonId
            ? Colors.redAccent
            : borderColor,
        strokeWidth: _selectedPolygonId == polygon.polygonId ? 4 : 2,
        fillColor: polygonColor.withOpacity(0.3),
        consumeTapEvents: true,
        onTap: () {
          _onBarangayPolygonTapped(barangayName);
        },
      ));
    }

    setState(() {
      _barangayPolygons = updatedPolygons;
    });
  }

  Future<void> _fetchDengueData() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Config.baseUrl}/api/v1/analytics/retrieve-pattern-recognition-results'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _dengueData = Map.fromEntries(
              (data['data'] as List).map((item) => MapEntry(
                    item['name'],
                    {
                      'cases':
                          0, // Since the API doesn't provide cases, we'll use 0
                      'severity':
                          item['risk_level']?.toString().toLowerCase() ??
                              'Unknown',
                      'alert': item['alert'],
                      'pattern': item['triggered_pattern'],
                    },
                  )),
            );
            _isLoadingData = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching dengue data: $e');
      setState(() => _isLoadingData = false);
    }
  }
}
