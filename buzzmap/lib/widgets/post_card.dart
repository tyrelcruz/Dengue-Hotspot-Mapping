import 'package:buzzmap/main.dart';
import 'package:buzzmap/widgets/engagement_row.dart';
import 'package:buzzmap/widgets/user_info_row.dart';
import 'package:flutter/material.dart';
import 'package:buzzmap/auth/config.dart';

class PostCard extends StatelessWidget {
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

  const PostCard(
      {super.key,
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
      this.type = 'normal'});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    final theme = Theme.of(context);
    final borderedType = type == 'bordered';

    return Container(
      decoration: borderedType
          ? BoxDecoration(
              border: Border.all(
                color: customColors?.surfaceLight ?? Colors.grey,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: Column(
        children: [
          Padding(
            padding: !borderedType
                ? EdgeInsets.symmetric(vertical: 30, horizontal: 20)
                : EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserInfoRow(
                  title: username,
                  subtitle: whenPosted,
                  iconUrl: iconUrl,
                  type: 'post',
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!borderedType)
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
                            '🕒 Date & Time:',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
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
                            '⚠️ Report Type:',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            reportType,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.start,
                        children: [
                          Text(
                            '📝 Description',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            description,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          _buildImageGrid(images, context),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          !borderedType
              ? Divider(
                  thickness: 8,
                  color: Colors.grey[300],
                )
              : SizedBox.shrink(),
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
                  child: Image.network(validImages[index]),
                );
              },
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              validImages[index].startsWith('http')
                  ? validImages[index]
                  : Config.baseUrl +
                      '/' +
                      validImages[index].replaceAll('\\', '/'),
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
