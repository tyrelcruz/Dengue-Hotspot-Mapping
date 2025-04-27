import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EarthWebViewScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const EarthWebViewScreen({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<EarthWebViewScreen> createState() => _EarthWebViewScreenState();
}

class _EarthWebViewScreenState extends State<EarthWebViewScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), _openEarthLink);
  }

  Future<void> _openEarthLink() async {
    final String url =
        "https://earth.google.com/web/search/?api=1&query=${widget.latitude},${widget.longitude}";

    final Uri earthUri = Uri.parse(url);

    if (await canLaunchUrl(earthUri)) {
      await launchUrl(
        earthUri,
        mode: LaunchMode.externalApplication, // Open in Chrome/Safari
      );
      Navigator.pop(context); // After launching, go back automatically
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch Google Earth')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opening Google Earth...'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Opening 3D Earth View...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 36, 82, 97),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
