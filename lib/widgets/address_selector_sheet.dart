import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grabitt/models/address_model.dart';
import 'package:grabitt/utils/constants.dart';

class AddressSelectorSheet extends StatelessWidget {
  const AddressSelectorSheet({
    super.key,
    required this.addresses,
    required this.selected,
    required this.userId,
    required this.onAddNew,
    this.onEdit,
    this.onManage,
  });

  final List<AddressModel> addresses;
  final AddressModel? selected;
  final String userId;
  final VoidCallback onAddNew;
  final ValueChanged<AddressModel>? onEdit;
  final VoidCallback? onManage;

  bool _isAddressSelected(AddressModel a) {
    if (selected == null) return false;
    if (selected!.id.isNotEmpty && a.id.isNotEmpty) {
      return selected!.id == a.id;
    }
    return selected == a ||
        (selected!.pincode == a.pincode &&
            selected!.addressLine1.toLowerCase().trim() ==
                a.addressLine1.toLowerCase().trim());
  }

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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select delivery address',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  if (onManage != null)
                    GestureDetector(
                      onTap: onManage,
                      child: Text(
                        'Manage',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: StoreProfileTheme.accentPink,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  for (final a in addresses) ...[
                    _buildAddressCard(context, a),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 6),
                  // Add new address button
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onAddNew,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: StoreProfileTheme.lightPink.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: StoreProfileTheme.accentPink.withValues(alpha: 0.5),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 20,
                            color: StoreProfileTheme.accentPink,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add new address',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: StoreProfileTheme.accentPink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, AddressModel a) {
    final isSelected = _isAddressSelected(a);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.pop(context, a),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? StoreProfileTheme.lightPink.withValues(alpha: 0.35)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? StoreProfileTheme.accentPink
                : Colors.grey.withValues(alpha: 0.25),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? StoreProfileTheme.accentPink.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio Indicator
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected
                    ? StoreProfileTheme.accentPink
                    : Colors.grey[400],
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Address details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          a.addressType.isNotEmpty ? a.addressType : 'Address',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isSelected
                                ? StoreProfileTheme.accentPink
                                : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: StoreProfileTheme.accentPink,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'DELIVERING HERE',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a.displaySummary,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.black87
                          : StoreProfileTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            // Edit Button
            if (onEdit != null) ...[
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onEdit!(a),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: StoreProfileTheme.accentPink,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Edit',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: StoreProfileTheme.accentPink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
