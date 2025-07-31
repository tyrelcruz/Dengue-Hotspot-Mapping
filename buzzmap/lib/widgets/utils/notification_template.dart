import 'package:flutter/material.dart';
import 'package:buzzmap/pages/mapping_screen.dart';
import 'package:buzzmap/widgets/utils/notification_popup.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NotificationTemplate extends StatelessWidget {
  final String message;
  final String? reportId;
  final String? barangay;
  final String? status;
  final String? reportType;
  final bool isRead;
  final double? latitude;
  final double? longitude;
  final String? streetName;
  final DateTime createdAt;
  final VoidCallback? onTap;

  const NotificationTemplate({
    Key? key,
    required this.message,
    this.reportId,
    this.barangay,
    this.status,
    this.reportType,
    this.isRead = false,
    this.latitude,
    this.longitude,
    this.streetName,
    required this.createdAt,
    this.onTap,
  }) : super(key: key);

  String _getTimeAgo() {
    if (createdAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(createdAt!);

    if (difference.inDays > 7) {
      return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ??
              () {
                print('🔍 Notification tapped:');
                print('📝 Message: $message');
                print('📍 Location: $latitude, $longitude');
                print('📊 Status: $status');

                if (status?.toLowerCase() == 'validated' &&
                    latitude != null &&
                    longitude != null) {
                  print(
                      '✅ Validated report with location data, navigating to map...');
                  print('📍 Using coordinates: $latitude, $longitude');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MappingScreen(
                        initialLatitude: latitude!,
                        initialLongitude: longitude!,
                        initialZoom: 18.0,
                        reportId: reportId,
                      ),
                    ),
                  );
                } else if (status?.toLowerCase() == 'pending') {
                  NotificationPopup.showUnderReview(context);
                } else if (status?.toLowerCase() == 'deleted') {
                  NotificationPopup.showReportDeleted(context);
                } else if (status?.toLowerCase() == 'rejected') {
                  NotificationPopup.showReportRejected(context);
                } else {
                  print(
                      '❌ Cannot navigate: Invalid status or missing location data');
                  print('Status: $status');
                  print('Latitude: $latitude');
                  print('Longitude: $longitude');
                }
              },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon or Logo based on notification type
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: status?.toLowerCase() == 'alert' ||
                            status?.toLowerCase() == 'announcement'
                        ? Colors.grey[50]
                        : _getStatusColor().withOpacity(0.1),
                    shape: status?.toLowerCase() == 'alert' ||
                            status?.toLowerCase() == 'announcement'
                        ? BoxShape.rectangle
                        : BoxShape.circle,
                    borderRadius: status?.toLowerCase() == 'alert' ||
                            status?.toLowerCase() == 'announcement'
                        ? BorderRadius.circular(8)
                        : null,
                  ),
                  child: status?.toLowerCase() == 'alert' ||
                          status?.toLowerCase() == 'announcement'
                      ? SvgPicture.asset(
                          'assets/icons/logo_ligthbg.svg',
                          fit: BoxFit.contain,
                        )
                      : Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight:
                              isRead ? FontWeight.normal : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(),
                              style: TextStyle(
                                color: _getStatusColor(),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            barangay ?? 'Unknown Location',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status?.toLowerCase()) {
      case 'validated':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'deleted':
        return Colors.grey;
      case 'alert':
        return Colors.red;
      case 'announcement':
        return Colors.blue;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    switch (status?.toLowerCase()) {
      case 'validated':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_empty;
      case 'rejected':
        return Icons.cancel;
      case 'deleted':
        return Icons.delete;
      case 'alert':
        return Icons.warning;
      case 'announcement':
        return Icons.announcement;
      default:
        return Icons.notifications;
    }
  }

  String _getStatusText() {
    switch (status?.toLowerCase()) {
      case 'validated':
        return 'Validated';
      case 'pending':
        return 'Under Review';
      case 'rejected':
        return 'Rejected';
      case 'deleted':
        return 'Deleted';
      case 'alert':
        return 'Alert';
      case 'announcement':
        return 'Announcement';
      default:
        return 'Unknown Status';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}
