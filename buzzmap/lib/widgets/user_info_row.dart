import 'package:buzzmap/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserInfoRow extends StatelessWidget {
  final String type;
  final String title;
  final String subtitle;
  final String iconUrl;
  final VoidCallback? onReport;
  final VoidCallback? onDelete;
  final bool isOwner;

  const UserInfoRow({
    super.key,
    this.type = 'announcement',
    required this.title,
    required this.subtitle,
    required this.iconUrl,
    this.onReport,
    this.onDelete,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: type == 'announcement' ? 45 : 35,
                height: type == 'announcement' ? 45 : 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                ),
                child: ClipOval(
                  child: iconUrl.startsWith('http')
                      ? Image.network(
                          iconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.person, color: Colors.grey),
                        )
                      : SvgPicture.asset(
                          iconUrl,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    type == 'announcement'
                        ? Text(
                            title.toUpperCase(),
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    type == 'announcement'
                        ? RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'From ',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                TextSpan(
                                  text: subtitle,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(),
                          )
                  ],
                ),
              ),
            ],
          ),
        ),
        if (type != 'announcement' &&
            isOwner) // Only show menu for posts that user owns
          Builder(
            builder: (context) => PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz,
                color: primaryColor,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    if (onDelete != null) onDelete!();
                    break;
                }
              },
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 20, color: primaryColor),
                        const SizedBox(width: 8),
                        const Text('Delete Post'),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ),
      ],
    );
  }
}
