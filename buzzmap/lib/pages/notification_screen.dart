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
  bool _isLoading = true;
  bool _showAllToday = false;
  bool _showAllWeek = false;
  String _selectedFilter = 'All';
  int _displayCount = 10; // Number of notifications to show initially

  @override
  void initState() {
    super.initState();
    _loadNotifications();
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

  List<Map<String, dynamic>> _getFilteredNotifications() {
    Logger.log('Filtering notifications with status: $_selectedFilter',
        tag: 'FILTER');
    Logger.log('Total notifications before filtering: ${_notifications.length}',
        tag: 'FILTER');

    // Filter by status and date
    List<Map<String, dynamic>> filtered = _notifications.where((notification) {
      final report = notification['report'] as Map<String, dynamic>?;
      final status = report?['status']?.toString().toLowerCase();
      final createdAt = DateTime.parse(notification['createdAt']);
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      // Skip notifications with unknown status
      if (status == null || status == 'unknown') {
        return false;
      }

      // Handle "Reviewing" filter to match "pending" status
      if (_selectedFilter.toLowerCase() == 'reviewing') {
        return status == 'pending' && createdAt.isAfter(sevenDaysAgo);
      }

      // For "All" filter, show all notifications
      if (_selectedFilter.toLowerCase() == 'all') {
        return createdAt.isAfter(sevenDaysAgo);
      }

      // For other filters, do normal comparison
      return status == _selectedFilter.toLowerCase() &&
          createdAt.isAfter(sevenDaysAgo);
    }).toList();

    // Sort notifications by date (newest first)
    filtered.sort((a, b) {
      final dateA = DateTime.parse(a['createdAt']);
      final dateB = DateTime.parse(b['createdAt']);
      return dateB.compareTo(dateA);
    });

    // Limit the number of notifications to display
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

  @override
  Widget build(BuildContext context) {
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
          // Filter Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Validated'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rejected'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Reviewing'),
                ],
              ),
            ),
          ),
          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _getFilteredNotifications().isEmpty
                    ? const Center(child: Text('No notifications yet'))
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: _getFilteredNotifications().length,
                                itemBuilder: (context, index) {
                                  final notification =
                                      _getFilteredNotifications()[index];
                                  final report = notification['report']
                                      as Map<String, dynamic>?;

                                  // Extract location data from the report
                                  double? latitude;
                                  double? longitude;

                                  if (report != null &&
                                      report['specific_location'] != null) {
                                    final location =
                                        report['specific_location'];
                                    if (location['coordinates'] != null) {
                                      final coordinates =
                                          location['coordinates'];
                                      if (coordinates is List &&
                                          coordinates.length >= 2) {
                                        longitude = coordinates[0].toDouble();
                                        latitude = coordinates[1].toDouble();
                                      }
                                    }
                                  }

                                  return NotificationTemplate(
                                    message: _formatNotificationMessage(
                                        notification),
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
                            _buildShowMoreButton(),
                          ],
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

      if (_selectedFilter.toLowerCase() == 'reviewing') {
        return status == 'pending' && createdAt.isAfter(sevenDaysAgo);
      }

      if (_selectedFilter.toLowerCase() == 'all') {
        return createdAt.isAfter(sevenDaysAgo);
      }

      return status == _selectedFilter.toLowerCase() &&
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

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color:
              isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        Logger.log('Filter chip selected: $label', tag: 'FILTER');
        setState(() {
          _selectedFilter = selected ? label : 'All';
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
