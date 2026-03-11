import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:GraBiTT/app_State/locale_provider.dart';
import 'package:GraBiTT/l10n/app_localizations.dart';
import 'package:GraBiTT/pages/address_management_page.dart';
import 'package:GraBiTT/pages/login_page.dart';
import 'package:GraBiTT/services/auth_service.dart';
import 'package:GraBiTT/utils/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

const String _geoapifyApiKey = 'd23ffd31df254fe59912a07a909c69e4';

class ProfilePage extends StatelessWidget {
  final ValueChanged<int> onSelectTab;
  ProfilePage({super.key, required this.onSelectTab});

  /// Safe string from saved user map (API keys: Name, Email, phone, Sex, DateOfBirth, lan, lon).
  static String _str(Map<String, dynamic>? user, String key) {
    if (user == null) return '—';
    final v = user[key];
    return v?.toString().trim() ?? '—';
  }

  /// Fetches formatted address from Geoapify reverse geocode API.
  /// Returns [features][0].[properties].[formatted] or null on error.
  static Future<String?> _fetchFormattedAddress(String lat, String lon) async {
    try {
      final uri = Uri.parse(
        'https://api.geoapify.com/v1/geocode/reverse?lat=$lat&lon=$lon&apiKey=$_geoapifyApiKey',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      final features = json?['features'] as List<dynamic>?;
      if (features == null || features.isEmpty) return null;
      final first = features.first;
      if (first is! Map<String, dynamic>) return null;
      final props = first['properties'];
      if (props is! Map<String, dynamic>) return null;
      final formatted = props['formatted']?.toString();
      return formatted?.trim();
    } catch (_) {
      return null;
    }
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
                trailing: localeProvider.isEnglish ? Icon(Icons.check, color: StoreProfileTheme.accentPink) : null,
                onTap: () async {
                  await localeProvider.setEnglish();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(l10n.kannada),
                trailing: localeProvider.isKannada ? Icon(Icons.check, color: StoreProfileTheme.accentPink) : null,
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

  /// Loads saved user and resolves formatted address when lan/lon present.
  static Future<({Map<String, dynamic>? user, String address})> _getUserWithAddress() async {
    final user = await AuthService.instance.getSavedUser();
    final lat = user?['lan']?.toString().trim();
    final lon = user?['lon']?.toString().trim();
    String address = '—';
    if (lat != null && lat.isNotEmpty && lon != null && lon.isNotEmpty) {
      address = await _fetchFormattedAddress(lat, lon) ?? '$lat, $lon';
    }
    return (user: user, address: address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StoreProfileTheme.background,
      body: FutureBuilder<({Map<String, dynamic>? user, String address})>(
        future: _getUserWithAddress(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: StoreProfileTheme.accentPink),
            );
          }
          final user = snapshot.data?.user;
          final address = snapshot.data?.address ?? '—';
          final name = _str(user, 'Name');
          final email = _str(user, 'Email');
          final phone = _str(user, 'phone');
          final sex = _str(user, 'Sex');
          final dob = _str(user, 'DateOfBirth');

          return CustomScrollView(
            slivers: [
              // 🔹 AppBar
              SliverAppBar(
                pinned: true,
                backgroundColor: StoreProfileTheme.background,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => onSelectTab(0),
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

              // 🔹 Header Section with Banner + Avatar
              // SliverToBoxAdapter(
              //   child: Stack(
              //     alignment: Alignment.center,
              //     children: [
              //       Container(
              //         height: 120,
              //         decoration: const BoxDecoration(
              //           gradient: LinearGradient(
              //             colors: [
              //               Color(0xFFF472B6),
              //               Color(0xFFFBCFE8),
              //             ],
              //             begin: Alignment.centerLeft,
              //             end: Alignment.centerRight,
              //           ),
              //         ),
              //       ),
              //       Positioned(
              //         bottom: -40,
              //         child: CircleAvatar(
              //           radius: 45,
              //           backgroundColor: StoreProfileTheme.surface,
              //           child: ClipOval(
              //             child: Image.asset(
              //               'assets/images/profile.png',
              //               width: 84,
              //               height: 84,
              //               fit: BoxFit.cover,
              //               errorBuilder: (context, error, stackTrace) {
              //                 return Image.network(
              //                   'https://placehold.co/400x400.png',
              //                   width: 84,
              //                   height: 84,
              //                   fit: BoxFit.cover,
              //                   errorBuilder: (context, error, stackTrace) {
              //                     return Container(
              //                       width: 84,
              //                       height: 84,
              //                       color: Colors.grey[300],
              //                       child: const Icon(
              //                         Icons.person,
              //                         color: Colors.grey,
              //                         size: 40,
              //                       ),
              //                     );
              //                   },
              //                 );
              //               },
              //             ),
              //           ),
              //         ),
              //       ),
              //       Positioned(
              //         top: 60,
              //         right: 16,
              //         child: CircleAvatar(
              //           radius: 16,
              //           backgroundColor: StoreProfileTheme.surface,
              //           child: Icon(Icons.edit, size: 16, color: StoreProfileTheme.accentPink),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              // const SliverToBoxAdapter(child: SizedBox(height: 60)),

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
                      user != null ? AppLocalizations.of(context)!.member : AppLocalizations.of(context)!.notLoggedIn,
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
              _buildSectionHeader(AppLocalizations.of(context)!.personalDetails),
              _buildInfoRow(AppLocalizations.of(context)!.email, email),
              _buildInfoRow(AppLocalizations.of(context)!.phone, phone == '—' ? phone : '+91 $phone'),
              _buildInfoRow(AppLocalizations.of(context)!.gender, sex),
              _buildInfoRow(AppLocalizations.of(context)!.dateOfBirth, dob),
              _buildInfoRow(AppLocalizations.of(context)!.address, address),
              _buildListItem(
                AppLocalizations.of(context)!.manageAddress,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddressManagementPage(),
                    ),
                  );
                },
              ),

          // 🔹 Language
          _buildListItem(
            AppLocalizations.of(context)!.language,
            onTap: () => _showLanguageSheet(context),
          ),

          // 🔹 Orders Section
       /*   _buildSectionHeader(AppLocalizations.of(context)!.orders),
          _buildListItem(AppLocalizations.of(context)!.viewOrders),*/

          // 🔹 Settings Section
          _buildListItem(
            AppLocalizations.of(context)!.logout,
            onTap: () async {
              await AuthService.instance.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.logoutSuccessfully, style: const TextStyle(color: Colors.white)),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }

  // 🔸 Helper Widgets

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
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
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

  static SliverToBoxAdapter _buildListItem(String title, {VoidCallback? onTap}) {
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: StoreProfileTheme.accentPink),
          onTap: onTap,
        ),
      ),
    );
  }
}
