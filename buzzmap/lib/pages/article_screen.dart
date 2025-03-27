import 'package:buzzmap/main.dart';
import 'package:flutter/material.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';

class ArticleScreen extends StatelessWidget {
  final Map<String, dynamic> article;

  const ArticleScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          title: 'Articles',
          currentRoute: '/articles',
          bannerTitle: 'Articles',
          themeMode: 'dark',
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 25),
                Image.network(article['publicationLogo'],
                    width: double.infinity, height: 20),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 27.0),
                    child: Text(article['articleTitle'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22,
                            color: primaryColor,
                            fontWeight: FontWeight.w700))),
                Text(
                  article['dateAndTime'] ?? 'No date available',
                  style: const TextStyle(
                      fontSize: 11,
                      color: primaryColor,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    article['articleImage'],
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 25),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(article['fullContent'],
                      style:
                          const TextStyle(fontSize: 12, color: primaryColor)),
                ),
                const SizedBox(height: 55)
              ],
            )));
  }
}
