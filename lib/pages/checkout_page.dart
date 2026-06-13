import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:GraBiTT/app_State/cart.dart';
import 'package:GraBiTT/l10n/app_localizations.dart';
import 'package:GraBiTT/models/address_model.dart';
import 'package:GraBiTT/pages/address_management_page.dart';
import 'package:GraBiTT/pages/waiting_page.dart';
import 'package:GraBiTT/services/address_api_service.dart';
import 'package:GraBiTT/services/auth_service.dart';
import 'package:GraBiTT/services/payment_service.dart';
import 'package:GraBiTT/services/razorpay_order_service.dart';
import 'package:GraBiTT/services/selected_address_storage.dart';
import 'package:GraBiTT/utils/constants.dart';
import 'package:GraBiTT/utils/shared_classes.dart';

import '../services/cart_api_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String paymentMethod = 'cod';
  final cart = CartService.instance;
  final PaymentService _paymentService = PaymentService.instance;
  String? _activeRazorpayOrderId;

  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  bool _loadingAddresses = true;
  String? _userId;
  bool _checkingOrderRadius = false;
  OrderRadiusCheckResult? _orderRadiusStatus;

  @override
  void initState() {
    super.initState();
    _paymentService.init();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   cart.syncCartFromServer();
    // });
    _loadAddressesAndSelection();
  }

  // ===================== CHANGE =====================
  // Refresh cart for updated delivery charges
  Future<void> _refreshCartForAddressChange() async {
    try {
      debugPrint(
        "Refreshing cart for address: ${_selectedAddress?.id}",
      );

      await cart.syncCartFromServer(
        addressId: _selectedAddress?.id.toString(),
      );

      debugPrint(
        "Updated delivery charge: ${cart.deliveryCharge}",
      );
    } catch (e) {
      debugPrint("Cart refresh failed: $e");
    }
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _loadAddressesAndSelection() async {
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
      if (mounted) {
        setState(() {
          _addresses = list;
          _selectedAddress = selected;
          _loadingAddresses = false;
        });
      }
      if (selected != null && mounted) {
        await _validateSelectedAddressRadius(selected);
        // ===================== CHANGE =====================
        // Refresh cart totals/delivery charge
        await _refreshCartForAddressChange();
      } else if (mounted) {
        setState(() => _orderRadiusStatus = null);
      }
    } catch (_) {
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

  Future<void> _openAddressSelector() async {
    if (_userId == null || _userId!.isEmpty) {
      ToastMessage.warning(
        context: context,
        msg: 'Please log in to select or add address',
      );
      return;
    }
    final picked = await showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddressSelectorSheet(
        addresses: _addresses,
        selected: _selectedAddress,
        userId: _userId!,
        onAddNew: () async {
          Navigator.pop(ctx);
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AddressFormPage(
                userId: _userId!,
                // ===================== CHANGE =====================
                // onSaved: () async {
                //   await _loadAddressesAndSelection();
                // },
              ),
            ),
          );
          if (!mounted) return;
          if (result == true && mounted) {
            await _loadAddressesAndSelection();
          }
        },
      ),
    );
    if (!mounted) return;
    if (picked != null && picked.id != _selectedAddress?.id) {
      setState(() => _selectedAddress = picked);
      await SelectedAddressStorage.instance.save(picked);
      if (!mounted) return;
      ToastMessage.success(context: context, msg: 'Address saved for checkout');
      await _validateSelectedAddressRadius(picked);
      await _refreshCartForAddressChange();
    }
  }

  Future<void> _validateSelectedAddressRadius(AddressModel address) async {
    if (!mounted) return;
    setState(() => _checkingOrderRadius = true);
    final result = await checkOrderRadius(
      address.id,
      address.userID,
    );
    debugPrint("Radius Allowed: ${result.allowed}");
    debugPrint("Radius Message: ${result.userMessage}");
    debugPrint("Address ID: ${address.id}");
    debugPrint("User ID: ${address.userID}");
    if (!mounted) return;
    setState(() {
      _orderRadiusStatus = result;
      _checkingOrderRadius = false;
    });
    if (!result.allowed) {
      ToastMessage.warning(
        context: context,
        msg: result.userMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cart,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: StoreProfileTheme.background,
          appBar: AppBar(
            title: Text(
              AppLocalizations.of(context)!.checkout,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            backgroundColor: StoreProfileTheme.background,
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          bottomNavigationBar: _placeOrderBar(),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionTitle(AppLocalizations.of(context)!.shippingAddress),
              _addressCard(),
              const SizedBox(height: 20),
              _sectionTitle(AppLocalizations.of(context)!.paymentMethod),
              _paymentCard(),
              const SizedBox(height: 20),
              _sectionTitle(AppLocalizations.of(context)!.orderSummary),
              ...cart.items.map(_orderItem),
              const SizedBox(height: 16),
              _totalCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: StoreProfileTheme.accentPink,
      ),
    );
  }

  Widget _addressCard() {
    if (_loadingAddresses) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(20),
        decoration: _cardStyle(),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: StoreProfileTheme.accentPink,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }
    if (_userId == null || _userId!.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        decoration: _cardStyle(),
        child: Row(
          children: [
            Icon(Icons.location_off, color: StoreProfileTheme.accentPink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.logInToAddOrSelectAddress,
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    if (_addresses.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        decoration: _cardStyle(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_location_alt,
                    color: StoreProfileTheme.accentPink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.noAddressAddedYet,
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openAddressSelector,
                icon: const Icon(Icons.add, size: 20),
                label: Text(AppLocalizations.of(context)!.addAddress),
                style: OutlinedButton.styleFrom(
                  foregroundColor: StoreProfileTheme.accentPink,
                  side: BorderSide(color: StoreProfileTheme.accentPink),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: _cardStyle(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  color: StoreProfileTheme.accentPink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _selectedAddress != null
                      ? '${_selectedAddress!.addressType.isNotEmpty ? "${_selectedAddress!.addressType}\n" : ""}${_selectedAddress!.displaySummary}'
                      : AppLocalizations.of(context)!.selectDeliveryAddress,
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: _openAddressSelector,
                child: Text(
                  _selectedAddress != null
                      ? AppLocalizations.of(context)!.change
                      : AppLocalizations.of(context)!.select,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: StoreProfileTheme.accentPink,
                  ),
                ),
              ),
            ],
          ),
          if (_checkingOrderRadius) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Checking delivery availability...',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ] else if (_orderRadiusStatus != null) ...[
            const SizedBox(height: 8),
            Text(
              _orderRadiusStatus!.userMessage,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _orderRadiusStatus!.allowed
                    ? Colors.green[700]
                    : Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: _cardStyle(),
      child: RadioGroup<String>(
        groupValue: paymentMethod,
        onChanged: (String? value) {
          if (value != null) {
            setState(() => paymentMethod = value);
          }
        },
        child: Column(
          children: [
            _paymentTile("cod", Icons.home, "Cash On Delivery"),
            _divider(),

            // 🚧 UPI (Coming Soon)
            _disabledPaymentTile("upi", Icons.qr_code, "UPI"),
            _divider(),

            // 🚧 GrabPoints (Coming Soon)
            _disabledPaymentTile("grabpoints", Icons.wallet, "Grab Points"),
          ],
        ),
      ),
    );
  }

  Widget _paymentTile(String value, IconData icon, String title) {
    return RadioListTile<String>(
      value: value,
      activeColor: StoreProfileTheme.accentPink,
      title: Row(
        children: [
          Icon(icon, color: StoreProfileTheme.accentPink),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.poppins(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _disabledPaymentTile(String value, IconData icon, String title) {
    return ListTile(
      onTap: () {
        _showWorkInProgressDialog(context);
        setState(() => paymentMethod = value); // still track selection
      },
      leading: Icon(icon, color: Colors.grey),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      trailing: const Icon(Icons.lock, color: Colors.grey, size: 18),
    );
  }

  void _showWorkInProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.construction, size: 40, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  "Coming Soon 🚀",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "This payment option is under development.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _orderItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: _cardStyle(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: (item.product.allImages.isNotEmpty &&
                    item.product.allImages.first.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: item.product.allImages.first,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 150),
                    memCacheWidth: 250,
                    maxWidthDiskCache: 350,
                    placeholder: (context, url) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      );
                    },
                    errorWidget: (context, url, error) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image_outlined,
                        ),
                      );
                    },
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  "Qty: ${item.quantity}",
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color:
                          StoreProfileTheme.accentPink.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          Text(
            "${AppConstants.currencySymbol}${item.total.toStringAsFixed(0)}",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: StoreProfileTheme.accentPink),
          ),
        ],
      ),
    );
  }

  Widget _totalCard() {
    final bool showNewUserDiscount =
        cart.isNewUserDiscountApplied && cart.newUserDiscountAmount > 0;

    final bool showEvenOrderDiscount =
        cart.isEvenOrderDiscountApplied && cart.evenOrderDiscountAmount > 0;

    final bool showDeliveryCharge = cart.deliveryCharge > 0;
    final bool showGST = cart.gst > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Column(
        children: [
          // Subtotal
          _priceRow(AppLocalizations.of(context)!.subtotal, cart.subtotal),

          // GST
          if (showGST)
            _priceRow(
              "GST (${cart.gstPercent}%)",
              cart.gst,
            ),

          // Delivery Charge
          if (showDeliveryCharge)
            _priceRow(
              "Delivery Charge",
              cart.deliveryCharge,
            ),

          // New User Discount
          if (showNewUserDiscount)
            _priceRow(
              "New User Discount (${cart.newUserDiscountPercent}% OFF)",
              -cart.newUserDiscountAmount,
              valueColor: Colors.green,
            ),

          // Even Order Discount
          if (showEvenOrderDiscount)
            _priceRow(
              "Even Order Discount (${cart.evenOrderDiscountPercent}% OFF)",
              -cart.evenOrderDiscountAmount,
              valueColor: Colors.green,
            ),

          // Service Fee
          _priceRow(
            "Service Fee",
            cart.serviceFee,
            showNil: true,
          ),

// Handling Fee
          _priceRow(
            cart.handlingFeeText.isNotEmpty
                ? cart.handlingFeeText
                : "Handling Fee",
            cart.handlingFee,
            showNil: true,
          ),

// Packaging Fee
          _priceRow(
            "Packaging Fee",
            cart.packagingFee,
            showNil: true,
          ),

          const Divider(height: 22),

          // Final Total
          _priceRow("Final Total", cart.finalTotal, isFinal: true),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    double amount, {
    bool isFinal = false,
    Color? valueColor,
    bool showNil = false,
  }) {
    final bool isNegative = amount < 0;
    final bool isZero = amount == 0;
    String amountText;
    if (showNil && isZero) {
      amountText = "Nil";
    } else if (isNegative) {
      amountText =
          '- ${AppConstants.currencySymbol}${amount.abs().toStringAsFixed(0)}';
    } else {
      amountText = '${AppConstants.currencySymbol}${amount.toStringAsFixed(0)}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isFinal ? 15 : 13,
                fontWeight: isFinal ? FontWeight.w600 : FontWeight.w400,
                color: isFinal ? Colors.black : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            amountText,
            style: GoogleFonts.poppins(
              fontSize: isFinal ? 18 : 14,
              fontWeight: isFinal ? FontWeight.bold : FontWeight.w500,
              color: valueColor ??
                  (isFinal
                      ? StoreProfileTheme.accentPink
                      : StoreProfileTheme.accentPink),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToWaitingPage() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WaitingPage()),
    );
  }

  void _handlePaymentFailed() {
    _activeRazorpayOrderId = null;
    if (!mounted) return;
    ToastMessage.warning(
      context: context,
      msg: 'Payment failed. Please try again.',
    );
  }

  void _handlePaymentSuccessData(PaymentSuccessResponse response) {
    final createdOrderId = _activeRazorpayOrderId;
    debugPrint(
      '[Razorpay] App callback success: createdOrderId=$createdOrderId, returnedOrderId=${response.orderId}, paymentId=${response.paymentId}',
    );
    if (createdOrderId != null &&
        createdOrderId.isNotEmpty &&
        response.orderId != null &&
        response.orderId != createdOrderId) {
      _handlePaymentFailed();
      return;
    }
    _activeRazorpayOrderId = null;
  }

  Future<void> _onPlaceOrder() async {
    final ctx = await CartService.instance.getUserContext();
    if (!mounted) return;
    if (cart.items.isEmpty) return;
    if (_loadingAddresses) {
      ToastMessage.warning(
        context: context,
        msg: 'Please wait, loading address...',
      );
      return;
    }
    if (_selectedAddress == null ||
        _addresses.isEmpty ||
        !_addresses.any((a) => a.id == _selectedAddress!.id)) {
      ToastMessage.warning(
        context: context,
        msg: 'Please select address',
      );
      return;
    }
    if (_checkingOrderRadius) {
      ToastMessage.warning(
        context: context,
        msg: 'Please wait, checking delivery availability...',
      );
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
    final amount = cart.finalTotal;

    if (paymentMethod == 'razorpay') {
      final amountPaise = (amount * 100).round();
      final orderId = await createRazorpayOrder(amountPaise);
      if (!mounted) return;
      if (orderId == null || orderId.isEmpty) {
        debugPrint(
          '[Razorpay] Backend order API failed. Falling back to amount-based checkout for testing.',
        );
        _activeRazorpayOrderId = null;
        _paymentService.onPaymentSuccess = _navigateToWaitingPage;
        _paymentService.onPaymentError = _handlePaymentFailed;
        _paymentService.onPaymentSuccessData = null;
        _paymentService.onPaymentErrorData = null;
        String? contact;
        String? email;
        final user = await AuthService.instance.getSavedUser();
        if (!mounted) return;
        if (user != null) {
          contact = user['phone']?.toString();
          email = user['Email']?.toString();
        }

        ToastMessage.warning(
          context: context,
          msg: 'Order API unavailable. Opening fallback checkout.',
        );

        _paymentService.openCheckout(
          amount: amount,
          contact: contact,
          email: email,
        );
        return;
      }
      _activeRazorpayOrderId = orderId;
      debugPrint(
        '[Razorpay] Backend order_id sent to checkout: $orderId',
      );
      _paymentService.onPaymentSuccess = null;
      _paymentService.onPaymentError = _handlePaymentFailed;
      _paymentService.onPaymentSuccessData = _handlePaymentSuccessData;
      String? contact;
      String? email;
      final user = await AuthService.instance.getSavedUser();
      if (!mounted) return;
      if (user != null) {
        contact = user['phone']?.toString();
        email = user['Email']?.toString();
      }
      _paymentService.openCheckout(
        orderId: orderId,
        contact: contact,
        email: email,
      );
      return;
    } else {
      final response = await CartApiService.placeOrder(
        userId: ctx['userId']!,
        macId: ctx['macId']!,
        paymentMode: paymentMethod,
        addressId: _selectedAddress!.id.toString(),
      );
      if (!mounted) return;

      try {
        debugPrint("Raw Response => $response");

        Map<String, dynamic> responseData = {};

        // CASE 1: Already decoded Map response
        if (response is Map<String, dynamic>) {
          responseData = response;
        }

        // CASE 2: String response with XML wrapper
        else if (response is String) {
          final cleanedResponse = response
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .replaceAll('<?xml version="1.0" encoding="utf-8"?>', '')
              .trim();

          debugPrint("Cleaned Response => $cleanedResponse");

          responseData = jsonDecode(cleanedResponse);
        }

        // Normalize keys to lowercase
        final normalizedData = <String, dynamic>{};

        responseData.forEach((key, value) {
          normalizedData[key.toString().toLowerCase()] = value;
        });

        final status =
            normalizedData["status"]?.toString().trim().toLowerCase() ?? "";

        final message = normalizedData["message"]?.toString().trim() ?? "";

        debugPrint("Parsed Status => $status");
        debugPrint("Parsed Message => $message");

        // SUCCESS
        if (status == "success") {
          ToastMessage.success(
            context: context,
            msg: message.isNotEmpty ? message : "Order placed successfully",
          );

          CartService.instance.clearCart();

          _navigateToWaitingPage();
          return;
        }

        // FAIL
        if (status == "fail") {
          ToastMessage.warning(
            context: context,
            msg: message.isNotEmpty ? message : "Shop is currently closed",
          );

          return;
        }

        // UNKNOWN RESPONSE
        ToastMessage.warning(
          context: context,
          msg: message.isNotEmpty ? message : "Unable to process order",
        );
      } catch (e) {
        debugPrint("Place order parse error => $e");

        ToastMessage.error(
          context: context,
          msg: "Something went wrong",
        );
      }

      return;
    }
  }

  Widget _placeOrderBar() {
    final isDisabled = paymentMethod != "cod";
    final radiusBlocked = _selectedAddress != null &&
        !_checkingOrderRadius &&
        _orderRadiusStatus != null &&
        !_orderRadiusStatus!.allowed;
    final noAddressSelected = _selectedAddress == null || _addresses.isEmpty;

    // final vendorNumber = '6360974868';
    // final message = Uri.encodeComponent(
    //   "New order received 🚀\n\nOrder ID: #1234\nOpen Vendor Panel:\nhttps://vendor.grabbit.com",
    // );
    // final url = "https://wa.me/91$vendorNumber?text=$message";

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: (isDisabled || radiusBlocked || noAddressSelected)
                ? Colors.grey
                : StoreProfileTheme.accentPink,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: (cart.items.isEmpty ||
                  isDisabled ||
                  radiusBlocked ||
                  noAddressSelected)
              ? () {
                  if (noAddressSelected) {
                    _openAddressSelector();
                    return;
                  }

                  if (isDisabled) {
                    _showWorkInProgressDialog(context);
                  } else if (radiusBlocked) {
                    ToastMessage.warning(
                      context: context,
                      msg: _orderRadiusStatus?.userMessage ??
                          'Delivery is not available for this address.',
                    );
                  }
                }
              : _onPlaceOrder,
          child: Text(
            noAddressSelected
                ? 'Add Address to Continue'
                : isDisabled
                    ? "Coming Soon 🚧"
                    : radiusBlocked
                        ? 'Address not serviceable'
                        : AppLocalizations.of(context)!.placeOrder,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Divider _divider() => Divider(
      height: 1, color: StoreProfileTheme.border.withValues(alpha: 0.6));

  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: StoreProfileTheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: StoreProfileTheme.border, width: 0.5),
      boxShadow: [
        BoxShadow(
          color: StoreProfileTheme.border.withValues(alpha: 0.12),
          blurRadius: 10,
          offset: const Offset(0, 5),
        )
      ],
    );
  }
}

class _AddressSelectorSheet extends StatelessWidget {
  final List<AddressModel> addresses;
  final AddressModel? selected;
  final String userId;
  final VoidCallback onAddNew;

  const _AddressSelectorSheet({
    required this.addresses,
    required this.selected,
    required this.userId,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select delivery address',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: StoreProfileTheme.accentPink,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  RadioGroup<AddressModel>(
                    groupValue: selected,
                    onChanged: (AddressModel? value) {
                      if (value != null) {
                        Navigator.pop(context, value);
                      }
                    },
                    child: Column(
                      children: addresses
                          .map(
                            (a) => RadioListTile<AddressModel>(
                              value: a,
                              activeColor: StoreProfileTheme.accentPink,
                              title: Text(
                                a.addressType.isNotEmpty
                                    ? a.addressType
                                    : 'Address',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  a.displaySummary,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: StoreProfileTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Icon(
                      Icons.add,
                      color: StoreProfileTheme.accentPink,
                    ),
                    title: Text(
                      'Add new address',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: StoreProfileTheme.accentPink,
                      ),
                    ),
                    onTap: onAddNew,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
