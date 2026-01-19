import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GraBiTT/pages/components/header_pill.dart';
import 'package:GraBiTT/pages/notification_page.dart';

import '../../app_State/Cart.dart';
import '../cart_page.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onOpenDrawer,
    this.showGreeting = true, // 👈 optional prop with default = true
  });

  final VoidCallback onOpenDrawer;
  final bool showGreeting; // 👈 defines whether greeting should be shown

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onOpenDrawer,
                borderRadius: BorderRadius.circular(24),
                child: const CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage('assets/icons/profile.png'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const HeaderPill(
                      icon: Icons.workspace_premium_rounded,
                      text: '25',
                    ),
                    const SizedBox(width: 10),

                    /// 🛒 CART WITH BADGE
                    AnimatedBuilder(
                      animation: CartService.instance,
                      builder: (context, _) {
                        return HeaderPill(
                          key: const ValueKey('cart_icon'),
                          icon: Icons.shopping_cart_outlined,
                          badgeCount: CartService.instance.count,
                          shouldAnimate: CartService.instance.shouldAnimateCart,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CartPage()),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(width: 10),

                    HeaderPill(
                      icon: Icons.notifications_none_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationsPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),

            ],
          ),

          // 👇 Conditionally show greeting text
          if (showGreeting) ...[
            const SizedBox(height: 18),
            Text(
              'Hello, Anya !',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Keep up the great work.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
