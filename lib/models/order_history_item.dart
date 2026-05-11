class OrderHistoryItem {
  final String orderId;
  final String status;
  final String createdOn;
  final String riderName;
  final String riderMobile;
  final String bikeNumber;
  final String shopName;

  final List<OrderHistoryProductItem> items;

  // ================= INVOICE FIELDS =================

  final String subtotal;
  final String gst;
  final int gstPercent;

  final String deliveryCharge;

  final bool isNewUserDiscountApplied;
  final int newUserDiscountPercent;
  final String newUserDiscountAmount;

  final bool isEvenOrderDiscountApplied;
  final int evenOrderDiscountPercent;
  final String evenOrderDiscountAmount;

  final String serviceFee;

  final bool isHandlingFeeApplied;
  final String handlingFee;
  final String handlingFeeText;

  final String packagingFee;
  final String finalTotal;

  const OrderHistoryItem({
    required this.orderId,
    required this.status,
    required this.createdOn,
    required this.riderName,
    required this.riderMobile,
    required this.bikeNumber,
    required this.shopName,
    required this.items,
    required this.subtotal,
    required this.gst,
    required this.gstPercent,
    required this.deliveryCharge,
    required this.isNewUserDiscountApplied,
    required this.newUserDiscountPercent,
    required this.newUserDiscountAmount,
    required this.isEvenOrderDiscountApplied,
    required this.evenOrderDiscountPercent,
    required this.evenOrderDiscountAmount,
    required this.serviceFee,
    required this.isHandlingFeeApplied,
    required this.handlingFee,
    required this.handlingFeeText,
    required this.packagingFee,
    required this.finalTotal,
  });

  factory OrderHistoryItem.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => v?.toString().trim() ?? '';

    int intValue(dynamic v) {
      if (v == null) return 0;
      return int.tryParse(v.toString()) ?? 0;
    }

    bool boolValue(dynamic v) {
      if (v == null) return false;

      if (v is bool) return v;

      final value = v.toString().toLowerCase();

      return value == 'true' || value == '1';
    }

    return OrderHistoryItem(
      orderId: str(json['OrderID']),
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

      // ================= INVOICE =================

      subtotal: str(json['Subtotal']),
      gst: str(json['GST']),
      gstPercent: intValue(json['GSTPercent']),

      deliveryCharge: str(json['DeliveryCharge']),

      isNewUserDiscountApplied: boolValue(
        json['IsNewUserDiscountApplied'],
      ),

      newUserDiscountPercent: intValue(
        json['NewUserDiscountPercent'],
      ),

      newUserDiscountAmount: str(
        json['NewUserDiscountAmount'],
      ),

      isEvenOrderDiscountApplied: boolValue(
        json['IsEvenOrderDiscountApplied'],
      ),

      evenOrderDiscountPercent: intValue(
        json['EvenOrderDiscountPercent'],
      ),

      evenOrderDiscountAmount: str(
        json['EvenOrderDiscountAmount'],
      ),

      serviceFee: str(json['ServiceFee']),

      isHandlingFeeApplied: boolValue(
        json['IsHandlingFeeApplied'],
      ),

      handlingFee: str(json['HandlingFee']),

      handlingFeeText: str(json['HandlingFeeText']),

      packagingFee: str(json['PackagingFee']),

      finalTotal: str(json['FinalTotal']),
    );
  }

  double get finalTotalValue => double.tryParse(finalTotal) ?? 0;

  double get subtotalValue => double.tryParse(subtotal) ?? 0;

  double get gstValue => double.tryParse(gst) ?? 0;

  double get deliveryChargeValue => double.tryParse(deliveryCharge) ?? 0;

  double get newUserDiscountAmountValue =>
      double.tryParse(newUserDiscountAmount) ?? 0;

  double get evenOrderDiscountAmountValue =>
      double.tryParse(evenOrderDiscountAmount) ?? 0;

  double get serviceFeeValue => double.tryParse(serviceFee) ?? 0;

  double get handlingFeeValue => double.tryParse(handlingFee) ?? 0;

  double get packagingFeeValue => double.tryParse(packagingFee) ?? 0;

  DateTime? get createdOnDateTime {
    if (createdOn.isEmpty) return null;

    final raw = createdOn.replaceFirst(' ', 'T');

    return DateTime.tryParse(raw);
  }

  String get riderDisplayName =>
      riderName.isEmpty ? 'Not assigned yet' : riderName;

  String get riderDisplayMobile =>
      riderMobile.isEmpty ? 'Contact unavailable' : riderMobile;

  String get bikeDisplayNumber =>
      bikeNumber.isEmpty ? 'Bike details unavailable' : bikeNumber;

  String get shopDisplayName =>
      shopName.isEmpty ? 'Shop details unavailable' : shopName;
}

class OrderHistoryProductItem {
  final String productId;
  final String productName;
  final String quantity;
  final String price;
  final String totalPrice;
  final String image;

  const OrderHistoryProductItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    required this.image,
  });

  factory OrderHistoryProductItem.fromJson(
    Map<String, dynamic> json,
  ) {
    String str(dynamic v) => v?.toString().trim() ?? '';

    return OrderHistoryProductItem(
      productId: str(json['ProductID']),
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

  double get quantityValue => double.tryParse(quantity) ?? 0;

  double get priceValue => double.tryParse(price) ?? 0;

  double get totalPriceValue => double.tryParse(totalPrice) ?? 0;
}
