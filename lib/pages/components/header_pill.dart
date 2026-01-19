import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class HeaderPill extends StatefulWidget {
  const HeaderPill({
    super.key,
    required this.icon,
    this.text,
    this.badgeCount,
    this.onTap,
    this.shouldAnimate = false,
  });

  final IconData icon;
  final String? text;
  final int? badgeCount; // 👈 NEW
  final VoidCallback? onTap;
  final bool shouldAnimate;

  @override
  State<HeaderPill> createState() => _HeaderPillState();
}

class _HeaderPillState extends State<HeaderPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _showQuote = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void didUpdateWidget(HeaderPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldAnimate && !oldWidget.shouldAnimate) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    setState(() {
      _showQuote = true;
    });
    _controller.forward().then((_) {
      _controller.reverse().then((_) {
        setState(() {
          _showQuote = false;
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          horizontal: widget.text == null ? 10 : 12,
          vertical: 8,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Row(
                children: [
                  Icon(widget.icon, color: const Color(0xFFFFA000), size: 20),
                  if (widget.text != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      widget.text!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            /// 🔴 BADGE
            if (widget.badgeCount != null && widget.badgeCount! > 0)
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
                    widget.badgeCount! > 9 ? '9+' : widget.badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            /// 💬 QUOTE: "Got it!"
            if (_showQuote)
              Positioned(
                bottom: -35,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _showQuote ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '"Got it!"',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return widget.onTap != null
        ? GestureDetector(onTap: widget.onTap, child: pill)
        : pill;
  }
}
