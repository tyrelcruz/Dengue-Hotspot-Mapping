import 'package:buzzmap/main.dart';
import 'package:buzzmap/widgets/engagement_row.dart';
import 'package:buzzmap/widgets/user_info_row.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementCard extends StatefulWidget {
  final VoidCallback? onRefresh;

  const AnnouncementCard({
    Key? key,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  bool _isLoading = true;
  bool _showFullContent = false;
  Map<String, dynamic>? _announcement;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchAnnouncement();
  }

  Future<void> refresh() async {
    print('🔄 Refreshing announcement card...');
    setState(() {
      _isLoading = true;
      _announcement = null; // Clear the current announcement
    });
    await _fetchAnnouncement();
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
  }

  Future<void> _fetchAnnouncement() async {
    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      print('🔑 Token from SharedPreferences: $token');

      if (token == null) {
        print('⚠️ No token found');
        setState(() {
          _announcement = null;
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:4000/api/v1/adminposts'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('🔍 Fetching announcements from backend...');
      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('📊 Number of posts: ${data.length}');
        
        if (data.isNotEmpty) {
          // Filter for announcements only (not tips)
          final announcements = data.where((post) {
            final category = post['category']?.toString().toLowerCase();
            print('🔍 Checking post category: $category');
            return category == 'announcement';
          }).toList();
          
          print('📢 Number of announcements: ${announcements.length}');
          print('📝 Announcements: ${announcements.map((a) => a['title']).toList()}');
          
          if (announcements.isNotEmpty) {
            // Sort announcements by createdAt to get the latest
            announcements.sort((a, b) {
              try {
                // Parse createdAt dates and handle potential null values
                final createdAtA = a['createdAt'] != null ? DateTime.parse(a['createdAt']) : DateTime(1970);
                final createdAtB = b['createdAt'] != null ? DateTime.parse(b['createdAt']) : DateTime(1970);
                
                print('📅 Comparing creation dates:');
                print('Created At A: $createdAtA (${a['title']})');
                print('Created At B: $createdAtB (${b['title']})');
                
                // Compare by createdAt (newest first)
                final createdAtComparison = createdAtB.compareTo(createdAtA);
                if (createdAtComparison != 0) {
                  print('📊 CreatedAt comparison result: $createdAtComparison');
                  return createdAtComparison;
                }
                
                // If createdAt is the same, compare by publishDate as secondary criteria
                final dateA = a['publishDate'] != null ? DateTime.parse(a['publishDate']) : DateTime(1970);
                final dateB = b['publishDate'] != null ? DateTime.parse(b['publishDate']) : DateTime(1970);
                final dateComparison = dateB.compareTo(dateA);
                print('📊 PublishDate comparison result: $dateComparison');
                return dateComparison;
              } catch (e) {
                print('❌ Error comparing dates: $e');
                return 0;
              }
            });
            
            // Log all announcements with their dates for debugging
            print('📊 Sorted announcements:');
            for (var announcement in announcements) {
              print('Title: ${announcement['title']}');
              print('Created At: ${announcement['createdAt']}');
              print('Publish Date: ${announcement['publishDate']}');
              print('---');
            }
            
            // Get the latest announcement (first in the sorted list)
            final latestAnnouncement = announcements[0];
            print('📢 Latest announcement: ${latestAnnouncement['title']}');
            print('📅 Publish date: ${latestAnnouncement['publishDate']}');
            print('📄 Content: ${latestAnnouncement['content']}');
            print('🖼️ Images: ${latestAnnouncement['images']}');
            
            // Update the announcement
            setState(() {
              _announcement = {
                'title': latestAnnouncement['title'],
                'content': latestAnnouncement['content'],
                'publishDate': latestAnnouncement['publishDate'],
                'images': latestAnnouncement['images'] ?? [],
                'references': latestAnnouncement['references'] ?? 'Quezon City Surveillance and Epidemiology Division',
                'category': latestAnnouncement['category'] ?? 'announcement',
              };
              _isLoading = false;
            });
          } else {
            print('⚠️ No announcements found (only tips)');
            setState(() {
              _announcement = null;
              _isLoading = false;
            });
          }
        } else {
          print('⚠️ No posts found');
          setState(() {
            _announcement = null;
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        print('🔒 Authentication required');
        setState(() {
          _announcement = null;
          _isLoading = false;
        });
      } else {
        print('❌ API error: ${response.statusCode}');
        print('❌ Error message: ${response.body}');
        setState(() {
          _announcement = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching announcements: $e');
      setState(() {
        _announcement = null;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      print('❌ Error formatting date: $e');
      return dateString;
    }
  }

  String _formatCategory(String category) {
    // Capitalize first letter and make it more readable
    return category[0].toUpperCase() + category.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_announcement == null) {
      print('❌ No announcement to display');
      return const SizedBox.shrink(); // Hide the card if no announcement
    }

    final title = _announcement!['title'] as String;
    final content = _announcement!['content'] as String;
    final publishDate = _announcement!['publishDate'] as String;
    final images = _announcement!['images'] as List<dynamic>;
    final references = _announcement!['references'] as String;
    final category = _announcement!['category'] as String;

    print('🎯 Current announcement:');
    print('Title: $title');
    print('Publish date: $publishDate');
    print('Category: $category');
    print('Images: $images');
    print('References: $references');

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Row
            UserInfoRow(
              title: 'Latest ${_formatCategory(category)}',
              subtitle: 'Quezon City Surveillance and Epidemiology Division',
              iconUrl: 'assets/icons/surveillance_logo.svg',
            ),
            const SizedBox(height: 16),
            
            // Title with emoji
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: '🚨 ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const TextSpan(
                    text: ' 🚨',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Content with show more/less
            Text(
              content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: _showFullContent ? null : 3,
              overflow: _showFullContent ? null : TextOverflow.ellipsis,
            ),
            if (content.length > 150) ...[
              TextButton(
                onPressed: () {
                  setState(() {
                    _showFullContent = !_showFullContent;
                  });
                },
                child: const Text(
                  'Show More',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
            
            // References
            if (references.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Source: $references',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            // Images
            if (images.isNotEmpty) ...[
              const SizedBox(height: 12),
              if (images.length == 1)
                // Single image - stretch to full width
                _buildImage(images[0])
              else
                // Multiple images - horizontal scroll
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildImage(images[index]),
                      );
                    },
                  ),
                ),
            ],
            
            // Date
            const SizedBox(height: 12),
            Text(
              'Published: ${_formatDate(publishDate)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    // Fix image URL if needed
    String fixedUrl = imageUrl;
    if (imageUrl.contains('i.ibb.co')) {
      // The URL is already in the correct format from the API
      // No need to modify it
      fixedUrl = imageUrl;
    }

    print('🖼️ Loading image from URL: $fixedUrl');
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: fixedUrl,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) {
          print('❌ Error loading image: $error');
          print('❌ Failed URL: $url');
          return Container(
            color: Colors.grey.shade200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 8),
                Text(
                  'Failed to load image',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
