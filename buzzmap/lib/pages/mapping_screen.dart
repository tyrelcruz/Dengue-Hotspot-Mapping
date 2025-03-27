import 'package:flutter/material.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';
import 'package:buzzmap/pages/location_details_screen.dart';

class MappingScreen extends StatelessWidget {
  const MappingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: 'Mapping',
          currentRoute: '/mapping',
          themeMode: 'dark',
        ),
      ),
      body: Column(
        children: [
          Column(
            children: [
              const Text(
                'CHECK YOUR PLACE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Koulen',
                  fontSize: 46,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const Text(
                'Stay Protected. Look out for Dengue Outbreaks.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              _buildLocationSelector(context, colorScheme),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 400,
                  height: 100,
                  child: Image.asset(
                    'assets/bgarts/Greenmarkers.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22.0),
            child: RichText(
              textAlign: TextAlign.center,
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: 'NOTE: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: 'Click on the '),
                  TextSpan(
                    text: 'GREEN LOCATION ICON.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' to view reports.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 56.0),
      child: SizedBox(
        width: 262,
        height: 34,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            padding: EdgeInsets.zero,
            dropdownColor: Color.fromRGBO(36, 82, 97, 1),
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            iconSize: 24,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
            items: <String>[
              'Baesa',
              'Balombato',
              'Bagbag',
              'Fairview',
              'Sangandaan'
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (selectedLocation) {
              if (selectedLocation != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LocationDetailsScreen(location: selectedLocation),
                  ),
                );
              }
            },
            hint: const Text(
              'Quezon City',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
