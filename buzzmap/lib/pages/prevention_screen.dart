import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:buzzmap/main.dart';
import 'package:buzzmap/pages/tips_screen.dart';
import 'package:buzzmap/pages/tip_details_screen.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';
import 'package:buzzmap/widgets/article_sampler.dart';
import 'package:buzzmap/widgets/interests.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:buzzmap/data/articles_data.dart';
import 'package:buzzmap/models/admin_post.dart';
import 'package:intl/intl.dart';
import 'package:buzzmap/pages/news_details_screen.dart';

class PreventionScreen extends StatefulWidget {
  const PreventionScreen({super.key});

  @override
  State<PreventionScreen> createState() => _PreventionScreenState();
}

class _PreventionScreenState extends State<PreventionScreen> {
  List<dynamic> newsPosts = [];
  bool isLoading = true;
  bool hasError = false;

  // Get the appropriate base URL based on platform
  String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:4000';
    } else if (Platform.isIOS) {
      return 'http://localhost:4000';
    }
    return 'http://localhost:4000';
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
      body: ListView(
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
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: primaryColor, size: 14),
                      SizedBox(width: 10),
                      Text('What can I do to prevent dengue...',
                          style: TextStyle(fontSize: 12, color: primaryColor)),
                    ],
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
                                fontSize: 27,
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
                                colors: [Color(0xFF245261), Color(0xFF4AA8C7)],
                                tileMode: TileMode.mirror,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          Positioned(
                            bottom: -80,
                            left: -45,
                            child: SvgPicture.asset(
                              'assets/icons/tipcard2.svg',
                              width: 250,
                              height: 250,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 10,
                            child: Container(
                              width: 150,
                              height: 80,
                              color: Colors.transparent,
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '4S',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 27,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          ' Against Dengue',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 27,
                                            color: onPrimaryColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 1),
                                    const Text(
                                      'Search and destroy \nmosquito breeding sites',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: onPrimaryColor,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                                      builder: (context) => TipDetailsScreen(
                                        tip: AdminPost(
                                          id: '4s-against-dengue',
                                          title: 'Mag 4S kontra DENGUE!',
                                          content:
                                              '', // Content will be handled in the details screen
                                          images: [
                                            'assets/images/4s_1.png',
                                            'assets/images/4s_2.png',
                                          ],
                                          publishDate: DateTime.now(),
                                          category: '4s',
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
                            top: 0,
                            right: 10,
                            child: Container(
                              width: 150,
                              height: 80,
                              color: Colors.transparent,
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Symptoms',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        color: onPrimaryColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
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
                                      builder: (context) => TipDetailsScreen(
                                        tip: AdminPost(
                                          id: 'symptoms',
                                          title: 'MGA SINTOMAS',
                                          content:
                                              '', // Content will be handled in the details screen
                                          images: [
                                            'assets/images/symptoms.png',
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
              : newsPosts.isEmpty
                  ? const Center(child: Text('No news posts available.'))
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: newsPosts.length,
                      itemBuilder: (context, index) {
                        final post = newsPosts[index];
                        final List<dynamic> imagesList = post['images'] ?? [];
                        final String articleImage = (imagesList.isNotEmpty &&
                                imagesList[0] != null &&
                                imagesList[0] is String &&
                                imagesList[0].isNotEmpty)
                            ? imagesList[0]
                            : 'assets/images/latestnews.png'; // Use a local asset as fallback
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
    );
  }
}
