import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final todayNotifications = [
      {'icon': Icons.notifications_none, 'title': 'Course Update', 'time': '10:30 AM'},
      {'icon': Icons.local_shipping_outlined, 'title': 'Order Shipped', 'time': '11:45 AM'},
      {'icon': Icons.card_giftcard_outlined, 'title': 'Referral Reward', 'time': '12:30 PM'},
    ];

    final yesterdayNotifications = [
      {'icon': Icons.notifications_none, 'title': 'Course Update', 'time': '9:15 AM'},
      {'icon': Icons.inventory_2_outlined, 'title': 'Order Delivered', 'time': '10:00 AM'},
      {'icon': Icons.card_giftcard_outlined, 'title': 'Referral Reward', 'time': '11:00 AM'},
      {'icon': Icons.card_giftcard_outlined, 'title': 'Referral Reward', 'time': '11:00 AM'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(
              color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔘 Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {},
                  child: Text("Mark as read",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500, color: Colors.black)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {},
                  child: Text("Clear all",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection("Today", todayNotifications),
                    const SizedBox(height: 20),
                    _buildSection("Yesterday", yesterdayNotifications),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 12),
        ...items.map((item) => _NotificationItem(
          icon: item['icon'],
          title: item['title'],
          time: item['time'],
        )),
      ],
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F3F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(time,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          const Icon(Icons.more_vert, color: Colors.black54),
        ],
      ),
    );
  }
}
