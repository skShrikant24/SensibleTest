import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grabitt/utils/constants.dart';

/// A single label + amount row in the order totals card.
class CheckoutPriceRow extends StatelessWidget {
  const CheckoutPriceRow(
    this.label,
    this.amount, {
    super.key,
    this.isFinal = false,
    this.valueColor,
    this.showNil = false,
  });

  final String label;
  final double amount;
  final bool isFinal;
  final Color? valueColor;

  /// When true, shows "Nil" instead of "₹0".
  final bool showNil;

  @override
  Widget build(BuildContext context) {
    final isNegative = amount < 0;
    final isZero = amount == 0;

    final String text;
    if (showNil && isZero) {
      text = 'Nil';
    } else if (isNegative) {
      text = '- ${AppConstants.currencySymbol}${amount.abs().toStringAsFixed(0)}';
    } else {
      text = '${AppConstants.currencySymbol}${amount.toStringAsFixed(0)}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
            text,
            style: GoogleFonts.poppins(
              fontSize: isFinal ? 18 : 14,
              fontWeight: isFinal ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? StoreProfileTheme.accentPink,
            ),
          ),
        ],
      ),
    );
  }
}