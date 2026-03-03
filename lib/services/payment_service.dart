import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Razorpay payment flow. Lazy-init on first openCheckout to avoid
/// MissingPluginException on app start. Callbacks: [onPaymentSuccess], [onPaymentError].
class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  Razorpay? _razorpay;
  bool _initialized = false;
  bool _pluginFailed = false;

  VoidCallback? onPaymentSuccess;
  VoidCallback? onPaymentError;
  ValueChanged<PaymentSuccessResponse>? onPaymentSuccessData;
  ValueChanged<PaymentFailureResponse>? onPaymentErrorData;

  /// Lazy init: only when opening checkout. Catches MissingPluginException
  /// so app doesn't crash if plugin isn't registered (e.g. hot reload).
  void _ensureInit() {
    if (_pluginFailed) return;
    if (_initialized) return;
    try {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      _initialized = true;
    } on PlatformException catch (e) {
      if (e.code == 'MissingPluginException' ||
          e.message?.contains('resync') == true) {
        _pluginFailed = true;
        onPaymentError?.call();
      }
      return;
    } on MissingPluginException catch (_) {
      _pluginFailed = true;
      onPaymentError?.call();
      return;
    }
  }

  /// Call from checkout initState (no-op; real init is lazy in openCheckout).
  void init() {}

  /// Opens Razorpay checkout. Per Razorpay docs, [orderId] must be from Razorpay
  /// Create Order API (usually via your backend). Pass the order_id returned by that API.
  ///
  /// [orderId] – required; from Create Order API (e.g. "order_RB58MiP5SPFYyM").
  /// [amount] – optional fallback when [orderId] is unavailable; in INR, converted to paise.
  /// [contact] and [email] optional for prefill.
  void openCheckout({
    String? orderId,
    double? amount,
    String? contact,
    String? email,
  }) {
    // razorpay_flutter is mobile-only.
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      onPaymentError?.call();
      return;
    }

    if (_pluginFailed) {
      onPaymentError?.call();
      return;
    }
    try {
      _ensureInit();
    } catch (_) {
      onPaymentError?.call();
      return;
    }
    if (!_initialized || _razorpay == null) {
      onPaymentError?.call();
      return;
    }

    final options = <String, dynamic>{
      'key': 'zp_live_SNt5ztsMS7EECJ',
      // 'key': 'rzp_test_xxxxxxxxx',
      'name': 'SattvikPlate',
      'description': 'Order Payment',
    };

    if (orderId != null && orderId.trim().isNotEmpty) {
      options['order_id'] = orderId.trim();
    } else if (amount != null && amount > 0) {
      options['amount'] = (amount * 100).round();
    } else {
      onPaymentError?.call();
      return;
    }

    if (contact != null && contact.isNotEmpty ||
        email != null && email.isNotEmpty) {
      options['prefill'] = <String, String>{};
      if (contact != null && contact.isNotEmpty) {
        options['prefill']['contact'] = contact;
      }
      if (email != null && email.isNotEmpty) {
        options['prefill']['email'] = email;
      }
    }

    debugPrint(
      '[Razorpay] Opening checkout with order_id=${options['order_id']}, amount=${options['amount']}, prefill=${options['prefill']}',
    );

    // Plugin open() is async-void; catch uncaught async errors in this zone.
    runZonedGuarded(
      () {
        _razorpay!.open(options);
      },
      (error, _) {
        if (error is MissingPluginException) {
          _pluginFailed = true;
        } else if (error is PlatformException &&
            (error.code == 'MissingPluginException' ||
                error.message?.contains('MissingPluginException') == true)) {
          _pluginFailed = true;
        }
        onPaymentError?.call();
      },
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint(
      '[Razorpay] Success callback: paymentId=${response.paymentId}, orderId=${response.orderId}, signature=${response.signature}',
    );
    onPaymentSuccessData?.call(response);
    onPaymentSuccess?.call();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint(
      '[Razorpay] Error callback: code=${response.code}, message=${response.message}',
    );
    onPaymentErrorData?.call(response);
    onPaymentError?.call();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Optional: handle wallet redirect
    onPaymentSuccess?.call();
  }

  void dispose() {
    if (_initialized && _razorpay != null) {
      _razorpay!.clear();
      _razorpay = null;
      _initialized = false;
    }
    _pluginFailed = false;
    onPaymentSuccess = null;
    onPaymentError = null;
    onPaymentSuccessData = null;
    onPaymentErrorData = null;
  }
}
