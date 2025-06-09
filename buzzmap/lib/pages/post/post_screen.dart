import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'package:buzzmap/main.dart';
import 'package:buzzmap/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

import 'package:buzzmap/auth/config.dart'; // Adjust the path based on your file structure
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:buzzmap/services/notification_service.dart';
import 'package:buzzmap/widgets/utils/notification_template.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buzzmap/errors/flushbar.dart';

import 'package:buzzmap/pages/community_screen.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:geolocator/geolocator.dart';
import 'package:buzzmap/services/offline_post_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> with TickerProviderStateMixin {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  String? selectedBarangay;
  String? selectedReportType;
  LatLng? selectedCoordinates;
  String? selectedAddress;
  String? selectedDistrict;
  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isAnonymous = false;
  String? _currentUsername;
  String? _profilePhotoUrl;
  late SharedPreferences _prefs;

  final List<String> reportTypes = [
    'Stagnant Water',
    'Uncollected Garbage or Trash',
    'Others'
  ];

  Set<Polygon> _barangayPolygons = {};

  final ImagePicker _picker = ImagePicker();

  GoogleMapController? mapController;
  Map<String, LatLng> barangayCenters = {};

  bool _mapScrollable = true;

  Map<String, List<String>> districtData = {};

  bool _isLoadingLocation = false;

  // Tutorial overlay state
  bool _showMapTutorial = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOut,
      ),
    );

    loadBarangayCentersFromGeoJson().then((data) {
      _addQuezonCityMask();
      setState(() {
        barangayCenters = data;
      });
    });

    _loadGeoJsonPolygons();
    _showMapTutorial = selectedCoordinates == null;
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _ensureProfilePhotoLoaded();
  }

  Future<void> _ensureProfilePhotoLoaded() async {
    String? profilePhotoUrl = _prefs.getString('profilePhotoUrl');
    final token = _prefs.getString('authToken');
    if ((profilePhotoUrl == null || profilePhotoUrl.isEmpty) && token != null) {
      try {
        final response = await http.get(
          Uri.parse('${Config.baseUrl}/api/v1/auth/me'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final photoUrl = data['user']?['profilePhotoUrl'];
          if (photoUrl != null && photoUrl.isNotEmpty) {
            await _prefs.setString('profilePhotoUrl', photoUrl);
            setState(() {
              _profilePhotoUrl = photoUrl;
            });
          }
        }
      } catch (e) {
        print('Error fetching profile photo URL: $e');
      }
    } else {
      setState(() {
        _profilePhotoUrl = profilePhotoUrl;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.stop();
    _pulseController.dispose();
    _fadeController.dispose();
    dateController.dispose();
    timeController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _disableMapScrolling() {
    setState(() {
      _mapScrollable = false;
    });
  }

  void _enableMapScrolling() {
    setState(() {
      _mapScrollable = true;
    });
  }

  Future<void> _submitPost() async {
    if (_isLoading) return; // Prevent duplicate submissions
    if (selectedCoordinates == null ||
        selectedBarangay == null ||
        selectedReportType == null ||
        dateController.text.isEmpty ||
        timeController.text.isEmpty ||
        descriptionController.text.trim().isEmpty) {
      await AppFlushBar.showError(
        context,
        title: 'Missing Information',
        message: 'Please complete all required fields before sharing.',
      );
      return;
    }

    // Ensure the coordinates are valid numbers
    if (selectedCoordinates!.latitude.isNaN ||
        selectedCoordinates!.longitude.isNaN) {
      await AppFlushBar.showError(
        context,
        title: 'Invalid Location',
        message: 'Please select a valid location within Quezon City.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final formattedDateTime =
        _combineDateAndTime(dateController.text, timeController.text);

    if (formattedDateTime == null) {
      setState(() {
        _isLoading = false;
      });
      await AppFlushBar.showError(
        context,
        title: 'Invalid Date/Time',
        message: 'Please check your date and time format.',
      );
      return;
    }

    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      // Prepare post data
      final postData = {
        'barangay': selectedBarangay!,
        'report_type': selectedReportType!,
        'description': descriptionController.text.trim(),
        'date_and_time': formattedDateTime,
        'specific_location': {
          'type': 'Point',
          'coordinates': [
            selectedCoordinates!.longitude,
            selectedCoordinates!.latitude,
          ],
        },
        'images': _selectedImages.map((file) => file.path).toList(),
      };

      if (isOnline) {
        try {
          // Try to submit online
          final url = Uri.parse(Config.createPostUrl);
          final request = http.MultipartRequest('POST', url);
          request.headers['Authorization'] = 'Bearer $token';

          request.fields.addAll({
            'barangay': postData['barangay'] as String,
            'report_type': postData['report_type'] as String,
            'description': postData['description'] as String,
            'date_and_time': postData['date_and_time'] as String,
            'specific_location[type]': (postData['specific_location']
                as Map<String, dynamic>)['type'] as String,
            'specific_location[coordinates][0]': (postData['specific_location']
                    as Map<String, dynamic>)['coordinates'][0]
                .toString(),
            'specific_location[coordinates][1]': (postData['specific_location']
                    as Map<String, dynamic>)['coordinates'][1]
                .toString(),
          });

          // Add images if any
          for (final image in _selectedImages) {
            request.files
                .add(await http.MultipartFile.fromPath('images', image.path));
          }

          final streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);

          if (response.statusCode == 200 || response.statusCode == 201) {
            if (mounted) {
              await AppFlushBar.showSuccess(
                context,
                title: 'Success',
                message: 'Your report has been submitted successfully!',
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const CommunityScreen()),
              );
            }
          } else {
            throw Exception('Failed to submit post: ${response.statusCode}');
          }
        } catch (e) {
          print('Online submission failed, saving offline: $e');
          // If online submission fails, save offline
          // Convert image paths to strings before saving
          final offlineData = Map<String, dynamic>.from(postData);
          offlineData['images'] =
              _selectedImages.map((file) => file.path.toString()).toList();
          await OfflinePostService().addOfflinePost(offlineData);
          if (mounted) {
            await AppFlushBar.showSuccess(
              context,
              title: 'Saved Offline',
              message:
                  'Your report has been saved and will be submitted when you\'re back online.',
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CommunityScreen()),
            );
          }
        }
      } else {
        // Save offline
        // Convert image paths to strings before saving
        final offlineData = Map<String, dynamic>.from(postData);
        offlineData['images'] =
            _selectedImages.map((file) => file.path.toString()).toList();
        await OfflinePostService().addOfflinePost(offlineData);
        if (mounted) {
          await AppFlushBar.showSuccess(
            context,
            title: 'Saved Offline',
            message:
                'Your report has been saved and will be submitted when you\'re back online.',
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CommunityScreen()),
          );
        }
      }
    } catch (e) {
      print('Error submitting post: $e');
      if (mounted) {
        await AppFlushBar.showError(
          context,
          title: 'Error',
          message: 'Failed to submit your report. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadGeoJsonPolygons() async {
    try {
      final String data =
          await rootBundle.loadString('assets/geojson/barangays.geojson');
      final geo = json.decode(data);

      Set<Polygon> loadedPolygons = {};
      for (final feature in geo['features']) {
        final properties = feature['properties'];
        final geometry = feature['geometry'];

        if (properties == null ||
            geometry == null ||
            geometry['type'] != 'Polygon') continue;

        final name = properties['name'] ?? properties['NAME_3'];
        if (name == null) continue;

        final coords = geometry['coordinates'][0]
            .map<LatLng>(
                (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()))
            .toList();

        loadedPolygons.add(
          Polygon(
            polygonId: PolygonId(name),
            points: coords,
            strokeColor: Colors.grey.shade400,
            strokeWidth: 2,
            fillColor: Colors.transparent,
          ),
        );
      }

      setState(() {
        _barangayPolygons = loadedPolygons;
      });
    } catch (e) {
      print('Error loading GeoJSON polygons: $e');
    }
  }

  Future<void> _addQuezonCityMask() async {
    try {
      final String data =
          await rootBundle.loadString('assets/geojson/barangays.geojson');
      final geo = json.decode(data);

      List<List<LatLng>> qcBarangayHoles = [];

      for (final feature in geo['features']) {
        final geometry = feature['geometry'];

        if (geometry == null || geometry['type'] != 'Polygon') continue;

        final coords = geometry['coordinates'][0]
            .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
            .toList();

        qcBarangayHoles.add(coords);
      }

      final List<LatLng> outerBounds = [
        const LatLng(15.0, 120.5),
        const LatLng(15.0, 121.5),
        const LatLng(14.2, 121.5),
        const LatLng(14.2, 120.5),
      ];

      setState(() {
        _barangayPolygons.add(
          Polygon(
            polygonId: const PolygonId('outside-quezon-city'),
            points: outerBounds,
            holes: qcBarangayHoles,
            fillColor: Colors.red.withOpacity(0.25),
            strokeColor: Colors.transparent,
          ),
        );
      });
    } catch (e) {
      print('Error fixing QC mask: $e');
    }
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 3) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: const Text(
                    'Take a photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? pickedFile = await _picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (pickedFile != null) {
                      setState(() {
                        _selectedImages.add(File(pickedFile.path));
                      });
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: const Text(
                    'Choose from gallery',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? pickedFile = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (pickedFile != null) {
                      setState(() {
                        _selectedImages.add(File(pickedFile.path));
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, LatLng>> loadBarangayCentersFromGeoJson() async {
    final String data =
        await rootBundle.loadString('assets/geojson/barangays.geojson');
    final geojson = json.decode(data);
    Map<String, LatLng> centers = {};
    Set<String> barangayNames = {};

    for (var feature in geojson['features']) {
      final properties = feature['properties'];
      final geometry = feature['geometry'];

      if (properties == null ||
          geometry == null ||
          geometry['type'] != 'Polygon') continue;

      // Get the name from either name or NAME_3 property
      final name = properties['name'] ?? properties['NAME_3'];
      if (name == null) continue;

      // Handle special cases for barangay names
      String processedName = name;
      if (name == 'E. Rodriguez Sr.') {
        processedName = 'E. Rodriguez';
      }

      final coords = geometry['coordinates'][0];
      double latSum = 0;
      double lngSum = 0;
      for (var point in coords) {
        lngSum += point[0];
        latSum += point[1];
      }
      final count = coords.length;
      centers[processedName] = LatLng(latSum / count, lngSum / count);
      barangayNames.add(processedName);
    }

    // Update the district data with all barangays
    setState(() {
      districtData = {
        'District I':
            barangayNames.where((name) => _isInDistrict(name, 1)).toList(),
        'District II':
            barangayNames.where((name) => _isInDistrict(name, 2)).toList(),
        'District III':
            barangayNames.where((name) => _isInDistrict(name, 3)).toList(),
        'District IV':
            barangayNames.where((name) => _isInDistrict(name, 4)).toList(),
        'District V':
            barangayNames.where((name) => _isInDistrict(name, 5)).toList(),
        'District VI':
            barangayNames.where((name) => _isInDistrict(name, 6)).toList(),
      };
    });

    return centers;
  }

  bool _isInDistrict(String barangayName, int district) {
    // This is a simplified version - you might want to implement a more accurate district mapping
    final districtRanges = {
      1: [
        'Alicia',
        'Apollonio Samson',
        'Bahay Toro',
        'Balingasa',
        'Damar',
        'Del Monte',
        'Lourdes',
        'Maharlika',
        'Manresa',
        'Mariblo',
        'N.S. Amoranto',
        'Paltok',
        'Paraiso',
        'Salvacion',
        'San Antonio',
        'San Isidro Labrador',
        'Santa Cruz',
        'Sienna',
        'Sta. Teresita',
        'Sto. Cristo',
        'Sto. Domingo',
        'Talayan',
        'Vasra',
        'Veterans Village'
      ],
      2: [
        'Baesa',
        'Bagong Pag-asa',
        'Balumbato',
        'Culiat',
        'Kaligayahan',
        'New Era',
        'Pasong Putik Proper',
        'San Bartolome',
        'Sangandaan',
        'Sauyo',
        'Talipapa',
        'Unang Sigaw'
      ],
      3: [
        'Amihan',
        'Botocan',
        'Claro',
        'Duyan-Duyan',
        'E. Rodriguez Sr.',
        'Escopa I',
        'Escopa II',
        'Escopa III',
        'Escopa IV',
        'Kalusugan',
        'Kristong Hari',
        'Loyola Heights',
        'Marilag',
        'Masagana',
        'Matandang Balara',
        'Milagrosa',
        'Pansol',
        'Quirino 2-A',
        'Quirino 2-B',
        'Quirino 2-C',
        'Quirino 3-A',
        'San Vicente',
        'Silangan',
        'Tagumpay',
        'Villa Maria Clara',
        'White Plains'
      ],
      4: [
        'Bagong Lipunan ng Crame',
        'Damayang Lagi',
        'Doña Aurora',
        'Doña Imelda',
        'Doña Josefa',
        'Horseshoe',
        'Immaculate Concepcion',
        'Kamuning',
        'Kaunlaran',
        'Laging Handa',
        'Obrero',
        'Old Capitol Site',
        'Paligsahan',
        'Roxas',
        'Sacred Heart',
        'San Martin de Porres',
        'South Triangle',
        'West Triangle'
      ],
      5: [
        'Bagong Silangan',
        'Capri',
        'Commonwealth',
        'Greater Lagro',
        'Gulod',
        'Holy Spirit',
        'Nagkaisang Nayon',
        'North Fairview',
        'Payatas',
        'San Agustin',
        'Santa Lucia',
        'Santa Monica',
        'Tandang Sora',
        'Fairview'
      ],
      6: [
        'Batasan Hills',
        'Blue Ridge A',
        'Blue Ridge B',
        'Camp Aguinaldo',
        'Central',
        'Cubao',
        'East Kamias',
        'Libis',
        'Mangga',
        'Pinagkaisahan',
        'Project 6',
        'San Roque',
        'Sikatuna Village',
        'Socorro',
        'UP Campus',
        'UP Village',
        'Ugong Norte',
        'West Kamias',
        'Teachers Village East',
        'Teachers Village West',
        'Pasong Tamo'
      ],
    };

    return districtRanges[district]?.contains(barangayName) ?? false;
  }

  String? guessDistrictFromBarangay(String? barangay) {
    if (barangay == null) return null;
    for (var entry in districtData.entries) {
      if (entry.value.contains(barangay)) {
        return entry.key;
      }
    }
    return null;
  }

  Widget _buildBarangayDropdown(BuildContext context) {
    final theme = Theme.of(context);
    // Use all barangay names from barangayCenters, sorted alphabetically
    final allBarangays = barangayCenters.keys.toList()..sort();

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: DropdownSearch<String>(
        items: allBarangays,
        selectedItem: selectedBarangay,
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            labelText: "Select Barangay",
            labelStyle:
                TextStyle(color: theme.colorScheme.primary, fontSize: 12),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        popupProps: const PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            style: TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: "Search barangay...",
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
        dropdownButtonProps: DropdownButtonProps(
          icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
        ),
        onChanged: (value) {
          setState(() {
            selectedBarangay = value;
            selectedDistrict = guessDistrictFromBarangay(value);
            if (value != null && barangayCenters.containsKey(value)) {
              selectedCoordinates = barangayCenters[value];
              mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(selectedCoordinates!, 16),
              );
            }
          });
        },
        dropdownBuilder: (context, selectedItem) {
          return Text(
            selectedItem ?? 'Select Barangay',
            style: TextStyle(color: theme.colorScheme.primary),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = Theme.of(context).extension<CustomColors>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Create Post',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          color: Colors.black,
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade200,
                    ),
                    child: ClipOval(
                      child: _profilePhotoUrl != null &&
                              _profilePhotoUrl!.isNotEmpty
                          ? Image.network(
                              _profilePhotoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  SvgPicture.asset('assets/icons/person_1.svg',
                                      fit: BoxFit.cover),
                            )
                          : SvgPicture.asset('assets/icons/person_1.svg',
                              fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📍 Location:',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 10),
                        _buildBarangayDropdown(context),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            ClipRect(
                              child: SizedBox(
                                height: 200,
                                child: Stack(
                                  children: [
                                    Listener(
                                      onPointerDown: (_) =>
                                          _disableMapScrolling(),
                                      onPointerUp: (_) => _enableMapScrolling(),
                                      child: AbsorbPointer(
                                        absorbing: false,
                                        child: GoogleMap(
                                          polygons: _barangayPolygons,
                                          onMapCreated: (controller) {
                                            mapController = controller;
                                          },
                                          initialCameraPosition: CameraPosition(
                                            target: selectedCoordinates ??
                                                const LatLng(14.6700, 121.0437),
                                            zoom: 11.8,
                                          ),
                                          onTap: (LatLng pos) async {
                                            if (!_isPointInsideBarangay(pos)) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Outside Quezon City'),
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  duration:
                                                      Duration(seconds: 2),
                                                ),
                                              );
                                              return;
                                            }

                                            if (_showMapTutorial) {
                                              print(
                                                  'Starting fade animation'); // Debug print
                                              await _fadeController.forward();
                                              print(
                                                  'Fade animation completed'); // Debug print
                                              if (mounted) {
                                                setState(() {
                                                  _showMapTutorial = false;
                                                });
                                              }
                                            }

                                            setState(() {
                                              selectedCoordinates = pos;
                                            });

                                            try {
                                              List<Placemark> placemarks =
                                                  await placemarkFromCoordinates(
                                                      pos.latitude,
                                                      pos.longitude);

                                              if (placemarks.isNotEmpty) {
                                                final place = placemarks.first;
                                                setState(() {
                                                  selectedAddress =
                                                      '${place.name}, ${place.subLocality}, ${place.locality}';
                                                  selectedBarangay =
                                                      place.subLocality;
                                                  selectedDistrict =
                                                      guessDistrictFromBarangay(
                                                          place.subLocality);
                                                });
                                              } else {
                                                // If no placemarks found, try to find the nearest barangay
                                                String? nearestBarangay =
                                                    _findNearestBarangay(pos);
                                                if (nearestBarangay != null) {
                                                  setState(() {
                                                    selectedBarangay =
                                                        nearestBarangay;
                                                    selectedDistrict =
                                                        guessDistrictFromBarangay(
                                                            nearestBarangay);
                                                    selectedAddress =
                                                        'Near $nearestBarangay';
                                                  });
                                                } else {
                                                  setState(() {
                                                    selectedAddress =
                                                        'Selected Location';
                                                    selectedBarangay = null;
                                                    selectedDistrict = null;
                                                  });
                                                }
                                              }
                                            } catch (e) {
                                              print(
                                                  "Reverse geocoding error: $e");
                                              // Try to find the nearest barangay as fallback
                                              String? nearestBarangay =
                                                  _findNearestBarangay(pos);
                                              if (nearestBarangay != null) {
                                                setState(() {
                                                  selectedBarangay =
                                                      nearestBarangay;
                                                  selectedDistrict =
                                                      guessDistrictFromBarangay(
                                                          nearestBarangay);
                                                  selectedAddress =
                                                      'Near $nearestBarangay';
                                                });
                                              } else {
                                                setState(() {
                                                  selectedAddress =
                                                      'Selected Location';
                                                  selectedBarangay = null;
                                                  selectedDistrict = null;
                                                });
                                              }
                                            }
                                          },
                                          markers: selectedCoordinates != null
                                              ? {
                                                  Marker(
                                                    markerId: const MarkerId(
                                                        'selected'),
                                                    position:
                                                        selectedCoordinates!,
                                                  )
                                                }
                                              : {},
                                          zoomGesturesEnabled: true,
                                          scrollGesturesEnabled: true,
                                          rotateGesturesEnabled: true,
                                          tiltGesturesEnabled: true,
                                          myLocationEnabled: true,
                                          myLocationButtonEnabled: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Tutorial overlay
                            if (_showMapTutorial && selectedCoordinates == null)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    alignment: Alignment.bottomCenter,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        AnimatedBuilder(
                                          animation: _pulseAnimation,
                                          builder: (context, child) {
                                            return Opacity(
                                              opacity: _fadeAnimation.value,
                                              child: Transform.scale(
                                                scale: _pulseAnimation.value,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.95),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black12,
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.touch_app,
                                                        size: 16,
                                                        color: theme.colorScheme
                                                            .primary,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'Tap the map to select your location',
                                                        style: theme
                                                            .textTheme.bodySmall
                                                            ?.copyWith(
                                                          color: theme
                                                              .colorScheme
                                                              .primary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        IgnorePointer(
                          child: CustomTextField(
                            hintText: 'Selected Location',
                            isRequired: false,
                            suffixIcon: const Icon(Icons.location_on_outlined),
                            controller: TextEditingController(
                                text: selectedAddress ?? ''),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('🕒 Date & Time:',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                hintText: 'Date',
                                isRequired: true,
                                controller: dateController,
                                isDate: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomTextField(
                                hintText: 'Time',
                                isRequired: false,
                                controller: timeController,
                                isTime: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                final now = DateTime.now();
                                dateController.text =
                                    DateFormat('MM-dd-yyyy').format(now);
                                timeController.text =
                                    DateFormat('h:mm a').format(now);
                              },
                              icon: Icon(Icons.access_time,
                                  color: theme.colorScheme.primary),
                              tooltip: 'Use current date and time',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('⚠ Report Type:',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(color: theme.colorScheme.primary)),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: CustomTextField(
                                hintText: 'Choose a Report Type',
                                isRequired: true,
                                suffixIcon:
                                    const Icon(Icons.arrow_drop_down, size: 20),
                                choices: reportTypes,
                                onChanged: (value) {
                                  setState(() {
                                    selectedReportType = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.info_outline,
                                  color: Colors.blueGrey),
                              tooltip: 'Report Type Info',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Report Type Meanings'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => Dialog(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    child: InteractiveViewer(
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                        child: Image.asset(
                                                          'assets/images/BreedingPots.jpg',
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.asset(
                                                  'assets/images/BreedingPots.jpg',
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Expanded(
                                              child: Text(
                                                'Breeding Site: A place where mosquitoes lay eggs (e.g., containers, tires, pots).',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => Dialog(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    child: InteractiveViewer(
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                        child: Image.asset(
                                                          'assets/images/standingwater.jpg',
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.asset(
                                                  'assets/images/standingwater.jpg',
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Expanded(
                                              child: Text(
                                                'Standing Water: Any stagnant water that can become a mosquito habitat.',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => Dialog(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    child: InteractiveViewer(
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                        child: Image.asset(
                                                          'assets/images/infestation.jpg',
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.asset(
                                                  'assets/images/infestation.jpg',
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Expanded(
                                              child: Text(
                                                'Infestation: An area with a high number of mosquitoes or larvae.',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                  color: customColors?.surfaceLight, thickness: 1, height: 56),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📝 Description:', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText:
                          'What did you see? Is there anything you\'d like to share?',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text('🖼 Attached Images:', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedImages
                      .map((image) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  image,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImages.remove(image);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.close,
                                        size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 5,
            right: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromRGBO(248, 169, 0, 1),
                    theme.colorScheme.secondary,
                  ],
                  stops: const [0.0, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SizedBox(
                height: 30,
                width: 130,
                child: FloatingActionButton.extended(
                  heroTag: 'report_submit_button',
                  onPressed: _isLoading ? null : _submitPost,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  label: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Report',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            left: 38,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _selectedImages.length >= 3 ? null : _pickImage,
                icon: SvgPicture.asset(
                  'assets/icons/image.svg',
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    _selectedImages.length >= 3
                        ? theme.colorScheme.primary.withOpacity(0.5)
                        : theme.colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _findNearestBarangay(LatLng point) {
    if (barangayCenters.isEmpty) return null;

    String? nearestBarangay;
    double minDistance = double.infinity;

    barangayCenters.forEach((barangay, center) {
      double distance = _calculateDistance(point, center);
      if (distance < minDistance) {
        minDistance = distance;
        nearestBarangay = barangay;
      }
    });

    // Only return the nearest barangay if it's within a reasonable distance (e.g., 1km)
    return minDistance <= 1.0 ? nearestBarangay : null;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double lat1 = point1.latitude * (pi / 180);
    double lat2 = point2.latitude * (pi / 180);
    double lon1 = point1.longitude * (pi / 180);
    double lon2 = point2.longitude * (pi / 180);

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2.0 * atan2(sqrt(a), sqrt(1 - a)).toDouble();
    double distance = earthRadius * c;

    return distance;
  }

  bool _isPointInsideBarangay(LatLng point) {
    for (final polygon in _barangayPolygons) {
      if (polygon.polygonId.value == 'outside-quezon-city') continue;
      if (_isPointInPolygon(point, polygon.points)) {
        // When we find a match, update the selected barangay
        setState(() {
          selectedBarangay = polygon.polygonId.value;
          selectedDistrict = guessDistrictFromBarangay(selectedBarangay);
        });
        return true;
      }
    }
    return false;
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.isEmpty) return false;

    bool isInside = false;
    int j = polygon.length - 1;
    double epsilon = 0.000001; // Small value for floating point comparison

    for (int i = 0; i < polygon.length; i++) {
      // Check if point is on the boundary
      if ((point.latitude == polygon[i].latitude &&
              point.longitude == polygon[i].longitude) ||
          (point.latitude == polygon[j].latitude &&
              point.longitude == polygon[j].longitude)) {
        return true;
      }

      // Check if point is on a horizontal boundary
      if ((polygon[i].latitude == polygon[j].latitude) &&
          (point.latitude == polygon[i].latitude) &&
          (point.longitude > min(polygon[i].longitude, polygon[j].longitude)) &&
          (point.longitude < max(polygon[i].longitude, polygon[j].longitude))) {
        return true;
      }

      if ((polygon[i].latitude > point.latitude) !=
          (polygon[j].latitude > point.latitude)) {
        double intersect = (polygon[j].longitude - polygon[i].longitude) *
                (point.latitude - polygon[i].latitude) /
                (polygon[j].latitude - polygon[i].latitude) +
            polygon[i].longitude;

        if (point.longitude < intersect) {
          isInside = !isInside;
        }
      }
      j = i;
    }

    return isInside;
  }

  String? _combineDateAndTime(String selectedDate, String selectedTime) {
    try {
      // Parse date
      DateTime parsedDate;
      if (selectedDate.startsWith('20')) {
        parsedDate = DateFormat('yyyy-MM-dd').parse(selectedDate);
      } else {
        parsedDate = DateFormat('MM-dd-yyyy').parse(selectedDate);
      }

      // Clean and split time
      final parts = selectedTime.trim().split(RegExp(r'\s+'));
      if (parts.length != 2) throw FormatException("Invalid time format");

      final timePart = parts[0]; // e.g., "5:39"
      final amPm = parts[1].toUpperCase(); // "PM" or "AM"

      final hourMinute = timePart.split(":");
      if (hourMinute.length != 2) throw FormatException("Invalid hour:minute");

      int hour = int.parse(hourMinute[0]);
      int minute = int.parse(hourMinute[1]);

      if (amPm == "PM" && hour != 12) hour += 12;
      if (amPm == "AM" && hour == 12) hour = 0;

      final combined = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        hour,
        minute,
      );

      return combined.toUtc().toIso8601String();
    } catch (e) {
      print("❌ Date/time combination error: $e");
      return null;
    }
  }
}
