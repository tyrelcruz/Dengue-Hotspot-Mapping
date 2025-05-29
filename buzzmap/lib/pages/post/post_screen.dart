import 'dart:io';
import 'dart:math';
import 'package:image_picker/image_picker.dart';

import 'package:buzzmap/main.dart';
import 'package:buzzmap/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

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

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final List<String> reportTypes = [
    'Breeding Site',
    'Standing Water',
    'Infestation'
  ];

  Set<Polygon> _barangayPolygons = {};

  List<File> _selectedImages = [];

  final ImagePicker _picker = ImagePicker();

  LatLng? selectedCoordinates;
  String? selectedAddress;
  String? selectedReportType;
  String? selectedBarangay;
  String? selectedDistrict;
  GoogleMapController? mapController;
  Map<String, LatLng> barangayCenters = {};

  bool _mapScrollable = true;

  Map<String, List<String>> districtData = {};

  bool _isLoadingLocation = false;

  bool _isLoading = false;

  bool _isPointInsideBarangay(LatLng point) {
    for (final polygon in _barangayPolygons) {
      if (polygon.polygonId.value == 'outside-quezon-city') continue;

      if (_isPointInPolygon(point, polygon.points)) {
        return true;
      }
    }
    return false;
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

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;

    for (int j = 0; j < polygon.length - 1; j++) {
      LatLng p1 = polygon[j];
      LatLng p2 = polygon[j + 1];

      if ((p1.longitude > point.longitude) !=
          (p2.longitude > point.longitude)) {
        double atX = (p2.latitude - p1.latitude) *
                (point.longitude - p1.longitude) /
                (p2.longitude - p1.longitude) +
            p1.latitude;
        if (point.latitude < atX) {
          intersectCount++;
        }
      }
    }

    return (intersectCount % 2) == 1;
  }

  void dispose() {
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

  @override
  void initState() {
    super.initState();
    loadBarangayCentersFromGeoJson().then((data) {
      _addQuezonCityMask();
      setState(() {
        barangayCenters = data;
      });
    });

    _loadGeoJsonPolygons();
  }

  Future<void> _submitPost() async {
    if (selectedCoordinates == null ||
        selectedBarangay == null ||
        selectedReportType == null ||
        dateController.text.isEmpty ||
        timeController.text.isEmpty) {
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

    final url = Uri.parse(Config.createPostUrl);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    try {
      final formattedDateTime =
          _combineDateAndTime(dateController.text, timeController.text);

      if (formattedDateTime == null) {
        await AppFlushBar.showError(
          context,
          title: 'Invalid Date/Time',
          message: 'Please check your date and time format.',
        );
        return;
      }

      Map<String, dynamic> specificLocation = {
        "type": "Point",
        "coordinates": [
          selectedCoordinates!.longitude,
          selectedCoordinates!.latitude,
        ]
      };

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      request.fields.addAll({
        'barangay': selectedBarangay!,
        'report_type': selectedReportType!,
        'description': descriptionController.text,
        'date_and_time': formattedDateTime,
        'specific_location[type]': specificLocation["type"],
        'specific_location[coordinates][0]':
            specificLocation["coordinates"][0].toString(),
        'specific_location[coordinates][1]':
            specificLocation["coordinates"][1].toString(),
      });

      // Process images in parallel if there are multiple
      if (_selectedImages.isNotEmpty) {
        final imageFutures = _selectedImages.map((image) async {
          final bytes = await image.readAsBytes();
          final filename = image.path.split('/').last;
          return http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: filename,
          );
        });

        final imageFiles = await Future.wait(imageFutures);
        request.files.addAll(imageFiles);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Show the empathetic feedback notification on success
        await NotificationService.showEmpatheticFeedback(context,
            "Thank you for reporting! We'll review your submission and notify you once verified.");

        final responseData = jsonDecode(response.body);
        debugPrint(
            '✅ Report submitted successfully: ${responseData['report']}');

        // Navigate to the community screen (replace current screen)
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CommunityScreen()),
          );
        }
      } else {
        throw Exception(
            'Failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error submitting post: $e');
      if (mounted) {
        await AppFlushBar.showError(
          context,
          title: 'Submission Failed',
          message: 'Unable to submit your report. Please try again.',
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
            strokeColor: Colors.black,
            strokeWidth: 1,
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
    if (_selectedImages.length >= 4) return;

    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<Map<String, LatLng>> loadBarangayCentersFromGeoJson() async {
    final String data =
        await rootBundle.loadString('assets/geojson/barangays.geojson');
    final geojson = json.decode(data);
    Map<String, LatLng> centers = {};
    Set<String> barangayNames = {};

    for (var feature in geojson['features']) {
      final name = feature['properties']['name'];
      if (name == null) continue;

      final geometry = feature['geometry'];
      if (geometry != null && geometry['type'] == 'Polygon') {
        final coords = geometry['coordinates'][0];
        double latSum = 0;
        double lngSum = 0;
        for (var point in coords) {
          lngSum += point[0];
          latSum += point[1];
        }
        final count = coords.length;
        centers[name] = LatLng(latSum / count, lngSum / count);
        barangayNames.add(name);
      }
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
    final allBarangays = districtData.values.expand((list) => list).toList()
      ..sort();

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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('New Report',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (_) => !_mapScrollable,
        child: SingleChildScrollView(
          physics: _mapScrollable
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 27.0, 16.0),
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
                        shape: BoxShape.circle, color: Colors.grey.shade200),
                    child: ClipOval(
                      child: SvgPicture.asset('assets/icons/person_4.svg'),
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
                        ClipRect(
                          child: SizedBox(
                            height: 200,
                            child: Stack(
                              children: [
                                Listener(
                                  onPointerDown: (_) => _disableMapScrolling(),
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
                                              content:
                                                  Text('Outside Quezon City'),
                                              backgroundColor: Colors.redAccent,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                          return;
                                        }

                                        setState(() {
                                          selectedCoordinates = pos;
                                        });

                                        try {
                                          List<Placemark> placemarks =
                                              await placemarkFromCoordinates(
                                                  pos.latitude, pos.longitude);

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
                                          print("Reverse geocoding error: $e");
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
                                                markerId:
                                                    const MarkerId('selected'),
                                                position: selectedCoordinates!,
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
                  onPressed: _submitPost,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  label: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
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
            bottom: -2,
            left: 35,
            child: IconButton(
              onPressed: _selectedImages.length >= 4 ? null : _pickImage,
              icon: SvgPicture.asset(
                'assets/icons/image.svg',
                width: 26,
                height: 26,
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
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
}
