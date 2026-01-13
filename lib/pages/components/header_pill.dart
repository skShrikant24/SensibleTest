import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class HeaderPill extends StatelessWidget {
  const HeaderPill({
    super.key,
    required this.icon,
    this.text,
    this.onTap, // 👈 added
  });

  final IconData icon;
  final String? text;
  final VoidCallback? onTap; // 👈 optional

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
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFFA000), size: 20),
            if (text != null) ...[
              const SizedBox(width: 8),
              Text(
                text!,
                style: GoogleFonts.poppins(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );

    // Wrap in GestureDetector only if clickable
    return onTap != null
        ? GestureDetector(onTap: onTap, child: pill)
        : pill;
  }
}
