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
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

// Map of districts to their barangays
final Map<String, List<String>> districtData = {
  'District 1': [
    'Alicia',
    'Bagong Silangan',
    'Batasan Hills',
    'Commonwealth',
    'Holy Spirit',
    'Immaculate Concepcion',
    'Payatas',
    'San Antonio',
    'San Bartolome',
    'San Isidro',
    'San Jose',
    'San Roque',
    'Santa Cruz',
    'Santa Lucia',
    'Santa Monica',
    'Sto. Cristo',
    'Sto. Niño',
    'Villa Maria Clara'
  ],
  'District 2': [
    'Bagong Silangan',
    'Batasan Hills',
    'Commonwealth',
    'Holy Spirit',
    'Immaculate Concepcion',
    'Payatas',
    'San Antonio',
    'San Bartolome',
    'San Isidro',
    'San Jose',
    'San Roque',
    'Santa Cruz',
    'Santa Lucia',
    'Santa Monica',
    'Sto. Cristo',
    'Sto. Niño',
    'Villa Maria Clara'
  ],
  'District 3': [
    'Alicia',
    'Bagong Silangan',
    'Batasan Hills',
    'Commonwealth',
    'Holy Spirit',
    'Immaculate Concepcion',
    'Payatas',
    'San Antonio',
    'San Bartolome',
    'San Isidro',
    'San Jose',
    'San Roque',
    'Santa Cruz',
    'Santa Lucia',
    'Santa Monica',
    'Sto. Cristo',
    'Sto. Niño',
    'Villa Maria Clara'
  ],
  'District 4': [
    'Alicia',
    'Bagong Silangan',
    'Batasan Hills',
    'Commonwealth',
    'Holy Spirit',
    'Immaculate Concepcion',
    'Payatas',
    'San Antonio',
    'San Bartolome',
    'San Isidro',
    'San Jose',
    'San Roque',
    'Santa Cruz',
    'Santa Lucia',
    'Santa Monica',
    'Sto. Cristo',
    'Sto. Niño',
    'Villa Maria Clara'
  ],
  'District 5': [
    'Alicia',
    'Bagong Silangan',
    'Batasan Hills',
    'Commonwealth',
    'Holy Spirit',
    'Immaculate Concepcion',
    'Payatas',
    'San Antonio',
    'San Bartolome',
    'San Isidro',
    'San Jose',
    'San Roque',
    'Santa Cruz',
    'Santa Lucia',
    'Santa Monica',
    'Sto. Cristo',
    'Sto. Niño',
    'Villa Maria Clara'
  ],
  'District 6': [
    'Alicia',
    'Bagong Silangan',
    'Batasan Hills',
    'Commonwealth',
    'Holy Spirit',
    'Immaculate Concepcion',
    'Payatas',
    'San Antonio',
    'San Bartolome',
    'San Isidro',
    'San Jose',
    'San Roque',
    'Santa Cruz',
    'Santa Lucia',
    'Santa Monica',
    'Sto. Cristo',
    'Sto. Niño',
    'Villa Maria Clara'
  ]
};

// Map of barangays to their coordinates
final Map<String, LatLng> locationData = {
  'Alicia': LatLng(14.6760, 121.0437),
  'Bagong Silangan': LatLng(14.6760, 121.0437),
  'Batasan Hills': LatLng(14.6760, 121.0437),
  'Commonwealth': LatLng(14.6760, 121.0437),
  'Holy Spirit': LatLng(14.6760, 121.0437),
  'Immaculate Concepcion': LatLng(14.6760, 121.0437),
  'Payatas': LatLng(14.6760, 121.0437),
  'San Antonio': LatLng(14.6760, 121.0437),
  'San Bartolome': LatLng(14.6760, 121.0437),
  'San Isidro': LatLng(14.6760, 121.0437),
  'San Jose': LatLng(14.6760, 121.0437),
  'San Roque': LatLng(14.6760, 121.0437),
  'Santa Cruz': LatLng(14.6760, 121.0437),
  'Santa Lucia': LatLng(14.6760, 121.0437),
  'Santa Monica': LatLng(14.6760, 121.0437),
  'Sto. Cristo': LatLng(14.6760, 121.0437),
  'Sto. Niño': LatLng(14.6760, 121.0437),
  'Villa Maria Clara': LatLng(14.6760, 121.0437),
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedBarangay;
  List<String> allBarangays = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Start polling for alerts when the app starts
    AlertService().startPolling();
    _loadBarangays();
  }

  Future<void> _loadBarangays() async {
    try {
      final String data =
          await rootBundle.loadString('assets/geojson/barangays.geojson');
      final geojson = json.decode(data);
      Set<String> barangayNames = {};

      for (var feature in geojson['features']) {
        final name = feature['properties']['name'];
        if (name != null) {
          barangayNames.add(name);
        }
      }

      setState(() {
        allBarangays = barangayNames.toList()..sort();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading barangays: $e');
      setState(() {
        isLoading = false;
      });
    }
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 30.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 300,
            child: _buildBarangayDropdown(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBarangayDropdown(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 300,
        height: 40,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SizedBox(
      width: 300,
      height: 40,
      child: DropdownSearch<String>(
        items: allBarangays,
        selectedItem: selectedBarangay,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: "Select Barangay in Quezon City",
            labelStyle: const TextStyle(color: Colors.white, fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(40),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
          ),
        ),
        popupProps: const PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            style: TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: "Search barangay...",
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        dropdownButtonProps: const DropdownButtonProps(
          icon: Icon(Icons.arrow_drop_down, color: Colors.white),
        ),
        onChanged: (value) {
          setState(() {
            selectedBarangay = value;
            if (value != null) {
              final coordinates = locationData[value];
              if (coordinates != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LocationDetailsScreen(
                      location: value,
                      streetName: value,
                      latitude: coordinates.latitude,
                      longitude: coordinates.longitude,
                      district: null,
                    ),
                  ),
                );
              }
            }
          });
        },
        dropdownBuilder: (context, selectedItem) {
          return Text(
            selectedItem ?? 'Select Barangay in Quezon City',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          );
        },
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
