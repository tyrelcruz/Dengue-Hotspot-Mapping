import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/services/notification_service.dart';
import 'package:buzzmap/widgets/utils/notification_template.dart';
import 'package:buzzmap/pages/mapping_screen.dart';

// Add a simple logging utility
class Logger {
  static bool _isDebugMode = false; // Set to false in production

  static void log(String message, {String? tag}) {
    if (_isDebugMode) {
      print('${tag != null ? '[$tag] ' : ''}$message');
    }
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _adminAlerts = [];
  List<Map<String, dynamic>> _adminAnnouncements = [];
  bool _isLoading = true;
  bool _showAllToday = false;
  bool _showAllWeek = false;
  Set<String> _selectedFilters = {}; // Allow multiple selection
  int _displayCount = 10;

  final List<String> _filters = [
    'All',
    'Reviewing',
    'Validated',
    'Rejected',
    'Admin Alerts'
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadAdminAlertsAndAnnouncements();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications =
          await NotificationService().fetchNotifications(context);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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

  Future<void> _loadAdminAlertsAndAnnouncements() async {
    try {
      // Fetch admin alerts (last 3)
      final alertsResponse =
          await http.get(Uri.parse('http://localhost:4000/api/v1/alerts'));
      if (alertsResponse.statusCode == 200) {
        final body = jsonDecode(alertsResponse.body);
        final List<dynamic> alertsData = body['data'] ?? [];
        setState(() {
          _adminAlerts =
              alertsData.take(3).map((e) => e as Map<String, dynamic>).toList();
        });
      }
      // Fetch important announcements
      final annResponse =
          await http.get(Uri.parse('http://localhost:4000/api/v1/adminPosts'));
      if (annResponse.statusCode == 200) {
        final List<dynamic> annData = jsonDecode(annResponse.body);
        setState(() {
          _adminAnnouncements =
              annData.take(3).map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      // Optionally show error
    }
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedFilters.clear();
    });
  }

  List<Map<String, dynamic>> _getFilteredNotifications() {
    if (_selectedFilters.contains('Admin Alerts')) {
      final combined = [..._adminAlerts, ..._adminAnnouncements];
      combined.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['createdAt'] ?? a['publishDate'] ?? '');
        final dateB =
            DateTime.tryParse(b['createdAt'] ?? b['publishDate'] ?? '');
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });
      return combined;
    }
    List<Map<String, dynamic>> filtered = _notifications.where((notification) {
      final report = notification['report'] as Map<String, dynamic>?;
      final status = report?['status']?.toString().toLowerCase();
      final createdAt = DateTime.parse(notification['createdAt']);
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      if (status == null || status == 'unknown') return false;
      if (_selectedFilters.isEmpty || _selectedFilters.contains('All')) {
        return createdAt.isAfter(sevenDaysAgo);
      }
      return _selectedFilters.any((filter) {
        if (filter.toLowerCase() == 'reviewing') {
          return status == 'pending' && createdAt.isAfter(sevenDaysAgo);
        }
        return status == filter.toLowerCase() &&
            createdAt.isAfter(sevenDaysAgo);
      });
    }).toList();
    filtered.sort((a, b) {
      final dateA = DateTime.parse(a['createdAt']);
      final dateB = DateTime.parse(b['createdAt']);
      return dateB.compareTo(dateA);
    });
    return filtered.take(_displayCount).toList();
  }

