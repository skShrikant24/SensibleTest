import 'package:grabitt/services/selected_address_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:grabitt/l10n/app_localizations.dart';
import 'package:grabitt/models/address_model.dart';
import 'package:grabitt/services/address_api_service.dart';
import 'package:grabitt/services/auth_service.dart';
import 'package:grabitt/utils/constants.dart';
import 'package:grabitt/utils/shared_classes.dart';

class AddressManagementPage extends StatefulWidget {
  const AddressManagementPage({super.key});

  @override
  State<AddressManagementPage> createState() => _AddressManagementPageState();
}

class _AddressManagementPageState extends State<AddressManagementPage> {
  List<AddressModel> _addresses = [];
  bool _loading = true;
  String? _userId;
  String? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _loadUserAndAddresses();
  }

  Future<void> _loadUserAndAddresses() async {
    setState(() => _loading = true);
    final user = await AuthService.instance.getSavedUser();
    final uid = user?['ID']?.toString() ?? user?['UserID']?.toString() ?? '';

    if (uid.isEmpty) {
      setState(() {
        _userId = null;
        _addresses = [];
        _selectedAddressId = null;
        _loading = false;
      });
      return;
    }
    _userId = uid;
    final list = await getAddressByUser(uid);
    final saved = await SelectedAddressStorage.instance.load();
    String? selectedId;
    if (saved != null && list.any((a) => a.id == saved.id)) {
      selectedId = saved.id.toString();
    } else if (list.isNotEmpty) {
      final first = list.first;

      await SelectedAddressStorage.instance.save(first);

      selectedId = first.id.toString();
    } else {
      await SelectedAddressStorage.instance.clear();
    }
    if (mounted) {
      setState(() {
        _addresses = list;
        _selectedAddressId = selectedId;
        _loading = false;
      });
    }
  }

  Future<void> _openAddAddress() async {
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
          // onSaved: () => _loadUserAndAddresses(),
        ),
      ),
    );
    if (result == true && mounted) {
      await _loadUserAndAddresses();
    }
  }

  Future<void> _openEditAddress(AddressModel address) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddressFormPage(
          userId: _userId ?? address.userID,
          address: address,
          // onSaved: () => _loadUserAndAddresses(),
        ),
      ),
    );
    if (result == true && mounted) {
      // await Future.delayed(const Duration(milliseconds: 300));
      // final updatedList = await getAddressByUser(_userId!);
      // final selected = await SelectedAddressStorage.instance.load();

      // if (selected != null) {
      //   try {
      //     final updatedSelected = updatedList.firstWhere(
      //       (a) => a.id == selected.id,
      //     );

      //     await SelectedAddressStorage.instance.save(updatedSelected);
      //   } catch (_) {
      //     if (updatedList.isNotEmpty) {
      //       await SelectedAddressStorage.instance.save(updatedList.first);
      //       setState(() {
      //         _selectedAddressId = updatedList.first.id.toString();
      //       });
      //     } else {
      //       await SelectedAddressStorage.instance.clear();
      //       setState(() {
      //         _selectedAddressId = null;
      //       });
      //     }
      //   }
      // }
      await _loadUserAndAddresses();
    }
  }

  Future<void> _deleteAddress(AddressModel address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text(
          'Delete this address?\n${address.displaySummary}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final success = await deleteAddress(address.id);
    if (!mounted) return;
    if (success) {
      final selected = await SelectedAddressStorage.instance.load();

      if (selected != null && selected.id == address.id) {
        await Future.delayed(const Duration(milliseconds: 300));
        final updatedAddresses = await getAddressByUser(_userId!);

        if (updatedAddresses.isNotEmpty) {
          await SelectedAddressStorage.instance.save(updatedAddresses.first);
          setState(() {
            _selectedAddressId = updatedAddresses.first.id.toString();
          });
        } else {
          await SelectedAddressStorage.instance.clear();
          setState(() {
            _selectedAddressId = null;
          });
        }
      }
      if (!mounted) return;
      ToastMessage.success(context: context, msg: 'Address deleted');
      await _loadUserAndAddresses();
    } else {
      ToastMessage.error(context: context, msg: 'Failed to delete address');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StoreProfileTheme.background,
      appBar: AppBar(
        backgroundColor: StoreProfileTheme.background,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.manageAddress,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: StoreProfileTheme.accentPink,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: StoreProfileTheme.accentPink),
            )
          : _userId == null || _userId!.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!
                              .pleaseLogInToManageAddresses,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _addresses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 72,
                            color: StoreProfileTheme.accentPink
                                .withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No addresses yet',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: StoreProfileTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to add an address',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: StoreProfileTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUserAndAddresses,
                      color: StoreProfileTheme.accentPink,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: _addresses.length,
                        itemBuilder: (context, index) {
                          final a = _addresses[index];
                          final isSelected = a.id == _selectedAddressId;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              await SelectedAddressStorage.instance.save(a);

                              if (!mounted) return;

                              setState(() {
                                _selectedAddressId = a.id.toString();
                              });

                              ToastMessage.success(
                                context: this.context,
                                msg: 'Selected delivery address updated',
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected
                                      ? StoreProfileTheme.accentPink
                                      : StoreProfileTheme.border
                                          .withValues(alpha: 0.5),
                                  width: isSelected ? 1.4 : 1,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isSelected
                                      ? StoreProfileTheme.lightPink
                                          .withValues(alpha: 0.15)
                                      : Colors.white,
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: isSelected
                                        ? StoreProfileTheme.accentPink
                                        : Colors.grey.shade300,
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          )
                                        : null,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          a.addressType.isNotEmpty
                                              ? a.addressType
                                              : 'Address',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? StoreProfileTheme.accentPink
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: StoreProfileTheme.accentPink,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'Selected',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      a.displaySummary,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: StoreProfileTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit_outlined,
                                          color: StoreProfileTheme.accentPink,
                                        ),
                                        onPressed: () => _openEditAddress(a),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: StoreProfileTheme.ctaAction,
                                        ),
                                        onPressed: () => _deleteAddress(a),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: _userId != null && _userId!.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openAddAddress,
              backgroundColor: StoreProfileTheme.accentPink,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                AppLocalizations.of(context)!.addAddress,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }
}

