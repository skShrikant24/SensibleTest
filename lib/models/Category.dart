



import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  /// Image URL when provided by API; use placeholder when null/empty.
  final String? imageUrl;

  Category({required this.id, required this.name, this.imageUrl});

  factory Category.fromJson(Map<String, dynamic> json) {
    final image = json['Image'] ?? json['image'] ?? json['ImageUrl'] ?? json['imageUrl'];
    String? url="https://grabitt.in/${json["CategoryImage"]}";
    // if (image != null && image.toString().trim().isNotEmpty) {
    //   final s = image.toString().trim();
    //   url = s.startsWith('http') ? s : 'https://grabitt.in/uploads/$s';
    // }
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['CategoryName']?.toString() ?? json['name']?.toString() ?? '',
      imageUrl: url,
    );
  }
}