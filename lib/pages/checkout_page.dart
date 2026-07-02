import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grabitt/widgets/address_selector_sheet.dart';
import 'package:grabitt/widgets/checkout_address_card.dart';
import 'package:grabitt/widgets/checkout_order_summary.dart';
import 'package:grabitt/widgets/checkout_payment_card.dart';
import 'package:grabitt/widgets/vendor_banner.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:grabitt/app_State/cart.dart';
import 'package:grabitt/l10n/app_localizations.dart';
import 'package:grabitt/models/address_model.dart';
import 'package:grabitt/pages/address_management_page.dart';
import 'package:grabitt/pages/waiting_page.dart';
import 'package:grabitt/services/address_api_service.dart';
import 'package:grabitt/services/auth_service.dart';
import 'package:grabitt/services/cart_api_service.dart';
import 'package:grabitt/services/payment_service.dart';
import 'package:grabitt/services/razorpay_order_service.dart';
import 'package:grabitt/services/selected_address_storage.dart';
import 'package:grabitt/utils/app_logger.dart';
import 'package:grabitt/utils/constants.dart';
import 'package:grabitt/utils/shared_classes.dart';

const String _tag = 'CheckoutPage';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _cart = CartService.instance;
  final _paymentService = PaymentService.instance;

  String _paymentMethod = 'cod';
  String? _activeRazorpayOrderId;

  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  bool _loadingAddresses = true;
  String? _userId;
  bool _checkingOrderRadius = false;
  OrderRadiusCheckResult? _orderRadiusStatus;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _paymentService.init();
    _loadAddressesAndSelection();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Address loading
  // ---------------------------------------------------------------------------

  Future<void> _loadAddressesAndSelection() async {
    if (!mounted) return;
    setState(() => _loadingAddresses = true);
    try {
      final user = await AuthService.instance.getSavedUser();
      final uid = user?['ID']?.toString() ?? user?['UserID']?.toString() ?? '';
      if (uid.isEmpty) {
        if (mounted) {
          setState(() {
            _userId = null;
            _addresses = [];
            _selectedAddress = null;
            _loadingAddresses = false;
          });
        }
        return;
      }

      _userId = uid;
      final list = await getAddressByUser(uid);
      final saved = await SelectedAddressStorage.instance.load();

      AddressModel? selected;
      if (saved != null && list.any((a) => a.id == saved.id)) {
        selected = list.firstWhere((a) => a.id == saved.id);
      } else if (list.isNotEmpty) {
        selected = list.first;
        await SelectedAddressStorage.instance.save(selected);
      }

      if (!mounted) return;
      setState(() {
        _addresses = list;
        _selectedAddress = selected;
        _loadingAddresses = false;
      });

      if (selected != null) {
        await _validateRadius(selected);
        await _refreshCartForAddress();
      } else {
        if (mounted) setState(() => _orderRadiusStatus = null);
      }
    } catch (e, st) {
      AppLogger.e(_tag, '_loadAddressesAndSelection failed', e, st);
      if (mounted) {
        setState(() {
          _addresses = [];
          _selectedAddress = null;
          _loadingAddresses = false;
          _orderRadiusStatus = null;
        });
      }
    }
  }

  Future<void> _refreshCartForAddress() async {
    await _cart.syncCartFromServer(
      addressId: _selectedAddress?.id.toString(),
    );
  }

  Future<void> _validateRadius(AddressModel address) async {
    if (!mounted) return;
    setState(() => _checkingOrderRadius = true);
    final result = await checkOrderRadius(address.id, address.userID);
    if (!mounted) return;
    setState(() {
      _orderRadiusStatus = result;
      _checkingOrderRadius = false;
    });
    if (!result.allowed) {
      ToastMessage.warning(context: context, msg: result.userMessage);
    }
  }

  // ---------------------------------------------------------------------------
  // Address selector
  // ---------------------------------------------------------------------------

  Future<void> _openAddressSelector() async {
    if (_userId == null || _userId!.isEmpty) {
      ToastMessage.warning(
          context: context, msg: 'Please log in to select or add address');
      return;
    }

    final picked = await showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddressSelectorSheet(
        addresses: _addresses,
        selected: _selectedAddress,
        userId: _userId!,
        onAddNew: () async {
          Navigator.pop(ctx);
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AddressFormPage(userId: _userId!),
            ),
          );
          if (mounted && result == true) {
            await _loadAddressesAndSelection();
          }
        },
      ),
    );

    if (!mounted || picked == null || picked.id == _selectedAddress?.id) return;

    setState(() => _selectedAddress = picked);
    await SelectedAddressStorage.instance.save(picked);
    if (!mounted) return;
    ToastMessage.success(context: context, msg: 'Address saved for checkout');
    await _validateRadius(picked);
    await _refreshCartForAddress();
  }

  // ---------------------------------------------------------------------------
  // Order placement
  // ---------------------------------------------------------------------------

  Future<void> _onPlaceOrder() async {
    if (_cart.items.isEmpty) return;

    if (_loadingAddresses) {
      ToastMessage.warning(
          context: context, msg: 'Please wait, loading address...');
      return;
    }
    if (_selectedAddress == null ||
        _addresses.isEmpty ||
        !_addresses.any((a) => a.id == _selectedAddress!.id)) {
      ToastMessage.warning(context: context, msg: 'Please select address');
      return;
    }
    if (_checkingOrderRadius) {
      ToastMessage.warning(
          context: context,
          msg: 'Please wait, checking delivery availability...');
      return;
    }
    if (_orderRadiusStatus == null || !_orderRadiusStatus!.allowed) {
      ToastMessage.warning(
        context: context,
        msg: _orderRadiusStatus?.userMessage ??
            'Delivery is not available for this address.',
      );
      return;
    }

    if (_paymentMethod == 'razorpay') {
      await _handleRazorpayOrder();
    } else {
      await _handleCodOrder();
    }
  }

  Future<void> _handleRazorpayOrder() async {
    final amountPaise = (_cart.finalTotal * 100).round();
    final orderId = await createRazorpayOrder(amountPaise);
    if (!mounted) return;

    final user = await AuthService.instance.getSavedUser();
    if (!mounted) return;
    final contact = user?['phone']?.toString();
    final email = user?['Email']?.toString();

    if (orderId == null || orderId.isEmpty) {
      AppLogger.w(
          _tag, 'Razorpay order API failed — using amount-based fallback');
      _activeRazorpayOrderId = null;
      _paymentService.onPaymentSuccess = _navigateToWaiting;
      _paymentService.onPaymentError = _onPaymentFailed;
      _paymentService.onPaymentSuccessData = null;
      _paymentService.onPaymentErrorData = null;
      ToastMessage.warning(
          context: context,
          msg: 'Order API unavailable. Opening fallback checkout.');
      _paymentService.openCheckout(
          amount: _cart.finalTotal, contact: contact, email: email);
      return;
    }

    _activeRazorpayOrderId = orderId;
    _paymentService.onPaymentSuccess = null;
    _paymentService.onPaymentError = _onPaymentFailed;
    _paymentService.onPaymentSuccessData = _onPaymentSuccessData;
    _paymentService.onPaymentErrorData = null;
    _paymentService.openCheckout(
        orderId: orderId, contact: contact, email: email);
  }

  Future<void> _handleCodOrder() async {
    final ctx = await CartService.instance.getUserContext();
    if (!mounted) return;

    final response = await CartApiService.placeOrder(
      userId: ctx['userId']!,
      macId: ctx['macId']!,
      paymentMode: _paymentMethod,
      addressId: _selectedAddress!.id.toString(),
    );
    if (!mounted) return;

    try {
      final Map<String, dynamic> raw;
      if (response is Map<String, dynamic>) {
        raw = response;
      } else if (response is String) {
        final cleaned = response
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll('<?xml version="1.0" encoding="utf-8"?>', '')
            .trim();
        raw = jsonDecode(cleaned) as Map<String, dynamic>;
      } else {
        throw FormatException(
            'Unexpected response type: ${response.runtimeType}');
      }

      final normalized = {
        for (final e in raw.entries) e.key.toLowerCase(): e.value,
      };
      final status =
          normalized['status']?.toString().trim().toLowerCase() ?? '';
      final message = normalized['message']?.toString().trim() ?? '';

      if (status == 'success') {
        ToastMessage.success(
          context: context,
          msg: message.isNotEmpty ? message : 'Order placed successfully',
        );
        CartService.instance.clearCart();
        _navigateToWaiting();
      } else {
        ToastMessage.warning(
          context: context,
          msg: message.isNotEmpty
              ? message
              : (status == 'fail'
                  ? 'Shop is currently closed'
                  : 'Unable to process order'),
        );
      }
    } catch (e, st) {
      AppLogger.e(_tag, 'placeOrder parse failed', e, st);
      if (mounted) {
        ToastMessage.error(context: context, msg: 'Something went wrong');
      }
    }
  }

  void _navigateToWaiting() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WaitingPage()),
    );
  }

  void _onPaymentFailed() {
    _activeRazorpayOrderId = null;
    if (!mounted) return;
    ToastMessage.warning(
        context: context, msg: 'Payment failed. Please try again.');
  }

  void _onPaymentSuccessData(PaymentSuccessResponse response) {
    final createdId = _activeRazorpayOrderId;
    if (createdId != null &&
        createdId.isNotEmpty &&
        response.orderId != null &&
        response.orderId != createdId) {
      _onPaymentFailed();
      return;
    }
    _activeRazorpayOrderId = null;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _cart,
      builder: (context, _) => Scaffold(
        backgroundColor: StoreProfileTheme.background,
        appBar: AppBar(
          title: Text(
            l10n.checkout,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black),
          ),
          backgroundColor: StoreProfileTheme.background,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        bottomNavigationBar: _PlaceOrderBar(
          paymentMethod: _paymentMethod,
          selectedAddress: _selectedAddress,
          addresses: _addresses,
          isCheckingRadius: _checkingOrderRadius,
          radiusStatus: _orderRadiusStatus,
          onPlaceOrder: _onPlaceOrder,
          onAddressSelect: _openAddressSelector,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            VendorBanner(
              vendorName: _cart.vendorName,
              vendorCategory: _cart.vendorCategory,
            ),
            _SectionTitle(l10n.shippingAddress),
            CheckoutAddressCard(
              isLoading: _loadingAddresses,
              userId: _userId,
              addresses: _addresses,
              selectedAddress: _selectedAddress,
              isCheckingRadius: _checkingOrderRadius,
              radiusStatus: _orderRadiusStatus,
              onChangeTap: _openAddressSelector,
            ),
            const SizedBox(height: 20),
            _SectionTitle(l10n.paymentMethod),
            CheckoutPaymentCard(
              selected: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v),
            ),
            const SizedBox(height: 20),
            CheckoutOrderSummary(cart: _cart),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Local stateless helpers (too small to warrant separate files)
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: StoreProfileTheme.accentPink,
      ),
    );
  }
}

