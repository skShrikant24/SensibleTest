import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:grabitt/l10n/app_localizations.dart';
import 'package:grabitt/models/address_model.dart';
import 'package:grabitt/pages/address_management_page.dart';
import 'package:grabitt/services/address_api_service.dart';
import 'package:grabitt/services/auth_service.dart';
import 'package:grabitt/utils/constants.dart';
import 'package:grabitt/utils/shared_classes.dart';

/// Pick & Deliver: choose pickup and delivery addresses, place order, get handover code.
class PickDeliverOrderPage extends StatefulWidget {
  const PickDeliverOrderPage({super.key});

  @override
  State<PickDeliverOrderPage> createState() => _PickDeliverOrderPageState();
}

class _PickDeliverOrderPageState extends State<PickDeliverOrderPage> {
  List<AddressModel> _addresses = [];
  AddressModel? _pickup;
  AddressModel? _delivery;
  bool _loading = true;
  String? _userId;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = await AuthService.instance.getSavedUser();
    final uid = user?['ID']?.toString() ?? user?['UserID']?.toString() ?? '';
    if (uid.isEmpty) {
      if (mounted) {
        setState(() {
          _userId = null;
          _addresses = [];
          _pickup = null;
          _delivery = null;
          _loading = false;
        });
      }
      return;
    }
    _userId = uid;
    final list = await getAddressByUser(uid);
    if (!mounted) return;
    setState(() {
      _addresses = list;
      if (list.isNotEmpty) {
        _pickup ??= list.first;
        _delivery ??= list.length > 1 ? list[1] : list.first;
      } else {
        _pickup = null;
        _delivery = null;
      }
      _loading = false;
    });
  }

  Future<void> _pickAddress({required bool forPickup}) async {
    if (_userId == null || _userId!.isEmpty) {
      ToastMessage.warning(
        context: context,
        msg: 'Please log in to select or add address',
      );
      return;
    }
    final title =
        forPickup ? 'Select pickup address' : 'Select delivery address';
    final current = forPickup ? _pickup : _delivery;
    final picked = await showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddressPickerSheet(
        title: title,
        addresses: _addresses,
        selected: current,
        onAddNew: () async {
          Navigator.pop(ctx);
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => AddressFormPage(
                userId: _userId!,
                // onSaved: () => _load(),
              ),
            ),
          );
          if (result == true && mounted) await _load();
        },
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (forPickup) {
          _pickup = picked;
        } else {
          _delivery = picked;
        }
      });
    }
  }

  Future<void> _addAddress() async {
    if (_userId == null || _userId!.isEmpty) {
      ToastMessage.warning(
        context: context,
        msg: 'Please log in to add address',
      );
      return;
    }
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddressFormPage(
          userId: _userId!,
          // onSaved: () => _load(),
        ),
      ),
    );
    if (result == true && mounted) await _load();
  }

  String _fourDigitCode() {
    final r = Random();
    return (1000 + r.nextInt(9000)).toString();
  }

  Future<void> _placeOrder() async {
    if (_userId == null || _userId!.isEmpty) {
      ToastMessage.warning(
          context: context, msg: 'Please log in to place an order');
      return;
    }
    if (_pickup == null || _delivery == null) {
      ToastMessage.warning(
        context: context,
        msg: 'Please choose pickup and delivery addresses',
      );
      return;
    }
    setState(() => _placing = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _placing = false);
    final code = _fourDigitCode();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _OrderSuccessDialog(code: code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: StoreProfileTheme.background,
      appBar: AppBar(
        backgroundColor: StoreProfileTheme.background,
        elevation: 0,
        title: Text(
          l10n.pickAndDeliver,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _placing ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: StoreProfileTheme.accentPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _placing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Place order',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: StoreProfileTheme.accentPink),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_userId == null || _userId!.isEmpty)
                  _loggedOutBanner(context)
                else ...[
                  _sectionTitle('Pickup address'),
                  _addressTile(
                    address: _pickup,
                    onChoose: () => _pickAddress(forPickup: true),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Delivery address'),
                  _addressTile(
                    address: _delivery,
                    onChoose: () => _pickAddress(forPickup: false),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addAddress,
                      icon:
                          Icon(Icons.add, color: StoreProfileTheme.accentPink),
                      label: Text(
                        l10n.addAddress,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: StoreProfileTheme.accentPink,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _loggedOutBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StoreProfileTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StoreProfileTheme.border),
      ),
      child: Row(
        children: [
          Icon(Icons.person_off, color: StoreProfileTheme.accentPink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.pleaseLogInToManageAddresses,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: StoreProfileTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: StoreProfileTheme.accentPink,
        ),
      ),
    );
  }

  Widget _addressTile({
    required AddressModel? address,
    required VoidCallback onChoose,
  }) {
    return Material(
      color: StoreProfileTheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onChoose,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: StoreProfileTheme.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined,
                  color: StoreProfileTheme.accentPink, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (address != null) ...[
                      Text(
                        address.addressType.isNotEmpty
                            ? address.addressType
                            : 'Address',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        address.displaySummary,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: StoreProfileTheme.textSecondary,
                        ),
                      ),
                    ] else
                      Text(
                        _addresses.isEmpty
                            ? 'No saved addresses. Add one or choose after adding.'
                            : 'Tap to choose an address',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                _addresses.isEmpty ? 'Add' : 'Choose',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: StoreProfileTheme.accentPink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressPickerSheet extends StatelessWidget {
  final String title;
  final List<AddressModel> addresses;
  final AddressModel? selected;
  final VoidCallback onAddNew;

  const _AddressPickerSheet({
    required this.title,
    required this.addresses,
    required this.selected,
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
                title,
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

class _OrderSuccessDialog extends StatelessWidget {
  final String code;

  const _OrderSuccessDialog({required this.code});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 40, color: Colors.green),
            ),
            const SizedBox(height: 16),
            Text(
              'Order placed successfully',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share this 4-digit code with your delivery partner. They will need it to collect your items.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            SelectableText(
              code,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
                color: StoreProfileTheme.accentPink,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (context.mounted) {
                  ToastMessage.success(context: context, msg: 'Code copied');
                }
              },
              icon: const Icon(Icons.copy, size: 18),
              label: Text('Copy code',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: StoreProfileTheme.accentPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
