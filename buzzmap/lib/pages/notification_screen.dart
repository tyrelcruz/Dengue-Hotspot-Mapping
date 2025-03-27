import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

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
        child: ListView(
          children: [
            sectionTitle("Today"),
            notificationItem(
              "Dengue Outbreak in Your Area!",
              "Cases have risen by 30% in Quezon City. Take precautions now!",
              "assets/notifications/clean.png",
            ),
            notificationDivider(),
            notificationItem(
              "High-Risk Dengue Zone Detected",
              "A hotspot has been identified near Mandaluyong City. Avoid mosquito-prone areas.",
              "assets/notifications/mosquitos.png",
            ),
            notificationDivider(),
            notificationItem(
              "Emergency Fumigation Scheduled",
              "Mosquito control operations will take place in Pasay City on February 18, 2025.",
              "assets/notifications/clearingoperation.png",
            ),
            notificationDivider(),
            sectionTitle("This Week"),
            notificationItem(
              "New Dengue Report Near You",
              "A user has reported a dengue case at Quezon City. Stay alert!",
              "assets/notifications/positivedengue.png",
            ),
            notificationDivider(),
            notificationItem(
              "Mosquito Breeding Site Found",
              "Stagnant water was reported at Caloocan City. Authorities have been notified.",
              "assets/notifications/breedingground.png",
            ),
            notificationDivider(),
            notificationItem(
              "Check Your Home for Breeding Sites!",
              "Empty water containers and keep surroundings clean.",
              "assets/notifications/breedingsites.png",
            ),
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
