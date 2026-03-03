import 'package:flutter/material.dart';

class ToastMessage {
  static void _showToast({
    required BuildContext context,
    required String msg,
    required Color backgroundColor,
    required IconData icon,
    Color textColor = Colors.white,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _BottomToastWidget(
        msg: msg,
        backgroundColor: backgroundColor,
        icon: icon,
        textColor: textColor,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
  }

  /// ✅ Success
  static void success({
    required BuildContext context,
    required String msg,
  }) {
    _showToast(
      context: context,
      msg: msg,
      backgroundColor: Colors.green.shade600,
      icon: Icons.check_circle,
    );
  }

  /// ❌ Error
  static void error({
    required BuildContext context,
    required String msg,
  }) {
    _showToast(
      context: context,
      msg: msg,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error,
    );
  }

  /// ⚠️ Warning
  static void warning({
    required BuildContext context,
    required String msg,
  }) {
    _showToast(
      context: context,
      msg: msg,
      backgroundColor: Colors.orange.shade700,
      icon: Icons.warning_amber_rounded,
    );
  }

  /// ℹ️ Info
  static void info({
    required BuildContext context,
    required String msg,
  }) {
    _showToast(
      context: context,
      msg: msg,
      backgroundColor: Colors.blue.shade600,
      icon: Icons.info,
    );
  }

  /// 🔔 Normal
  static void normal({
    required BuildContext context,
    required String msg,
  }) {
    _showToast(
      context: context,
      msg: msg,
      backgroundColor: Colors.grey.shade800,
      icon: Icons.notifications,
    );
  }
}

class _BottomToastWidget extends StatefulWidget {
  final String msg;
  final Color backgroundColor;
  final IconData icon;
  final Color textColor;
  final VoidCallback onDismiss;

  const _BottomToastWidget({
    required this.msg,
    required this.backgroundColor,
    required this.icon,
    required this.textColor,
    required this.onDismiss,
  });

  @override
  State<_BottomToastWidget> createState() => _BottomToastWidgetState();
}

class _BottomToastWidgetState extends State<_BottomToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () async {
      await _controller.reverse();
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 30,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.textColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.msg,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}