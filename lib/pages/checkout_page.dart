import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_State/Cart.dart';
import '../utils/constants.dart';
import 'waiting_page.dart';
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String paymentMethod = 'card';
  final cart = CartService.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: StoreProfileTheme.background,
          appBar: AppBar(
            title: Text(
              'Checkout',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            backgroundColor: StoreProfileTheme.background,
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          bottomNavigationBar: _placeOrderBar(),

          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionTitle("Shipping Address"),
              _addressCard(),

              const SizedBox(height: 20),
              _sectionTitle("Payment Method"),
              _paymentCard(),

              const SizedBox(height: 20),
              _sectionTitle("Order Summary"),
              ...cart.items.map(_orderItem).toList(),

              const SizedBox(height: 16),
              _totalCard(),
            ],
          ),
        );
      },
    );
  }

  // ---------------- UI Components ----------------

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: StoreProfileTheme.accentPink),
    );
  }

  Widget _addressCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: _cardStyle(),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined,
              color: StoreProfileTheme.accentPink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "D-09, High Street,\nBangalore - 560098",
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              "Change",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: StoreProfileTheme.accentPink),
            ),
          )
        ],
      ),
    );
  }

  Widget _paymentCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: _cardStyle(),
      child: Column(
        children: [
          _paymentTile("card", Icons.credit_card, "Credit Card"),
          _divider(),
          _paymentTile("paypal", Icons.paypal, "PayPal"),
          _divider(),
          _paymentTile("coins", Icons.workspace_premium, "Coins (1000)"),
        ],
      ),
    );
  }

  Widget _paymentTile(String value, IconData icon, String title) {
    return RadioListTile<String>(
      value: value,
      groupValue: paymentMethod,
      onChanged: (v) => setState(() => paymentMethod = v!),
      activeColor: StoreProfileTheme.accentPink,
      title: Row(
        children: [
          Icon(icon, color: StoreProfileTheme.accentPink),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.poppins(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _orderItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: _cardStyle(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item.product.allImages.first,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  "Qty: ${item.quantity}",
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: StoreProfileTheme.accentPink.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          Text(
            "${AppConstants.currencySymbol}${item.total.toStringAsFixed(0)}",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: StoreProfileTheme.accentPink),
          ),
        ],
      ),
    );
  }

  Widget _totalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Subtotal",
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black87)),
          Text(
            "${AppConstants.currencySymbol}${cart.subtotal.toInt()}",
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: StoreProfileTheme.accentPink),
          ),
        ],
      ),
    );
  }

  Widget _placeOrderBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: StoreProfileTheme.accentPink,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: cart.items.isEmpty
              ? null
              : () {
                  // Navigate to waiting page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WaitingPage(),
                    ),
                  );
                },
          child: Text(
            "Place Order",
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
        ),
      ),
    );
  }

  Divider _divider() =>
      Divider(height: 1, color: StoreProfileTheme.border.withValues(alpha: 0.6));

  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: StoreProfileTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StoreProfileTheme.border, width: 0.5),
      boxShadow: [
        BoxShadow(
          color: StoreProfileTheme.border.withValues(alpha: 0.12),
          blurRadius: 10,
          offset: const Offset(0, 5),
        )
      ],
    );
  }
}
