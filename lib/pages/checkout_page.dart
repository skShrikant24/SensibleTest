import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:GraBiTT/app_State/Cart.dart';
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
import 'package:GraBiTT/utils/sharedClasses.dart';

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
    _loadAddressesAndSelection();
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
                onSaved: () => _loadAddressesAndSelection(),
              ),
            ),
          );
          if (result == true && mounted) await _loadAddressesAndSelection();
        },
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedAddress = picked);
      await SelectedAddressStorage.instance.save(picked);
      ToastMessage.success(context: context, msg: 'Address saved for checkout');
      await _validateSelectedAddressRadius(picked);
    }
  }

  Future<void> _validateSelectedAddressRadius(AddressModel address) async {
    if (!mounted) return;
    setState(() => _checkingOrderRadius = true);
    final result = await checkOrderRadius(address.id);
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
              ...cart.items.map(_orderItem).toList(),
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
              Icon(Icons.location_on_outlined, color: StoreProfileTheme.accentPink),
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
                  _selectedAddress != null ? AppLocalizations.of(context)!.change : AppLocalizations.of(context)!.select,
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
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ] else if (_orderRadiusStatus != null) ...[
            const SizedBox(height: 8),
            Text(
              _orderRadiusStatus!.userMessage,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: _orderRadiusStatus!.allowed ? Colors.green[700] : Colors.red[700],
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
    );
  }

  Widget _paymentTile(String value, IconData icon, String title) {
    return RadioListTile<String>(
      value: value,
      groupValue: paymentMethod,
      onChanged: (v) => setState(() => paymentMethod = v!),
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
            child: Image.network(
              item.product.allImages.first,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(AppLocalizations.of(context)!.subtotal,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
          Text(
            "${AppConstants.currencySymbol}${cart.subtotal.toInt()}",
            style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: StoreProfileTheme.accentPink),
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
    final amount = cart.subtotal;

    if (paymentMethod == 'razorpay') {
      final amountPaise = (amount * 100).round();
      final orderId = await createRazorpayOrder(amountPaise);
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
        if (user != null) {
          contact = user['phone']?.toString();
          email = user['Email']?.toString();
        }
        if (mounted) {
          ToastMessage.warning(
            context: context,
            msg: 'Order API unavailable. Opening fallback checkout.',
          );
        }
        _paymentService.openCheckout(
          amount: amount,
          contact: contact,
          email: email,
        );
        return;
      }
      _activeRazorpayOrderId = orderId;
      debugPrint('[Razorpay] Backend order_id sent to checkout: $orderId');
      _paymentService.onPaymentSuccess = null;
      _paymentService.onPaymentError = _handlePaymentFailed;
      _paymentService.onPaymentSuccessData = _handlePaymentSuccessData;
      String? contact;
      String? email;
      final user = await AuthService.instance.getSavedUser();
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
    }else{
      await CartApiService.placeOrder(
        userId: ctx['userId']!,
        macId: ctx['macId']!,
        paymentMode: paymentMethod,
        addressId: _selectedAddress!.id.toString(),
      );
// Clear cart after order
      CartService.instance.clearCart();
      _navigateToWaitingPage();
      return ;
    }

    _navigateToWaitingPage();
  }

  Widget _placeOrderBar() {
    final isDisabled = paymentMethod != "cod";
    final radiusBlocked =
        _selectedAddress != null &&
        !_checkingOrderRadius &&
        _orderRadiusStatus != null &&
        !_orderRadiusStatus!.allowed;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: (isDisabled || radiusBlocked)
                ? Colors.grey
                : StoreProfileTheme.accentPink,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: (cart.items.isEmpty || isDisabled || radiusBlocked)
              ? () {
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
            isDisabled
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
                  ...addresses.map((a) => RadioListTile<AddressModel>(
                        value: a,
                        groupValue: selected,
                        onChanged: (v) {
                          if (v != null) Navigator.pop(context, v);
                        },
                        activeColor: StoreProfileTheme.accentPink,
                        title: Text(
                          a.addressType.isNotEmpty ? a.addressType : 'Address',
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
                      )),
                  const SizedBox(height: 8),
                  ListTile(
                    leading:
                        Icon(Icons.add, color: StoreProfileTheme.accentPink),
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
