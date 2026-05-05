import 'package:flutter/material.dart';
import '../utils/constants.dart';

class UpdatePopup extends StatelessWidget {
  final VoidCallback onUpdate;
  final VoidCallback onSkip;
  final String latestVersion;

  const UpdatePopup({
    super.key,
    required this.onUpdate,
    required this.onSkip,
    required this.latestVersion,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // ❌ back button disable
      onPopInvokedWithResult: (didPop, result) {
        // kuch nahi karna, back already blocked hai
      },
      child: Dialog(
        backgroundColor: StoreProfileTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Column(
                children: [
                  Text(
                    "Update Available",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: StoreProfileTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "A new version ($latestVersion) is available. Please update the app.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: StoreProfileTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: StoreProfileTheme.border),
            Row(
              children: [
                // SKIP
                Expanded(
                  child: InkWell(
                    onTap: onSkip,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        "Skip",
                        style: TextStyle(
                          color: StoreProfileTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                Container(
                  width: 1,
                  height: 48,
                  color: StoreProfileTheme.border,
                ),

                // UPDATE
                Expanded(
                  child: InkWell(
                    onTap: onUpdate,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        "Update",
                        style: TextStyle(
                          color: StoreProfileTheme.accentPink, // 👈 highlight
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
