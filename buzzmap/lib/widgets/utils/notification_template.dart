import 'package:flutter/material.dart';
import 'package:buzzmap/pages/mapping_screen.dart';
import 'package:buzzmap/widgets/utils/notification_popup.dart';

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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('🔍 Notification tapped:');
          print('📝 Message: $message');
          print('📍 Location: $latitude, $longitude');
          print('📊 Status: $status');

          if (status?.toLowerCase() == 'validated' &&
              latitude != null &&
              longitude != null) {
            print(
                '✅ Validated report with location data, navigating to map...');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MappingScreen(
                  initialLatitude: latitude!,
                  initialLongitude: longitude!,
                  initialZoom: 15.0,
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
            print('❌ Cannot navigate: Invalid status or missing location data');
            print('Status: $status');
            print('Latitude: $latitude');
            print('Longitude: $longitude');
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isRead ? Colors.grey[100] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
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
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      default:
        return 'Unknown Status';
    }
  }
}
