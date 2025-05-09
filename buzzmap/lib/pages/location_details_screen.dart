import 'package:buzzmap/widgets/floatingactionbutton/yellow_gradient_button.dart';
import 'package:buzzmap/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:buzzmap/data/dengue_data.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

import 'package:buzzmap/auth/config.dart';

class LocationDetailsScreen extends StatefulWidget {
  final String location;
  final String? district;
  final double latitude;
  final double longitude;
  final int? cases; // 🔥 ADD THIS
  final String? severity; // 🔥 ADD THIS
  final String streetName; // 🔥 ADD THIS

  const LocationDetailsScreen({
    Key? key,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.cases, // 🔥 not required anymore
    this.severity, // 🔥 not required anymore
    required this.streetName,
    this.district,
  }) : super(key: key);

  @override
  State<LocationDetailsScreen> createState() => _LocationDetailsScreenState();
}

class _LocationDetailsScreenState extends State<LocationDetailsScreen> {
  GoogleMapController? _mapController;

  int cases = 0;
  String severity = 'Unknown';

  List<Map<String, dynamic>> _barangayPosts = [];
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    _loadDengueData();
    _loadReports();
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Severe':
        return Colors.red;
      case 'Moderate':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<List<Map<String, dynamic>>> fetchReports() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    final response = await http.get(
      Uri.parse('${Config.baseUrl}/api/v1/reports'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    print('🔍 Raw response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map<Map<String, dynamic>>((report) {
        final DateTime reportDate = DateTime.parse(report['date_and_time']);
        final DateTime now = DateTime.now();
        final Duration difference = now.difference(reportDate);
        
        String whenPosted;
        if (difference.inDays > 0) {
          whenPosted = '${difference.inDays} days ago';
        } else if (difference.inHours > 0) {
          whenPosted = '${difference.inHours} hours ago';
        } else if (difference.inMinutes > 0) {
          whenPosted = '${difference.inMinutes} minutes ago';
        } else {
          whenPosted = 'Just now';
        }

        return {
          'username': report['user']?['username'] ?? 'Anonymous',
          'whenPosted': whenPosted,
          'location': report['barangay'] ?? 'Unknown Location',
          'barangay': report['barangay'],
          'date': '${reportDate.month}/${reportDate.day}/${reportDate.year}',
          'time': '${reportDate.hour.toString().padLeft(2, '0')}:${reportDate.minute.toString().padLeft(2, '0')}',
          'reportType': report['report_type'],
          'description': report['description'],
          'images': report['images'] != null
              ? List<String>.from(report['images'])
              : <String>[],
          'iconUrl': 'assets/icons/person_1.svg',
          'status': report['status'],
        };
      }).toList();
    }
    throw Exception('Failed to fetch reports');
  }

  Future<void> _loadReports() async {
    try {
      final reports = await fetchReports();
      print('All reports: ${reports.length}');
      print('Target barangay: ${widget.location}');

      setState(() {
        _barangayPosts = reports.where((report) {
          // Debug print
          print('Checking report: ${report['barangay']} vs ${widget.location}');

          // Check status first (remove or modify this if you want to show all)
          if (report['status']?.toString().toLowerCase() != 'validated') {
            return false;
          }

          // Compare barangay names
          final reportBarangay =
              report['barangay']?.toString().trim().toLowerCase();
          final targetBarangay = widget.location.trim().toLowerCase();

          return reportBarangay == targetBarangay;
        }).toList();

        print('Filtered reports: ${_barangayPosts.length}');
        _isLoadingPosts = false;
      });
    } catch (e) {
      print('❌ Error filtering reports: $e');
      setState(() => _isLoadingPosts = false);
    }
  }

  void _loadDengueData() {
    final data = dengueData[widget.location]; // 🔥 lookup barangay name
    if (data != null) {
      setState(() {
        cases = data['cases'] ?? 0;
        severity = data['severity'] ?? 'Unknown';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context);

    final LatLng targetLocation = LatLng(widget.latitude, widget.longitude);

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
            Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background container
                    Container(
                      height: MediaQuery.of(context).size.height * 0.40,
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
                    // Dengue Info Section (fixed container height, auto text adjust)
                    Positioned(
                      top: 20,
                      left: 16,
                      right: 16,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          // 📦 Main white container
                          Container(
                            height: 70, // 🔥 Fixed height
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Barangay name (small gray)
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

                                  // Street name (big bold)
                                  AutoSizeText(
                                    widget.streetName,
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
                                ],
                              ),
                            ),
                          ),

                          // 🏷️ Overlapping badges
                          Positioned(
                            bottom: -18,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Cases Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(255, 179, 0, 1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 16,
                                        color: Color(0xFF264F64),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${cases > 0 ? cases : 0} Cases',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 6),

                                // Severity Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getSeverityColor(severity),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.local_hospital_rounded,
                                        size: 16,
                                        color: Color(0xFF264F64),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        severity != 'Unknown'
                                            ? 'Case Severity: $severity'
                                            : 'Severity N/A',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // Google Map
                    Positioned(
                      top: 110,
                      left: 0,
                      right: 0,
                      height: 250,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(60),
                        ),
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
                    // Back to Maps button
                    Positioned(
                      bottom: 39,
                      left: 34,
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

                const SizedBox(height: 24),

                // Scrollable section
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadReports,
                    edgeOffset: 80,
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
                                style: Theme.of(context).textTheme.headlineLarge,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_isLoadingPosts)
                              const Center(child: CircularProgressIndicator())
                            else if (_barangayPosts.isEmpty)
                              const Center(
                                  child: Text('No reports for this barangay yet.'))
                            else
                              ..._barangayPosts.map((post) => Container(
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
                                        username: post['username'],
                                        whenPosted: post['whenPosted'],
                                        location: post['location'],
                                        date: post['date'],
                                        time: post['time'],
                                        reportType: post['reportType'],
                                        description: post['description'],
                                        images: List<String>.from(post['images']),
                                        iconUrl: post['iconUrl'],
                                        numUpvotes: post['numUpvotes'] ?? 0,
                                        numDownvotes: post['numDownvotes'] ?? 0,
                                        type: 'bordered',
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
