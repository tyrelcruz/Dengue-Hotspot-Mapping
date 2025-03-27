import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class YellowGradientButton extends StatelessWidget {
  final String name;
  final String route;
  final bool hasIcon;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double? height;
  final double? width;

  const YellowGradientButton({
    super.key,
    required this.name,
    required this.route,
    this.hasIcon = true,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromRGBO(248, 169, 0, 1),
              theme.colorScheme.secondary,
            ],
            stops: const [0.0, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SizedBox(
          height: height,
          width: width,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, route);
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            label: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (hasIcon) ...[
                    const SizedBox(width: 8),
                    SvgPicture.asset(
                      'assets/icons/right_arrow.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        theme.colorScheme.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
