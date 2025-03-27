import 'package:buzzmap/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserInfoRow extends StatelessWidget {
  final String type;
  final String title;
  final String subtitle;
  final String iconUrl;

  const UserInfoRow(
      {super.key,
      this.type = 'announcement',
      required this.title,
      required this.subtitle,
      required this.iconUrl});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();

    final theme = Theme.of(context);
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
                  child: SvgPicture.asset(
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
        Padding(
          padding: EdgeInsets.symmetric(vertical: 3),
          child: Icon(
            Icons.more_horiz,
            color: type == 'announcement'
                ? Colors.white
                : theme.colorScheme.primary,
          ),
        )
      ],
    );
  }
}
