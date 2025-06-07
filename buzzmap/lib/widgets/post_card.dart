import 'package:buzzmap/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:buzzmap/widgets/user_info_row.dart';
import 'package:flutter/material.dart';
import 'package:buzzmap/widgets/engagement_row.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final String username;
  final String whenPosted;
  final String location;
  final String date;
  final String time;
  final String reportType;
  final String description;
  final int numUpvotes;
  final int numDownvotes;
  final List<String> images;
  final String iconUrl;
  final String type;
  final VoidCallback? onReport;
  final VoidCallback? onDelete;
  final bool isOwner;
  final String postId;
  final bool showDistance;

  const PostCard({
    super.key,
    required this.post,
    required this.username,
    required this.whenPosted,
    this.location = '',
    required this.date,
    required this.time,
    required this.reportType,
    required this.description,
    required this.numUpvotes,
    required this.numDownvotes,
    this.images = const <String>[],
    required this.iconUrl,
    this.type = 'normal',
    this.onReport,
    this.onDelete,
    this.isOwner = false,
    required this.postId,
    this.showDistance = false,
  });

  String _formatDistance(double distance) {
    if (distance < 1) {
      return '${(distance * 1000).round()}m away';
    } else {
      return '${distance.toStringAsFixed(1)}km away';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = Theme.of(context).extension<CustomColors>();
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserInfoRow(
                  title: post['isAnonymous'] ? 'Anonymous' : username,
                  subtitle: whenPosted,
                  iconUrl: iconUrl,
                  type: 'post',
                  onReport: onReport,
                  onDelete: onDelete,
                  isOwner: isOwner,
                ),
                const SizedBox(height: 12),
                if (showDistance && post['distance'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _formatDistance(post['distance']),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '📍 Location: ',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      location,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '🕒 Date & Time: ',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$date, $time',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '⚠️ Report Type: ',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      reportType,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '📝 Description: ',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildImageGrid(images, context),
                ],
              ],
            ),
          ),
          EngagementRow(
            postId: post['_id'] ?? postId,
            initialUpvotes: numUpvotes,
            initialDownvotes: numDownvotes,
            isAdminPost: false,
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid(List<String> images, BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    final validImages = images.where((img) => img.isNotEmpty).toList();

    if (validImages.isEmpty) {
      return const SizedBox.shrink();
    }

    int crossAxisCount = 2; // Default grid for 2 images per row
    if (validImages.length == 1) {
      crossAxisCount = 1; // Single image takes full width
    } else if (validImages.length == 2) {
      crossAxisCount = 2; // Two images in one row
    } else if (validImages.length == 3) {
      crossAxisCount = 2; // Two images in the first row, one in the second row
    } else if (validImages.length == 4) {
      crossAxisCount = 2; // Two rows with two images each
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: validImages.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // Open image in full view on click
            showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  child: CachedNetworkImage(
                    imageUrl: validImages[index],
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                );
              },
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: validImages[index],
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => Icon(Icons.error),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
