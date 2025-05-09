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
                _buildBackgroundImage(
                    context, 'assets/bgarts/RunMan.svg', 0.00001, 0.273, 200, 200),
                _buildBackgroundImage(
                    context, 'assets/bgarts/Gentleman.svg', 0.61, 0.23, 250, 250),
                _buildBackgroundImage(
                    context, 'assets/bgarts/AntiD.svg', 0.72, 0.72, 250, 250),
                _buildBackgroundImage(
                    context, 'assets/bgarts/Line1.svg', 0.0003, 0.5, 200, 200),
                _buildBackgroundImage(
                    context, 'assets/bgarts/Line2.svg', 0.65, 0.52, 200, 200),
                _buildBackgroundImage(
                    context, 'assets/bgarts/ManHand.svg', 0.0003, 0.7, 250, 250),
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.fromLTRB(23.0, 23.0, 23.0, 7.0),
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
                            ' in the fight \n against dengue outbreaks. Together, we aim to empower the community with real-time data, alerts, and prevention tips, \n creating a united effort to reduce the spread of dengue and \n protect public health across Quezon City.',
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
                            'BuzzMap is dedicated to empowering communities through \n real-time dengue tracking, crowdsourced reports, and \n data-driven insights.',
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
                  'MEET THE TEAM',
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                              child: _buildTeamMember(
                                  'assets/team/Zophia.svg',
                                  'Zophia Rey',
                                  'Project Manager')),
                          const SizedBox(width: 5),
                          Expanded(
                              child: _buildTeamMember(
                                  'assets/team/Neo.svg',
                                  'Neo David',
                                  'Programmer')),
                          const SizedBox(width: 5),
                          Expanded(
                              child: _buildTeamMember(
                                  'assets/team/Tyrel.svg',
                                  'Tyrel Cruz',
                                  'Systems Analyst')),
                          const SizedBox(width: 5),
                          Expanded(
                              child: _buildTeamMember(
                                  'assets/team/Rapi.svg',
                                  'Russel Rapi',
                                  'Technical Writer')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Community-Powered, Data-Driven, Dengue-Free!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage(
      BuildContext context, String assetPath, double left, double top, double width, double height) {
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

  Widget _buildTeamMember(String svgPath, String name, String role) {
    return Flexible(
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: SvgPicture.asset(
                svgPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            role,
            style: const TextStyle(
              fontSize: 7,
              color: Colors.white70,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
