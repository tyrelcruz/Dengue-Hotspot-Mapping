import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buzzmap/main.dart';
import 'package:buzzmap/pages/tip_details_screen.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';
import 'package:buzzmap/widgets/article_sampler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buzzmap/models/admin_post.dart';
import 'package:intl/intl.dart';
import 'package:buzzmap/pages/news_details_screen.dart';
import 'package:buzzmap/config/config.dart';
import 'package:buzzmap/widgets/custom_search_bar.dart';

class PreventionScreen extends StatefulWidget {
  const PreventionScreen({super.key});

  @override
  State<PreventionScreen> createState() => _PreventionScreenState();
}

class _PreventionScreenState extends State<PreventionScreen> {
  List<dynamic> newsPosts = [];
  List<dynamic> filteredNewsPosts = [];
  bool isLoading = true;
  bool hasError = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Get the appropriate base URL based on platform
  String get baseUrl {
    return Config.baseUrl;
  }

  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      print('Error formatting date: $e');
      return dateStr;
    }
  }

  @override
  void initState() {
    super.initState();
    print('🔍 initState: calling fetchNewsPosts');
    fetchNewsPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterNewsPosts(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (query.isEmpty) {
        filteredNewsPosts = newsPosts;
      } else {
        filteredNewsPosts = newsPosts.where((post) {
          final title = post['title']?.toString().toLowerCase() ?? '';
          final content = post['content']?.toString().toLowerCase() ?? '';
          final category = post['category']?.toString().toLowerCase() ?? '';
          return title.contains(_searchQuery) ||
              content.contains(_searchQuery) ||
              category.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<void> fetchNewsPosts() async {
    print('🔍 fetchNewsPosts called');
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/adminPosts'));
      print('🔍 API URL: $baseUrl/api/v1/adminPosts');
      if (response.statusCode == 200) {
        final List<dynamic> allPosts = json.decode(response.body);
        print('Fetched posts: ${allPosts.length}');
        final filtered =
            allPosts.where((post) => post['category'] == 'news').toList();
        print('Filtered news posts: ${filtered.length}');
        print('Filtered posts: $filtered');
        setState(() {
          newsPosts = filtered;
          filteredNewsPosts =
              filtered; // Initialize filtered posts with all posts
          isLoading = false;
        });
      } else {
        print('❌ fetchNewsPosts: response.statusCode = ${response.statusCode}');
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error in fetchNewsPosts: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🟢 PreventionScreen build called');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Prevention',
        currentRoute: '/prevention',
        themeMode: 'light',
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 13.0),
            children: [
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      alignment: Alignment.centerLeft,
                      height: 45,
                      width: 360,
                      decoration: const BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      child: CustomSearchBar(
                        controller: _searchController,
                        onChanged: _filterNewsPosts,
                        hintText: 'Search for latest news...',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 375,
                      height: 140,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Dengue Information',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 25,
                                    fontFamily: 'Inter-Bold',
                                    color: onPrimaryColor,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'Learn about dengue fever,\n its causes, and prevention methods',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: onPrimaryColor,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: -110,
                            left: -27,
                            child: SvgPicture.asset(
                              'assets/icons/tipcard1.svg',
                              width: 325,
                              height: 325,
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TipDetailsScreen(
                                        tip: AdminPost(
                                          id: 'dengue-alert',
                                          title: 'DENGUE ALERT!',
                                          content:
                                              'Ano ang DENGUE?\n\nAng DENGUE ay isang sakit o virus (genus flavivirus) mula sa kagat ng lamok (female mosquito) na Aedes aegypti. Ang lamok na ito ay karaniwang nakikita sa ating kapaligiran at ito ang klase na mas nangangagat sa mga tao sa araw imbes na sa gabi.\n\nPaano ito naipapasa?\n\nAng DENGUE ay naipapasa mula sa kagat ng lamok; (Nangingitlog sa malinaw na tubig tulad ng makikita sa flower vases at naiipong tubig-ulan sa gulong o basyong lata. Ang lamok ay karaniwang naglalagi sa madidilim na lugar ng bahay)',
                                          images: [
                                            'assets/images/dengue_alert.png'
                                          ],
                                          publishDate: DateTime.now(),
                                          category: 'alert',
                                          references: '',
                                          adminId: 'static',
                                          createdAt: DateTime.now(),
                                          updatedAt: DateTime.now(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 125,
                                  height: 31,
                                  alignment: Alignment.center,
                                  color: Colors.yellow,
                                  child: const Text('Read More'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: 175,
                          height: 155,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF245261),
                                      Color(0xFF4AA8C7)
                                    ],
                                    tileMode: TileMode.mirror,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              Positioned(
                                bottom: -90,
                                left: -50,
                                child: SvgPicture.asset(
                                  'assets/icons/tipcard2.svg',
                                  width: 300,
                                  height: 270,
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 20,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '5S Against Dengue',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Inter-Bold',
                                        color: onPrimaryColor,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    const Text(
                                      'Learn the 5S strategy\nto prevent dengue',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: onPrimaryColor,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: 5,
                                right: 10,
                                child: ClipOval(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TipDetailsScreen(
                                            tip: AdminPost(
                                              id: '5s-against-dengue',
                                              title: '5S AGAINST DENGUE',
                                              content: '',
                                              images: [],
                                              publishDate: DateTime.now(),
                                              category: 'tip',
                                              references: '',
                                              adminId: 'static',
                                              createdAt: DateTime.now(),
                                              updatedAt: DateTime.now(),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 45,
                                      height: 45,
                                      alignment: Alignment.center,
                                      color: Colors.yellow,
                                      child: const Icon(Icons.arrow_forward,
                                          color: Colors.black),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 175,
                          height: 155,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4AA8C7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: -10,
                                child: SvgPicture.asset(
                                  'assets/icons/tipcard3.svg',
                                  width: 300,
                                  height: 270,
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 30,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Symptoms',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Inter-Bold',
                                        color: onPrimaryColor,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    const Text(
                                      'Recognize early signs\nand symptoms of dengue',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: onPrimaryColor,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: 5,
                                right: 10,
                                child: ClipOval(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TipDetailsScreen(
                                            tip: AdminPost(
                                              id: 'symptoms',
                                              title: 'MGA SINTOMAS',
                                              content: '',
                                              images: [
                                                'assets/images/symptoms.png'
                                              ],
                                              publishDate: DateTime.now(),
                                              category: 'symptoms',
                                              references: '',
                                              adminId: 'static',
                                              createdAt: DateTime.now(),
                                              updatedAt: DateTime.now(),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 45,
                                      height: 45,
                                      alignment: Alignment.center,
                                      color: Colors.yellow,
                                      child: const Icon(Icons.arrow_forward,
                                          color: Colors.black),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Latest News Updates',
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredNewsPosts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No news posts available.'
                                    : 'No results found for "$_searchQuery"',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredNewsPosts.length,
                          itemBuilder: (context, index) {
                            final post = filteredNewsPosts[index];
                            final List<dynamic> imagesList =
                                post['images'] ?? [];
                            final String articleImage =
                                (imagesList.isNotEmpty &&
                                        imagesList[0] != null &&
                                        imagesList[0] is String &&
                                        imagesList[0].isNotEmpty)
                                    ? imagesList[0]
                                    : 'assets/images/latestnews.png';
                            final article = {
                              'articleImage': articleImage,
                              'articleTitle': post['title']?.toString() ?? '',
                              'dateAndTime': post['publishDate'] != null
                                  ? formatDate(post['publishDate'].toString())
                                  : '',
                              'sampleText': post['content']?.toString() ?? '',
                              'maxLines': 2,
                            };
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NewsDetailsScreen(
                                      postId: post['_id']?.toString() ?? '',
                                    ),
                                  ),
                                );
                              },
                              child: ArticleSampler(article: article),
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                        ),
              const SizedBox(height: 25),
            ],
          ),
          if (_searchQuery.isNotEmpty)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Builder(
                    builder: (context) {
                      final suggestions = filteredNewsPosts
                          .where((post) {
                            final title =
                                post['title']?.toString().toLowerCase() ?? '';
                            final content =
                                post['content']?.toString().toLowerCase() ?? '';
                            final category =
                                post['category']?.toString().toLowerCase() ??
                                    '';
                            return title.contains(_searchQuery) ||
                                content.contains(_searchQuery) ||
                                category.contains(_searchQuery);
                          })
                          .take(5)
                          .toList();

                      if (suggestions.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'No matches found.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView(
                        shrinkWrap: true,
                        children: suggestions
                            .map((post) => ListTile(
                                  title: Text(post['title']?.toString() ?? ''),
                                  subtitle: Text(
                                    '📰 ${post['category']?.toString() ?? ''} · 📅 ${formatDate(post['publishDate']?.toString() ?? '')}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  onTap: () {
                                    final title =
                                        post['title']?.toString() ?? '';
                                    setState(() {
                                      _searchController.text = title;
                                      _searchQuery = title.toLowerCase();
                                    });
                                  },
                                ))
                            .toList(),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
