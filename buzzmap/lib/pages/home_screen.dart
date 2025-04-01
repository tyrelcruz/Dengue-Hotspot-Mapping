import 'package:buzzmap/pages/prevention_screen.dart';
import 'package:buzzmap/pages/community_screen.dart';
import 'package:flutter/material.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:buzzmap/pages/location_details_screen.dart';
import 'package:buzzmap/pages/post_screen.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : colorScheme.primary;

// Define a map for location coordinates
    final locationData = {
      'Baesa': LatLng(14.674376, 121.013138),
      'Balombato': LatLng(14.6760, 121.0437),
      'Bagbag': LatLng(14.7000, 121.0500),
      'Fairview': LatLng(14.6300, 121.0400),
      'Sangandaan': LatLng(14.6200, 121.0300),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Home',
        currentRoute: '/',
        themeMode: 'dark',
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.335,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 6,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 51.sp,
                            color: Colors.white,
                            fontFamily: 'Koulen',
                            letterSpacing: .5,
                            height: .9,
                          ),
                          children: [
                            TextSpan(text: 'STAY PROTECTED \nFROM '),
                            TextSpan(
                              text: 'DENGUE!',
                              style: TextStyle(color: Colors.yellow),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    _buildText(
                      'Check Dengue Hotspots in Your Area:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontFamily: 'Inter',
                        height: .2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLocationSelector(context, colorScheme, locationData),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.406,
            left: 0,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'SPREAD ',
                          style: TextStyle(
                            fontFamily: 'Koulen',
                            color: Color.fromRGBO(153, 192, 211, 1),
                            fontSize: 43.sp,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.2,
                            height: 0.4,
                          ),
                        ),
                        TextSpan(
                          text: 'AWARENESS!',
                          style: TextStyle(
                            fontFamily: 'Koulen',
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 43.sp,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1.2,
                            height: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.zero,
                    margin: EdgeInsets.zero,
                    child: _buildText(
                      'Report Cases, Raise Awareness, and \n Help Protect Your Community!',
                      style: TextStyle(
                          fontSize: 12.sp,
                          color: colorScheme.primary,
                          fontFamily: 'Inter-Regular',
                          fontWeight: FontWeight.w600,
                          height: 1.1),
                    ),
                  ),
                  _buildAwarenessSection(context, colorScheme),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'DENGUE ',
                          style: TextStyle(
                            fontSize: 36.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                            color: colorScheme.primary,
                            fontFamily: 'Koulen',
                          ),
                        ),
                        TextSpan(
                          text: 'PREVENTION ',
                          style: TextStyle(
                            fontSize: 36.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                            color: const Color.fromARGB(255, 255, 222, 59),
                            fontFamily: 'Koulen',
                          ),
                        ),
                        TextSpan(
                          text: 'TIPS',
                          style: TextStyle(
                            fontSize: 36.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                            color: colorScheme.primary,
                            fontFamily: 'Koulen',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPreventionCards(context, colorScheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreventionCards(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              colorScheme,
              'How to \nIdentify \nDengue \nMosquitoes?',
              'assets/bgarts/thinkman.png',
              width: 212,
              height: 145,
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                _buildSmallCard(
                  colorScheme,
                  'TRAVELERS BEWARE!',
                  "It's a big year for Dengue.",
                  width: 150,
                  height: 106,
                ),
                const SizedBox(height: 3),
                Container(
                  height: 35,
                  width: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(248, 169, 0, 1),
                        Color.fromRGBO(250, 221, 55, 1),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                PreventionScreen()), // Replace with your actual page widget
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'More Prevention Tips',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter-Bold',
                        fontSize: 9.5.sp,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(36, 82, 97, 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(ColorScheme colorScheme, String text, String imagePath,
      {double width = 250, double height = 130}) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Color.fromRGBO(96, 147, 175, 1),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                            fontFamily: 'Inter-Bold',
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.0),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromRGBO(248, 169, 0, 1),
                              Color.fromRGBO(250, 221, 55, 1),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 4),
                              child: Text(
                                'Learn More',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                maxLines: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -15,
            top: -1,
            child: SizedBox(
              width: 140,
              height: 150,
              child: OverflowBox(
                maxWidth: 140,
                maxHeight: 180,
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCard(ColorScheme colorScheme, String title, String subtitle,
      {double width = 140, double height = 160}) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color.fromRGBO(153, 192, 211, 1),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Koulen',
                    letterSpacing: 1.9,
                    fontSize: 23.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [
                    Color.fromRGBO(248, 169, 0, 1),
                    Color.fromRGBO(250, 221, 55, 1),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {},
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    child: Text(
                      'Learn More',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildText(String text, {required TextStyle style}) {
    return Text(
      text,
      style: style,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLocationSelector(BuildContext context, ColorScheme colorScheme,
      Map<String, LatLng> locationData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 56.0),
      child: SizedBox(
        width: 300,
        height: 40,
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
            items: locationData.keys.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (selectedLocation) {
              if (selectedLocation != null) {
                final coordinates = locationData[selectedLocation];
                if (coordinates != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationDetailsScreen(
                        location: selectedLocation,
                        latitude: coordinates.latitude,
                        longitude: coordinates.longitude,
                      ),
                    ),
                  );
                }
              }
            },
            hint: const Text(
              ' Select Location',
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

  Widget _buildAwarenessSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        const SizedBox(height: 15),
        SizedBox(
          height: 52,
          width: 350,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PostScreen()),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(36, 82, 97, 1),
                    Color.fromRGBO(74, 168, 199, 1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Container(
                    child: ClipOval(
                      child: SvgPicture.asset(
                        'assets/icons/Person.svg',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Middle | Share your report Container
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(219, 235, 243, 1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'Share your report here...',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Color.fromARGB(255, 105, 105, 105),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: 250,
          height: 47,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        CommunityScreen()), // Ensure this screen exists
              );
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF8A900),
                    Color(0xFFFADD37),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Container(
                alignment: Alignment.center,
                child: _buildText(
                  'Read more dengue reports here.',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 11.sp,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
