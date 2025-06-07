import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:buzzmap/config/config.dart';
import 'package:buzzmap/services/notification_service.dart';
import 'package:buzzmap/widgets/utils/notification_template.dart';
import 'package:buzzmap/widgets/offline_posts_list.dart';
import 'package:buzzmap/widgets/global_alert_overlay.dart';
import 'package:buzzmap/services/alert_service.dart';
import 'package:buzzmap/pages/mapping_screen.dart';
import 'package:flutter/services.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _adminAlerts = [];
  List<Map<String, dynamic>> _adminAnnouncements = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  int _displayCount = 10;
  Timer? _refreshTimer;
  List<Map<String, dynamic>>? _cachedFilteredNotifications;
  String? _lastFilterKey;
  Position? _currentPosition;
  String? _currentBarangayId;

  final List<String> _filters = [
    'All',
    'Admin Alerts',
    'Pending',
    'Approved',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _notificationService.initialize();
      await Future.wait([
        _loadNotifications(),
        _getCurrentLocation(),
        _loadAdminAlertsAndAnnouncements(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initialize notifications'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications =
          await _notificationService.fetchNotifications(context);

      // Filter notifications from the last week
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      final filteredNotifications = notifications.where((notification) {
        final report = notification['report'] as Map<String, dynamic>?;
        final createdAt = DateTime.parse(
            report?['createdAt'] ?? DateTime.now().toIso8601String());
        return createdAt.isAfter(oneWeekAgo);
      }).toList();

      if (mounted) {
        setState(() {
          _notifications = filteredNotifications;
          _cachedFilteredNotifications = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load notifications'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('Current position: ${position.latitude}, ${position.longitude}');

      setState(() {
        _currentPosition = position;
      });

      // Reload alerts after getting location
      await _loadAdminAlertsAndAnnouncements();
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Error getting location. Some alerts may not be shown.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Helper function to check if a point is inside a polygon
  bool _isPointInPolygon(List<List<double>> polygon, double lat, double lng) {
    bool isInside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i][1] > lat) != (polygon[j][1] > lat) &&
          (lng <
              (polygon[j][0] - polygon[i][0]) *
                      (lat - polygon[i][1]) /
                      (polygon[j][1] - polygon[i][1]) +
                  polygon[i][0])) {
        isInside = !isInside;
      }
      j = i;
    }

    return isInside;
  }

  // Helper function to get current barangay name from coordinates using GeoJSON
  Future<String?> _getCurrentBarangay(double latitude, double longitude) async {
    try {
      print('Getting barangay for coordinates: $latitude, $longitude');

      // Load GeoJSON data from local assets
      final String jsonString =
          await rootBundle.loadString('assets/geojson/barangays.geojson');
      final data = jsonDecode(jsonString);
      print('GeoJSON data loaded successfully');

      // The data is a GeoJSON FeatureCollection
      final features = data['features'] as List;
      print('Found ${features.length} barangays in GeoJSON data');

      for (var feature in features) {
        final properties = feature['properties'];
        final geometry = feature['geometry'];

        if (geometry['type'] == 'Polygon') {
          final coordinates = geometry['coordinates'][0] as List;
          final polygon = coordinates
              .map((coord) => [
                    double.parse(coord[0].toString()),
                    double.parse(coord[1].toString())
                  ])
              .toList();

          if (_isPointInPolygon(polygon, latitude, longitude)) {
            final barangayName = properties['name'] as String;
            print('Detected barangay: $barangayName');
            return barangayName;
          }
        }
      }

      print('No barangay found for coordinates');
      return null;
    } catch (e) {
      print('Error getting barangay name: $e');
      return null;
    }
  }

  Future<void> _loadAdminAlertsAndAnnouncements() async {
    try {
      // Calculate date 1 week ago
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      print('Fetching alerts from: ${Config.baseUrl}/api/v1/alerts');

      // Fetch admin alerts with date filter
      final alertsResponse = await http.get(
        Uri.parse(
            '${Config.baseUrl}/api/v1/alerts?startDate=${oneWeekAgo.toIso8601String()}'),
      );

      print('Alerts response status: ${alertsResponse.statusCode}');
      print('Alerts response body: ${alertsResponse.body}');

      if (alertsResponse.statusCode == 200) {
        final body = jsonDecode(alertsResponse.body);

        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> alertsData = body['data'];
          print('Total alerts received: ${alertsData.length}');

          // Get current barangay name
          String? currentBarangayName;
          if (_currentPosition != null) {
            currentBarangayName = await _getCurrentBarangay(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            );
            print('Current barangay name: $currentBarangayName');
          }

          // First, sort all alerts by timestamp (newest first)
          alertsData.sort((a, b) {
            final timestampA = DateTime.parse(
                a['timestamp'] ?? DateTime.now().toIso8601String());
            final timestampB = DateTime.parse(
                b['timestamp'] ?? DateTime.now().toIso8601String());
            return timestampB.compareTo(timestampA);
          });

          // Filter alerts for current location only
          List<Map<String, dynamic>> filteredAlerts = [];
          Set<String> processedBarangays = {};

          for (var alert in alertsData) {
            final barangays = alert['barangays'] as List?;
            final status = alert['status']?.toString();

            print('\nProcessing alert: ${alert['_id']}');
            print('Alert status: $status');
            print('Alert barangays: $barangays');

            // Only include active alerts
            if (status != 'ACTIVE') {
              print('Skipping non-active alert');
              continue;
            }

            // If no barangays specified, it's a general alert for all areas
            if (barangays == null || barangays.isEmpty) {
              print('Adding general alert');
              filteredAlerts.add(alert as Map<String, dynamic>);
              continue;
            }

            // If we have current barangay name, check if it's in the affected barangays
            if (currentBarangayName != null) {
              print(
                  'Checking if alert is for current barangay: $currentBarangayName');

              final isCurrentBarangayAffected = barangays.any((b) {
                final barangayName = b['name']?.toString().toLowerCase();
                final currentBarangayLower =
                    currentBarangayName?.toLowerCase() ?? '';
                print(
                    'Comparing alert barangay: $barangayName with current barangay: $currentBarangayLower');
                return barangayName == currentBarangayLower;
              });

              print('Is current barangay affected: $isCurrentBarangayAffected');
              if (isCurrentBarangayAffected) {
                // Only add if we haven't processed an alert for this barangay yet
                if (!processedBarangays
                    .contains(currentBarangayName.toLowerCase())) {
                  print(
                      'Adding latest alert for current barangay: $currentBarangayName');
                  filteredAlerts.add(alert as Map<String, dynamic>);
                  processedBarangays.add(currentBarangayName.toLowerCase());
                } else {
                  print(
                      'Skipping alert - already have a newer alert for this barangay');
                }
              } else {
                print('Skipping alert - not for current barangay');
              }
            } else {
              print('No current barangay name available');
            }
          }

          print('\nFiltered alerts count: ${filteredAlerts.length}');
          print(
              'Filtered alerts: ${filteredAlerts.map((a) => a['_id']).join(', ')}');

          setState(() {
            _adminAlerts = filteredAlerts;
          });
        }
      }

      // Fetch important announcements (last week only)
      final annResponse = await http.get(
        Uri.parse(
            '${Config.baseUrl}/api/v1/adminPosts?startDate=${oneWeekAgo.toIso8601String()}'),
      );
      if (annResponse.statusCode == 200) {
        final List<dynamic> annData = jsonDecode(annResponse.body);
        setState(() {
          _adminAnnouncements = annData
              .where((post) => post['category'] == 'announcement')
              .take(3)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      print('Error loading admin alerts and announcements: $e');
    }
  }

  void _toggleFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      _displayCount = 10;
      _cachedFilteredNotifications = null;
    });
  }

  List<Map<String, dynamic>> _getFilteredNotifications() {
    if (_cachedFilteredNotifications != null &&
        _lastFilterKey == _selectedFilter) {
      return _cachedFilteredNotifications!;
    }

    List<Map<String, dynamic>> filtered = [];

    if (_selectedFilter == 'Admin Alerts') {
      filtered = [..._adminAlerts, ..._adminAnnouncements];
    } else {
      print('Filtering notifications for: $_selectedFilter');
      print('Total notifications before filtering: ${_notifications.length}');

      filtered = _notifications.where((notification) {
        final report = notification['report'] as Map<String, dynamic>?;
        if (report == null) {
          print('Notification has no report data: $notification');
          return false;
        }

        final status = report['status']?.toString();
        print('Notification status: $status');

        bool shouldInclude = _selectedFilter == 'All' ||
            (_selectedFilter == 'Pending' && status == 'Pending') ||
            (_selectedFilter == 'Approved' &&
                (status == 'Approved' || status == 'Validated')) ||
            (_selectedFilter == 'Rejected' && status == 'Rejected');

        print('Should include notification: $shouldInclude');
        return shouldInclude;
      }).toList();

      print('Filtered notifications count: ${filtered.length}');
    }

    _cachedFilteredNotifications = filtered;
    _lastFilterKey = _selectedFilter;
    return filtered;
  }

  void _showMoreNotifications() {
    setState(() {
      _displayCount += 10;
    });
  }

  String _formatAdminAlertTitle(Map<String, dynamic> alert) {
    return alert['severity']?.toString().toUpperCase() ?? 'ALERT';
  }

  String _formatAdminAlertSubtitle(Map<String, dynamic> alert) {
    final messages = alert['messages'] as List?;
    return messages?.isNotEmpty == true ? messages!.first : 'Alert';
  }

  String _formatAdminAlertDetails(Map<String, dynamic> alert) {
    final barangays = alert['barangays'] as List?;
    final barangayNames = (barangays != null && barangays.isNotEmpty)
        ? barangays.map((b) => b['name']).whereType<String>().join(', ')
        : 'All Areas';
    final timestamp =
        DateTime.parse(alert['timestamp'] ?? DateTime.now().toIso8601String());
    return '$barangayNames • ${_formatDate(timestamp)}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildShowMoreButton() {
    final totalFiltered = _notifications.where((notification) {
      final report = notification['report'] as Map<String, dynamic>?;
      if (report == null) return false;

      final status = report['status']?.toString();
      return _selectedFilter == 'All' ||
          (_selectedFilter == 'Pending' && status == 'Pending') ||
          (_selectedFilter == 'Approved' &&
              (status == 'Approved' || status == 'Validated')) ||
          (_selectedFilter == 'Rejected' && status == 'Rejected');
    }).length;

    if (totalFiltered <= _displayCount) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: TextButton(
          onPressed: _showMoreNotifications,
          child: Text(
            'Show More (${totalFiltered - _displayCount} remaining)',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final primaryGreen = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () => _toggleFilter(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryGreen : Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? primaryGreen : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAdminAlertItem(Map<String, dynamic> notification) {
    final messages = notification['messages'] as List?;
    final firstMessage =
        messages?.isNotEmpty == true ? messages!.first : 'Alert';
    final barangays = notification['barangays'] as List?;
    final barangayNames = (barangays != null && barangays.isNotEmpty)
        ? barangays.map((b) => b['name']).whereType<String>().join(', ')
        : 'All Areas';

    return NotificationTemplate(
      message: firstMessage,
      reportId: notification['_id']?.toString(),
      barangay: barangayNames,
      status: 'alert',
      reportType: _formatAdminAlertTitle(notification),
      isRead: false,
      latitude: null,
      longitude: null,
      streetName: null,
      createdAt: DateTime.parse(
          notification['timestamp'] ?? DateTime.now().toIso8601String()),
      onTap: () => _showAlertDetails(notification),
    );
  }

  Widget _buildAdminAnnouncementItem(Map<String, dynamic> notification) {
    return NotificationTemplate(
      message: notification['message'] ?? 'Announcement',
      reportId: notification['_id']?.toString(),
      barangay: 'All Areas',
      status: 'announcement',
      reportType: 'ANNOUNCEMENT',
      isRead: false,
      latitude: null,
      longitude: null,
      streetName: null,
      createdAt: DateTime.parse(
          notification['createdAt'] ?? DateTime.now().toIso8601String()),
      onTap: () => _showAnnouncementDetails(notification),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final report = notification['report'] as Map<String, dynamic>?;
    final status = report?['status']?.toString().toLowerCase() ?? 'pending';
    final message = notification['message'] ?? 'No message';
    final barangay = report?['barangay'] ?? 'Unknown Location';
    final latitude =
        report?['specific_location']?['coordinates']?[1] as double?;
    final longitude =
        report?['specific_location']?['coordinates']?[0] as double?;
    final streetName = report?['specific_location']?['street_name'] as String?;
    final createdAt = DateTime.parse(
        notification['createdAt'] ?? DateTime.now().toIso8601String());

    return NotificationTemplate(
      message: message,
      reportId: report?['_id']?.toString(),
      barangay: barangay,
      status: status,
      reportType: report?['report_type'] ?? 'REPORT',
      isRead: notification['isRead'] ?? false,
      latitude: latitude,
      longitude: longitude,
      streetName: streetName,
      createdAt: createdAt,
      onTap: () => _showReportDetails(notification),
    );
  }

  void _showAlertDetails(Map<String, dynamic> alert) {
    AlertService().showAlert(alert);
  }

  void _showAnnouncementDetails(Map<String, dynamic> announcement) {
    // TODO: Implement announcement details view
  }

  void _showReportDetails(Map<String, dynamic> notification) async {
    final report = notification['report'] as Map<String, dynamic>?;
    if (report == null) {
      print('No report data found in notification');
      return;
    }

    print('Handling notification tap for report ID: ${report['_id']}');

    // Fetch full report details
    final reportDetails =
        await _notificationService.fetchReportDetails(report['_id']);
    if (reportDetails == null) {
      print('Failed to fetch report details');
      return;
    }

    double? latitude;
    double? longitude;

    if (reportDetails['specific_location'] != null) {
      final location = reportDetails['specific_location'];
      if (location['coordinates'] != null) {
        final coordinates = location['coordinates'];
        if (coordinates is List && coordinates.length >= 2) {
          longitude = coordinates[0].toDouble();
          latitude = coordinates[1].toDouble();
        }
      }
    }

    final status = reportDetails['status']?.toString();
    print('Report status: $status');
    print('Latitude: $latitude');
    print('Longitude: $longitude');

    if ((status == 'Approved' || status == 'Validated') &&
        latitude != null &&
        longitude != null) {
      print(
          'Approved/Validated report with location data, navigating to map...');
      print('Using coordinates: $latitude, $longitude');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MappingScreen(
              initialLatitude: latitude!,
              initialLongitude: longitude!,
              initialZoom: 18.0,
              reportId: reportDetails['_id'],
            ),
          ),
        );
      }
    } else {
      print('Cannot navigate: Invalid status or missing location data');
      print('Status: $status');
      print('Latitude: $latitude');
      print('Longitude: $longitude');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _getFilteredNotifications();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Pending Offline Reports',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: OfflinePostsList(),
          ),
          const SliverToBoxAdapter(
            child: Divider(),
          ),
          SliverToBoxAdapter(
            child: _buildFilterBar(),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_selectedFilter == 'Admin Alerts')
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final notification = filteredNotifications[index];
                  final isAlert = notification.containsKey('messages');
                  return isAlert
                      ? _buildAdminAlertItem(notification)
                      : _buildAdminAnnouncementItem(notification);
                },
                childCount: filteredNotifications.length,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final notification = filteredNotifications[index];
                  return _buildNotificationItem(notification);
                },
                childCount: filteredNotifications.length,
              ),
            ),
          if (filteredNotifications.length >= _displayCount)
            SliverToBoxAdapter(
              child: _buildShowMoreButton(),
            ),
        ],
      ),
    );
  }
}

class _CurvedDividerPainter extends CustomPainter {
  final Color color;
  _CurvedDividerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(size.width / 2, 8);
    path.quadraticBezierTo(
        size.width / 2, size.height / 2, size.width / 2, size.height - 8);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
