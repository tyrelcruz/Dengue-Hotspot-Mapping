import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? pickedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick Location')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(14.5995, 120.9842), // Default to Manila
          zoom: 12,
        ),
        onTap: (LatLng position) {
          setState(() {
            pickedLocation = position;
          });
        },
        markers: pickedLocation != null
            ? {
                Marker(
                  markerId: const MarkerId('picked'),
                  position: pickedLocation!,
                )
              }
            : {},
      ),
      floatingActionButton: pickedLocation != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context, pickedLocation);
              },
              label: const Text('Select'),
              icon: const Icon(Icons.check),
            )
          : null,
    );
  }
}
