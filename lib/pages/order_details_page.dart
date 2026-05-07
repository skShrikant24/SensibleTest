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
      _items = res;
      _loading = false;
    });
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();

    if (s.contains('assign')) return Colors.orange;
    if (s.contains('accept')) return Colors.green;
    if (s.contains('pickup')) return Colors.blue;
    if (s.contains('deliver')) return Colors.green;

    if (s.contains('reject') || s.contains('cancel') || s.contains('fail')) {
      return Colors.red;
    }

    return StoreProfileTheme.accentPink;
  }

  String _formatDate(String raw) {
    final dt = widget.order.createdOnDateTime;

    if (dt == null) return raw;

    String two(int n) => n.toString().padLeft(2, '0');

    return '${two(dt.day)}-${two(dt.month)}-${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

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
          _priceRow(
            'Item Total',
            '${AppConstants.currencySymbol}${order.totalAmount}',
          ),
          // const SizedBox(height: 10),
          // _priceRow(
          //   'Delivery Fee',
          //   '${AppConstants.currencySymbol}0',
          // ),
          const Divider(height: 24),
          _priceRow(
            'Grand Total',
            '${AppConstants.currencySymbol}${order.totalAmount}',
            isBold: true,
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
    String title,
    String value, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: StoreProfileTheme.textPrimary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: StoreProfileTheme.accentPink,
          ),
        ),
      ],
    );
  }
}
