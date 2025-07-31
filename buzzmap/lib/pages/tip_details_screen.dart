import 'package:flutter/material.dart';
import 'package:buzzmap/models/admin_post.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';
import 'package:buzzmap/main.dart';

class TipDetailsScreen extends StatelessWidget {
  final AdminPost tip;

  const TipDetailsScreen({
    super.key,
    required this.tip,
  });

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
            if (tip.id == '4s-against-dengue' ||
                tip.id == '5s-against-dengue') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  '5S KONTRA DENGUE',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 1S Card
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/1S.png',
                          width: 48, height: 48),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'S',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'earch and destroy\n',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Suyurin at alisin ang mga pinamumugaran ng mga lamok na pwedeng pangitlogan ng mga ito. Palaging linisin ang kapaligiran.',
                              style:
                                  TextStyle(fontSize: 14, color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 2S Card
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/2S.png',
                          width: 48, height: 48),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'S',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'elf Protection Measures\n',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Sarili ay protektahan laban sa mga lamok. Magsuot ng mahabang manggas; gumamit ng mosquito repellant.',
                              style:
                                  TextStyle(fontSize: 14, color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 3S Card
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/3S.png',
                          width: 48, height: 48),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'S',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'eek Early Consultation\n',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Sumangguni sa pinakamalapit na Health Center o Ospital lalo na kapag may sintomas ng Dengue.',
                              style:
                                  TextStyle(fontSize: 14, color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 4S Card
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/4S.png',
                          width: 48, height: 48),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'S',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'upport fogging/spraying to prevent further outbreaks\n',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Sumuporta sa spraying at fogging sa inyong komunidad kapag may banta ng outbreak.',
                              style:
                                  TextStyle(fontSize: 14, color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 5S Card
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/5S.png',
                          width: 48, height: 48),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'S',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'ustain Hydration\n',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Uminom ng hindi bababa sa dalawang (2) litro ng tubig kada araw, lalo na kung may lagnat.',
                              style:
                                  TextStyle(fontSize: 14, color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ] else if (tip.id == 'symptoms') ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.asset(
                  'assets/images/Symptomsbanner.png',
                  width: double.infinity,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 27.0),
                child: Text(
                  tip.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Symptoms grid
              _buildSymptomsGrid(),
              const SizedBox(height: 30),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 27.0),
                child: Text(
                  tip.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Last updated: ${tip.publishDate.toString().split(' ')[0]}',
                style: const TextStyle(
                  fontSize: 11,
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 15),
              if (tip.id == 'dengue-alert') ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Image.asset(
                    'assets/images/dengue_alert.png',
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (tip.id != 'dengue-alert' && tip.images.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: tip.images[0].startsWith('http')
                      ? Image.network(
                          tip.images[0],
                          width: 300,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 300,
                              height: 200,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            );
                          },
                        )
                      : Image.asset(
                          tip.images[0],
                          width: 300,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(height: 20),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tip.id == 'dengue-alert') ...[
                      const Text(
                        'Ano ang DENGUE?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ang DENGUE ay isang sakit o virus (genus flavivirus) mula sa kagat ng lamok (female mosquito) na Aedes aegypti. Ang lamok na ito ay karaniwang nakikita sa ating kapaligiran at ito ang klase na mas nangangagat sa mga tao sa araw imbes na sa gabi.',
                        textAlign: TextAlign.justify,
                        style: const TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Paano ito naipapasa?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ang DENGUE ay naipapasa mula sa kagat ng lamok; (Nangingitlog sa malinaw na tubig tulad ng makikita sa flower vases at naiipong tubig-ulan sa gulong o basyong lata. Ang lamok ay karaniwang naglalagi sa madidilim na lugar ng bahay)',
                        textAlign: TextAlign.justify,
                        style: const TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          height: 1.5,
                        ),
                      ),
                    ] else ...[
                      Text(
                        tip.content,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          height: 1.5,
                        ),
                      ),
                    ],
                    if (tip.references.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        tip.references,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: (tip.id == 'dengue-alert' ||
              tip.id == '4s-against-dengue' ||
              tip.id == 'symptoms')
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 19, horizontal: 10),
              decoration: BoxDecoration(
                color: Color(0xFF245261),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'FOLLOW US: ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Icon(Icons.facebook, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '@QCEpidemiologyDiseaseSurveillance/',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildSymptomsGrid() {
    // List of symptoms and their labels
    final symptoms = [
      {'icon': Icons.bloodtype, 'label': 'Pagdurugo ng ilong'},
      {'icon': Icons.thermostat, 'label': 'Pagkakaroon ng mataas na lagnat'},
      {'icon': Icons.sick, 'label': 'Pananakit ng tiyan at pagsusuka'},
      {
        'icon': Icons.blur_circular,
        'label': 'Pagkakaroon ng pantal-pantal o rashes sa balat'
      },
      {'icon': Icons.bolt, 'label': 'Matinding pananakit ng ulo'},
      {'icon': Icons.accessibility_new, 'label': 'Pananakit ng katawan'},
      {'icon': Icons.remove_red_eye, 'label': 'Pananakit ng mata'},
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _symptomIcon(symptoms[0]),
            _symptomIcon(symptoms[1]),
            _symptomIcon(symptoms[2]),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _symptomIcon(symptoms[3]),
            _symptomIcon(symptoms[4]),
            _symptomIcon(symptoms[5]),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _symptomIcon(symptoms[6]),
          ],
        ),
      ],
    );
  }

  Widget _symptomIcon(Map<String, dynamic> symptom) {
    return SizedBox(
      width: 90,
      child: Column(
        children: [
          Icon(
            symptom['icon'],
            size: 48,
            color: primaryColor,
          ),
          const SizedBox(height: 8),
          Text(
            symptom['label'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: primaryColor),
          ),
        ],
      ),
    );
  }
}
