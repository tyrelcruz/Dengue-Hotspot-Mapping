import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/services/notification_service.dart';
import 'package:buzzmap/widgets/utils/notification_template.dart';
import 'package:buzzmap/pages/mapping_screen.dart';

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
    print('🔍 Filtering notifications with status: $_selectedFilter');
    print('📱 Total notifications before filtering: ${_notifications.length}');

    // Filter by status only
    List<Map<String, dynamic>> statusFiltered =
        _notifications.where((notification) {
      final report = notification['report'] as Map<String, dynamic>?;
      final status = report?['status']?.toString().toLowerCase();
      print('📄 Notification status: $status');

      // Skip notifications with unknown status
      if (status == null || status == 'unknown') {
        return false;
      }

      // Handle "Reviewing" filter to match "pending" status
      if (_selectedFilter.toLowerCase() == 'reviewing') {
        return status == 'pending';
      }

      // For "All" filter, show all notifications
      if (_selectedFilter.toLowerCase() == 'all') {
        return true;
      }

      // For other filters, do normal comparison
      return status == _selectedFilter.toLowerCase();
    }).toList();
    print('✅ Notifications after status filter: ${statusFiltered.length}');

    return statusFiltered;
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final report = notification['report'] as Map<String, dynamic>?;
    if (report == null) {
      print('❌ No report data found in notification');
      return;
    }

    print('🔍 Handling notification tap:');
    print('📝 Report ID: ${report['_id']}');
    print('📊 Status: ${report['status']}');
    print(
        '📍 Location data: ${notification['latitude']}, ${notification['longitude']}');

    if (report['status']?.toLowerCase() == 'validated' &&
        notification['latitude'] != null &&
        notification['longitude'] != null) {
      print('✅ Validated report with location data, navigating to map...');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MappingScreen(
            initialLatitude: notification['latitude'].toDouble(),
            initialLongitude: notification['longitude'].toDouble(),
            initialZoom: 15.0,
            reportId: report['_id'],
          ),
        ),
      );
    } else {
      print('❌ Cannot navigate: Invalid status or missing location data');
      print('Status: ${report['status']}');
      print('Latitude: ${notification['latitude']}');
      print('Longitude: ${notification['longitude']}');
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
                        child: ListView.builder(
                          itemCount: _getFilteredNotifications().length,
                          itemBuilder: (context, index) {
                            final notification =
                                _getFilteredNotifications()[index];
                            final report =
                                notification['report'] as Map<String, dynamic>?;

                            // Extract location data from the notification
                            double? latitude =
                                notification['latitude'] as double?;
                            double? longitude =
                                notification['longitude'] as double?;

                            if (report != null) {
                              if (report['specific_location'] != null) {
                                final location = report['specific_location'];
                                if (location['coordinates'] != null) {
                                  final coordinates = location['coordinates'];
                                  if (coordinates is List &&
                                      coordinates.length >= 2) {
                                    latitude = coordinates[1].toDouble();
                                    longitude = coordinates[0].toDouble();
                                  }
                                }
                              } else if (report['coordinates'] != null) {
                                final coordinates =
                                    report['coordinates'] as List;
                                if (coordinates.length >= 2) {
                                  latitude = coordinates[1].toDouble();
                                  longitude = coordinates[0].toDouble();
                                }
                              }
                            }

                            return NotificationTemplate(
                              message: _formatNotificationMessage(notification),
                              reportId: report?['_id'] as String?,
                              barangay: report?['barangay'] as String?,
                              status: report?['status'] as String?,
                              reportType: report?['report_type'] as String?,
                              isRead: notification['isRead'] as bool? ?? false,
                              latitude: latitude,
                              longitude: longitude,
                              streetName: report?['street_name'] as String?,
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

  Widget _buildSeeAllButton(bool isToday) {
    final totalCount = _notifications.where((notification) {
      final notificationDate = DateTime.parse(notification['createdAt']);
      final now = DateTime.now();
      if (isToday) {
        return notificationDate.isAfter(now.subtract(Duration(days: 1)));
      } else {
        final oneDayAgo = now.subtract(Duration(days: 1));
        final sevenDaysAgo = now.subtract(Duration(days: 7));
        return notificationDate.isAfter(sevenDaysAgo) &&
            notificationDate.isBefore(oneDayAgo);
      }
    }).length;

    print('🔢 ${isToday ? "Today" : "This Week"} total count: $totalCount');

    if (totalCount <= 10) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: TextButton(
          onPressed: () {
            setState(() {
              if (isToday) {
                _showAllToday = !_showAllToday;
              } else {
                _showAllWeek = !_showAllWeek;
              }
            });
          },
          child: Text(
            (isToday ? _showAllToday : _showAllWeek) ? 'Show Less' : 'See All',
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
        print('🔘 Filter chip selected: $label');
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
