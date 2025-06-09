import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buzzmap/pages/menu_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background images
          Positioned.fill(
            child: Stack(
              // Horizontal, Vertical, Width, Height
              children: [
                _buildBackgroundImage(
                    context, 'assets/bgarts/Line3.svg', 0.003, 0.006, 300, 300),
                _buildBackgroundImage(
                    context, 'assets/bgarts/Line1.svg', 0.90, 0.072, 200, 200),
                _buildBackgroundImage(context, 'assets/bgarts/RunMan.svg',
                    0.00001, 0.273, 200, 200),
                _buildBackgroundImage(context, 'assets/bgarts/Gentleman.svg',
                    0.61, 0.23, 250, 250),
                _buildBackgroundImage(
                    context, 'assets/bgarts/AntiD.svg', 0.72, 0.72, 250, 250),
                _buildBackgroundImage(
                    context, 'assets/bgarts/Line1.svg', 0.0003, 0.5, 200, 200),
                _buildBackgroundImage(
                    context, 'assets/bgarts/Line2.svg', 0.65, 0.52, 200, 200),
                _buildBackgroundImage(context, 'assets/bgarts/ManHand.svg',
                    0.0003, 0.7, 250, 250),
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.fromLTRB(23.0, 23.0, 23.0, 7.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF2D5D68),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, size: 23),
                            color: Colors.white,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.menu,
                                size: 28,
                                color: Theme.of(context).colorScheme.primary),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        MenuScreen(currentRoute: '/about')),
                              );
                            },
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Transform.translate(
                        offset: const Offset(1, 10),
                        child: SvgPicture.asset(
                          'assets/icons/logo_ligthbg.svg',
                          width: 60,
                          height: 60,
                        ),
                      ),
                      const SizedBox(width: 1),
                      Padding(
                        padding: const EdgeInsets.only(right: 40.0),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'Koulen',
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                            children: [
                              TextSpan(
                                text: 'ABOUT ',
                                style: TextStyle(
                                  fontSize: 40,
                                  letterSpacing: 1.2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              TextSpan(
                                text: '\nBUZZ',
                                style: TextStyle(
                                  fontSize: 60,
                                  letterSpacing: 1.2,
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              TextSpan(
                                text: 'MAP',
                                style: TextStyle(
                                  fontSize: 60,
                                  letterSpacing: 1.2,
                                  fontStyle: FontStyle.italic,
                                  color: Color.fromRGBO(96, 147, 175, 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 1.36,
                      ),
                      children: [
                        const TextSpan(
                          text: 'BuzzMap ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(
                          text:
                              'is proud to partner with the Quezon City \n Epidemiology & Surveillance Division, specifically Quezon City Environmental and Sanitation Unit ',
                        ),
                        const TextSpan(
                          text: '(QC CESD)',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(
                          text:
                              ' in the fight \n against dengue outbreaks. Together, we aim to empower the community with weekly updated data , alerts, and prevention tips, \n creating a united effort to reduce the spread of dengue and \n protect public health across Quezon City.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'MISSION',
                    style: TextStyle(
                      fontSize: 40,
                      fontFamily: 'Koulen',
                      color: Color.fromRGBO(96, 147, 175, 1),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 1),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.36,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(
                          text:
                              'BuzzMap is dedicated to empowering communities through \n dengue tracking, crowdsourced reports, and \n data-driven insights.',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' By partnering with local health\n agencies like QC CESU, we strive to enhance public\n awareness, promote proactive dengue prevention, and\n support rapid response efforts to reduce outbreaks and \nprotect lives.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  const Text(
                    'VISION',
                    style: TextStyle(
                      fontSize: 40,
                      fontFamily: 'Koulen',
                      color: Color.fromRGBO(96, 147, 175, 1),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'To be the leading community-driven dengue prevention\n platform, harnessing technology and collective action to \ncreate a safer, healthier, and dengue-free future for all.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ABOUT QCESD',
                    style: TextStyle(
                      fontSize: 40,
                      fontFamily: 'Koulen',
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromRGBO(36, 82, 97, 1),
                          Color.fromRGBO(74, 168, 199, 1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: ClipOval(
                                child: SvgPicture.asset(
                                  'assets/icons/surveillance_logo.svg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quezon City Epidemiology & Surveillance Division',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Department of Health - Center for Health Development',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildInfoSection(
                          'Location',
                          'Quezon City Hall Compound, Diliman, Quezon City',
                          Icons.location_on,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoSection(
                          'Contact Numbers',
                          'Emergency: (02) 8928-4242\nOffice: (02) 8928-4242',
                          Icons.phone,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoSection(
                          'Email',
                          'qcesd@quezoncity.gov.ph',
                          Icons.email,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoSection(
                          'Operating Hours',
                          'Monday to Friday\n8:00 AM - 5:00 PM',
                          Icons.access_time,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'The Quezon City Epidemiology & Surveillance Division (QCESD) is dedicated to protecting public health through disease surveillance, outbreak investigation, and health promotion. We work tirelessly to prevent and control the spread of diseases, including dengue, through community education, vector control, and rapid response to health threats.',
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage(BuildContext context, String assetPath,
      double left, double top, double width, double height) {
    return Positioned(
      left: left * MediaQuery.of(context).size.width,
      top: top * MediaQuery.of(context).size.height,
      child: Opacity(
        opacity: 1,
        child: SvgPicture.asset(
          assetPath,
          width: width,
          height: height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
