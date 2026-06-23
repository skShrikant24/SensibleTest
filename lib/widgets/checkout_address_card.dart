import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grabitt/l10n/app_localizations.dart';
import 'package:grabitt/models/address_model.dart';
import 'package:grabitt/services/address_api_service.dart';
import 'package:grabitt/utils/constants.dart';
import 'package:grabitt/utils/shared_classes.dart';

class CheckoutAddressCard extends StatelessWidget {
  const CheckoutAddressCard({
    super.key,
    required this.isLoading,
    required this.userId,
    required this.addresses,
    required this.selectedAddress,
    required this.isCheckingRadius,
    required this.radiusStatus,
    required this.onChangeTap,
  });

  final bool isLoading;
  final String? userId;
  final List<AddressModel> addresses;
  final AddressModel? selectedAddress;
  final bool isCheckingRadius;
  final OrderRadiusCheckResult? radiusStatus;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: checkoutCardDecoration(),
      child: _buildContent(context, l10n),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    if (isLoading) return _LoadingIndicator();

    if (userId == null || userId!.isEmpty) {
      return _InfoRow(
        icon: Icons.location_off,
        text: l10n.logInToAddOrSelectAddress,
      );
    }

    if (addresses.isEmpty) {
      return _EmptyAddressState(l10n: l10n, onAddTap: onChangeTap);
    }

    return _AddressDisplay(
      l10n: l10n,
      selectedAddress: selectedAddress,
      isCheckingRadius: isCheckingRadius,
      radiusStatus: radiusStatus,
      onChangeTap: onChangeTap,
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: StoreProfileTheme.accentPink,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: StoreProfileTheme.accentPink),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: GoogleFonts.poppins(fontSize: 13)),
        ),
      ],
    );
  }
}

class _EmptyAddressState extends StatelessWidget {
  const _EmptyAddressState({required this.l10n, required this.onAddTap});

  final AppLocalizations l10n;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          icon: Icons.add_location_alt,
          text: l10n.noAddressAddedYet,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onAddTap,
            icon: const Icon(Icons.add, size: 20),
            label: Text(l10n.addAddress),
            style: OutlinedButton.styleFrom(
              foregroundColor: StoreProfileTheme.accentPink,
              side: BorderSide(color: StoreProfileTheme.accentPink),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressDisplay extends StatelessWidget {
  const _AddressDisplay({
    required this.l10n,
    required this.selectedAddress,
    required this.isCheckingRadius,
    required this.radiusStatus,
    required this.onChangeTap,
  });

  final AppLocalizations l10n;
  final AddressModel? selectedAddress;
  final bool isCheckingRadius;
  final OrderRadiusCheckResult? radiusStatus;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on_outlined,
                color: StoreProfileTheme.accentPink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedAddress != null
                    ? '${selectedAddress!.addressType.isNotEmpty ? '${selectedAddress!.addressType}\n' : ''}${selectedAddress!.displaySummary}'
                    : l10n.selectDeliveryAddress,
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: onChangeTap,
              child: Text(
                selectedAddress != null ? l10n.change : l10n.select,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: StoreProfileTheme.accentPink,
                ),
              ),
            ),
          ],
        ),
        _RadiusStatus(
          isChecking: isCheckingRadius,
          status: radiusStatus,
        ),
      ],
    );
  }
}

class _RadiusStatus extends StatelessWidget {
  const _RadiusStatus({required this.isChecking, required this.status});

  final bool isChecking;
  final OrderRadiusCheckResult? status;

  @override
  Widget build(BuildContext context) {
    if (isChecking) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
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
      );
    }

    if (status == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        status!.userMessage,
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: status!.allowed ? Colors.green[700] : Colors.red[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}