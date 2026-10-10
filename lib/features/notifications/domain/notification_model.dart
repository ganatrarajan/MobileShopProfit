class AppNotification {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final bool isRead;
  final String? createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at']?.toString(),
    );
  }
}
