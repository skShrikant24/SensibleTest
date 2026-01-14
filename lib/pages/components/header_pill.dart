import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class HeaderPill extends StatelessWidget {
  const HeaderPill({
    super.key,
    required this.icon,
    this.text,
    this.badgeCount,
    this.onTap,
  });

  final IconData icon;
  final String? text;
  final int? badgeCount; // 👈 NEW
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: text == null ? 10 : 12,
          vertical: 8,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFFFA000), size: 20),
                if (text != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    text!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),

            /// 🔴 BADGE
            if (badgeCount != null && badgeCount! > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount! > 9 ? '9+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return onTap != null
        ? GestureDetector(onTap: onTap, child: pill)
        : pill;
  }
}
