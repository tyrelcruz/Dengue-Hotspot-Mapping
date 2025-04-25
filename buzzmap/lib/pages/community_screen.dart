import 'package:buzzmap/data/community_data.dart';
import 'package:buzzmap/main.dart';
import 'package:buzzmap/pages/post/post_screen.dart';
import 'package:buzzmap/widgets/announcement_card.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';
import 'package:buzzmap/widgets/custom_search_bar.dart';
import 'package:buzzmap/widgets/custom_tab_bar.dart';
import 'package:buzzmap/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int selectedIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  List<Map<String, dynamic>> get _currentPosts {
    switch (selectedIndex) {
      case 0:
        return CommunityData.popularPosts;
      case 1:
        return CommunityData.latestPosts;
      case 2:
        return CommunityData.myPosts;
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Community',
        currentRoute: '/community',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CustomSearchBar(),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomTabBar(
                    label: 'Popular',
                    isSelected: selectedIndex == 0,
                    onTap: () => _onTabSelected(0),
                  ),
                  CustomTabBar(
                    label: 'Latest',
                    isSelected: selectedIndex == 1,
                    onTap: () => _onTabSelected(1),
                  ),
                  CustomTabBar(
                    label: 'My Posts',
                    isSelected: selectedIndex == 2,
                    onTap: () => _onTabSelected(2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (selectedIndex == 0 || selectedIndex == 1) ...[
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'stay '.toUpperCase(),
                      style: theme.textTheme.displayLarge
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                    TextSpan(
                      text: 'ahead '.toUpperCase(),
                      style: theme.textTheme.displayLarge
                          ?.copyWith(color: customColors?.surfaceDark),
                    ),
                    TextSpan(
                      text: 'of dengue'.toUpperCase(),
                      style: theme.textTheme.displayLarge
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Real-Time Dengue Updates from the Community.',
                style: theme.textTheme.titleSmall?.copyWith(),
              ),
              const SizedBox(height: 18),
              const AnnouncementCard(),
            ],

            // Display posts based on the selected tab
            ..._currentPosts.map((post) => PostCard(
                  username: post['username'],
                  whenPosted: post['whenPosted'],
                  location: post['location'],
                  date: post['date'],
                  time: post['time'],
                  reportType: post['reportType'],
                  description: post['description'],
                  numUpvotes: post['numUpvotes'] ?? 0,
                  numDownvotes: post['numDownvotes'] ?? 0,
                  numComments: post['numComments'] ?? 0,
                  numShares: post['numShares'] ?? 0,
                  images:
                      List<String>.from(post['images']), // Ensure List<String>
                  iconUrl: post['iconUrl'], // Pass iconUrl
                )),
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
                height: 40,
                width: 160,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pushNamed(context, '/prevention');
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  label: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Prevention Tips',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SvgPicture.asset(
                          'assets/icons/right_arrow.svg',
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            theme.colorScheme.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 55,
            right: 3,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromRGBO(248, 169, 0, 1),
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
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
                  'assets/icons/add.svg',
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
