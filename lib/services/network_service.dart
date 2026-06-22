import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:grabitt/utils/app_logger.dart';

const String _tag = 'NetworkService';

/// Monitors real internet connectivity using dart:io only — no extra package.
///
/// Uses InternetAddress.lookup() to do a real DNS ping every [_pollInterval].
/// Also exposes checkNow() for on-demand rechecks (e.g. Retry button).
class NetworkService extends ChangeNotifier {
  NetworkService._();
  static final NetworkService instance = NetworkService._();

  static const Duration _pollInterval = Duration(seconds: 10);

  bool _isOnline = true; // optimistic default until first check
  bool get isOnline => _isOnline;

  Timer? _timer;

  // ---------------------------------------------------------------------------
  // Init / Dispose
  // ---------------------------------------------------------------------------

  /// Call once in main() after WidgetsFlutterBinding.ensureInitialized().
  Future<void> init() async {
    await checkNow(); // immediate check on startup
    _timer = Timer.periodic(_pollInterval, (_) => checkNow());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Force a real internet check. Returns true if reachable.
  /// Call this on Retry button tap.
  Future<bool> checkNow() async {
    final online = await _hasRealInternet();
    _setOnline(online);
    return online;
  }

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  void _setOnline(bool value) {
    if (_isOnline == value) return;
    _isOnline = value;
    AppLogger.d(_tag, 'connectivity → ${value ? "ONLINE" : "OFFLINE"}');
    notifyListeners();
  }

  /// DNS lookup on a reliable host — no package needed.
  Future<bool> _hasRealInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }
}