import 'package:flutter/material.dart';
class Product {
  final String id;
  final String name;
  final String categoryName;
  final double originalPrice;
  final double discountPrice;
  final String discountPercent;

  final String productImage;
  final String image1;
  final String image2;
  final String image3;
  final String image4;
  final String image5;

  Product({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.originalPrice,
    required this.discountPrice,
    required this.discountPercent,
    required this.productImage,
    required this.image1,
    required this.image2,
    required this.image3,
    required this.image4,
    required this.image5,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['ProductID'] ?? '',
      name: json['ProductName'] ?? '',
      categoryName: json['CategoryName'] ?? '',
      originalPrice: double.tryParse(json['OriginalPrice'] ?? '0') ?? 0,
      discountPrice: double.tryParse(json['DiscountPrice'] ?? '0') ?? 0,
      discountPercent: json['DiscountPercent'] ?? '0',

      productImage: json['ProductImage'] ?? '',
      image1: json['Image1'] ?? '',
      image2: json['Image2'] ?? '',
      image3: json['Image3'] ?? '',
      image4: json['Image4'] ?? '',
      image5: json['Image5'] ?? '',
    );
  }

  /// 🔥 Helper to get all images safely
  List<String> get allImages => [
    productImage,
    image1,
    image2,
    image3,
    image4,
    image5,
  ]
      .where((img) => img.isNotEmpty)
      .map((img) => "https://grabitt.in/$img")
      .toList();
}

