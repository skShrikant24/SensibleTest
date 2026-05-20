import 'package:GraBiTT/models/order_history_item.dart';
import 'package:GraBiTT/services/order_history_api_service.dart';
import 'package:GraBiTT/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderDetailsPage extends StatefulWidget {
  final OrderHistoryItem order;

  const OrderDetailsPage({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  bool _loading = true;
  OrderHistoryItem? _orderDetails;
  List<OrderHistoryProductItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() => _loading = true);

    final res = await getOrderDetails(widget.order.orderId);

    if (!mounted) return;

    setState(() {
      _orderDetails = res;
      _items = res?.items ?? [];
      _loading = false;
    });
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();

    if (s.contains('placed')) {
      return StoreProfileTheme.accentPink;
    }

    if (s.contains('accepted')) {
      return Colors.orange;
    }

    if (s.contains('assigned')) {
      return Colors.deepPurple;
    }

    if (s.contains('pickup')) {
      return Colors.blue;
    }

    if (s.contains('delivered')) {
      return Colors.green;
    }

    if (s.contains('rejected')) {
      return Colors.red;
    }

    return StoreProfileTheme.accentPink;
  }

  // String _statusMessage(String status) {
  //   final s = status.toLowerCase();

  //   if (s.contains('placed')) {
  //     return 'Order successfully placed';
  //   }

  //   if (s.contains('accepted')) {
  //     return 'Vendor accepted the order';
  //   }

  //   if (s.contains('assigned')) {
  //     return 'Rider assigned to the order';
  //   }

  //   if (s.contains('pickup')) {
  //     return 'Rider picked up the order';
  //   }

  //   if (s.contains('delivered')) {
  //     return 'Rider delivered the order';
  //   }

  //   if (s.contains('rejected')) {
  //     return 'Vendor rejected the order';
  //   }

  //   return status;
  // }

  String _formatDate(String raw) {
    final dt = widget.order.createdOnDateTime;

    if (dt == null) return raw;

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(dt.day)}-${two(dt.month)}-${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final order = _orderDetails ?? widget.order;

    return Scaffold(
      backgroundColor: StoreProfileTheme.background,
      appBar: AppBar(
        backgroundColor: StoreProfileTheme.background,
        elevation: 0,
        title: Text(
          'Order Details',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: StoreProfileTheme.accentPink,
              ),
            )
          : RefreshIndicator(
              color: StoreProfileTheme.accentPink,
              onRefresh: _loadDetails,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _headerCard(order),
                  const SizedBox(height: 14),
                  _deliverySection(order),
                  const SizedBox(height: 14),
                  _priceSection(order),
                  const SizedBox(height: 14),
                  _itemsSection(),
                ],
              ),
            ),
    );
  }

  // ================= HEADER =================

  Widget _headerCard(OrderHistoryItem order) {
    final statusColor = _statusColor(order.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StoreProfileTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: StoreProfileTheme.border.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: StoreProfileTheme.border.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order No: ${order.orderId}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: StoreProfileTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status.isEmpty ? 'Unknown' : order.status,
                  // order.status.isEmpty
                  //     ? 'Unknown'
                  //     : _statusMessage(order.status),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _detailRow(
            Icons.storefront_outlined,
            'Shop',
            order.shopDisplayName,
          ),
          const SizedBox(height: 10),
          _detailRow(
            Icons.calendar_month_outlined,
            'Placed On',
            _formatDate(order.createdOn),
          ),
          const SizedBox(height: 10),
          _detailRow(
            Icons.payments_outlined,
            'Payment',
            'Cash on Delivery',
          ),
        ],
      ),
    );
  }

  // ================= DELIVERY SECTION =================

  Widget _deliverySection(OrderHistoryItem order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StoreProfileTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: StoreProfileTheme.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Details',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: StoreProfileTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _detailRow(
            Icons.delivery_dining,
            'Rider Name',
            order.riderDisplayName.isEmpty
                ? 'Not Assigned'
                : order.riderDisplayName,
          ),
          const SizedBox(height: 10),
          _detailRow(
            Icons.phone,
            'Mobile No',
            order.riderDisplayMobile.isEmpty
                ? 'Not Available'
                : order.riderDisplayMobile,
          ),
          const SizedBox(height: 10),
          _detailRow(
            Icons.two_wheeler,
            'Bike No',
            order.bikeDisplayNumber.isEmpty
                ? 'Not Assigned'
                : order.bikeDisplayNumber,
          ),
        ],
      ),
    );
  }

  // ================= PRICE SECTION =================

  Widget _priceSection(OrderHistoryItem order) {
    final bool showNewUserDiscount =
        order.isNewUserDiscountApplied && order.newUserDiscountAmountValue > 0;

    final bool showEvenOrderDiscount = order.isEvenOrderDiscountApplied &&
        order.evenOrderDiscountAmountValue > 0;

    final bool showDeliveryCharge = order.deliveryChargeValue > 0;

    final bool showGST = order.gstValue > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StoreProfileTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: StoreProfileTheme.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Subtotal
          _priceRow(
            'Subtotal',
            order.subtotalValue,
          ),

          // GST
          if (showGST)
            _priceRow(
              'GST (${order.gstPercent}%)',
              order.gstValue,
            ),

          // Delivery Charge
          if (showDeliveryCharge)
            _priceRow(
              'Delivery Charge',
              order.deliveryChargeValue,
            ),

          // New User Discount
          if (showNewUserDiscount)
            _priceRow(
              'New User Discount (${order.newUserDiscountPercent}% OFF)',
              -order.newUserDiscountAmountValue,
              valueColor: Colors.green,
            ),

          // Even Order Discount
          if (showEvenOrderDiscount)
            _priceRow(
              'Even Order Discount (${order.evenOrderDiscountPercent}% OFF)',
              -order.evenOrderDiscountAmountValue,
              valueColor: Colors.green,
            ),

          // Service Fee
          _priceRow(
            'Service Fee',
            order.serviceFeeValue,
            showNil: true,
          ),

          // Handling Fee
          _priceRow(
            order.handlingFeeText.isNotEmpty
                ? order.handlingFeeText
                : 'Handling Fee',
            order.handlingFeeValue,
            showNil: true,
          ),

          // Packaging Fee
          _priceRow(
            'Packaging Fee',
            order.packagingFeeValue,
            showNil: true,
          ),

          const Divider(height: 24),

          // Final Total
          _priceRow(
            'Final Total',
            order.finalTotalValue,
            isFinal: true,
          ),
        ],
      ),
    );
  }
  // ================= ITEMS SECTION =================

  Widget _itemsSection() {
    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: StoreProfileTheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 10),
            Text(
              'No items found',
              style: GoogleFonts.poppins(
                color: StoreProfileTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StoreProfileTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: StoreProfileTheme.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ordered Items',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: StoreProfileTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ..._items.map(_itemTile),
        ],
      ),
    );
  }

  // ================= ITEM TILE =================

  Widget _itemTile(OrderHistoryProductItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.imageUrl.isEmpty
                ? Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 150),
                    memCacheWidth: 250,
                    maxWidthDiskCache: 350,
                    placeholder: (context, url) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      );
                    },
                    errorWidget: (context, url, error) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image_outlined,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName.isEmpty ? 'Product' : item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: StoreProfileTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Qty: ${item.quantity.isEmpty ? '0' : item.quantity}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: StoreProfileTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Price: ${AppConstants.currencySymbol}${item.price.isEmpty ? '0' : item.price}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: StoreProfileTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${AppConstants.currencySymbol}${item.totalPrice}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: StoreProfileTheme.accentPink,
            ),
          ),
        ],
      ),
    );
  }

  // ================= COMMON ROWS =================

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: StoreProfileTheme.accentPink,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: StoreProfileTheme.textPrimary,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: StoreProfileTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _priceRow(
    String label,
    double amount, {
    bool isFinal = false,
    Color? valueColor,
    bool showNil = false,
  }) {
    final bool isNegative = amount < 0;
    final bool isZero = amount == 0;

    String amountText;

    if (showNil && isZero) {
      amountText = "Nil";
    } else if (isNegative) {
      amountText =
          '- ${AppConstants.currencySymbol}${amount.abs().toStringAsFixed(0)}';
    } else {
      amountText = '${AppConstants.currencySymbol}${amount.toStringAsFixed(0)}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isFinal ? 15 : 13,
                fontWeight: isFinal ? FontWeight.w600 : FontWeight.w400,
                color: isFinal ? Colors.black : StoreProfileTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            amountText,
            style: GoogleFonts.poppins(
              fontSize: isFinal ? 18 : 14,
              fontWeight: isFinal ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? StoreProfileTheme.accentPink,
            ),
          ),
        ],
      ),
    );
  }
}