class _PlaceOrderBar extends StatelessWidget {
  const _PlaceOrderBar({
    required this.paymentMethod,
    required this.selectedAddress,
    required this.addresses,
    required this.isCheckingRadius,
    required this.radiusStatus,
    required this.onPlaceOrder,
    required this.onAddressSelect,
  });

  final String paymentMethod;
  final AddressModel? selectedAddress;
  final List<AddressModel> addresses;
  final bool isCheckingRadius;
  final OrderRadiusCheckResult? radiusStatus;
  final VoidCallback onPlaceOrder;
  final VoidCallback onAddressSelect;

  bool get _isComingSoon => paymentMethod != 'cod';
  bool get _noAddress => selectedAddress == null || addresses.isEmpty;
  bool get _radiusBlocked =>
      selectedAddress != null &&
      !isCheckingRadius &&
      radiusStatus != null &&
      !radiusStatus!.allowed;

  bool get _isDisabled => _isComingSoon || _radiusBlocked || _noAddress;

  String _label(AppLocalizations l10n) {
    if (_noAddress) return 'Add Address to Continue';
    if (_isComingSoon) return 'Coming Soon 🚧';
    if (_radiusBlocked) return 'Address not serviceable';
    return l10n.placeOrder;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isDisabled ? Colors.grey : StoreProfileTheme.accentPink,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _isDisabled ? _onDisabledTap(context) : onPlaceOrder,
          child: Text(
            _label(l10n),
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),
      ),
    );
  }

  VoidCallback _onDisabledTap(BuildContext context) => () {
        if (_noAddress) {
          onAddressSelect();
        } else if (_isComingSoon) {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.construction,
                        size: 40, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text('Coming Soon 🚀',
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('This payment option is under development.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 13)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK')),
                  ],
                ),
              ),
            ),
          );
        } else if (_radiusBlocked) {
          ToastMessage.warning(
            context: context,
            msg: radiusStatus?.userMessage ??
                'Delivery is not available for this address.',
          );
        }
      };
}
