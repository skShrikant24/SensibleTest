class OrderHistoryItem {
  final String orderId;
  final String totalAmount;
  final String status;
  final String createdOn;
  final String riderName;
  final String riderMobile;
  final String bikeNumber;
  final String shopName;
  final List<OrderHistoryProductItem> items;

  const OrderHistoryItem({
    required this.orderId,
    required this.totalAmount,
    required this.status,
    required this.createdOn,
    required this.riderName,
    required this.riderMobile,
    required this.bikeNumber,
    required this.shopName,
    required this.items,
  });

  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => v?.toString().trim() ?? '';
    return OrderHistoryItem(
      orderId: str(json['OrderID']),
      totalAmount: str(json['TotalAmount']),
      status: str(json['Status']),
      createdOn: str(json['CreatedOn']),
      riderName: str(json['RiderName']),
      riderMobile: str(json['RiderMobile']),
      bikeNumber: str(json['BikeNumber']),
      shopName: str(json['ShopName']),
      items: (json['Items'] is List)
          ? (json['Items'] as List)
              .map(
                (e) => OrderHistoryProductItem.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
    );
  }

  double get totalAmountValue => double.tryParse(totalAmount) ?? 0;

  DateTime? get createdOnDateTime {
    if (createdOn.isEmpty) return null;
    final raw = createdOn.replaceFirst(' ', 'T');
    return DateTime.tryParse(raw);
  }

  String get riderDisplayName => riderName.isEmpty ? 'Not assigned yet' : riderName;

  String get riderDisplayMobile =>
      riderMobile.isEmpty ? 'Contact unavailable' : riderMobile;

  String get bikeDisplayNumber =>
      bikeNumber.isEmpty ? 'Bike details unavailable' : bikeNumber;

  String get shopDisplayName =>
      shopName.isEmpty ? 'Shop details unavailable' : shopName;
}

class OrderHistoryProductItem {
  final String productName;
  final String quantity;
  final String price;
  final String totalPrice;
  final String image;

  const OrderHistoryProductItem({
    required this.productName,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    required this.image,
  });

  factory OrderHistoryProductItem.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => v?.toString().trim() ?? '';
    return OrderHistoryProductItem(
      productName: str(json['ProductName']),
      quantity: str(json['Quantity']),
      price: str(json['Price']),
      totalPrice: str(json['TotalPrice']),
      image: str(json['Image']),
    );
  }

  String get imageUrl {
    if (image.isEmpty) return '';
    final normalized = image.replaceFirst('~/', '');
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    return 'https://grabitt.in/$normalized';
  }

  double get totalPriceValue => double.tryParse(totalPrice) ?? 0;
}
