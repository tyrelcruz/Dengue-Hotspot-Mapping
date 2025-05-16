class AdminPost {
  final String id;
  final String title;
  final String content;
  final DateTime publishDate;
  final String category;
  final List<String> images;
  final String references;
  final String adminId;
  final DateTime createdAt;
  final DateTime updatedAt;

  AdminPost({
    required this.id,
    required this.title,
    required this.content,
    required this.publishDate,
    required this.category,
    required this.images,
    required this.references,
    required this.adminId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminPost.fromJson(Map<String, dynamic> json) {
    return AdminPost(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      publishDate: json['publishDate'] != null
          ? DateTime.parse(json['publishDate'])
          : DateTime.now(),
      category: json['category'] ?? '',
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      references: json['references'] ?? '',
      adminId: json['adminId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'content': content,
      'publishDate': publishDate.toIso8601String(),
      'category': category,
      'images': images,
      'references': references,
      'adminId': adminId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
