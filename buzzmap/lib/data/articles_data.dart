import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ArticlesData {
  static final List<Map<String, dynamic>> articles = [
    {
      'articleImage':
          'https://www.bworldonline.com/wp-content/uploads/2021/08/Mosquito-Dengue.jpg',
      'publicationLogo':
          'https://www.bworldonline.com/wp-content/uploads/2021/04/bw-logo-1.png',
      'articleTitle':
          'Philippine Health department flags worrisome uptick in dengue cases in Luzon',
      'dateAndTime': 'February 17, 2025 | 9:17 pm',
      'sampleText':
          'PHILIPPINE health authorities on Monday flagged a "concerning rise" in dengue cases in Luzon, with eight more local governments there likely to declare an outbreak after Quezon City.',
      'maxLines': 1,
      'fullContent':
          'PHILIPPINE health authorities on Monday flagged a "concerning rise" in dengue cases in Luzon, with eight more local governments there likely to declare an outbreak after Quezon City.\n\nIn a statement, the Department of Health (DoH) cited an uptick in dengue cases in nine local government units across  Metro Manila, Calabarzon and Central Luzon. It did not disclose the names of the cities and the number of infections.\n\nThis comes after Quezon City Mayor Maria Josefina "Joy" Tanya G. Belmonte declared a dengue outbreak in the country\'s largest city, where at least 10 people have died from the disease spread by mosquitoes and more than 1,700 cases have been posted this year.\n\nThe Health department has reported 28,384 dengue cases as of Feb. 1, a 40% increase from a year earlier.\n\nThe agency said regional epidemiology and surveillance units have been advising their local government counterparts about the cases, adding that the declaration of a local dengue outbreak may only be done by a local government official.\n\nThe Philippine Health department last declared a national dengue epidemic in 2019.\n\nThe eight localities other than Quezon City are likely to declare a dengue outbreak due to an uptick in cases, DoH spokesman Albert Francis E. Domingo told DZBB radio.\n\nDengue is the most common mosquito-borne disease worldwide, typically found in tropical and sub-tropical climates.\n\nCommon symptoms include high fever, severe headaches, nausea, vomiting, rashes and muscle pain, according to the World Health Organization\'s website.\n\nIf left untreated, dengue can progress to a severe stage, which may involve intense stomach pain, vomiting, bleeding of the gums or nose, blood in urine or stools, difficulty breathing and bleeding under the skin. — John Victor D. Ordoñez',
    },
    {
      'articleImage':
          'https://od2-image-api.abs-cbn.com/prod/editorImage/173976500925020190716-dengue-patient-GC-3806.jpg',
      'publicationLogo':
          'https://od2-image-api.abs-cbn.com/prod/ABS-CBN_OneDomain_Logo.png',
      'articleTitle':
          'DOH reports \'concerning rise\' of dengue cases in 9 LGUs',
      'dateAndTime': 'February 17, 2025 | 12:25 pm',
      'sampleText':
          'MANILA (UPDATE) — The Department of Health (DOH) on Monday said it saw a "concerning rise in the number of Dengue cases" in at least 9 localities in the Philippines.',
      'maxLines': 2,
      'fullContent':
          'PHILIPPINE health authorities on Monday flagged a "concerning rise" in dengue cases in Luzon, with eight more local governments there likely to declare an outbreak after Quezon City.\n\nIn a statement, the Department of Health (DoH) cited an uptick in dengue cases in nine local government units across  Metro Manila, Calabarzon and Central Luzon. It did not disclose the names of the cities and the number of infections.\n\nThis comes after Quezon City Mayor Maria Josefina "Joy" Tanya G. Belmonte declared a dengue outbreak in the country\'s largest city, where at least 10 people have died from the disease spread by mosquitoes and more than 1,700 cases have been posted this year.\n\nThe Health department has reported 28,384 dengue cases as of Feb. 1, a 40% increase from a year earlier.\n\nThe agency said regional epidemiology and surveillance units have been advising their local government counterparts about the cases, adding that the declaration of a local dengue outbreak may only be done by a local government official.\n\nThe Philippine Health department last declared a national dengue epidemic in 2019.\n\nThe eight localities other than Quezon City are likely to declare a dengue outbreak due to an uptick in cases, DoH spokesman Albert Francis E. Domingo told DZBB radio.\n\nDengue is the most common mosquito-borne disease worldwide, typically found in tropical and sub-tropical climates.\n\nCommon symptoms include high fever, severe headaches, nausea, vomiting, rashes and muscle pain, according to the World Health Organization\'s website.\n\nIf left untreated, dengue can progress to a severe stage, which may involve intense stomach pain, vomiting, bleeding of the gums or nose, blood in urine or stools, difficulty breathing and bleeding under the skin. — John Victor D. Ordoñez',
    },
    {
      'articleImage':
          'https://www.rappler.com/tachyon/2022/07/dengue-fogging-tondo-july-5-2022-003.jpg',
      'publicationLogo':
          'https://assets.codeenginestudio.com/2024-06/rappler_0.webp',
      'articleTitle':
          'Rising dengue cases seen in Metro Manila, Calabarzon, Central Luzon',
      'dateAndTime': 'February 17, 2025 | 2:57 pm',
      'sampleText':
          'Aside from Quezon City, the Department of Health says there are eight other local government units that have logged \'a concerning rise\' in the number of patients with dengue',
      'maxLines': 2,
      'fullContent':
          'PHILIPPINE health authorities on Monday flagged a "concerning rise" in dengue cases in Luzon, with eight more local governments there likely to declare an outbreak after Quezon City.\n\nIn a statement, the Department of Health (DoH) cited an uptick in dengue cases in nine local government units across  Metro Manila, Calabarzon and Central Luzon. It did not disclose the names of the cities and the number of infections.\n\nThis comes after Quezon City Mayor Maria Josefina "Joy" Tanya G. Belmonte declared a dengue outbreak in the country\'s largest city, where at least 10 people have died from the disease spread by mosquitoes and more than 1,700 cases have been posted this year.\n\nThe Health department has reported 28,384 dengue cases as of Feb. 1, a 40% increase from a year earlier.\n\nThe agency said regional epidemiology and surveillance units have been advising their local government counterparts about the cases, adding that the declaration of a local dengue outbreak may only be done by a local government official.\n\nThe Philippine Health department last declared a national dengue epidemic in 2019.\n\nThe eight localities other than Quezon City are likely to declare a dengue outbreak due to an uptick in cases, DoH spokesman Albert Francis E. Domingo told DZBB radio.\n\nDengue is the most common mosquito-borne disease worldwide, typically found in tropical and sub-tropical climates.\n\nCommon symptoms include high fever, severe headaches, nausea, vomiting, rashes and muscle pain, according to the World Health Organization\'s website.\n\nIf left untreated, dengue can progress to a severe stage, which may involve intense stomach pain, vomiting, bleeding of the gums or nose, blood in urine or stools, difficulty breathing and bleeding under the skin. — John Victor D. Ordoñez',
    },
  ];
  static final List<Map<String, dynamic>> interestsArticles = [
    {
      'articleImage':
          'https://www.healthxchange.sg/sites/hexassets/Assets/head-neck/how-protect-yourself-from-dengue-fever.jpg',
      'publicationLogo':
          'https://www.healthxchange.sg/_catalogs/masterpage/HealthXChange/images/healthxchange-logo.png',
      'articleTitle': 'How to Protect Yourself and Family From Dengue Fever',
      'dateAndTime': 'Anjana Motihar Chandra',
      'sampleText':
          'The National Environment Agency (NEA) is spearheading the fight against dengue fever in Singapore by raising public awareness about mosquito breeding and destroying existing breeding sites.',
      'maxLines': 3,
      'fullContent': 'Testing',
    },
    {
      'articleImage':
          'https://www.dengue.com/sites/default/files/styles/dengue_image_medium_834px/public/2024-10/Dengue_mosquito_prevention_endemic.jpg.webp?itok=FfyisDkX',
      'publicationLogo':
          'https://www.dengue.com/sites/default/files/styles/dengue_image_medium_834px/public/2024-05/Dengue.com%20logo%20%281%29.png.webp?itok=vio3ThF8',
      'articleTitle':
          'Help prevent the spread of dengue through your home and community',
      'dateAndTime': 'Dengue.com',
      'sampleText':
          'The threat of dengue is rising fast. Cases have increased 30-50 fold in some areas over a period of just 50 years. Based on the current trajectory, one study predicts that over six billion people will be at risk of dengue fever by 2080.',
      'maxLines': 2,
      'fullContent': 'Test'
    },
    {
      'articleImage':
          'https://www.prubsn.com.my/export/sites/prudential-pbtb/.galleries/image/articles/PruBSN-Effective-Ways-to-Protect-Yourself-Against-Dengue_Desktop.png',
      'publicationLogo':
          'https://www.prubsn.com.my/export/sites/prudential-pbtb/.galleries/logo-prubsn.png',
      'articleTitle': 'Five Effective Ways to Protect Yourself Against Dengue',
      'dateAndTime': 'Takaful Tips',
      'sampleText':
          'You\'ve probably heard the joke about Malaysia\'s four seasons: we experience the dry season, the durian season, the haze season and the Dengue season. All jokes aside though, while Dengue is at its peak during our country\'s monsoon period, which typically falls between October to February, transmission can and does occur all year round.',
      'maxLines': 3,
      'fullContent': 'Test'
    },
    {
      'articleImage':
          'https://assets.unilab.com.ph/uploads/Unilab/Articles/Dengue%20Prevention%20Tips%20at%20Home-940/AB_Dengue%20Prevention%20Tips%20at%20Home.jpg',
      'publicationLogo':
          'https://upload.wikimedia.org/wikipedia/commons/f/f0/Unilab_logo.png',
      'articleTitle': 'Dengue Prevention Tips at Home',
      'dateAndTime':
          'Medically Inspected by: Loreta D. Dayco MD, Maria Nathalia V. Paat-Capulong MD',
      'sampleText':
          'The start of the rainy season has been announced by the Philippine Atmospheric, Geophysical and Astronomical Services Administration (PAG-ASA) and while that can mean cooler temperatures this June, it also signals the start of the dengue season. Moist environments and more frequent bouts of rain makes it easier for mosquitoes to breed and to spread the disease within communities.',
      'maxLines': 2,
      'fullContent': 'Test'
    },
    {
      'articleImage':
          'https://images.onlymyhealth.com/imported/images/2023/August/26_Aug_2023/dengue-symptoms-in-kids-thumb.jpg',
      'publicationLogo':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/UNICEF_Logo.png/1200px-UNICEF_Logo.png',
      'articleTitle': 'Dengue: How to keep children safe',
      'dateAndTime': 'UNICEF South Asia',
      'sampleText':
          'It\'s rainy season in South Asia, an ideal time for disease outbreaks from stagnant and contaminated water — including dengue that can be passed on by mosquitoes.',
      'maxLines': 3,
      'fullContent': 'Test'
    },
  ];
}

class ArticleImage extends StatelessWidget {
  final String imageUrl;

  const ArticleImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.error, color: Colors.red),
      ),
    );
  }
}
