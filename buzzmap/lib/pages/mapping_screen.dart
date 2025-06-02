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
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';

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
    with TickerProviderStateMixin {
  late GoogleMapController _mapController;
  String? selectedDistrict;
  String? selectedBarangay;
  Set<Circle> _circles = {};
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  Set<Polygon> _barangayPolygons = {};
  Set<Polyline> _polylines = {};
  String? selectedSeverity;

  Map<String, String> hazardRiskLevels = {};

  PolygonId? _selectedPolygonId;

  Map<String, LatLng> _barangayCentroids = {};
  bool _isCardVisible = false;

  bool _isLoading = true;
  bool _isLoadingMarkers = false;
  bool _isLoadingRiskLevels = false;
  bool _isLoadingInterventions = false;
  MapType _currentMapType = MapType.normal;

  // Animation controllers and animations
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  bool _showTooltip = false;
  Timer? _tooltipTimer;
  late AnimationController _tooltipAnimationController;
  late Animation<double> _tooltipAnimation;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(14.6760, 121.0437), // Center of Quezon City
    zoom: 11.4,
  );

  // Layer control options
  final Map<String, bool> _layerOptions = {
    'Borders': true,
    'Markers': false,
    'Interventions': false,
  };

  // Add new set for intervention markers
  Set<Marker> _interventionMarkers = {};

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

  Set<Marker> _clusterMarkers = {};
  double _currentZoom = 11.4;
  static const double _clusterDistance =
      0.01; // Distance threshold for clustering

  bool _isMapReady = false; // Add this flag

  @override
  void initState() {
    super.initState();
    // Initialize bounce animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize tooltip animation
    _tooltipAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tooltipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _tooltipAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize pulse animation
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize layer options
    _layerOptions['Borders'] = true;
    _layerOptions['Markers'] = widget.reportId != null;
    _layerOptions['Heatmap'] = false;

    // Start the new initialization sequence
    _initializeMappingScreen();
  }

  Future<void> _initializeMappingScreen() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Fetch dengue data first
      await _fetchDengueData();
      // Fetch risk levels
      await _fetchRiskLevels();
      // Load GeoJSON
      await _loadGeoJSON();
      // Optionally, initialize location services (don't block UI)
      Future.delayed(const Duration(seconds: 1), () {
        _initializeLocationServices();
      });
      // If we have initial coordinates from a notification, add a marker
      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        setState(() {
          _markers.add(
            Marker(
              markerId: const MarkerId('notification-marker'),
              position:
                  LatLng(widget.initialLatitude!, widget.initialLongitude!),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            ),
          );
        });
      }
      // Using a slight delay to ensure Google Maps is fully loaded
      Timer(const Duration(milliseconds: 500), () {
        _updateMapLayers();
      });
      // Start polling for alerts
      _alertService.startPolling();
    } catch (e) {
      print('Error initializing mapping screen: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateMarkers(Set<Marker> markers) {
    setState(() {
      _clusterMarkers = markers;
    });
  }

  @override
  void dispose() {
    // Cancel the location check timer
    _locationCheckTimer?.cancel();
    _locationCheckTimer = null;

    // Safely dispose the map controller if it exists
    if (_mapController != null) {
      _mapController.dispose();
    }

    // Dispose the bounce controller
    _animationController.dispose();

    // Clear any existing notifications
    LocationNotificationService.dismiss();

    _alertService.dispose();

    _tooltipTimer?.cancel();
    _tooltipAnimationController.dispose();
    _pulseAnimationController.dispose();

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

  Future<void> _updateMapLayers() async {
    Set<Polygon> polygons = {};
    Set<Marker> markers = {};

    // Add polygons if Borders is enabled
    if (_layerOptions['Borders']!) {
      // Update polygon styles based on whether markers or interventions are enabled
      Set<Polygon> updatedPolygons = _barangayPolygons.map((polygon) {
        final barangayName = polygon.polygonId.value;
        final pattern = _barangayPatterns[barangayName]?.toLowerCase();

        Color borderColor;
        Color fillColor;

        if (_layerOptions['Markers']! || _layerOptions['Interventions']!) {
          // When markers or interventions are enabled, all borders should be green
          borderColor = Colors.green;
          fillColor = Colors.green.withOpacity(0.4); // Increased opacity
        } else {
          // When markers/interventions are disabled, use pattern-based colors
          switch (pattern) {
            case 'spike':
              borderColor = _selectedPolygonId == polygon.polygonId
                  ? Colors.red.shade900
                  : Colors.red.shade800;
              fillColor =
                  Colors.red.shade700.withOpacity(0.5); // Increased opacity
              break;
            case 'gradual_rise':
              borderColor = _selectedPolygonId == polygon.polygonId
                  ? Colors.orange.shade900
                  : Colors.orange.shade800;
              fillColor =
                  Colors.orange.shade500.withOpacity(0.5); // Increased opacity
              break;
            case 'decline':
              borderColor = _selectedPolygonId == polygon.polygonId
                  ? Colors.green.shade900
                  : Colors.green.shade800;
              fillColor =
                  Colors.green.shade600.withOpacity(0.5); // Increased opacity
              break;
            case 'stable':
            case 'stability':
              borderColor = _selectedPolygonId == polygon.polygonId
                  ? Colors.lightBlue.shade900
                  : Colors.lightBlue.shade800;
              fillColor = Colors.lightBlue.shade600
                  .withOpacity(0.5); // Increased opacity
              break;
            default:
              borderColor = _selectedPolygonId == polygon.polygonId
                  ? Colors.grey.shade900
                  : Colors.grey.shade800;
              fillColor =
                  Colors.grey.shade700.withOpacity(0.5); // Increased opacity
          }
        }

        return Polygon(
          polygonId: polygon.polygonId,
          points: polygon.points,
          strokeColor: borderColor,
          strokeWidth: _selectedPolygonId == polygon.polygonId
              ? 3
              : 2, // Increased stroke width
          fillColor: fillColor,
          consumeTapEvents: true,
          onTap: () {
            _onBarangayPolygonTapped(polygon.polygonId.value);
          },
        );
      }).toSet();
      polygons = updatedPolygons;
    }

    // Add markers if Markers is enabled
    if (_layerOptions['Markers']!) {
      markers = await _loadVerifiedReportMarkers();
    }

    // Add intervention markers if Interventions is enabled
    if (_layerOptions['Interventions']!) {
      await _fetchInterventions();
      markers = markers.union(_interventionMarkers);
    }

    if (mounted) {
      setState(() {
        _polygons = polygons;
        _markers = markers;
      });
    }
  }

  void _updatePolygonsWithRiskLevels() {
    Set<Polygon> updatedPolygons = {};

    // Name mapping for special cases
    final nameMapping = {
      'E. Rodriguez Sr.': 'E. Rodriguez',
      // Add more mappings if needed
    };

    for (var polygon in _barangayPolygons) {
      final barangayName = polygon.polygonId.value;
      // Check if we need to map this name
      final lookupName = nameMapping[barangayName] ?? barangayName;
      final pattern = _barangayPatterns[lookupName]?.toLowerCase();
      print(
          'Updating polygon for $barangayName (mapped to $lookupName) with pattern: $pattern'); // Debug log

      Color polygonColor;
      Color borderColor;

      // If report markers are enabled, use green borders
      if (_layerOptions['Markers']!) {
        polygonColor = Colors.transparent;
        borderColor = Colors.green;
      } else {
        // If no data is available, use gray
        if (pattern == null) {
          print(
              'No pattern data for polygon $barangayName (mapped to $lookupName)'); // Debug log
          polygonColor = Colors.grey.shade700;
          borderColor = Colors.grey.shade800;
        } else {
          // Color based on pattern status
          switch (pattern) {
            case 'spike':
              polygonColor = Colors.red.shade700;
              borderColor = Colors.red.shade900;
              break;
            case 'gradual_rise':
              polygonColor = Colors.orange.shade500;
              borderColor = Colors.orange.shade700;
              break;
            case 'decline':
              polygonColor = Colors.green.shade600;
              borderColor = Colors.green.shade800;
              break;
            case 'stable':
            case 'stability':
              polygonColor = Colors.lightBlue.shade600;
              borderColor = Colors.lightBlue.shade800;
              break;
            default:
              print(
                  'Unknown pattern for polygon $barangayName (mapped to $lookupName): $pattern'); // Debug log
              polygonColor = Colors.grey.shade700;
              borderColor = Colors.grey.shade800;
          }
        }
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

  Future<Set<Marker>> _loadVerifiedReportMarkers() async {
    if (!_layerOptions['Markers']!) return {};

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        print('❌ No auth token found');
        return {};
      }

      print('🔍 Fetching reports with token: ${token.substring(0, 10)}...');
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/reports'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> reports = jsonDecode(response.body);
        print('📊 Total reports fetched: ${reports.length}');

        final verifiedReports = reports.where((r) {
          final status = r['status']?.toString().toLowerCase();
          final isVerified = status == 'validated';
          print('🔍 Report status: $status, isVerified: $isVerified');
          return isVerified;
        }).toList();

        print('✅ Verified reports: ${verifiedReports.length}');

        // Create markers
        final markers = verifiedReports
            .map((report) {
              final coords = report['specific_location']?['coordinates'];
              if (coords == null || coords.length != 2) {
                print('❌ Invalid coordinates for report: ${report['_id']}');
                return null;
              }

              final position = LatLng(coords[1], coords[0]);
              final barangay = report['barangay'] ?? 'Unknown';

              return Marker(
                markerId: MarkerId(report['_id']),
                position: position,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed),
                onTap: () {
                  _showDengueDetails(
                    context,
                    barangay,
                    1,
                    'Verified',
                    position,
                  );
                },
              );
            })
            .whereType<Marker>()
            .toList();

        // Apply clustering based on zoom level
        if (_currentZoom < 12) {
          // Changed from 14 to 12
          return _createClusters(markers);
        } else {
          return markers.toSet();
        }
      } else {
        print('❌ Failed to fetch reports: ${response.statusCode}');
        if (response.statusCode == 401) {
          print('Authentication failed. Please log in again.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please log in to view reports'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        return {};
      }
    } catch (e) {
      print('❌ Exception in _loadVerifiedReportMarkers: $e');
      return {};
    }
  }

  Set<Marker> _createClusters(List<Marker> markers) {
    final clusters = <Marker>[];
    final processed = <String>{};

    for (var i = 0; i < markers.length; i++) {
      if (processed.contains(markers[i].markerId.value)) continue;

      final cluster = <Marker>[markers[i]];
      processed.add(markers[i].markerId.value);

      for (var j = i + 1; j < markers.length; j++) {
        if (processed.contains(markers[j].markerId.value)) continue;

        if (_areMarkersClose(markers[i], markers[j])) {
          cluster.add(markers[j]);
          processed.add(markers[j].markerId.value);
        }
      }

      if (cluster.length > 1) {
        // Create cluster marker
        final clusterPosition = _getClusterCenter(cluster);
        clusters.add(
          Marker(
            markerId: MarkerId(
                'cluster_${clusterPosition.latitude}_${clusterPosition.longitude}'),
            position: clusterPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet),
            infoWindow: InfoWindow(
              title: '${cluster.length} Reports',
              snippet: 'Tap to zoom in',
            ),
            onTap: () {
              _zoomToCluster(cluster);
            },
          ),
        );
      } else {
        clusters.add(cluster[0]);
      }
    }

    return clusters.toSet();
  }

  bool _areMarkersClose(Marker m1, Marker m2) {
    final latDiff = (m1.position.latitude - m2.position.latitude).abs();
    final lngDiff = (m1.position.longitude - m2.position.longitude).abs();
    return latDiff < _clusterDistance && lngDiff < _clusterDistance;
  }

  LatLng _getClusterCenter(List<Marker> markers) {
    double latSum = 0;
    double lngSum = 0;
    for (var marker in markers) {
      latSum += marker.position.latitude;
      lngSum += marker.position.longitude;
    }
    return LatLng(
      latSum / markers.length,
      lngSum / markers.length,
    );
  }

  void _zoomToCluster(List<Marker> cluster) {
    final bounds = LatLngBounds(
      southwest: LatLng(
        cluster.map((m) => m.position.latitude).reduce(min),
        cluster.map((m) => m.position.longitude).reduce(min),
      ),
      northeast: LatLng(
        cluster.map((m) => m.position.latitude).reduce(max),
        cluster.map((m) => m.position.longitude).reduce(max),
      ),
    );

    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  bool _isPointInBounds(LatLng point, LatLngBounds bounds) {
    return bounds.contains(point);
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
          strokeColor: Colors.white, // Changed to white
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
    print('Getting color for severity: $severity');
    switch (severity.toLowerCase()) {
      case 'spike':
        return Colors.red.shade700;
      case 'gradual_rise':
        return Colors.orange.shade500;
      case 'decline':
        return Colors.green.shade600;
      case 'stable':
        return Colors.lightBlue.shade600;
      default:
        print('Unknown severity: $severity, using grey');
        return Colors.grey.shade700;
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
    final data = _dengueData[barangayName];
    final riskLevel = data?['severity']?.toLowerCase() ?? 'no data';
    final pattern = data?['pattern']?.toLowerCase() ?? '';
    final alert = data?['alert'] ?? 'No alerts triggered.';
    final lastAnalysisTime = data?['last_analysis_time'];

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
        'Alert': alert,
        'LastAnalysisTime': lastAnalysisTime,
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
                          onMapCreated: (controller) {
                            _mapController = controller;
                            setState(() {
                              _isMapReady = true;
                            });
                          },
                          circles: _circles,
                          markers: _layerOptions['Markers']!
                              ? _clusterMarkers.union(
                                  _layerOptions['Interventions']!
                                      ? _interventionMarkers
                                      : {})
                              : _layerOptions['Interventions']!
                                  ? _interventionMarkers
                                  : _markers,
                          polygons: _polygons,
                          polylines: _polylines,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                          mapToolbarEnabled: false,
                          onCameraMove: (position) {
                            setState(() {
                              _currentZoom = position.zoom;
                              if (_currentZoom > 12 && !_showTooltip) {
                                _showResetTooltip();
                              }
                            });
                          },
                          onCameraIdle: () {
                            if (_layerOptions['Markers']!) {
                              _loadVerifiedReportMarkers().then((markers) {
                                setState(() {
                                  _clusterMarkers = markers;
                                });
                              });
                            }
                          },
                        ),
                        if (_isLoading || !_isMapReady)
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isLoadingMarkers
                                        ? 'Loading report markers...'
                                        : _isLoadingRiskLevels
                                            ? 'Loading risk levels...'
                                            : _isLoadingInterventions
                                                ? 'Loading interventions...'
                                                : 'Loading map data...',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        _buildLayerControls(),
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
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        height: 1.2,
                                                        letterSpacing: 1.0,
                                                      ),
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              'Broad Urban Zone and Zeroing\n',
                                                          style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              'Metropolitan Active Prevention',
                                                          style: TextStyle(
                                                            color: Color(
                                                                0xFF4AA8C7),
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
                                            RecommendationsWidget(
                                              severity:
                                                  selectedSeverity ?? 'Unknown',
                                              hazardRiskLevels:
                                                  hazardRiskLevels,
                                              latitude: _barangayCentroids[
                                                          selectedBarangay ??
                                                              '']
                                                      ?.latitude ??
                                                  14.6760,
                                              longitude: _barangayCentroids[
                                                          selectedBarangay ??
                                                              '']
                                                      ?.longitude ??
                                                  121.0437,
                                              selectedBarangay:
                                                  selectedBarangay ?? '',
                                              barangayColor:
                                                  _getColorForBarangay(
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
      top: 80, // Moved down to avoid overlap with header
      right: 12,
      child: Column(
        children: [
          Container(
            decoration: _buttonStyle().copyWith(
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.layers, color: Colors.blue),
              onPressed: () => _showLayerOptions(context),
              tooltip: 'Layer Controls',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: _buttonStyle().copyWith(
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blue),
              onPressed: () => _showMapLegend(context),
              tooltip: 'Map Legend',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: _buttonStyle().copyWith(
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.map, color: Colors.blue),
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
          if (_currentZoom > 12) ...[
            const SizedBox(height: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        decoration: _buttonStyle().copyWith(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.center_focus_strong,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            _mapController.animateCamera(
                              CameraUpdate.newCameraPosition(
                                const CameraPosition(
                                  target: LatLng(14.6760, 121.0437),
                                  zoom: 11.4,
                                ),
                              ),
                            );
                          },
                          tooltip: 'Reset View',
                        ),
                      ),
                    );
                  },
                ),
                if (_showTooltip)
                  Positioned(
                    right: 50,
                    top: -35,
                    child: FadeTransition(
                      opacity: _tooltipAnimation,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Reset to city view',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Arrow pointer
                          Positioned(
                            right: -6,
                            bottom: -6,
                            child: Transform.rotate(
                              angle: -0.785398, // 45 degrees in radians
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
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
                _buildLayerSwitch(
                  'Interventions',
                  'Shows locations of dengue interventions',
                  'Interventions',
                  setState,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Set loading state based on which options are enabled
              setState(() {
                if (_layerOptions['Markers']!) {
                  _isLoadingMarkers = true;
                }
                if (_layerOptions['Borders']!) {
                  _isLoadingRiskLevels = true;
                }
                if (_layerOptions['Interventions']!) {
                  _isLoadingInterventions = true;
                }
              });

              // Update map layers
              await _updateMapLayers();

              // Clear loading states
              if (mounted) {
                setState(() {
                  _isLoadingMarkers = false;
                  _isLoadingRiskLevels = false;
                  _isLoadingInterventions = false;
                });
              }
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
        value: _layerOptions[optionKey] ?? false,
        onChanged: (value) {
          setState(() {
            if (value) {
              // If turning on Report Markers, ensure Borders stay enabled
              if (optionKey == 'Markers') {
                _layerOptions['Borders'] = true;
              }
              // Turn off other options except Borders
              _layerOptions.forEach((key, _) {
                if (key != 'Borders') {
                  _layerOptions[key] = false;
                }
              });
            }
            // Set the selected option
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
        title: const Text('Dengue Pattern Recognition'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendRow(
                Colors.grey.shade700, 'No Data', 'Information not available'),
            const SizedBox(height: 8),
            _buildLegendRow(
                Colors.red.shade700, 'Spike', 'Sudden increase in cases'),
            _buildLegendRow(Colors.orange.shade500, 'Gradual Rise',
                'Steady increase in cases'),
            const SizedBox(height: 8),
            _buildLegendRow(
                Colors.green.shade600, 'Decline', 'Decreasing trend'),
            _buildLegendRow(
                Colors.lightBlue.shade600, 'Stable', 'No significant change'),
            const SizedBox(height: 16),
            const Text(
              'Areas are color-coded based on dengue case patterns. Click on any area to see detailed information.',
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
    // Dynamic legend: show risk levels legend only if Interventions is OFF
    if (_layerOptions['Interventions'] == true) {
      // Show a legend for interventions using images and names
      final interventionTypes = [
        {'name': 'Fogging', 'asset': 'assets/icons/fogging.png'},
        {'name': 'Education', 'asset': 'assets/icons/education.png'},
        {'name': 'Cleanup', 'asset': 'assets/icons/cleanup.png'},
        {'name': 'Trapping', 'asset': 'assets/icons/trapping.png'},
        {'name': 'Default', 'asset': 'assets/icons/default.png'},
      ];
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
            children: interventionTypes.map((type) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      type['asset']!,
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type['name']!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    } else {
      // Default risk levels legend
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
              _legendItem(Colors.grey.shade700, 'No Data'),
              const SizedBox(width: 8),
              _legendItem(Colors.lightBlue.shade600, 'Stable'),
              const SizedBox(width: 8),
              _legendItem(Colors.green.shade600, 'Decline'),
              const SizedBox(width: 8),
              _legendItem(Colors.orange.shade500, 'Gradual Rise'),
              const SizedBox(width: 8),
              _legendItem(Colors.red.shade700, 'Spike'),
            ],
          ),
        ),
      );
    }
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

  Future<List<LatLng>> _getDirections(LatLng origin, LatLng destination) async {
    final apiKey = 'AIzaSyC1qJ8pzXVWuWOEyc7svbEKDa_HEPE2EL0';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        final List<LatLng> points = [];
        final List<dynamic> steps = data['routes'][0]['legs'][0]['steps'];

        for (var step in steps) {
          final String polyline = step['polyline']['points'];
          points.addAll(_decodePolyline(polyline));
        }

        return points;
      }
    } catch (e) {
      print('Error getting directions: $e');
    }

    // Fallback to direct line if directions fail
    return [origin, destination];
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final p = LatLng(lat / 1E5, lng / 1E5);
      poly.add(p);
    }
    return poly;
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FutureBuilder<List<Map<String, dynamic>>>(
        future:
            fetchNearbyHealthFacilities(location.latitude, location.longitude),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final facilities = snapshot.data!;
          int _currentFacilityPage = 0;
          final PageController _pageController = PageController();
          return StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getColorForSeverity(severity),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            severity,
                            style: TextStyle(
                              color: severity == 'Low'
                                  ? Colors.black
                                  : Colors.white,
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

                    const SizedBox(height: 20),
                    // --- Critical Facilities Carousel ---
                    const Text(
                      'Health Care Facilities Nearby:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (facilities.isEmpty)
                      const Text('No nearby health facilities found.'),
                    if (facilities.isNotEmpty)
                      SizedBox(
                        height: 170,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_left,
                                  size: 32, color: Colors.blue),
                              onPressed: () {
                                if (_currentFacilityPage > 0) {
                                  setModalState(() {
                                    _currentFacilityPage--;
                                    _pageController.animateToPage(
                                      _currentFacilityPage,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  });
                                }
                              },
                            ),
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: facilities.length,
                                onPageChanged: (index) {
                                  setModalState(() {
                                    _currentFacilityPage = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final facility = facilities[index];
                                  return GestureDetector(
                                    onTap: () async {
                                      // Close the bottom sheet
                                      Navigator.pop(context);

                                      // First zoom out slightly to show context
                                      _mapController.animateCamera(
                                        CameraUpdate.newCameraPosition(
                                          CameraPosition(
                                            target: LatLng(
                                              facility['lat'],
                                              facility['lng'],
                                            ),
                                            zoom: 14.0,
                                          ),
                                        ),
                                      );

                                      // Get directions between report and facility
                                      final routePoints = await _getDirections(
                                        location,
                                        LatLng(
                                            facility['lat'], facility['lng']),
                                      );

                                      // Update markers and polyline in the main widget's state
                                      this.setState(() {
                                        // Remove any existing facility markers and polylines
                                        _markers.removeWhere((marker) => marker
                                            .markerId.value
                                            .startsWith('facility-'));
                                        _polylines.clear();

                                        // Add new marker
                                        _markers.add(
                                          Marker(
                                            markerId: MarkerId(
                                                'facility-${facility['name']}'),
                                            position: LatLng(
                                              facility['lat'],
                                              facility['lng'],
                                            ),
                                            icon: BitmapDescriptor
                                                .defaultMarkerWithHue(
                                              BitmapDescriptor.hueBlue,
                                            ),
                                            infoWindow: InfoWindow(
                                              title: facility['name'],
                                              snippet:
                                                  '${facility['type']} • ${facility['distance_km'].toStringAsFixed(1)} km away',
                                            ),
                                          ),
                                        );

                                        // Add glow effect polyline
                                        _polylines.add(
                                          Polyline(
                                            polylineId:
                                                const PolylineId('route-glow'),
                                            points: routePoints,
                                            color: const Color(0xFFFFD700)
                                                .withOpacity(
                                                    0.3), // Semi-transparent yellow
                                            width:
                                                12, // Wider than the main line
                                            patterns: [
                                              PatternItem.dash(40),
                                              PatternItem.gap(20),
                                            ],
                                          ),
                                        );

                                        // Add main polyline with proper route
                                        _polylines.add(
                                          Polyline(
                                            polylineId:
                                                const PolylineId('route'),
                                            points: routePoints,
                                            color: const Color(
                                                0xFFFFD700), // Bright golden yellow
                                            width: 6, // Increased width
                                            patterns: [
                                              PatternItem.dash(
                                                  40), // Longer dashes
                                              PatternItem.gap(
                                                  20), // Longer gaps
                                            ],
                                          ),
                                        );
                                      });

                                      // After a short delay, zoom in closer
                                      Future.delayed(
                                          const Duration(milliseconds: 800),
                                          () {
                                        _mapController.animateCamera(
                                          CameraUpdate.newCameraPosition(
                                            CameraPosition(
                                              target: LatLng(
                                                facility['lat'],
                                                facility['lng'],
                                              ),
                                              zoom: 16.5,
                                              tilt: 45.0,
                                            ),
                                          ),
                                        );
                                      });

                                      // Show a snackbar with facility info
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Viewing ${facility['name']}',
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          duration: const Duration(seconds: 3),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 13, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      color: Colors.white,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      facility['name'],
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      facility['type'],
                                                      style: const TextStyle(
                                                        color: Colors.blue,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on,
                                                    size: 14,
                                                    color: Colors.black54,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      facility['vicinity'],
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              if (facility['distance_km'] !=
                                                  null)
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.directions_walk,
                                                      size: 14,
                                                      color: Colors.black54,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${facility['distance_km'].toStringAsFixed(1)} km away',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              const SizedBox(height: 12),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.touch_app,
                                                      color: Colors.blue,
                                                      size: 16,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Tap to view on map',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.blue,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_right,
                                  size: 32, color: Colors.blue),
                              onPressed: () {
                                if (_currentFacilityPage <
                                    facilities.length - 1) {
                                  setModalState(() {
                                    _currentFacilityPage++;
                                    _pageController.animateToPage(
                                      _currentFacilityPage,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    if (facilities.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(facilities.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentFacilityPage == index ? 16 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentFacilityPage == index
                                  ? Colors.blue
                                  : Colors.blue.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }),
                      ),
                    const SizedBox(height: 20),
                    // View Detailed Report Button
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
                                streetName: streetName,
                                latitude: location.latitude,
                                longitude: location.longitude,
                                cases: _dengueData[barangay]?['cases'] as int,
                                severity: _dengueData[barangay]?['severity']
                                    as String,
                                district: selectedDistrict,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('View Detailed Report'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Add this helper function to calculate distance between two lat/lng points in km
  // Haversine formula
  double calculateDistanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371; // km
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) *
            cos(lat2 * pi / 180.0) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  Future<List<Map<String, dynamic>>> fetchNearbyHealthFacilities(
      double lat, double lng) async {
    final apiKey = 'AIzaSyC1qJ8pzXVWuWOEyc7svbEKDa_HEPE2EL0';

    // Single API call for all health facilities
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=1000&type=hospital&key=$apiKey';
    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      final List<Map<String, dynamic>> facilities =
          (data['results'] as List).map((place) {
        final List types = place['types'] ?? [];
        String facilityType = '';
        final nameLower = place['name'].toString().toLowerCase();

        // Strict filtering for admitting facilities
        if (types.contains('hospital')) {
          // Check for specific hospital types that can admit patients
          if (nameLower.contains('general hospital') ||
              nameLower.contains('medical center') ||
              nameLower.contains('regional hospital') ||
              nameLower.contains('provincial hospital') ||
              nameLower.contains('city hospital') ||
              nameLower.contains('university hospital') ||
              nameLower.contains('specialty hospital') ||
              nameLower.contains('tertiary hospital') ||
              nameLower.contains('secondary hospital')) {
            facilityType = 'Hospital';
          }
        } else if (nameLower.contains('health center') ||
            nameLower.contains('healthcare')) {
          // Only include major health centers that can admit patients
          if (nameLower.contains('regional') ||
              nameLower.contains('provincial') ||
              nameLower.contains('city') ||
              nameLower.contains('district')) {
            facilityType = 'Health Center';
          }
        }

        // Exclude facilities that are clearly not admitting facilities
        if (nameLower.contains('clinic') ||
            nameLower.contains('diagnostic') ||
            nameLower.contains('laboratory') ||
            nameLower.contains('imaging') ||
            nameLower.contains('radiology') ||
            nameLower.contains('outpatient') ||
            nameLower.contains('ambulatory') ||
            nameLower.contains('animal') ||
            nameLower.contains('pet') ||
            nameLower.contains('veterinary') ||
            nameLower.contains('vet') ||
            nameLower.contains('airgun') ||
            nameLower.contains('shooting') ||
            nameLower.contains('dental') ||
            nameLower.contains('optical') ||
            nameLower.contains('eye') ||
            nameLower.contains('vision') ||
            nameLower.contains('skin') ||
            nameLower.contains('dermatology') ||
            nameLower.contains('wellness') ||
            nameLower.contains('spa')) {
          facilityType = '';
        }

        return {
          'name': place['name'],
          'type': facilityType,
          'vicinity': place['vicinity'] ?? '',
          'lat': place['geometry']['location']['lat'],
          'lng': place['geometry']['location']['lng'],
        };
      }).toList();

      // Remove duplicates and filter by type
      final seen = <String>{};
      final all = <Map<String, dynamic>>[];

      for (final facility in facilities) {
        final key = facility['name'] + facility['vicinity'];
        if (!seen.contains(key) && facility['type'].isNotEmpty) {
          // Calculate distance from report location to facility
          final distance = calculateDistanceKm(
            lat,
            lng,
            facility['lat'],
            facility['lng'],
          );
          facility['distance_km'] = distance;
          seen.add(key);
          all.add(facility);
        }
      }

      // Sort facilities by distance
      all.sort((a, b) =>
          (a['distance_km'] as double).compareTo(b['distance_km'] as double));

      return all;
    }
    return [];
  }

  Future<void> _fetchRiskLevels() async {
    try {
      print('Fetching risk levels from API...');
      final response = await http.get(
        Uri.parse(
            '${Config.baseUrl}/api/v1/analytics/retrieve-pattern-recognition-results'),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed data: $data');

        if (data['success'] == true && data['data'] != null) {
          print('Data array length: ${(data['data'] as List).length}');

          setState(() {
            _barangayRiskLevels = {};
            _barangayPatterns = {};
            _barangayAlerts = {};

            // Name mapping for special cases
            final nameMapping = {
              'E. Rodriguez Sr.': 'E. Rodriguez',
              // Add more mappings if needed
            };

            for (var item in data['data'] as List) {
              String name = item['name'];
              // Check if we need to map this name
              if (nameMapping.containsKey(name)) {
                name = nameMapping[name]!;
              }

              print('Processing barangay: $name');
              print('Item data: $item');

              // Handle pattern directly from the pattern field
              String pattern =
                  item['pattern']?.toString().toLowerCase() ?? 'stable';
              _barangayPatterns[name] = pattern;
              print('Set pattern for $name: ${_barangayPatterns[name]}');

              // Handle alert
              _barangayAlerts[name] = item['alert']?.toString() ?? '';
              print('Set alert for $name: ${_barangayAlerts[name]}');
            }

            print('Final _barangayPatterns: $_barangayPatterns');
            print('Final _barangayAlerts: $_barangayAlerts');
          });

          // Update polygons with new risk levels and patterns
          _updatePolygonsWithRiskLevels();

          // Force a map update
          _updateMapLayers();
        } else {
          print('API response indicates failure or no data');
          print('Success flag: ${data['success']}');
          print('Data present: ${data['data'] != null}');
        }
      } else {
        print('API request failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching risk levels: $e');
      print('Error stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _fetchDengueData() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/barangays/get-all-barangays'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _dengueData = Map.fromEntries(
              data.map((item) => MapEntry(
                    item['name'],
                    {
                      'cases':
                          0, // Since the API doesn't provide cases, we'll use 0
                      'severity':
                          item['risk_level']?.toString().toLowerCase() ??
                              'Unknown',
                      'alert': item['status_and_recommendation']
                              ?['pattern_based']?['alert'] ??
                          'No alerts triggered.',
                      'pattern': item['status_and_recommendation']
                              ?['pattern_based']?['status'] ??
                          '',
                      'last_analysis_time': item['last_analysis_time'],
                    },
                  )),
            );
            _isLoadingData = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching dengue data: $e');
      print('Error stack trace: ${StackTrace.current}');
    }
  }

  Future<BitmapDescriptor> _getInterventionMarkerIcon(
      String interventionType, String status) async {
    // Define marker colors based on status
    final statusColors = {
      'complete': BitmapDescriptor.hueGreen,
      'scheduled': BitmapDescriptor.hueBlue,
      'ongoing': BitmapDescriptor.hueYellow,
    };

    // Get base color from status
    final baseColor =
        statusColors[status.toLowerCase()] ?? BitmapDescriptor.hueYellow;

    // Create custom marker with intervention type icon
    String iconPath;
    switch (interventionType.toLowerCase()) {
      case 'fogging':
        iconPath = 'assets/icons/fogging.png';
        break;
      case 'ovicidal-larvicidal trapping':
        iconPath = 'assets/icons/trapping.png';
        break;
      case 'clean-up drive':
        iconPath = 'assets/icons/cleanup.png';
        break;
      case 'education campaign':
        iconPath = 'assets/icons/education.png';
        break;
      default:
        iconPath = 'assets/icons/default.png';
    }

    try {
      // Try to load the custom marker image
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        iconPath,
      );
    } catch (e) {
      print('Error loading custom marker icon: $e');
      // Fallback to default marker with status color
      return BitmapDescriptor.defaultMarkerWithHue(baseColor);
    }
  }

  Future<void> _fetchInterventions() async {
    try {
      print('Fetching interventions...'); // Debug log

      // Get the auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null) {
        print('No auth token found for interventions');
        return;
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/interventions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(
          'Interventions response status: ${response.statusCode}'); // Debug log
      print('Interventions response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final List<dynamic> interventions = jsonDecode(response.body);
        print(
            'Number of interventions found: ${interventions.length}'); // Debug log

        // Create a temporary set to store markers
        final Set<Marker> newMarkers = {};

        // Process each intervention and create markers
        for (var intervention in interventions) {
          final coords = intervention['specific_location']['coordinates'];
          final position = LatLng(coords[1], coords[0]);
          final status =
              intervention['status']?.toString().toLowerCase() ?? 'scheduled';
          final interventionType =
              intervention['interventionType'] ?? 'Unknown';
          final date = DateTime.parse(intervention['date']);
          final formattedDate = '${date.day}/${date.month}/${date.year}';

          print(
              'Creating marker for intervention: $interventionType at ${position.latitude}, ${position.longitude}'); // Debug log

          // Get custom marker icon
          final markerIcon =
              await _getInterventionMarkerIcon(interventionType, status);

          // Create and add the marker
          newMarkers.add(
            Marker(
              markerId: MarkerId(intervention['_id']),
              position: position,
              icon: markerIcon,
              infoWindow: InfoWindow(
                title: interventionType,
                snippet:
                    'Status: ${status.toUpperCase()}\nDate: $formattedDate',
              ),
              onTap: () {
                _showInterventionDetails(intervention);
              },
            ),
          );
        }

        // Update the state with the new markers
        setState(() {
          _interventionMarkers = newMarkers;
        });

        print(
            'Number of intervention markers created: ${_interventionMarkers.length}'); // Debug log
      } else {
        print('Failed to fetch interventions: ${response.statusCode}');
        if (response.statusCode == 401) {
          print('Authentication failed. Please log in again.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please log in to view interventions'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error fetching interventions: $e');
    }
  }

  Color _getColorForBarangay(String barangayName) {
    // Name mapping for special cases
    final nameMapping = {
      'E. Rodriguez Sr.': 'E. Rodriguez',
      // Add more mappings if needed
    };

    // Check if we need to map this name
    final lookupName = nameMapping[barangayName] ?? barangayName;
    final pattern = _barangayPatterns[lookupName]?.toLowerCase();
    print(
        'Getting color for $barangayName (mapped to $lookupName) with pattern: $pattern'); // Debug log

    // If no data is available, return gray
    if (pattern == null) {
      print(
          'No pattern data for $barangayName (mapped to $lookupName)'); // Debug log
      return Colors.grey.shade700;
    }

    // Color based on pattern status
    switch (pattern) {
      case 'spike':
        return Colors.red.shade700;
      case 'gradual_rise':
        return Colors.orange.shade500;
      case 'decline':
        return Colors.green.shade600;
      case 'stable':
      case 'stability':
        return Colors.lightBlue.shade600;
      default:
        print(
            'Unknown pattern for $barangayName (mapped to $lookupName): $pattern'); // Debug log
        return Colors.grey.shade700;
    }
  }

  void _showResetTooltip() {
    setState(() {
      _showTooltip = true;
    });
    _tooltipAnimationController.forward();

    // Cancel any existing timer
    _tooltipTimer?.cancel();

    // Set new timer to hide tooltip
    _tooltipTimer = Timer(const Duration(seconds: 3), () {
      _tooltipAnimationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _showTooltip = false;
          });
        }
      });
    });
  }

  // Add function to show intervention details
  void _showInterventionDetails(Map<String, dynamic> intervention) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              intervention['interventionType'] ?? 'Unknown Intervention',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Status',
                intervention['status']?.toString().toUpperCase() ?? 'Unknown'),
            _buildInfoRow('Date',
                DateTime.parse(intervention['date']).toString().split(' ')[0]),
            _buildInfoRow('Address', intervention['address'] ?? 'Unknown'),
            _buildInfoRow('Barangay', intervention['barangay'] ?? 'Unknown'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _zoomToLocation(
                    LatLng(
                      intervention['specific_location']['coordinates'][1],
                      intervention['specific_location']['coordinates'][0],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('View on Map'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
