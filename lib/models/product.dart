import 'package:grabitt/models/vendor_product.dart';

class Product {
  final String id;
  final String name;
  final String categoryName;
  final String originalPrice;
  final String discountPrice;
  final String discountPercent;
  final String? description;
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
    this.description,
    required this.productImage,
    required this.image1,
    required this.image2,
    required this.image3,
    required this.image4,
    required this.image5,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['ProductID']?.toString() ?? '',
      name: json['ProductName']?.toString() ?? '',
      categoryName: json['CategoryName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      originalPrice: json['OriginalPrice']?.toString() ?? '0',
      discountPrice: json['DiscountPrice']?.toString() ?? '0',
      discountPercent: json['DiscountPercent']?.toString() ?? '0',
      productImage: json['ProductImage']?.toString() ?? '',
      image1: json['Image1']?.toString() ?? '',
      image2: json['Image2']?.toString() ?? '',
      image3: json['Image3']?.toString() ?? '',
      image4: json['Image4']?.toString() ?? '',
      image5: json['Image5']?.toString() ?? '',
    );
  }

  factory Product.fromVendor(VendorProduct v) {
    return Product(
      id: v.id,
      name: v.name,
      categoryName: v.categoryName,
      description: v.description,
      originalPrice: v.originalPrice,
      discountPrice: v.discountPrice,
      discountPercent: v.discountPercent,
      productImage: v.images.isNotEmpty ? v.images.first : '',
      image1: v.images.length > 1 ? v.images[1] : '',
      image2: v.images.length > 2 ? v.images[2] : '',
      image3: v.images.length > 3 ? v.images[3] : '',
      image4: v.images.length > 4 ? v.images[4] : '',
      image5: v.images.length > 5 ? v.images[5] : '',
    );
  }

  Map<String, dynamic> toJson() => {
        'ProductID': id,
        'ProductName': name,
        'CategoryName': categoryName,
        'OriginalPrice': originalPrice,
        'DiscountPrice': discountPrice,
        'DiscountPercent': discountPercent,
        'ProductImage': productImage,
        'description': description ?? '',
        'Image1': image1,
        'Image2': image2,
        'Image3': image3,
        'Image4': image4,
        'Image5': image5,
      };

  /// All non-empty images with resolved URLs.
  List<String> get allImages => [
        productImage,
        image1,
        image2,
        image3,
        image4,
        image5,
      ]
          .where((img) => img.isNotEmpty)
          .map(
              (img) => img.startsWith('http') ? img : 'https://grabitt.in/$img')
          .toList();
}
