import 'package:flutter/foundation.dart';

/// Lightweight logger that only emits output in debug builds.
///
/// Usage:
///   AppLogger.e('AuthService', 'getUserByPhone failed', error, stackTrace);
///   AppLogger.w('CartService', 'cartId is null, falling back to full sync');
///   AppLogger.d('CartApiService', 'response: $cleaned');
class AppLogger {
  AppLogger._();

  /// Error — unexpected failures that should never happen in normal flow.
  static void e(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!kDebugMode) return;
    final buf = StringBuffer()
      ..write('[ERROR] [$tag] $message');
    if (error != null) buf.write('\n  error: $error');
    if (stackTrace != null) buf.write('\n  stack: $stackTrace');
    debugPrint(buf.toString());
  }

  /// Warning — degraded but recoverable situation.
  static void w(String tag, String message) {
    if (!kDebugMode) return;
    debugPrint('[WARN]  [$tag] $message');
  }

  /// Debug — verbose info useful during development.
  static void d(String tag, String message) {
    if (!kDebugMode) return;
    debugPrint('[DEBUG] [$tag] $message');
  }
}