  void _handleNotificationTap(Map<String, dynamic> notification) async {
    final report = notification['report'] as Map<String, dynamic>?;
    if (report == null) {
      Logger.log('No report data found in notification', tag: 'ERROR');
      return;
    }

    Logger.log('Handling notification tap for report ID: ${report['_id']}',
        tag: 'NOTIFICATION');

    // Fetch full report details
    final reportDetails =
        await _notificationService.fetchReportDetails(report['_id']);
    if (reportDetails == null) {
      Logger.log('Failed to fetch report details', tag: 'ERROR');
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

    if (reportDetails['status']?.toLowerCase() == 'validated' &&
        latitude != null &&
        longitude != null) {
      Logger.log('Validated report with location data, navigating to map...',
          tag: 'NOTIFICATION');
      Logger.log('Using coordinates: $latitude, $longitude',
          tag: 'NOTIFICATION');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MappingScreen(
              initialLatitude: latitude!,
              initialLongitude: longitude!,
              initialZoom: 18.0, // Increased zoom level for better visibility
              reportId: reportDetails['_id'],
            ),
          ),
        );
      }
    } else {
      Logger.log('Cannot navigate: Invalid status or missing location data',
          tag: 'ERROR');
      Logger.log('Status: ${reportDetails['status']}', tag: 'ERROR');
      Logger.log('Latitude: $latitude', tag: 'ERROR');
      Logger.log('Longitude: $longitude', tag: 'ERROR');
    }
  }

  Future<void> _refreshAdminAlerts() async {
    await _loadAdminAlertsAndAnnouncements();
    setState(() {});
  }

  String _formatAdminAlertTitle(Map<String, dynamic> alert) {
    // Use severity and first message as title
    final severity = alert['severity']?.toString().toUpperCase() ?? '';
    final messages = alert['messages'] as List?;
    final firstMessage =
        (messages != null && messages.isNotEmpty) ? messages.first : '';
    return severity.isNotEmpty ? '[$severity] $firstMessage' : firstMessage;
  }

  String _formatAdminAlertSubtitle(Map<String, dynamic> alert) {
    final messages = alert['messages'] as List?;
    if (messages == null || messages.isEmpty) return '';
    return messages.skip(1).take(2).join(' ');
  }

  String _formatAdminAlertDetails(Map<String, dynamic> alert) {
    final barangays = alert['barangays'] as List?;
    final barangayNames = (barangays != null && barangays.isNotEmpty)
        ? barangays.map((b) => b['name']).whereType<String>().join(', ')
        : 'All Areas';
    final timestamp =
        alert['timestamp'] ?? alert['createdAt'] ?? alert['publishDate'] ?? '';
    final date = timestamp.isNotEmpty && timestamp.length >= 10
        ? timestamp.substring(0, 10)
        : '';
    return 'Barangays: $barangayNames\nDate: $date';
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = Theme.of(context).colorScheme.primary;
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
      body: Column(
        children: [
          // Spotify-style merged filter bar
          Container(
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedFilters.isNotEmpty)
                  GestureDetector(
                    onTap: _clearFilters,
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Render merged selected filters as one pill with curved dividers
                        if (_selectedFilters.isNotEmpty)
                          Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children:
                                    List.generate(_selectedFilters.length, (i) {
                                  final filter = _selectedFilters.elementAt(i);
                                  final isFirst = i == 0;
                                  final isLast =
                                      i == _selectedFilters.length - 1;
                                  return Transform.translate(
                                    offset: Offset(i == 0 ? 0 : -16.0,
                                        0), // Overlap effect
                                    child: GestureDetector(
                                      onTap: () => _toggleFilter(filter),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        padding: EdgeInsets.only(
                                          left: isFirst ? 16 : 20,
                                          right: isLast ? 16 : 20,
                                          top: 8,
                                          bottom: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: primaryGreen,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(
                                                isFirst ? 20 : 0),
                                            bottomLeft: Radius.circular(
                                                isFirst ? 20 : 0),
                                            topRight: Radius.circular(
                                                isLast ? 20 : 0),
                                            bottomRight: Radius.circular(
                                                isLast ? 20 : 0),
                                          ),
                                          border: Border.all(
                                            color: primaryGreen,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          filter,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight:
                                                FontWeight.normal, // Not bold
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              // Draw curved dividers between pills (except after last)
                              ...List.generate(_selectedFilters.length - 1,
                                  (i) {
                                return Positioned(
                                  left: 32.0 +
                                      i * 36.0, // Adjust for pill width/overlap
                                  child: CustomPaint(
                                    size: const Size(24, 32),
                                    painter: _CurvedDividerPainter(
                                        color: Colors.black.withOpacity(0.18)),
                                  ),
                                );
                              }),
                            ],
                          ),
                        // Render unselected filters as individual pills
                        ..._filters
                            .where((f) => !_selectedFilters.contains(f))
                            .map((filter) {
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
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Notification List
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              child: _isLoading
                  ? const Center(
                      key: ValueKey('loading'),
                      child: CircularProgressIndicator())
                  : _selectedFilters.contains('Admin Alerts')
                      ? RefreshIndicator(
                          key: ValueKey('admin_alerts'),
                          onRefresh: _refreshAdminAlerts,
                          child: ListView.builder(
                            itemCount: _getFilteredNotifications().length,
                            itemBuilder: (context, index) {
                              final notification =
                                  _getFilteredNotifications()[index];
                              final isAlert =
                                  notification.containsKey('messages');
                              if (isAlert) {
                                // Admin Alert - use NotificationTemplate for consistency
                                return NotificationTemplate(
                                  message: _formatAdminAlertTitle(notification),
                                  reportId: notification['_id']?.toString(),
                                  barangay: (notification['barangays'] !=
                                              null &&
                                          (notification['barangays'] as List)
                                              .isNotEmpty)
                                      ? (notification['barangays'][0]['name'] ??
                                          'All Areas')
                                      : 'All Areas',
                                  status: 'alert',
                                  reportType: 'Admin Alert',
                                  isRead: false,
                                  latitude: null,
                                  longitude: null,
                                  streetName: null,
                                );
                              } else {
                                // Admin Announcement - use NotificationTemplate for consistency
                                return NotificationTemplate(
                                  message:
                                      notification['title'] ?? 'Announcement',
                                  reportId: notification['_id']?.toString(),
                                  barangay: 'All Areas',
                                  status: 'announcement',
                                  reportType: 'Admin Announcement',
                                  isRead: false,
                                  latitude: null,
                                  longitude: null,
                                  streetName: null,
                                );
                              }
                            },
                          ),
                        )
                      : ListView.builder(
                          key: ValueKey(_selectedFilters.join(',')),
                          itemCount: _getFilteredNotifications().length,
                          itemBuilder: (context, index) {
                            final notification =
                                _getFilteredNotifications()[index];
                            // Extract location data from the report
                            double? latitude;
                            double? longitude;
                            final report =
                                notification['report'] as Map<String, dynamic>?;
                            if (report != null &&
                                report['specific_location'] != null) {
                              final location = report['specific_location'];
                              if (location['coordinates'] != null) {
                                final coordinates = location['coordinates'];
                                if (coordinates is List &&
                                    coordinates.length >= 2) {
                                  longitude = coordinates[0].toDouble();
                                  latitude = coordinates[1].toDouble();
                                }
                              }
                            }
                            return NotificationTemplate(
                              message: _formatNotificationMessage(notification),
                              reportId: report?['_id']?.toString(),
                              barangay: report?['barangay'],
                              status: report?['status'],
                              reportType: report?['report_type'],
                              isRead: notification['isRead'] ?? false,
                              latitude: latitude,
                              longitude: longitude,
                              streetName: report?['street_name'],
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNotificationMessage(Map<String, dynamic> notification) {
    final report = notification['report'] as Map<String, dynamic>?;
    if (report == null) {
      return notification['message'] as String? ?? 'No message';
    }

    final reportType = report['report_type'] as String? ?? 'Report';
    final barangay = report['barangay'] as String? ?? 'Unknown Location';
    final status = report['status'] as String? ?? 'Pending';

    if (status == 'Validated') {
      return 'Your $reportType report in $barangay has been validated.';
    } else if (status == 'Rejected') {
      return 'Your $reportType report in $barangay has been rejected.';
    } else {
      return 'Your $reportType report in $barangay is being reviewed.';
    }
  }

  Widget _buildShowMoreButton() {
    final totalFiltered = _notifications.where((notification) {
      final report = notification['report'] as Map<String, dynamic>?;
      final status = report?['status']?.toString().toLowerCase();
      final createdAt = DateTime.parse(notification['createdAt']);
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      if (status == null || status == 'unknown') return false;

      if (_selectedFilters.contains('reviewing')) {
        return status == 'pending' && createdAt.isAfter(sevenDaysAgo);
      }

      if (_selectedFilters.contains('all')) {
        return createdAt.isAfter(sevenDaysAgo);
      }

      return status ==
              _selectedFilters.firstWhere(
                  (filter) =>
                      filter.toLowerCase() == 'reviewing' ||
                      filter.toLowerCase() == 'all',
                  orElse: () => '') &&
          createdAt.isAfter(sevenDaysAgo);
    }).length;

    if (totalFiltered <= _displayCount) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: TextButton(
          onPressed: () {
            setState(() {
              _displayCount += 10;
            });
          },
          child: Text(
            'Show More',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
