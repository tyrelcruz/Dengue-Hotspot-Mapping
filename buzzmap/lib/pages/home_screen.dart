import 'package:buzzmap/pages/prevention_screen.dart';
import 'package:buzzmap/pages/community_screen.dart';
import 'package:flutter/material.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:buzzmap/pages/location_details_screen.dart';
import 'package:buzzmap/pages/post/post_screen.dart';
import 'package:buzzmap/tips/id_mosquito.dart';
import 'package:latlong2/latlong.dart';
import 'package:buzzmap/services/alert_service.dart';
import 'package:buzzmap/widgets/global_alert_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedDistrict;
  String? selectedBarangay;

  @override
  void initState() {
    super.initState();
    // Start polling for alerts when the app starts
    AlertService().startPolling();
  }

  @override
  void dispose() {
    AlertService().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : colorScheme.primary;

    return GlobalAlertOverlay(
      child: Scaffold(
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
                        padding: const EdgeInsets.only(top: 10.0),
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
                      _buildLocationSelector(context, colorScheme),
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
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(.6),
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
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
              context,
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

  Widget _buildCard(BuildContext context, ColorScheme colorScheme, String text,
      String imagePath,
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const IdMosquito()),
                              );
                            },
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
        padding: const EdgeInsets.all(22),
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
                    fontSize: 20.sp,
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
                    fontSize: 7.sp,
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

  Widget _buildLocationSelector(BuildContext context, ColorScheme colorScheme) {
    final districtData = {
      'District I': [
        'Bahay Toro',
        'Balingasa',
        'Damar',
        'Katipunan',
        'Mariblo'
      ],
      'District II': ['Baesa', 'Balumbato', 'Sangandaan', 'Unang Sigaw'],
      'District III': [
        'Amihan',
        'Bagbag',
        'Claro',
        'Masambong',
        'San Isidro Labrador'
      ],
      'District IV': ['Bagong Lipunan', 'Dona Josefa', 'Mariblo', 'San Jose'],
      'District V': ['Bagong Silangan', 'Commonwealth', 'Fairview', 'Payatas'],
      'District VI': [
        'Batasan Hills',
        'Holy Spirit',
        'Matandang Balara',
        'Pasong Tamo'
      ],
    };

    final locationData = {
      'Bahay Toro': LatLng(14.6572, 121.0214), // Verify coordinates
      'Balingasa': LatLng(14.6482, 120.9978), // Verify coordinates
      'Damar': LatLng(14.6523, 121.0112), // Verify coordinates
      'Katipunan': LatLng(14.6392, 121.0744), // Verify coordinates
      'Mariblo': LatLng(14.6581, 121.0045), // Verify coordinates
      'Baesa': LatLng(14.6743, 121.0131), // Verify coordinates
      'Balumbato': LatLng(14.6760, 121.0437), // Verify coordinates
      'Sangandaan': LatLng(14.6556, 121.0053), // Verify coordinates
      'Unang Sigaw': LatLng(14.6611, 121.0172), // Verify coordinates
      'Amihan': LatLng(14.6467, 121.0491), // Verify coordinates
      'Bagbag': LatLng(14.7000, 121.0500), // Verify coordinates
      'Claro': LatLng(14.6512, 121.0367), // Verify coordinates
      'Masambong': LatLng(14.6461, 121.0133), // Verify coordinates
      'San Isidro Labrador': LatLng(14.6437, 121.0231), // Verify coordinates
      'Bagong Lipunan': LatLng(14.6386, 121.0376), // Verify coordinates
      'Dona Josefa': LatLng(14.6413, 121.0416), // Verify coordinates
      'San Jose': LatLng(14.6288, 121.0343), // Verify coordinates
      'Bagong Silangan': LatLng(14.6731, 121.1067), // Verify coordinates
      'Commonwealth': LatLng(14.6903, 121.0819), // Verify coordinates
      'Fairview': LatLng(14.6300, 121.0400), // Verify coordinates
      'Payatas': LatLng(14.7015, 121.0965), // Verify coordinates
      'Batasan Hills': LatLng(14.6831, 121.0912), // Verify coordinates
      'Holy Spirit': LatLng(14.6694, 121.0777), // Verify coordinates
      'Matandang Balara': LatLng(14.6574, 121.0823), // Verify coordinates
      'Pasong Tamo': LatLng(14.6499, 121.0693), // Verify coordinates
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 30.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // District Dropdown
          Container(
            width: 300,
            height: 40,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: const Color.fromRGBO(36, 82, 97, 1),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                iconSize: 24,
                style: const TextStyle(
                    fontSize: 14, color: Colors.white, fontFamily: 'Inter'),
                value: selectedDistrict,
                items: districtData.keys.map((String district) {
                  return DropdownMenuItem<String>(
                    value: district,
                    child: Text(district),
                  );
                }).toList(),
                onChanged: (newDistrict) {
                  setState(() {
                    selectedDistrict = newDistrict;
                    selectedBarangay = null;
                  });
                },
                hint: const Text(
                  ' Select District in Quezon City',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white, fontFamily: 'Inter'),
                ),
              ),
            ),
          ),

          // Barangay Dropdown
          if (selectedDistrict != null)
            Container(
              width: 300,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  dropdownColor: const Color.fromRGBO(36, 82, 97, 1),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  iconSize: 24,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.white, fontFamily: 'Inter'),
                  value: selectedBarangay,
                  items: districtData[selectedDistrict]?.map((String barangay) {
                        return DropdownMenuItem<String>(
                          value: barangay,
                          child: Text(barangay),
                        );
                      }).toList() ??
                      [],
                  onChanged: (newBarangay) {
                    if (newBarangay != null) {
                      final coordinates = locationData[newBarangay];
                      if (coordinates != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LocationDetailsScreen(
                              location: newBarangay,
                              streetName:
                                  newBarangay, // 🔥 just pass barangay as placeholder street
                              latitude: coordinates.latitude,
                              longitude: coordinates.longitude,
                              district: selectedDistrict,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  hint: const Text(
                    ' Select Barangay',
                    style: TextStyle(
                        fontSize: 12, color: Colors.white, fontFamily: 'Inter'),
                  ),
                ),
              ),
            ),
        ],
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
