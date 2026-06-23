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
  });

  final List<AddressModel> addresses;
  final AddressModel? selected;
  final String userId;
  final VoidCallback onAddNew;

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
                    onChanged: (v) {
                      if (v != null) Navigator.pop(context, v);
                    },
                    child: Column(
                      children: addresses
                          .map((a) => RadioListTile<AddressModel>(
                                value: a,
                                activeColor: StoreProfileTheme.accentPink,
                                title: Text(
                                  a.addressType.isNotEmpty
                                      ? a.addressType
                                      : 'Address',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14),
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
                              ))
                          .toList(),
                    ),
                  ),
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