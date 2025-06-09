import 'package:buzzmap/widgets/floatingactionbutton/yellow_gradient_button.dart';
import 'package:buzzmap/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:buzzmap/data/dengue_data.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:convert';
import 'dart:math' show min, max;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:buzzmap/auth/config.dart';
import 'package:provider/provider.dart';
import 'package:buzzmap/providers/vote_provider.dart';
import 'package:buzzmap/providers/post_provider.dart';
import 'package:flutter/services.dart';

class LocationDetailsScreen extends StatefulWidget {
  final String location;
  final String? district;
  final double latitude;
  final double longitude;
  final int? cases;
  final String? severity;
  final String? streetName;
  final Color? barangayColor;

  const LocationDetailsScreen({
    Key? key,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.cases,
    this.severity,
    this.streetName,
    this.district,
    this.barangayColor,
  }) : super(key: key);

  @override
  State<LocationDetailsScreen> createState() => _LocationDetailsScreenState();
}

class _LocationDetailsScreenState extends State<LocationDetailsScreen> {
  GoogleMapController? _mapController;
  int cases = 0;
  String severity = 'Unknown';
  bool _isLoadingPosts = true;
  String? _currentUsername;
  Set<Polygon> _barangayPolygons = {};
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentLocation;
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    _loadDengueData();
    _loadCurrentUsername();
    _loadBarangayPolygon();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize providers
      await Provider.of<PostProvider>(context, listen: false)
          .fetchPosts(forceRefresh: true);
      await Provider.of<VoteProvider>(context, listen: false).refreshAllVotes();
    });
  }

  Future<void> _loadCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUsername = prefs.getString('email');
    });
  }

  Future<void> _loadDengueData() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/barangays/get-all-barangays'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final barangayData = data.firstWhere(
          (item) => item['name'] == widget.location,
          orElse: () => null,
        );

        if (barangayData != null) {
          setState(() {
            cases = Provider.of<PostProvider>(context, listen: false)
                .posts
                .where((post) => post['barangay'] == widget.location)
                .length;
            severity = barangayData['status_and_recommendation']
                        ?['pattern_based']?['status']
                    ?.toString()
                    .toLowerCase() ??
                'Unknown';
            print('DEBUG: Severity loaded from API: $severity');
          });

          // Reload the polygon with the new severity
          await _loadBarangayPolygon();
        }
      }
    } catch (e) {
      print('Error loading dengue data: $e');
    }
  }

  Color _getColorForPattern(String pattern) {
    switch (pattern.toLowerCase()) {
      case 'spike':
        return Colors.red.shade700;
      case 'gradual_rise':
        return Colors.orange.shade500;
      case 'decline':
        return Colors.green.shade600;
      case 'stable':
      case 'stability':
        return Colors.lightBlue.shade600;
      case 'low_level_activity':
        return Colors.grey.shade400;
      default:
        return Colors.grey.shade700;
    }
  }

  Future<void> _loadBarangayPolygon() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/geojson/barangays.geojson');
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> features = jsonData['features'];

      for (var feature in features) {
        final properties = feature['properties'];
        final geometry = feature['geometry'];

        if (properties == null ||
            geometry == null ||
            geometry['type'] != 'Polygon') continue;

        final name = properties['name'] ?? properties['NAME_3'];
        if (name == null || name != widget.location) continue;

        final coords = geometry['coordinates'][0]
            .map<LatLng>(
                (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
            .toList();

        // Use the current severity status that's displayed in the screen
        final pattern = severity.toLowerCase();
        print('DEBUG: Current severity pattern: $pattern');
        Color borderColor;
        Color fillColor;

        // Set colors based on pattern
        switch (pattern) {
          case 'spike':
            borderColor = Colors.red.shade800;
            fillColor = Colors.red.shade700.withOpacity(0.5);
            print('DEBUG: Setting spike colors - Red');
            break;
          case 'gradual_rise':
            borderColor = Colors.orange.shade800;
            fillColor = Colors.orange.shade500.withOpacity(0.5);
            print('DEBUG: Setting gradual_rise colors - Orange');
            break;
          case 'decline':
            borderColor = Colors.green.shade800;
            fillColor = Colors.green.shade600.withOpacity(0.5);
            print('DEBUG: Setting decline colors - Green');
            break;
          case 'stable':
          case 'stability':
            borderColor = Colors.lightBlue.shade800;
            fillColor = Colors.lightBlue.shade600.withOpacity(0.5);
            print('DEBUG: Setting stable colors - Light Blue');
            break;
          default:
            borderColor = Colors.grey.shade800;
            fillColor = Colors.grey.shade700.withOpacity(0.5);
            print('DEBUG: Setting default colors - Grey');
        }

        setState(() {
          _barangayPolygons = {
            Polygon(
              polygonId: PolygonId(name),
              points: coords,
              strokeColor: borderColor,
              strokeWidth: 2,
              fillColor: fillColor,
            ),
          };
        });
        print(
            'DEBUG: Polygon updated with colors - Border: $borderColor, Fill: $fillColor');
        break;
      }
    } catch (e) {
      print('Error loading barangay polygon: $e');
    }
  }

  List<Map<String, dynamic>> get _barangayPosts {
    return Provider.of<PostProvider>(context)
        .posts
        .where((post) => post['barangay'] == widget.location)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context);
    final LatLng targetLocation = LatLng(widget.latitude, widget.longitude);
    final postProvider = Provider.of<PostProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: const CustomAppBar(
        title: 'Location Details',
        currentRoute: '/location-details',
        themeMode: 'dark',
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Colored background
            Container(
              height: MediaQuery.of(context).size.height * 0.44,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(36, 82, 97, 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
            ),
            // Foreground content
            Column(
              children: [
                SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AutoSizeText(
                          widget.location,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          minFontSize: 10,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.1,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 69, 69, 69),
                          ),
                        ),
                        AutoSizeText(
                          widget.streetName ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          minFontSize: 14,
                          style: const TextStyle(
                            fontSize: 22,
                            height: 1.1,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(36, 82, 97, 1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFE066),
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.insert_drive_file,
                                        color: Color(0xFF35505A), size: 16),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '${cases > 0 ? cases : 0} Reported Cases',
                                        style: const TextStyle(
                                          color: Color(0xFF35505A),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getSeverityColor(severity),
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        severity != 'Unknown'
                                            ? 'Status: $severity'
                                            : 'Severity N/A',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 220,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: targetLocation,
                          zoom: 15.0,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('selected-location'),
                            position: targetLocation,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed,
                            ),
                          ),
                        },
                        polygons: _barangayPolygons,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        tiltGesturesEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 29),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await Provider.of<PostProvider>(context, listen: false)
                          .fetchPosts(forceRefresh: true);
                      await Provider.of<VoteProvider>(context, listen: false)
                          .refreshAllVotes();
                    },
                    edgeOffset: 70,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'WHAT OTHERS ARE REPORTING...',
                                style:
                                    Theme.of(context).textTheme.headlineLarge,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (postProvider.isLoading)
                              const Center(child: CircularProgressIndicator())
                            else if (_barangayPosts.isEmpty)
                              const Center(
                                  child:
                                      Text('No reports for this barangay yet.'))
                            else
                              ..._barangayPosts.map((report) => Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 16),
                                      child: PostCard(
                                        username:
                                            report['username'] ?? 'Anonymous',
                                        whenPosted:
                                            report['whenPosted'] ?? 'Just now',
                                        location: report['location'] ??
                                            'Unknown Location',
                                        date: report['date'] ?? 'N/A',
                                        time: report['time'] ?? 'N/A',
                                        reportType:
                                            report['reportType'] ?? 'General',
                                        description: report['description'] ??
                                            'No description provided',
                                        numUpvotes: report['numUpvotes'] ?? 0,
                                        numDownvotes:
                                            report['numDownvotes'] ?? 0,
                                        images: List<String>.from(
                                            report['images'] ?? []),
                                        iconUrl: report['iconUrl'] ??
                                            'assets/icons/person_1.svg',
                                        type: 'bordered',
                                        postId: report['id'] ?? '',
                                        isOwner:
                                            report['email'] == _currentUsername,
                                        post: report,
                                      ),
                                    ),
                                  )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 34,
              bottom: MediaQuery.of(context).size.height * 0.43,
              child: SizedBox(
                width: 116,
                height: 31,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromRGBO(248, 169, 0, 1),
                        Color.fromRGBO(250, 221, 55, 1),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      "Back to Maps",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                        color: Color.fromRGBO(36, 82, 97, 1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Stack(
        children: [
          YellowGradientButton(
            name: 'Community',
            bottom: 53,
            right: 3,
            height: 40,
            width: 140,
            route: '/community',
          ),
          YellowGradientButton(
            name: 'Prevention Tips',
            bottom: 3,
            right: 3,
            height: 40,
            width: 160,
            route: '/prevention',
          )
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'spike':
        return Colors.red;
      case 'gradual_rise':
        return Colors.orange;
      case 'decline':
        return Colors.green;
      case 'stable':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _showDengueDetails(String barangay, String severity, LatLng location) {
    // Set current location when showing details
    setState(() {
      _currentLocation = location;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          barangay,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _getColorForSeverity(severity).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            severity,
                            style: TextStyle(
                              color: _getColorForSeverity(severity),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cases and Coordinates
                    Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Recommendations Section
                    const Text(
                      'Recommendations:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(
                        maxHeight: 300,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recommendations based on severity level:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getColorForSeverity(severity),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getRecommendationsForSeverity(severity),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Health Facilities Section
                    const Text(
                      'Health Care Facilities Nearby:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchNearbyHealthFacilities(
                        location.latitude,
                        location.longitude,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading facilities: ${snapshot.error}',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          );
                        }

                        final facilities = snapshot.data ?? [];
                        if (facilities.isEmpty) {
                          return const Center(
                            child: Text('No health facilities found nearby'),
                          );
                        }

                        return SizedBox(
                          height: 200,
                          child: PageView.builder(
                            itemCount: facilities.length,
                            itemBuilder: (context, index) {
                              final facility = facilities[index];
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    // Show facility on map
                                    final facilityLatLng = LatLng(
                                      facility['lat'] as double,
                                      facility['lng'] as double,
                                    );
                                    _showFacilityOnMap(
                                        facilityLatLng, facility);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.local_hospital,
                                              size: 24,
                                              color: Colors.blue.shade700,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                facility['name'] as String,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          facility['vicinity'] as String,
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(facility['distance_km'] as double).toStringAsFixed(1)} km away',
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRecommendationsForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'spike':
        return '''
• Immediate action required
• Conduct intensive vector control measures
• Increase public awareness campaigns
• Deploy additional health workers
• Consider temporary closure of affected areas
• Coordinate with local health authorities
''';
      case 'gradual_rise':
        return '''
• Monitor situation closely
• Implement preventive measures
• Conduct regular vector control
• Increase public awareness
• Prepare response plan
''';
      case 'decline':
        return '''
• Continue monitoring
• Maintain preventive measures
• Document successful interventions
• Keep public informed
''';
      case 'stable':
        return '''
• Regular monitoring
• Maintain preventive measures
• Continue public awareness
• Document status
''';
      default:
        return 'No specific recommendations available for this severity level.';
    }
  }

  void _showFacilityOnMap(
      LatLng facilityLocation, Map<String, dynamic> facility) {
    // Add marker for the facility
    final facilityMarker = Marker(
      markerId: MarkerId('facility_${facility['name']}'),
      position: facilityLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: facility['name'] as String,
        snippet: facility['vicinity'] as String,
      ),
    );

    // Add route polyline
    final polyline = Polyline(
      polylineId: const PolylineId('route_to_facility'),
      points: [
        _currentLocation!,
        facilityLocation,
      ],
      color: Colors.blue,
      width: 3,
    );

    setState(() {
      _markers.add(facilityMarker);
      _polylines.add(polyline);
    });

    // Move camera to show both locations
    _controller?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            min(_currentLocation!.latitude, facilityLocation.latitude),
            min(_currentLocation!.longitude, facilityLocation.longitude),
          ),
          northeast: LatLng(
            max(_currentLocation!.latitude, facilityLocation.latitude),
            max(_currentLocation!.longitude, facilityLocation.longitude),
          ),
        ),
        100, // padding
      ),
    );

    // Show snackbar with facility info
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Showing route to ${facility['name']}',
        ),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Close',
          onPressed: () {
            setState(() {
              _markers.remove(facilityMarker);
              _polylines.remove(polyline);
            });
          },
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> fetchNearbyHealthFacilities(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Config.baseUrl}/api/v1/health-facilities/nearby?lat=$latitude&lng=$longitude'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((facility) => {
                  'name': facility['name'],
                  'address': facility['address'],
                  'distance': facility['distance'],
                })
            .toList();
      } else {
        throw Exception('Failed to load health facilities');
      }
    } catch (e) {
      print('Error fetching health facilities: $e');
      return [];
    }
  }

  Color _getColorForSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'spike':
        return Colors.red;
      case 'gradual_rise':
        return Colors.orange;
      case 'decline':
        return Colors.green;
      case 'stable':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
