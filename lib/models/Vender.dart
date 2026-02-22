class Vendor {
  final String id;
  final String name;
  final String categoryName;
  final String city;
  final String mobileNo;

  /// Multiple images — API gives 5 image fields
  final List<String> images;

  Vendor({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.city,
    required this.mobileNo,
    required this.images,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    /// helper function to build full url
    String? buildUrl(dynamic value) {
      if (value == null) return null;
      final s = value.toString().trim();
      if (s.isEmpty) return null;
      return s.startsWith('http') ? s : 'https://grabitt.in/$s'; // base url
    }

    final imageList = [
      buildUrl(json['Image1']),
      buildUrl(json['Image2']),
      buildUrl(json['Image3']),
      buildUrl(json['Image4']),
      buildUrl(json['Image5']),
    ].whereType<String>().toList(); // removes nulls

    return Vendor(
      id: json['VendorID']?.toString() ?? '',
      name: json['VendorName']?.toString() ?? '',
      categoryName: json['CategoryName']?.toString() ?? '',
      city: json['City']?.toString() ?? '',
      mobileNo: json['MobileNo']?.toString() ?? '',
      images: imageList,
    );
  }

  @override
  String toString() {
    return '''
Vendor(
  id: $id,
  name: $name,
  category: $categoryName,
  city: $city,
  mobile: $mobileNo,
  images: $images
)
''';
  }
}
