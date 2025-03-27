import 'package:buzzmap/main.dart';
import 'package:buzzmap/pages/article_screen.dart';
import 'package:flutter/material.dart';

class ArticleSampler extends StatelessWidget {
  final Map<String, dynamic> article;
  final double height;
  final Color color;
  final Color textColor;
  final Color bgColor;
  final bool isInInterest;

  const ArticleSampler(
      {super.key,
      required this.article,
      this.height = 100,
      this.color = Colors.white,
      this.textColor = primaryColor,
      this.bgColor = Colors.white,
      this.isInInterest = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ArticleScreen(article: article)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: bgColor,
        ),
        child: SizedBox(
          height: height,
          child: Padding(
            padding: isInInterest
                ? const EdgeInsets.only(left: 8, top: 4, bottom: 2, right: 3)
                : const EdgeInsets.all(0),
            child: Stack(
              children: [_buildContentRow(), _buildForwardButton()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentRow() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildArticleImage(),
      const SizedBox(width: 12),
      _buildArticleDetails(),
    ]);
  }

  Widget _buildArticleImage() {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 8, left: isInInterest ? 10 : 0),
      child: SizedBox(
        width: 95,
        height: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(article['articleImage'], fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildArticleDetails() {
    return SizedBox(
        width: isInInterest ? 220 : 250,
        height: height,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 5),
          Image.network(article['publicationLogo'],
              width: 47, height: 10, fit: BoxFit.cover),
          Text(article['articleTitle'],
              maxLines: 3,
              softWrap: true,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.0,
              )),
          Text(article['dateAndTime'],
              style: TextStyle(
                fontSize: 9,
                color: textColor,
              )),
          const SizedBox(height: 15),
          Expanded(
            child: Padding(
                padding: const EdgeInsets.only(right: 28),
                child: Text(article['sampleText'],
                    maxLines: article['maxLines'],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isInInterest ? onPrimaryColor : textColor,
                      fontSize: 9,
                    ))),
          )
        ]));
  }

  Widget _buildForwardButton() {
    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isInInterest ? onPrimaryColor : primaryColor,
        ),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Icon(
              Icons.arrow_forward,
              size: 15,
              color: isInInterest ? primaryColor : onPrimaryColor,
              weight: 100,
            ),
          ),
        ),
      ),
    );
  }
}