class AddressFormPage extends StatefulWidget {
  final String userId;
  final AddressModel? address;
  // final VoidCallback? onSaved;

  const AddressFormPage({
    super.key,
    required this.userId,
    this.address,
    // this.onSaved,
  });

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressType = TextEditingController();
  final _addressLine1 = TextEditingController();
  final _addressLine2 = TextEditingController();
  final _landmark = TextEditingController();
  final _area = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _lon = TextEditingController();
  final _lan = TextEditingController();

  final _addressTypeFocus = FocusNode();
  final _addressLine1Focus = FocusNode();
  final _addressLine2Focus = FocusNode();
  final _landmarkFocus = FocusNode();
  final _areaFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _districtFocus = FocusNode();
  final _stateFocus = FocusNode();
  final _pincodeFocus = FocusNode();

  bool _submitted = false;

  bool _saving = false;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      final a = widget.address!;
      _addressType.text = a.addressType;
      _addressLine1.text = a.addressLine1;
      _addressLine2.text = a.addressLine2;
      _landmark.text = a.landmark;
      _area.text = a.area;
      _city.text = a.city;
      _district.text = a.district;
      _state.text = a.state;
      _pincode.text = a.pincode;
      _lon.text = a.lon;
      _lan.text = a.lan;
    }
  }

  @override
  void dispose() {
    _addressType.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _landmark.dispose();
    _area.dispose();
    _city.dispose();
    _district.dispose();
    _state.dispose();
    _pincode.dispose();
    _lon.dispose();
    _lan.dispose();
    _addressTypeFocus.dispose();
    _addressLine1Focus.dispose();
    _addressLine2Focus.dispose();
    _landmarkFocus.dispose();
    _areaFocus.dispose();
    _cityFocus.dispose();
    _districtFocus.dispose();
    _stateFocus.dispose();
    _pincodeFocus.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        if (mounted) {
          ToastMessage.warning(
            context: context,
            msg: 'Location permission denied',
          );
        }
        setState(() => _loadingLocation = false);
        return;
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ToastMessage.warning(
            context: context,
            msg: 'Location services are disabled',
          );
        }
        setState(() => _loadingLocation = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (mounted) {
        setState(() {
          _lon.text = position.longitude.toString();
          _lan.text = position.latitude.toString();
        });
        ToastMessage.success(
          context: context,
          msg: 'Location updated',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.error(
          context: context,
          msg: 'Could not get location',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _submit() async {
    if (_saving) return;

    setState(() {
      _submitted = true;
    });
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final at = _addressType.text.trim();
    final a1 = _addressLine1.text.trim();
    final a2 = _addressLine2.text.trim();
    final lm = _landmark.text.trim();
    final ar = _area.text.trim();
    final ci = _city.text.trim();
    final di = _district.text.trim();
    final st = _state.text.trim();
    final pi = _pincode.text.trim();
    final lon = _lon.text.trim();
    final lan = _lan.text.trim();

    // if (a1.isEmpty) {
    //   ToastMessage.warning(context: context, msg: 'Address line 1 is required');
    //   setState(() => _saving = false);
    //   return;
    // }

    if (lon.isEmpty || lan.isEmpty || lon == '0' || lan == '0') {
      ToastMessage.warning(
        context: context,
        msg: 'Please get current location before saving address',
      );
      setState(() => _saving = false);
      return;
    }

    bool success;
    if (widget.address != null) {
      success = await updateAddress(
        id: widget.address!.id,
        addressType: at,
        addressLine1: a1,
        addressLine2: a2,
        landmark: lm,
        area: ar,
        city: ci,
        district: di,
        state: st,
        pincode: pi,
        lon: lon,
        lan: lan,
      );
    } else {
      success = await addAddress(
        userID: widget.userId,
        addressType: at,
        addressLine1: a1,
        addressLine2: a2,
        landmark: lm,
        area: ar,
        city: ci,
        district: di,
        state: st,
        pincode: pi,
        lon: lon,
        lan: lan,
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      ToastMessage.success(
        context: context,
        msg: widget.address != null ? 'Address updated' : 'Address added',
      );
      // widget.onSaved?.call();
      Navigator.pop(context, true);
    } else {
      ToastMessage.error(
        context: context,
        msg: 'Something went wrong. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.address != null;
    return Scaffold(
      backgroundColor: StoreProfileTheme.background,
      appBar: AppBar(
        backgroundColor: StoreProfileTheme.background,
        elevation: 0,
        title: Text(
          isEdit
              ? AppLocalizations.of(context)!.editAddress
              : AppLocalizations.of(context)!.addAddress,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: StoreProfileTheme.accentPink,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          children: [
            _buildField(
              'Address type (e.g. Home, Work)',
              _addressType,
              required: true,
              focusNode: _addressTypeFocus,
              nextFocus: _addressLine1Focus,
            ),
            _buildField(
              'Address line 1 *',
              _addressLine1,
              required: true,
              focusNode: _addressLine1Focus,
              nextFocus: _addressLine2Focus,
            ),
            _buildField(
              'Address line 2',
              _addressLine2,
              focusNode: _addressLine2Focus,
              nextFocus: _landmarkFocus,
            ),
            _buildField(
              'Landmark',
              _landmark,
              focusNode: _landmarkFocus,
              nextFocus: _areaFocus,
            ),
            _buildField(
              'Area',
              _area,
              required: true,
              focusNode: _areaFocus,
              nextFocus: _cityFocus,
            ),
            _buildField(
              'City',
              _city,
              required: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r"[a-zA-Z\s]"),
                ),
              ],
              focusNode: _cityFocus,
              nextFocus: _districtFocus,
            ),
            _buildField(
              'District',
              _district,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r"[a-zA-Z\s]"),
                ),
              ],
              focusNode: _districtFocus,
              nextFocus: _stateFocus,
            ),
            _buildField(
              'State',
              _state,
              required: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r"[a-zA-Z\s]"),
                ),
              ],
              focusNode: _stateFocus,
              nextFocus: _pincodeFocus,
            ),
            _buildField(
              'Pincode',
              _pincode,
              required: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              focusNode: _pincodeFocus,
              isLastField: true,
            ),
            const SizedBox(height: 12),
            Text(
              'Location (lat/lng)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: StoreProfileTheme.textPrimary,
              ),
            ),
            if (_submitted &&
                (_lon.text.trim().isEmpty ||
                    _lan.text.trim().isEmpty ||
                    _lon.text.trim() == '0' ||
                    _lan.text.trim() == '0'))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Please get current location',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lan,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Latitude',
                      filled: true,
                      fillColor: StoreProfileTheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: StoreProfileTheme.border,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lon,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Longitude',
                      filled: true,
                      fillColor: StoreProfileTheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: StoreProfileTheme.border,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _loadingLocation ? null : _getCurrentLocation,
                icon: _loadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  _loadingLocation
                      ? 'Getting location...'
                      : 'Get current location',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: StoreProfileTheme.accentPink,
                  side: BorderSide(color: StoreProfileTheme.accentPink),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                // onPressed: _saving ||
                //         _lon.text.trim().isEmpty ||
                //         _lan.text.trim().isEmpty ||
                //         _lon.text.trim() == '0' ||
                //         _lan.text.trim() == '0'
                //     ? null
                //     : _submit,
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: StoreProfileTheme.accentPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEdit ? 'Update Address' : 'Save Address',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool required = false,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    TextInputType keyboardType = TextInputType.text,
    bool isLastField = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: StoreProfileTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: TextCapitalization.words,
            textInputAction:
                isLastField ? TextInputAction.done : TextInputAction.next,
            onFieldSubmitted: (_) {
              if (isLastField) {
                FocusScope.of(context).unfocus();
              } else if (nextFocus != null) {
                FocusScope.of(context).requestFocus(nextFocus);
              }
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: StoreProfileTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: StoreProfileTheme.accentPink, width: 1.5),
              ),
            ),
            validator: required
                ? (v) {
                    if (v == null || v.toString().trim().isEmpty) {
                      if (label.startsWith('Address type')) {
                        return 'Please enter address type';
                      }
                      return 'Please enter $label';
                    }
                    if (label == 'Pincode') {
                      if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                        return 'Enter valid 6 digit pincode';
                      }
                    }

                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
