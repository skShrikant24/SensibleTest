import 'package:GraBiTT/utils/shared_classes.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GraBiTT/models/order_history_item.dart';
import 'package:GraBiTT/services/auth_service.dart';
import 'package:GraBiTT/services/order_history_api_service.dart';
import 'package:GraBiTT/utils/constants.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  bool _loading = true;
  String? _userId;
  List<OrderHistoryItem> _orders = [];
  final Set<String> _ratingSubmittingOrders = <String>{};
  final Set<String> _ratedOrders = <String>{};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final user = await AuthService.instance.getSavedUser();
    final uid = user?['ID']?.toString() ?? user?['UserID']?.toString() ?? '';
    if (uid.isEmpty) {
      if (mounted) {
        setState(() {
          _userId = null;
          _orders = [];
          _loading = false;
        });
      }
      return;
    }
    final list = await getOrderHistoryByUser(uid);
    print(list);
    if (!mounted) return;
    setState(() {
      _userId = uid;
      _orders = list;
      _loading = false;
    });
  }

  Future<void> _openRatingSheet(OrderHistoryItem order) async {
    int selectedRating = 5;
    final noteController = TextEditingController();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Rate your delivery rider',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: StoreProfileTheme.accentPink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order.riderDisplayName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: StoreProfileTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final star = index + 1;
                          final selected = star <= selectedRating;
                          return IconButton(
                            onPressed: () =>
                                setLocalState(() => selectedRating = star),
                            icon: Icon(
                              selected
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: selected
                                  ? Colors.amber[700]
                                  : Colors.grey[400],
                              size: 34,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add a short note (optional)',
                          filled: true,
                          fillColor: StoreProfileTheme.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: StoreProfileTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: StoreProfileTheme.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: StoreProfileTheme.accentPink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx, true);
                            await _submitRating(
                              orderId: order.orderId,
                              rating: selectedRating,
                              note: noteController.text.trim(),
                            );
                          },
                          child: Text(
                            'Submit rating',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    noteController.dispose();
    if (submitted == true && mounted) {
      await _loadOrders();
    }
  }

  Future<void> _submitRating({
    required String orderId,
    required int rating,
    required String note,
  }) async {
    setState(() => _ratingSubmittingOrders.add(orderId));
    final ok = await submitRiderRating(
      orderId: orderId,
      rating: rating.toString(),
      note: note,
    );
    if (!mounted) return;
    setState(() {
      _ratingSubmittingOrders.remove(orderId);
      if (ok) _ratedOrders.add(orderId);
    });
    if (ok) {
      ToastMessage.success(
          context: context, msg: "Thanks! Rider rating submitted.");
    } else {
      ToastMessage.error(
          context: context, msg: 'Could not submit rating. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StoreProfileTheme.background,
      appBar: AppBar(
        backgroundColor: StoreProfileTheme.background,
        elevation: 0,
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: StoreProfileTheme.accentPink),
            )
          : _userId == null || _userId!.isEmpty
              ? _buildLoggedOutState()
              : _orders.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: StoreProfileTheme.accentPink,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _OrderCard(
                            order: order,
                            isRatingSubmitting:
                                _ratingSubmittingOrders.contains(order.orderId),
                            isRated: _ratedOrders.contains(order.orderId),
                            onTapRateRider: () => _openRatingSheet(order),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildLoggedOutState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 66, color: Colors.grey[400]),
            const SizedBox(height: 14),
            Text(
              'Please log in to view your orders.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: StoreProfileTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed and ongoing orders will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: StoreProfileTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _loadOrders,
              style: OutlinedButton.styleFrom(
                foregroundColor: StoreProfileTheme.accentPink,
                side: BorderSide(color: StoreProfileTheme.accentPink),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderHistoryItem order;
  final bool isRatingSubmitting;
  final bool isRated;
  final VoidCallback onTapRateRider;

  const _OrderCard({
    required this.order,
    required this.isRatingSubmitting,
    required this.isRated,
    required this.onTapRateRider,
  });

  bool get _isDelivered {
    final s = order.status.toLowerCase();
    return s.contains('deliver') || s.contains('complete');
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
    final dt = order.createdOnDateTime;
    if (dt == null) return raw;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}-${two(dt.month)}-${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: StoreProfileTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: StoreProfileTheme.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: StoreProfileTheme.border.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order No: ${order.orderId}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: StoreProfileTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
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
            const SizedBox(height: 8),
            Text(
              'Placed on: ${_formatDate(order.createdOn)}',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: StoreProfileTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _detailRow(
                Icons.storefront_outlined, 'Shop', order.shopDisplayName),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: StoreProfileTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppConstants.currencySymbol}${order.totalAmountValue.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: StoreProfileTheme.accentPink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            //   decoration: BoxDecoration(
            //     color: const Color(0xFFF8F3FF),
            //     borderRadius: BorderRadius.circular(10),
            //     border: Border.all(color: StoreProfileTheme.border.withValues(alpha: 0.6)),
            //   ),
            //   child: Row(
            //     children: [
            //       Icon(Icons.pin_outlined, size: 18, color: StoreProfileTheme.accentPink),
            //       const SizedBox(width: 8),
            //       Expanded(
            //         child: Text(
            //           'Delivery OTP: 1234',
            //           style: GoogleFonts.poppins(
            //             fontSize: 12.5,
            //             fontWeight: FontWeight.w600,
            //             color: StoreProfileTheme.textPrimary,
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // const SizedBox(height: 12),
            if (order.items.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: StoreProfileTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children:
                      order.items.map((item) => _orderItemTile(item)).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Divider(
                color: StoreProfileTheme.border.withValues(alpha: 0.7),
                height: 1),
            const SizedBox(height: 10),
            _detailRow(
                Icons.delivery_dining, 'Rider Name', order.riderDisplayName),
            const SizedBox(height: 8),
            _detailRow(Icons.phone, 'Mobile No', order.riderDisplayMobile),
            const SizedBox(height: 8),
            _detailRow(
                Icons.two_wheeler, 'Rider Bike No', order.bikeDisplayNumber),
            if (_isDelivered) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      (isRatingSubmitting || isRated) ? null : onTapRateRider,
                  icon: isRatingSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isRated
                              ? Icons.check_circle_outline
                              : Icons.star_outline_rounded,
                          size: 18,
                        ),
                  label: Text(
                    isRated ? 'Rider rated' : 'Rate rider',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: StoreProfileTheme.accentPink,
                    side: BorderSide(color: StoreProfileTheme.accentPink),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: StoreProfileTheme.accentPink),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: StoreProfileTheme.textPrimary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: StoreProfileTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _orderItemTile(OrderHistoryProductItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl.isEmpty
                ? Container(
                    width: 52,
                    height: 52,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported_outlined,
                        size: 18),
                  )
                : Image.network(
                    item.imageUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 52,
                      height: 52,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image_outlined, size: 18),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
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
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity.isEmpty ? '0' : item.quantity}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: StoreProfileTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${AppConstants.currencySymbol}${item.totalPriceValue.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: StoreProfileTheme.accentPink,
            ),
          ),
        ],
      ),
    );
  }
}
