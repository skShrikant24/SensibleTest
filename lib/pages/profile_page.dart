import 'package:grabitt/services/address_api_service.dart';
import 'package:grabitt/services/selected_address_storage.dart';
import 'package:grabitt/utils/shared_classes.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grabitt/app_State/locale_provider.dart';
import 'package:grabitt/l10n/app_localizations.dart';
import 'package:grabitt/pages/address_management_page.dart';
import 'package:grabitt/pages/login_page.dart';
import 'package:grabitt/pages/order_history_page.dart';
import 'package:grabitt/services/auth_service.dart';
import 'package:grabitt/utils/constants.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatefulWidget {
  final ValueChanged<int> onSelectTab;
  const ProfilePage({super.key, required this.onSelectTab});

  /// Safe string from saved user map (API keys: Name, Email, phone, Sex, DateOfBirth, lan, lon).
  static String _str(Map<String, dynamic>? user, String key) {
    if (user == null) return '—';
    final v = user[key];
    return v?.toString().trim() ?? '—';
  }

  static void _showLanguageSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.read<LocaleProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: StoreProfileTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.selectLanguage,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(l10n.english),
                trailing: localeProvider.isEnglish
                    ? Icon(Icons.check, color: StoreProfileTheme.accentPink)
                    : null,
                onTap: () async {
                  await localeProvider.setEnglish();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(l10n.kannada),
                trailing: localeProvider.isKannada
                    ? Icon(Icons.check, color: StoreProfileTheme.accentPink)
                    : null,
                onTap: () async {
                  await localeProvider.setKannada();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<({Map<String, dynamic>? user, String address})>
      _getUserWithAddress() async {
    final user = await AuthService.instance.getSavedUser();

    String address = 'No address added';

    try {
      // First try loading selected address from local storage
      final selectedAddress = await SelectedAddressStorage.instance.load();

      if (selectedAddress != null) {
        address = selectedAddress.displaySummary;
      } else {
        // Fallback: fetch address from API after app reinstall/data clear
        final uid =
            user?['ID']?.toString() ?? user?['UserID']?.toString() ?? '';

        if (uid.isNotEmpty) {
          final addresses = await getAddressByUser(uid);

          if (addresses.isNotEmpty) {
            final firstAddress = addresses.first;

            // Save it locally so next time no API fallback is needed
            await SelectedAddressStorage.instance.save(firstAddress);

            address = firstAddress.displaySummary;
          }
        }
      }
    } catch (_) {}

    return (user: user, address: address);
  }

  @override
  State<ProfilePage> createState() => _ProfilePageState();

  static SliverToBoxAdapter _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: StoreProfileTheme.lightPink,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: StoreProfileTheme.border, width: 0.5),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: StoreProfileTheme.accentPink,
          ),
        ),
      ),
    );
  }

  static SliverToBoxAdapter _buildInfoRow(String title, String value) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static SliverToBoxAdapter _buildListItem(
    String title, {
    VoidCallback? onTap,
    Color? textColor,
    Color? trailingColor,
  }) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: StoreProfileTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: StoreProfileTheme.border.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: textColor ?? Colors.black87,
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios,
              size: 16, color: trailingColor ?? StoreProfileTheme.accentPink),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<({Map<String, dynamic>? user, String address})> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profileFuture = ProfilePage._getUserWithAddress();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _loadProfile();
    });
  }

  Future<void> _handleDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountRequestSent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );

    await AuthService.instance.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StoreProfileTheme.background,
      body: FutureBuilder<({Map<String, dynamic>? user, String address})>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: StoreProfileTheme.accentPink),
            );
          }
          final user = snapshot.data?.user;
          final address = snapshot.data?.address ?? '—';
          final name = ProfilePage._str(user, 'Name');
          final email = ProfilePage._str(user, 'Email');
          final phone = ProfilePage._str(user, 'phone');
          final sex = ProfilePage._str(user, 'Sex');
          final dob = ProfilePage._str(user, 'DateOfBirth');

          return CustomScrollView(
            slivers: [
              // 🔹 AppBar
              SliverAppBar(
                pinned: true,
                backgroundColor: StoreProfileTheme.background,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => widget.onSelectTab(0),
                ),
                centerTitle: true,
                title: Text(
                  AppLocalizations.of(context)!.profile,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ),

              // 🔹 User Name and Role (from login data)
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Text(
                      name == '—' ? AppLocalizations.of(context)!.guest : name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user != null
                          ? AppLocalizations.of(context)!.member
                          : AppLocalizations.of(context)!.notLoggedIn,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // 🔹 Personal Details Section (from login data)
              ProfilePage._buildSectionHeader(
                  AppLocalizations.of(context)!.personalDetails),
              ProfilePage._buildInfoRow(
                  AppLocalizations.of(context)!.email, email),
              ProfilePage._buildInfoRow(AppLocalizations.of(context)!.phone,
                  phone == '—' ? phone : '+91 $phone'),
              ProfilePage._buildInfoRow(
                  AppLocalizations.of(context)!.gender, sex),
              ProfilePage._buildInfoRow(
                  AppLocalizations.of(context)!.dateOfBirth, dob),
              ProfilePage._buildInfoRow(
                  AppLocalizations.of(context)!.address, address),
              ProfilePage._buildListItem(
                AppLocalizations.of(context)!.manageAddress,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddressManagementPage(),
                    ),
                  );
                  if (mounted) {
                    await _refreshProfile();
                  }
                },
              ),

              // 🔹 Language
              ProfilePage._buildListItem(
                AppLocalizations.of(context)!.language,
                onTap: () => ProfilePage._showLanguageSheet(context),
              ),

              // 🔹 Orders Section
              ProfilePage._buildSectionHeader(
                  AppLocalizations.of(context)!.orders),
              ProfilePage._buildListItem(
                AppLocalizations.of(context)!.viewOrders,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OrderHistoryPage(),
                    ),
                  );
                },
              ),

              // 🔹 Settings Section
              ProfilePage._buildListItem(
                AppLocalizations.of(context)!.logout,
                onTap: () async {
                  await AuthService.instance.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (route) => false,
                    );
                    ToastMessage.error(
                        context: context, msg: "Logout Successfully..!");
                  }
                },
              ),
              ProfilePage._buildListItem(
                AppLocalizations.of(context)!.deleteAccount,
                textColor: Colors.red.shade700,
                trailingColor: Colors.red.shade700,
                onTap: _handleDeleteAccount,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }
}
