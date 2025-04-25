import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'package:buzzmap/main.dart';
import 'package:buzzmap/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class PostScreen extends StatefulWidget {
  const PostScreen({super.key});

  @override
  State<PostScreen> createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final List<String> reportTypes = [
    'Breeding Site',
    'Suspected Case',
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

  bool _isPointInsideBarangay(LatLng point) {
    for (final polygon in _barangayPolygons) {
      if (polygon.polygonId.value == 'outside-quezon-city') continue;

      if (_isPointInPolygon(point, polygon.points)) {
        return true;
      }
    }
    return false;
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
    print('GeoJSON loaded: ${data.length} characters');

    final geojson = json.decode(data);
    Map<String, LatLng> centers = {};
    for (var feature in geojson['features']) {
      final name =
          feature['properties']['barangay'] ?? feature['properties']['name'];
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
      }
    }
    return centers;
  }

  String? guessDistrictFromBarangay(String? barangay) {
    if (barangay == null) return null;
    for (var entry in districtBarangays.entries) {
      if (entry.value.contains(barangay)) {
        return entry.key;
      }
    }
    return null;
  }

  final Map<String, List<String>> districtBarangays = {
    '1st District': [
      'Bagong Pag-asa',
      'Bahay Toro',
      'Alicia',
      'Bungad',
      'Project 6',
      'Vasra',
      'Phil-Am',
      'San Antonio',
      'Sto. Cristo',
      'Ramon Magsaysay'
    ],
    '2nd District': [
      'Bagong Silangan',
      'Batasan Hills',
      'Commonwealth',
      'Holy Spirit',
      'Payatas'
    ],
    '3rd District': [
      'Amihan',
      'Bagumbuhay',
      'Bayanihan',
      'Blue Ridge A',
      'Blue Ridge B',
      'Duyan-Duyan',
      'E. Rodriguez',
      'East Kamias',
      'Escopa I',
      'Escopa II',
      'Escopa III',
      'Escopa IV',
      'Libis',
      'Loyola Heights',
      'Mangga',
      'Marilag',
      'Masagana',
      'Matandang Balara',
      'Pansol',
      'Quirino 2-A',
      'Quirino 2-B',
      'Quirino 2-C',
      'Quirino 3-A',
      'San Roque',
      'Silangan',
      'St. Ignatius',
      'Tagumpay',
      'Villa Maria Clara',
      'West Kamias',
      'White Plains'
    ],
    '4th District': [
      'Bagumbayan',
      'Bagong Lipunan Crame',
      'Camp Aguinaldo',
      'Claro',
      'Damar',
      'Damayang Lagi',
      'Del Monte',
      'Don Manuel',
      'Dona Aurora',
      'Dona Imelda',
      'Dona Josefa',
      'Horseshoe',
      'Immaculate Concepcion',
      'Kalusugan',
      'Kaunlaran',
      'Kristong Hari',
      'Laging Handa',
      'Mariana',
      'N.S. Amoranto',
      'Obrero',
      'Paligsahan',
      'Pinagkaisahan',
      'Roxas',
      'Sacred Heart',
      'San Isidro Galas',
      'San Martin de Porres',
      'San Vicente',
      'Santol',
      'Santo Domingo',
      'Santo Nino',
      'Sikatuna Village',
      'South Triangle',
      'Tatalon',
      'Teachers Village East',
      'Teachers Village West',
      'Ugong Norte',
      'Valencia'
    ],
    '5th District': [
      'Bagbag',
      'Capri',
      'Fairview',
      'Greater Lagro',
      'Gulod',
      'Kaligayahan',
      'Nagkaisang Nayon',
      'North Fairview',
      'Novaliches Proper',
      'Pasong Putik Proper',
      'San Agustin',
      'San Bartolome',
      'Santa Monica',
      'Santa Lucia',
      'Sauyo'
    ],
    '6th District': [
      'Apolonio Samson',
      'Baesa',
      'Balon Bato',
      'Culiat',
      'New Era',
      'Pasong Tamo',
      'Sangandaan',
      'Tandang Sora',
      'Unang Sigaw'
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = Theme.of(context).extension<CustomColors>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('New Post',
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
                        CustomTextField(
                          hintText: 'Select Barangay',
                          isRequired: true,
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                          choices: barangayCenters.keys.toList(),
                          onChanged: (barangay) {
                            setState(() {
                              selectedBarangay = barangay;
                              selectedDistrict =
                                  guessDistrictFromBarangay(barangay);
                              selectedCoordinates = barangayCenters[barangay];
                            });

                            if (mapController != null &&
                                selectedCoordinates != null) {
                              mapController!.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                    selectedCoordinates!, 16),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        ClipRect(
                          child: SizedBox(
                            height: 200,
                            child: Listener(
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
                                          content: Text('Outside Quezon City'),
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
                                          selectedBarangay = place.subLocality;
                                          selectedDistrict =
                                              guessDistrictFromBarangay(
                                                  place.subLocality);
                                        });
                                      }
                                    } catch (e) {
                                      print("Reverse geocoding error: $e");
                                      setState(() {
                                        selectedAddress = null;
                                        selectedBarangay = null;
                                        selectedDistrict = null;
                                      });
                                    }

                                    try {
                                      List<Placemark> placemarks =
                                          await placemarkFromCoordinates(
                                        pos.latitude,
                                        pos.longitude,
                                      );

                                      if (placemarks.isNotEmpty) {
                                        final place = placemarks.first;
                                        setState(() {
                                          selectedAddress =
                                              '${place.name}, ${place.subLocality}, ${place.locality}';
                                          selectedBarangay = place.subLocality;
                                          selectedDistrict =
                                              guessDistrictFromBarangay(
                                                  place.subLocality);
                                        });
                                      }
                                    } catch (e) {
                                      print("Reverse geocoding error: $e");
                                      setState(() {
                                        selectedAddress = null;
                                        selectedBarangay = null;
                                        selectedDistrict = null;
                                      });
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
                                ),
                              ),
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
                        CustomTextField(
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
                    maxLines: 15,
                    keyboardType: TextInputType.multiline,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText:
                          'What did you see? Is there anything you’d like to share?',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5)),
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
                  onPressed: () {},
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  label: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'Share',
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
}
