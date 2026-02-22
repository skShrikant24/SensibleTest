class VendorProduct {
  final String id;
  final String name;
  final String categoryName;
  final String originalPrice;
  final String discountPrice;
  final String discountPercent;
  final List<String> images;

  VendorProduct({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.originalPrice,
    required this.discountPrice,
    required this.discountPercent,
    required this.images,
  });

  factory VendorProduct.fromJson(Map<String, dynamic> json) {
    List<String> imgs = [];

    // for (int i = 1; i <= 5; i++) {
    //   final key = i == 1 ? 'ProductImage' : 'Image$i';
    //   if (json[key] != null && json[key].toString().isNotEmpty) {
    //     imgs.add("https://grabitt.in/${json[key]}");
    //   }
    // }

    for (int i = 1; i <= 5; i++) {
      final key = i == 1 ? 'ProductImage' : 'Image$i';

      if (json[key] != null && json[key].toString().isNotEmpty) {
        String imagePath = json[key].toString();

        // Remove "~/" if present
        if (imagePath.startsWith("~/")) {
          imagePath = imagePath.replaceFirst("~/", "");
        }

        imgs.add("https://grabitt.in/$imagePath");
      }
    }

    return VendorProduct(
      id: json['ProductID'].toString(),
      name: json['ProductName'] ?? '',
      categoryName: json['CategoryName'] ?? '',
      originalPrice: json['OriginalPrice']?? 0,
      discountPrice: json['DiscountPrice'] ?? 0,
      discountPercent: json['DiscountPercent'] ?? 0,
      images: imgs,
    );
  }
}
