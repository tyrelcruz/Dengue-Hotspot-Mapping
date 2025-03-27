import 'package:buzzmap/main.dart';
import 'package:buzzmap/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  String? selectedReportType;
  String? selectedDistrict;
  String? selectedBarangay;

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
        title: Text(
          'New Post',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              hintText: 'Select District',
                              isRequired: true,
                              suffixIcon:
                                  const Icon(Icons.arrow_drop_down, size: 20),
                              choices: districtBarangays.keys.toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedDistrict = value;
                                  selectedBarangay = null; // Reset barangay
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              hintText: 'Select Barangay',
                              isRequired: true,
                              suffixIcon:
                                  const Icon(Icons.arrow_drop_down, size: 20),
                              choices: selectedDistrict != null
                                  ? districtBarangays[selectedDistrict]!
                                  : [],
                              onChanged: (value) {
                                setState(() {
                                  selectedBarangay = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        hintText: 'Specific Location or Landmark',
                        isRequired: false,
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
                        suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
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
              color: customColors?.surfaceLight,
              thickness: 1,
              height: 56,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📝 Description:',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8), // Adds some spacing
                TextFormField(
                  maxLines: 15, // Adjust the number of visible lines
                  keyboardType: TextInputType.multiline,
                  style: theme.textTheme
                      .bodyMedium, // Ensures text matches bodyMedium size
                  decoration: InputDecoration(
                    hintText:
                        'What did you see? Is there anything you’d like to share?',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withOpacity(0.5), // Slightly faded hint text
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            )
          ],
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PostScreen(),
                  ),
                );
              },
              icon: SvgPicture.asset(
                'assets/icons/image.svg',
                width: 26,
                height: 26,
                colorFilter: ColorFilter.mode(
                  theme.colorScheme.primary, // Use primary color
                  BlendMode.srcIn,
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(), // Removes any extra padding
            ),
          ),
        ],
      ),
    );
  }
}
