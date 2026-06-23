import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grabitt/utils/constants.dart';
import 'package:grabitt/utils/shared_classes.dart';

class CheckoutPaymentCard extends StatelessWidget {
  const CheckoutPaymentCard({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: checkoutCardDecoration(),
      child: RadioGroup<String>(
        groupValue: selected,
        onChanged: (v) { if (v != null) onChanged(v); },
        child: Column(
          children: [
            _ActiveTile(
              value: 'cod',
              icon: Icons.home,
              label: 'Cash On Delivery',
            ),
            _divider(),
            _LockedTile(value: 'upi', icon: Icons.qr_code, label: 'UPI',
                onTap: () => _showComingSoon(context)),
            _divider(),
            _LockedTile(value: 'grabpoints', icon: Icons.wallet, label: 'Grab Points',
                onTap: () => _showComingSoon(context)),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(
      height: 1,
      color: StoreProfileTheme.border.withValues(alpha: 0.6));

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _ComingSoonDialog(),
    );
  }
}

class _ActiveTile extends StatelessWidget {
  const _ActiveTile({
    required this.value,
    required this.icon,
    required this.label,
  });

  final String value;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      value: value,
      activeColor: StoreProfileTheme.accentPink,
      title: Row(
        children: [
          Icon(icon, color: StoreProfileTheme.accentPink),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 14)),
        ],
      ),
    );
  }
}

class _LockedTile extends StatelessWidget {
  const _LockedTile({
    required this.value,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String value;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.grey),
      title: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
      ),
      trailing: const Icon(Icons.lock, color: Colors.grey, size: 18),
    );
  }
}

class _ComingSoonDialog extends StatelessWidget {
  const _ComingSoonDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 40, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              'Coming Soon 🚀',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'This payment option is under development.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}