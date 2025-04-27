import 'package:buzzmap/main.dart';
import 'package:buzzmap/widgets/appbar/custom_app_bar.dart';
import 'package:buzzmap/widgets/article_sampler.dart';
import 'package:flutter/material.dart';
import 'package:buzzmap/data/articles_data.dart';

class InterestsScreen extends StatelessWidget {
  const InterestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Interests',
        currentRoute: '/interests',
        themeMode: 'dark',
        bannerTitle: 'Interests',
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Personal',
                              style: TextStyle(
                                  fontSize: 40,
                                  color: primaryColor,
                                  fontFamily: 'Koulen'),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Prevention',
                              style: TextStyle(
                                  fontSize: 40,
                                  color: surfaceColor,
                                  fontFamily: 'Koulen'),
                            ),
                          ]),
                      SizedBox(height: 10),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          'Protect yourself and your loved ones from dengue with simple yet effective precautions. Stay informed, stay safe, and take action to prevent mosquito bites and eliminate breeding grounds.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: primaryColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 20),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Related Articles',
                    style: TextStyle(
                      fontSize: 18,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  // shrinkWrap: true,
                  // physics: const NeverScrollableScrollPhysics(),
                  itemCount: ArticlesData.interestsArticles.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF4AA8C7),
                            Color(0xFF245261),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                            12), // optional: add rounded corners
                      ),
                      child: ArticleSampler(
                        article: ArticlesData.interestsArticles[index],
                        height: 130,
                        textColor: Colors.white,
                        bgColor: Colors
                            .transparent, // <-- Make background transparent inside
                        isInInterest: true,
                      ),
                    );
                  },

                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                ),
              ),
              const SizedBox(height: 30)
            ]),
      ),
    );
  }
}
