class CommunityData {
  static final List<Map<String, dynamic>> popularPosts = [
    {
      'username': 'Anonymous Pig',
      'whenPosted': '1 hour ago',
      'location': 'Cubao, Quezon City – Near Farmers Market',
      'date': 'February 14, 2025',
      'time': '2:30 PM',
      'reportType': 'Standing Water Found Near Market',
      'description':
          'Large puddles of stagnant water spotted near Farmers Market after the recent rain. Lots of mosquitoes flying around, and a neighbor just got diagnosed with dengue. This area needs urgent cleanup!',
      'numLikes': 2000,
      'numComments': 1000,
      'numShares': 1000,
      'images': <String>[
        'assets/images/polluted_water_1.jpg',
        'assets/images/dengue_patient_1.jpg'
      ],
      'iconUrl': 'assets/icons/person_1.svg', // Add iconUrl
    },
    {
      'username': 'Anonymous Unicorn',
      'whenPosted': '12 hours ago',
      'location': 'Novaliches, Quezon City – Near Bus Terminal',
      'date': 'February 14, 2025',
      'time': '7:30 PM',
      'reportType': 'Dengue Case and Mosquito Breeding Site',
      'description':
          'A neighbor was hospitalized due to dengue, and we noticed a clogged drainage near the bus terminal filled with stagnant water. Mosquitoes are swarming, especially in the evening. Immediate action is needed!',
      'numLikes': 1500,
      'numComments': 3000,
      'numShares': 2000,
      'images': <String>[],
      'iconUrl': 'assets/icons/person_2.svg', // Add iconUrl
    },
  ];

  static final List<Map<String, dynamic>> latestPosts = [
    {
      'username': 'Anonymous Cat',
      'whenPosted': '30 minutes ago',
      'location': 'Katipunan, Quezon City – Near Ateneo',
      'date': 'February 14, 2025',
      'time': '3:00 PM',
      'reportType': 'Mosquito Breeding Site',
      'description':
          'Found stagnant water in a nearby construction site. Mosquitoes are breeding rapidly. Immediate action is required!',
      'numLikes': 1000,
      'numComments': 2000,
      'numShares': 1000,
      'images': <String>[],
      'iconUrl': 'assets/icons/person_3.svg', // Add iconUrl
    },
  ];

  static final List<Map<String, dynamic>> myPosts = [
    {
      'username': 'My Post',
      'whenPosted': '2 days ago',
      'location': 'Tandang Sora, Quezon City – Near Market',
      'date': 'February 12, 2025',
      'time': '10:00 AM',
      'reportType': 'Stagnant Water in Drainage',
      'description':
          'Reported stagnant water in the drainage near the market. Authorities have been notified.',
      'numLikes': 10,
      'numComments': 2,
      'numShares': 1,
      'images': <String>[],
      'iconUrl': 'assets/icons/person_4.svg', // Add iconUrl
    },
  ];
}
