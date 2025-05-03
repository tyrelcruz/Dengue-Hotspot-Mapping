import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:buzzmap/services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final notificationService = NotificationService();
      final notifications =
          await notificationService.fetchNotifications(context);
      setState(() {
        _notifications =
            notifications; // Update notifications list with fetched data
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  sectionTitle("Today"),
                  ..._notifications.where((notification) {
                    // Filter today's notifications
                    return DateTime.parse(notification['createdAt'])
                        .isAfter(DateTime.now().subtract(Duration(days: 1)));
                  }).map((notification) {
                    return notificationItem(
                      notification['message'],
                      notification['createdAt'],
                      "assets/notifications/clean.png", // Adjust this image
                    );
                  }).toList(),
                  notificationDivider(),
                  sectionTitle("This Week"),
                  ..._notifications.where((notification) {
                    // Filter notifications for this week
                    final notificationDate =
                        DateTime.parse(notification['createdAt']);
                    final now = DateTime.now();
                    return notificationDate
                            .isAfter(now.subtract(Duration(days: 7))) &&
                        notificationDate.isBefore(now);
                  }).map((notification) {
                    return notificationItem(
                      notification['message'],
                      notification['createdAt'],
                      "assets/notifications/clean.png", // Adjust this image
                    );
                  }).toList(),
                ],
              ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            height: 15 / 14,
            letterSpacing: 0,
            color: Color.fromRGBO(96, 147, 175, 1)),
      ),
    );
  }

  Widget notificationItem(String title, String description, String imagePath) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.asset(
              imagePath,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget notificationDivider() {
    return const Divider(color: Color.fromRGBO(219, 235, 243, 1), thickness: 1);
  }
}
