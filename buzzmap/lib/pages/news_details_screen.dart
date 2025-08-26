import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart' as auth_config;
import 'package:buzzmap/models/admin_post.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';
import 'package:buzzmap/main.dart';
import 'package:intl/intl.dart';
import 'package:buzzmap/config/config.dart';

class NewsDetailsScreen extends StatefulWidget {
  final String postId;

  const NewsDetailsScreen({
    super.key,
    required this.postId,
  });

  @override
  State<NewsDetailsScreen> createState() => _NewsDetailsScreenState();
}

class _NewsDetailsScreenState extends State<NewsDetailsScreen> {
  AdminPost? news;
  bool isLoading = true;
  bool hasError = false;

  String get baseUrl {
    return Config.baseUrl;
  }

  @override
  void initState() {
    super.initState();
    print('🟢 NewsDetailsScreen initState called');
    fetchNewsPost();
  }

  Future<void> fetchNewsPost() async {
    print('Fetching news post with ID: \'${widget.postId}\'');
    print('URL: ' + baseUrl + '/api/v1/adminPosts/' + widget.postId);
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/adminPosts/${widget.postId}'));
      if (response.statusCode == 200) {
        final post = json.decode(response.body);
        setState(() {
          news = AdminPost(
            id: post['_id']?.toString() ?? '',
            title: post['title']?.toString() ?? '',
            content: post['content']?.toString() ?? '',
            images: List<String>.from(post['images'] ?? []),
            publishDate: post['publishDate'] != null
                ? DateTime.tryParse(post['publishDate'].toString()) ??
                    DateTime.now()
                : DateTime.now(),
            category: post['category']?.toString() ?? '',
            references: post['references']?.toString() ?? '',
            adminId: post['adminId']?.toString() ?? '',
            createdAt: post['createdAt'] != null
                ? DateTime.tryParse(post['createdAt'].toString()) ??
                    DateTime.now()
                : DateTime.now(),
            updatedAt: post['updatedAt'] != null
                ? DateTime.tryParse(post['updatedAt'].toString()) ??
                    DateTime.now()
                : DateTime.now(),
          );
          isLoading = false;
        });
      } else {
        print('Failed to fetch news post. Status code: ${response.statusCode}');
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Exception while fetching news post: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🟢 NewsDetailsScreen build called');
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Latest News',
        currentRoute: '/news',
        themeMode: 'dark',
        bannerTitle: 'Latest News',
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError || news == null
              ? const Center(child: Text('Failed to load news post.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 27.0),
                        child: Text(
                          news!.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'Published: ${DateFormat('MMMM d, yyyy').format(news!.publishDate)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (news!.images.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: news!.images[0].startsWith('http')
                              ? Image.network(
                                  news!.images[0],
                                  width: double.infinity,
                                  height: 250,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height: 250,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.error),
                                    );
                                  },
                                )
                              : Image.asset(
                                  news!.images[0],
                                  width: double.infinity,
                                  height: 250,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              news!.content,
                              textAlign: TextAlign.justify,
                              style: const TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                height: 1.5,
                              ),
                            ),
                            if (news!.references.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Text(
                                news!.references,
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
                  ),
                ),
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 19, horizontal: 10),
        decoration: const BoxDecoration(
          color: Color(0xFF245261),
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FOLLOW US: ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Icon(Icons.facebook, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                '@QCEpidemiologyDiseaseSurveillance/',
                style: TextStyle(
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
      ),
    );
  }
}
