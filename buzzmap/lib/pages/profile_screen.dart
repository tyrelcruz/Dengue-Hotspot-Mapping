import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:buzzmap/providers/post_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buzzmap/widgets/post_card.dart';
import 'package:buzzmap/widgets/post_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:buzzmap/auth/config.dart';
import 'package:buzzmap/providers/vote_provider.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  final String email;

  const ProfileScreen({Key? key, required this.username, required this.email})
      : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userId;
  late SharedPreferences _prefs;
  bool _isPrefsLoaded = false;
  String? _profilePhotoUrl;

  // Editable About fields
  String _bio =
      'Mom, teacher, and dengue awareness advocate in Brgy. Bagong Silangan. Actively contributing to a healthier community.';
  bool _isEditingAbout = false;
  final TextEditingController _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<PostProvider>(context, listen: false).fetchPosts();
      // Use lazy loading instead of refreshAllVotes
      await Provider.of<VoteProvider>(context, listen: false)
          .loadVoteStatesIfNeeded();
    });
    _bioController.text = _bio;
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = _prefs.getString('userId');
      _isPrefsLoaded = true;
      // Load saved profile photo URL
      _profilePhotoUrl = _prefs.getString('profilePhotoUrl');
    });
    print(
        'Debug: Loaded profile photo URL from SharedPreferences: $_profilePhotoUrl');

    // Fetch latest profile data from server
    await _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final token = _prefs.getString('authToken');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/api/v1/accounts/basic/$_userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final photoUrl = data['profilePhotoUrl'];
        final fetchedBio = data['bio'];

        if (photoUrl != null && photoUrl.isNotEmpty) {
          print('Debug: Fetched profile photo URL from server: $photoUrl');
          await _prefs.setString('profilePhotoUrl', photoUrl);
          setState(() {
            _profilePhotoUrl = photoUrl;
          });
        }

        if (fetchedBio != null) {
          print('Debug: Fetched bio from server: $fetchedBio');
          setState(() {
            _bio = fetchedBio;
            _bioController.text = fetchedBio;
          });
        }
      } else {
        print('Debug: Failed to fetch profile data: ${response.statusCode}');
      }
    } catch (e) {
      print('Debug: Error fetching profile data: $e');
    }
  }

  Future<bool> _verifyImageUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      print('Debug: Image URL verification status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Debug: Image URL verification error: $e');
      return false;
    }
  }

  Future<void> _changePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    final token = _prefs.getString('authToken');
    if (token == null) return;

    print('Debug: Starting profile photo upload');
    print('Debug: Selected file path: ${pickedFile.path}');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${Config.baseUrl}/api/v1/accounts/profile-photo'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['email'] = widget.email;
    request.files.add(
        await http.MultipartFile.fromPath('profilePhoto', pickedFile.path));

    print('Debug: Sending request to: ${request.url}');
    print('Debug: Request headers: ${request.headers}');
    print('Debug: Request fields: ${request.fields}');

    try {
      final response = await request.send();
      print('Debug: Response status code: ${response.statusCode}');

      final respStr = await response.stream.bytesToString();
      print('Debug: Response body: $respStr');

      if (response.statusCode == 200) {
        final data = jsonDecode(respStr);
        final newPhotoUrl = data['profilePhotoUrl'];

        // Verify the image URL is accessible
        final isUrlValid = await _verifyImageUrl(newPhotoUrl);
        print('Debug: Image URL valid: $isUrlValid');

        if (isUrlValid) {
          // Save the new photo URL to SharedPreferences
          await _prefs.setString('profilePhotoUrl', newPhotoUrl);
          print(
              'Debug: Saved profile photo URL to SharedPreferences: $newPhotoUrl');

          setState(() {
            _profilePhotoUrl = newPhotoUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load the uploaded image.')),
          );
        }
      } else {
        print('Debug: Error response: $respStr');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile photo.')),
        );
      }
    } catch (e) {
      print('Debug: Exception during upload: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateBio() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found. Please try again.')),
      );
      return;
    }

    final token = _prefs.getString('authToken');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Authentication token not found. Please log in again.')),
      );
      return;
    }

    // Validate bio length (500 characters max as per backend)
    if (_bioController.text.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bio cannot exceed 500 characters.')),
      );
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse('${Config.baseUrl}/api/v1/accounts/$_userId/bio'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bio': _bioController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _bio = data['account']['bio'] ?? _bioController.text;
          _isEditingAbout = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bio updated successfully!')),
        );
      } else {
        final error =
            jsonDecode(response.body)['error'] ?? 'Failed to update bio';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      print('Error updating bio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to update bio. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    // Save the current profile photo URL when the screen is disposed
    if (_profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty) {
      _prefs.setString('profilePhotoUrl', _profilePhotoUrl!);
      print('Debug: Saved profile photo URL on dispose: $_profilePhotoUrl');
    }
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredPosts(
      List<Map<String, dynamic>> posts) {
    return posts;
  }

  @override
  Widget build(BuildContext context) {
    final posts = Provider.of<PostProvider>(context).posts;
    final myPosts =
        posts.where((post) => post['userId']?.toString() == _userId).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Stack(
          children: [
            // Background with pattern overlay
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/pattern_overlay.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, size: 24, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),

            // Main content (static card, avatar, tabs, and tab content)
            Column(
              children: [
                const SizedBox(height: 170), // Space for avatar

                // White card content (static)
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 70), // Space for avatar overlap

                      // User info
                      Text(
                        widget.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF718096),
                        ),
                      ),

                      const SizedBox(height: 24),
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${myPosts.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Reports Posted',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF38546B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 48),
                          Column(
                            children: [
                              Text(
                                '${myPosts.fold<int>(0, (sum, post) => sum + ((post['numUpvotes'] as int?) ?? 0))}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Upvotes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF38546B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),

                // Tabs (outside the card)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const TabBar(
                    labelColor: Color(0xFF2D3748),
                    unselectedLabelColor: Color(0xFF718096),
                    indicatorColor: Color(0xFF6B9B9C),
                    indicatorWeight: 3,
                    tabs: [
                      Tab(text: 'My Posts'),
                      Tab(text: 'Media'),
                      Tab(text: 'About'),
                    ],
                  ),
                ),

                // Tab content (scrollable)
                Expanded(
                  child: TabBarView(
                    children: [
                      // My Posts Tab
                      _isPrefsLoaded
                          ? Column(
                              children: [
                                // Posts list
                                Expanded(
                                  child: _getFilteredPosts(myPosts).isEmpty
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(32),
                                            child: Text(
                                              'No posts yet.',
                                              style: TextStyle(
                                                color: Color(0xFF718096),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          itemCount:
                                              _getFilteredPosts(myPosts).length,
                                          itemBuilder: (context, index) {
                                            final post = _getFilteredPosts(
                                                myPosts)[index];
                                            // Format post data to ensure all required fields are present
                                            final formattedPost = {
                                              '_id': post['_id']?.toString() ??
                                                  post['id']?.toString() ??
                                                  '',
                                              'username': post['username']
                                                      ?.toString() ??
                                                  'Anonymous',
                                              'whenPosted': post['whenPosted']
                                                      ?.toString() ??
                                                  'Just now',
                                              'location': post['location']
                                                      ?.toString() ??
                                                  'Unknown location',
                                              'date':
                                                  post['date']?.toString() ??
                                                      '',
                                              'time':
                                                  post['time']?.toString() ??
                                                      '',
                                              'reportType': post['reportType']
                                                      ?.toString() ??
                                                  'Unknown',
                                              'description': post['description']
                                                      ?.toString() ??
                                                  '',
                                              'numUpvotes': (post['numUpvotes']
                                                      as int?) ??
                                                  0,
                                              'numDownvotes':
                                                  (post['numDownvotes']
                                                          as int?) ??
                                                      0,
                                              'images': (post['images']
                                                          as List<dynamic>?)
                                                      ?.map((e) => e.toString())
                                                      .toList() ??
                                                  [],
                                              'iconUrl': post['iconUrl']
                                                      ?.toString() ??
                                                  'assets/icons/person_1.svg',
                                              'isAnonymous':
                                                  post['isAnonymous'] ?? false,
                                              'userId':
                                                  post['userId']?.toString(),
                                              'status':
                                                  post['status']?.toString() ??
                                                      'Pending',
                                            };
                                            return GestureDetector(
                                              onTap: () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        PostDetailScreen(
                                                            post:
                                                                formattedPost),
                                                  ),
                                                );
                                                setState(() {});
                                              },
                                              child: PostCard(
                                                key: ValueKey(
                                                    formattedPost['_id']),
                                                post: formattedPost,
                                                username:
                                                    formattedPost['username']!,
                                                whenPosted: formattedPost[
                                                    'whenPosted']!,
                                                location:
                                                    formattedPost['location']!,
                                                date: formattedPost['date']!,
                                                time: formattedPost['time']!,
                                                reportType: formattedPost[
                                                    'reportType']!,
                                                description: formattedPost[
                                                    'description']!,
                                                numUpvotes:
                                                    formattedPost['numUpvotes']
                                                        as int,
                                                numDownvotes: formattedPost[
                                                    'numDownvotes'] as int,
                                                images: formattedPost['images']
                                                    as List<String>,
                                                iconUrl:
                                                    formattedPost['iconUrl']!,
                                                type: 'bordered',
                                                onReport: () {},
                                                onDelete: () {},
                                                isOwner: true,
                                                postId: formattedPost['_id']!,
                                                showDistance: false,
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            )
                          : const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                      // Media Tab
                      Builder(
                        builder: (context) {
                          // Collect all images from myPosts
                          final List<String> allImages = myPosts
                              .expand((post) =>
                                  (post['images'] as List<dynamic>? ?? [])
                                      .map((e) => e.toString()))
                              .toList();
                          if (allImages.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text('No media uploaded yet.'),
                              ),
                            );
                          }
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: allImages.length,
                            itemBuilder: (context, index) {
                              final imageUrl = allImages[index];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image,
                                        size: 32, color: Colors.grey),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      // About Tab
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 32),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_isEditingAbout) ...[
                                  TextField(
                                    controller: _bioController,
                                    maxLines: 3,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF2D3748),
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Bio',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _updateBio,
                                    child: const Text('Save'),
                                  ),
                                ] else ...[
                                  // Bio
                                  Text(
                                    _bio,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF2D3748),
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  // Info row
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 16, color: Color(0xFF718096)),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Joined: ',
                                        style: TextStyle(
                                          color: Color(0xFF718096),
                                          fontSize: 15,
                                        ),
                                      ),
                                      const Text(
                                        'February 2025',
                                        style: TextStyle(
                                          color: Color(0xFF718096),
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            // Edit icon floating top right
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: Icon(
                                    _isEditingAbout ? Icons.close : Icons.edit,
                                    color: const Color(0xFF2D3748)),
                                tooltip: _isEditingAbout ? 'Cancel' : 'Edit',
                                onPressed: () {
                                  setState(() {
                                    _isEditingAbout = !_isEditingAbout;
                                    if (_isEditingAbout) {
                                      _bioController.text = _bio;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Avatar
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(75),
                        child: _profilePhotoUrl != null &&
                                _profilePhotoUrl!.isNotEmpty
                            ? Image.network(
                                _profilePhotoUrl!,
                                fit: BoxFit.cover,
                                width: 150,
                                height: 150,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Debug: Image loading error: $error');
                                  print('Debug: Image URL: $_profilePhotoUrl');
                                  return Container(
                                    width: 150,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person,
                                        size: 50, color: Colors.grey),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const CircularProgressIndicator();
                                },
                              )
                            : Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: _changePhoto,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Color(0xFF245262), size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
