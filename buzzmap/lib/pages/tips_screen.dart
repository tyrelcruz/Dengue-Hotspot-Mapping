import 'package:buzzmap/main.dart';
import 'package:flutter/material.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';

class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Prevention / Tips',
        currentRoute: '/tips',
        themeMode: 'dark',
        bannerTitle: 'Prevention/Tips',
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
                height: 20),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 27.0),
                child: Text(
                  'How Can I Eliminate Mosquito Breeding Grounds?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 22,
                      color: primaryColor,
                      fontWeight: FontWeight.w700),
                )),
            const Text(
              'Last updated: 26 February 2020',
              style: TextStyle(
                  fontSize: 11,
                  color: primaryColor,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                'https://www.wikihow.com/images/thumb/c/c0/Protect-Pets-from-Mosquitoes-Step-13.jpg/v4-460px-Protect-Pets-from-Mosquitoes-Step-13.jpg',
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 25),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    Text(
                        'Under the Public Health Act, you could be fined by your local council if you are breeding mosquitoes around your home.\n\nCheck the following ares around your home weekly for evidennce of mosquitoes or mosquito larvae and tip out, wipe out, throw out or dry store items that can hold water.',
                        style: TextStyle(fontSize: 12, color: primaryColor)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(TextSpan(
                                text: '• Tip out, and wipe out ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                      text:
                                          'any water from things like plastic containers, tarpaulins or buckets.',
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal))
                                ])),
                            Text.rich(TextSpan(
                                text: '• Store ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                      text:
                                          'anything that can hold water undercover or in a dry place, including work equipment, surplus materials or trailers, and keep bins covered.',
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal))
                                ])),
                            Text.rich(TextSpan(
                                text: '• Throw out ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                children: [
                                  TextSpan(
                                      text:
                                          'any rubbish lying around like unused or empty containers, tyres, additional materials and keep worksites tidy.',
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
              child: Text('Potential household mosquito breeding sites',
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
                    padding: EdgeInsets.only(left: 25, right: 75),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Breeding Site',
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                            )),
                        SizedBox(
                          width: 10,
                        ),
                        Text('Risk Mitigation',
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
                            child: Image.network(
                              'https://www.qld.gov.au/__data/assets/image/0015/3129/birdbath.jpg',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(
                              width: 200,
                              child: Text(
                                'Flush and wipe out bird baths regularly to prevent mosquitoes from breeding.',
                                softWrap: true,
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
                            child: Image.network(
                              'https://www.qld.gov.au/__data/assets/image/0017/3293/boat-thumb.jpg',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(
                              width: 200,
                              child: Text(
                                'Store under cover to prevent water collecting and mosquitoes from breeding in boats.',
                                softWrap: true,
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
                            child: Image.network(
                              'https://www.qld.gov.au/__data/assets/image/0019/3583/bromeliad-thumb.jpg',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(
                              width: 200,
                              child: Text(
                                'Reduce the number of Bromellad plants in your yard as they collect water and have the potential to breed mosquitoes.',
                                softWrap: true,
                                style: TextStyle(fontSize: 12),
                              ))
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
