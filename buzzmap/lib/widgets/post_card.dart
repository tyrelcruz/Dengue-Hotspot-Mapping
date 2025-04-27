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
  final int numComments;
  final int numShares;
  final List<String> images;
  final String iconUrl; // Add iconUrl parameter
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
      required this.numComments,
      required this.numShares,
      this.images = const <String>[],
      required this.iconUrl,
      this.type = 'normal' // Add iconUrl parameter
      });

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
                  iconUrl: iconUrl, // Pass iconUrl to UserInfoRow
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
                      if (images.isNotEmpty) _buildImageGrid(images),
                      const SizedBox(height: 12),
                      Divider(
                        color: customColors?.surfaceLight,
                        thickness: .9,
                        height: 6,
                      ),
                      const SizedBox(height: 10),
                      EngagementRow(
                        numUpvotes: numUpvotes,
                        numDownvotes: numDownvotes,
                        numComments: numComments,
                        numShares: numShares,
                        themeMode: 'light',
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

  Widget _buildImageGrid(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    final validImages = images.where((img) => img.isNotEmpty).toList();

    if (validImages.isEmpty) {
      return const SizedBox.shrink();
    }

    if (validImages.length == 1) {
      return ClipRRect(
        child: Image.network(
          validImages[0].startsWith('http')
              ? validImages[0]
              : Config.baseUrl + '/' + validImages[0].replaceAll('\\', '/'),
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
        ),
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: validImages.length <= 2 ? 2 : 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: validImages.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            child: Image.network(
              validImages[index].startsWith('http')
                  ? validImages[index]
                  : Config.baseUrl +
                      '/' +
                      validImages[index].replaceAll('\\', '/'),
              fit: BoxFit.cover,
            ),
          );
        },
      );
    }
  }
}
