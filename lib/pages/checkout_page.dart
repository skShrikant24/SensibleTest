import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_State/Cart.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
          const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // 🟢 Place Order Button
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
  }

  // ---------------- UI Components ----------------

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  Widget _addressCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: _cardStyle(),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined,
              color: Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "D-09, High Street,\nBangalore - 560098",
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text("Change"),
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
      activeColor: Colors.redAccent,
      title: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700),
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
                      fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            "₹${(item.product.discountPrice * item.quantity).toInt()}",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600),
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
              style: GoogleFonts.poppins(fontSize: 14)),
          Text(
            "₹${cart.subtotal.toInt()}",
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold),
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
            backgroundColor: Colors.redAccent,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () {},
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

  Divider _divider() => Divider(height: 1, color: Colors.grey.shade200);

  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 5),
        )
      ],
    );
  }
}
