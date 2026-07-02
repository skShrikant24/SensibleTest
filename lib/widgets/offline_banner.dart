// GRABIIT REVIEW
// New file: OfflineBanner widget — wraps child with animated top banner when offline
// Wired in app.dart around SplashPage so it covers all screens

import 'package:flutter/material.dart';
import 'package:grabitt/services/network_service.dart';
import 'package:provider/provider.dart';

/// Wraps [child] with a persistent animated offline banner at the top.
/// Place once at the root of your widget tree (in app.dart around SplashPage).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: NetworkService.instance,
      child: Column(
        children: [
          _BannerSliver(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _BannerSliver extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isOnline = context.select<NetworkService, bool>((s) => s.isOnline);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1.0,
        child: child,
      ),
      child: isOnline
          ? const SizedBox.shrink(key: ValueKey('online'))
          : const _OfflineTile(key: ValueKey('offline')),
    );
  }
}

class _OfflineTile extends StatelessWidget {
  const _OfflineTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade700,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'No internet connection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => NetworkService.instance.checkNow(),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
