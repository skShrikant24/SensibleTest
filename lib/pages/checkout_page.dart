import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool creditCard = false;
  bool paypal = false;
  bool coins = false;

  @override
  Widget build(BuildContext context) {
    final orderItems = [
      {'name': 'Disha Group T-Shirt', 'size': 'M', 'price': 500, 'image': 'assets/images/tshirt.png'},
      {'name': 'Disha Group T-Shirt', 'size': 'M', 'price': 500, 'image': 'assets/images/tshirt.png'},
      {'name': 'Disha Group T-Shirt', 'size': 'M', 'price': 500, 'image': 'assets/images/tshirt.png'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                Text('Shipping Address', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'd-09, high street, banglore-00986',
                    hintStyle: GoogleFonts.poppins(fontSize: 13),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Payment Method', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                SwitchListTile(
                  title: const Text('Credit Card'),
                  value: creditCard,
                  onChanged: (val) => setState(() => creditCard = val),
                ),
                SwitchListTile(
                  title: const Text('PayPal'),
                  value: paypal,
                  onChanged: (val) => setState(() => paypal = val),
                ),
                SwitchListTile(
                  title: Row(
                    children: const [
                      Icon(Icons.workspace_premium_rounded, color: Colors.amber),
                      SizedBox(width: 6),
                      Text('1000'),
                    ],
                  ),
                  value: coins,
                  onChanged: (val) => setState(() => coins = val),
                ),
                const SizedBox(height: 20),
                Text('Order Summary', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                ...orderItems.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(item['image'] as String, width: 50, height: 50, fit: BoxFit.cover),
                    ),
                    title: Text(item['name'] as String, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: Text('Size ${item['size']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                    trailing: Text('₹${item['price']}', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                )),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    Text('₹500', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Place Order', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
