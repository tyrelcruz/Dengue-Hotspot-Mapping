import 'package:buzzmap/main.dart';
import 'package:flutter/material.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';

class IdMosquito extends StatelessWidget {
  const IdMosquito({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mosquito Identification',
        currentRoute: '/tips',
        themeMode: 'dark',
        bannerTitle: 'Mosquito Identification',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 15),
            Image.network(
              'https://1000logos.net/wp-content/uploads/2023/02/Queensland-Government-logo.png',
              width: double.infinity,
              height: 50,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 27.0),
              child: Text(
                'How to Identify Common Mosquito Species',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Text(
              'Last updated: 17 August 2023',
              style: TextStyle(
                fontSize: 11,
                color: primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 15),
            // ✅ Shadowed dengue image
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.asset(
                  'assets/images/dengue_banner.png',
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 25),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    Text(
                        'Identifying mosquito species is important for understanding disease risks. Here are key features to look for when identifying common mosquito species:\n',
                        style: TextStyle(fontSize: 12, color: primaryColor)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(TextSpan(
                                text: '• Aedes aegypti ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                      text:
                                          '(Yellow Fever Mosquito): Black with white lyre-shaped markings on the thorax and white bands on legs.',
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal))
                                ])),
                            Text.rich(TextSpan(
                                text: '• Aedes albopictus ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                      text:
                                          '(Asian Tiger Mosquito): Black with a single white stripe down the middle of the thorax and legs with white bands.',
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal))
                                ])),
                            Text.rich(TextSpan(
                                text: '• Culex species ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                      text:
                                          '(House Mosquitoes): Brown with unmarked thorax and abdomen, often found resting at a 45-degree angle to surfaces.',
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal))
                                ])),
                            Text.rich(TextSpan(
                                text: '• Anopheles species ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                      text:
                                          '(Malaria Mosquitoes): Pale and dark markings on wings, and rest with their bodies at an angle to the surface.',
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal))
                                ])),
                          ]),
                    ),
                  ],
                )),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.topLeft,
              child: Text('Key Identification Features',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                  )),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 50, right: 75),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Feature',
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                            )),
                        SizedBox(
                          width: 10,
                        ),
                        Text('What to Look For',
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child: Image.asset(
                              'assets/images/DGThorax.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(
                              width: 200,
                              child: Text(
                                'Thorax markings: Look for distinctive patterns on the upper body (thorax) of the mosquito.',
                                softWrap: true,
                                textAlign: TextAlign.justify,
                                style: TextStyle(fontSize: 12),
                              ))
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child: Image.asset(
                              'assets/images/DGPattern.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(
                              width: 200,
                              child: Text(
                                'Leg bands: Check for white or light-colored bands on the legs.',
                                softWrap: true,
                                textAlign: TextAlign.justify,
                                style: TextStyle(fontSize: 12),
                              ))
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child: Image.asset(
                              'assets/images/DGPosture.jpg',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(
                              width: 200,
                              child: Text(
                                'Resting position: Observe how the mosquito rests - some species rest at angles while others stay parallel.',
                                softWrap: true,
                                textAlign: TextAlign.justify,
                                style: TextStyle(fontSize: 12),
                              ))
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Note: If you find mosquitoes with these characteristics, especially Aedes species, report them to your local health authority as they may carry diseases like dengue, Zika, or chikungunya.',
                textAlign: TextAlign.justify,
                style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                    fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
