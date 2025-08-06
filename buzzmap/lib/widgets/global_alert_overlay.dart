import 'package:flutter/material.dart';
import 'package:buzzmap/services/alert_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GlobalAlertOverlay extends StatefulWidget {
  final Widget child;

  const GlobalAlertOverlay({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<GlobalAlertOverlay> createState() => _GlobalAlertOverlayState();
}

class _GlobalAlertOverlayState extends State<GlobalAlertOverlay> {
  Map<String, dynamic>? _currentAlert;
  bool _isVisible = false;
  bool _showFullMessage = false;

  static const int _maxPreviewLength = 120;

  @override
  void initState() {
    super.initState();
    _setupAlertListener();
  }

  void _setupAlertListener() {
    AlertService().alertStream.listen((alert) {
      if (alert != null && alert.isNotEmpty) {
        // Only show if alert is not null and not empty
        setState(() {
          _currentAlert = alert;
          _isVisible = true;
          _showFullMessage = false;
        });

        // Auto-hide after 10 seconds
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted) {
            setState(() {
              _isVisible = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    String getMessagePreview(String message) {
      if (_showFullMessage || message.length <= _maxPreviewLength) {
        return message;
      } else {
        return message.substring(0, _maxPreviewLength) + '...';
      }
    }

    return Stack(
      children: [
        widget.child,
        if (_isVisible && _currentAlert != null && _currentAlert!.isNotEmpty)
          Center(
            child: Material(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  child: Card(
                    elevation: 8,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header Row
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
                          child: Column(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/logo_ligthbg.svg',
                                height: 40,
                                width: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'IMPORTANT',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 37,
                                  fontFamily: 'Koulen',
                                  letterSpacing: 1.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Admin Subheading

                        Divider(
                          height: 1,
                          thickness: 2,
                          color: Colors.grey.shade400,
                          indent: 20,
                          endIndent: 20,
                        ),
                        // Content Section
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: primaryColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Alert Message',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_currentAlert!["messages"] != null &&
                                  _currentAlert!["messages"].isNotEmpty)
                                ..._currentAlert!["messages"]
                                    .map<Widget>((msg) {
                                  final message = msg.toString();
                                  final isLong =
                                      message.length > _maxPreviewLength;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        constraints: BoxConstraints(
                                          maxHeight: _showFullMessage
                                              ? MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.5
                                              : double.infinity,
                                        ),
                                        child: SingleChildScrollView(
                                          physics: _showFullMessage
                                              ? const BouncingScrollPhysics()
                                              : const NeverScrollableScrollPhysics(),
                                          child: Text(
                                            getMessagePreview(message),
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 16,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isLong)
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _showFullMessage =
                                                  !_showFullMessage;
                                            });
                                          },
                                          child: Text(_showFullMessage
                                              ? 'Show Less'
                                              : 'Show More'),
                                        ),
                                    ],
                                  );
                                }).toList(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Affected Areas Card
                        if (_currentAlert!['barangays'] != null &&
                            (_currentAlert!['barangays'] as List).isNotEmpty)
                          Card(
                            color: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: primaryColor,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Affected Areas',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    (_currentAlert!['barangays'] as List)
                                        .map((b) => b['name'])
                                        .join(', '),
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontStyle: FontStyle.italic,
                                      fontSize: 14,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        // OK Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isVisible = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
