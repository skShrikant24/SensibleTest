import 'dart:convert';

import 'package:GraBiTT/utils/api_helper.dart';
import 'package:GraBiTT/utils/constants.dart';
import 'package:GraBiTT/widgets/home_banner_slider.dart';
import 'package:GraBiTT/widgets/update_popup.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GraBiTT/l10n/app_localizations.dart';
import 'package:GraBiTT/pages/profile_page.dart';
import 'package:GraBiTT/pages/store_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;

  /// On Store page: hide bottom bar when scrolling down, show when scrolling up.
  bool _hideBottomBar = false;

  bool _isDialogShowing = false;
  bool _isBannerShowing = false;
  static const String _bannerDateKey = "home_banner_last_seen";

  @override
  void initState() {
    super.initState();
    // App lifecycle observer add
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //await _checkAppUpdate();
      if (!_isDialogShowing) {
      //  await _checkHomeBanner();
      }
    });
  }

  @override
  void dispose() {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Called when app resumes from background / Play Store
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    /* if (state == AppLifecycleState.resumed) {
      _checkAppUpdate();
      if (!_isDialogShowing) {
        _checkHomeBanner();
      }
    }
    }*/
  }

  Future<void> _checkHomeBanner() async {
    if (_isBannerShowing) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      final today = DateTime.now().toIso8601String().split('T').first;

      final lastSeen = prefs.getString(_bannerDateKey);

      if (lastSeen == today) return;

      final response = await http.get(
        Uri.parse(
          "https://grabitt.in/Webservice.asmx/GetHomeBanner",
        ),
      );

      if (response.statusCode != 200) return;

      final cleaned = response.body
          .replaceAll(RegExp(r'<\?xml.*?\?>'), '')
          .replaceAll(RegExp(r'<string[^>]*>'), '')
          .replaceAll('</string>', '')
          .trim();

      final json = jsonDecode(cleaned);

      if (json["status"] != "Success") return;

      final data = json["data"];

      if (data == null || data is! List || data.isEmpty) return;

      final List<HomeBannerModel> banners = [];

      for (final item in data) {
        if (item == null) continue;
        if (item["IsActive"] != true) continue;

        final image = item["Image"]?.toString() ?? "";
        if (image.isEmpty) continue;

        banners.add(
          HomeBannerModel(
            imageUrl: ApiHelper.buildUrl(image) ?? '',
            title: item["ImageTitle"]?.toString(),
            description: item["ImageDescription"]?.toString(),
          ),
        );
      }

      if (banners.isEmpty) return;
      if (!mounted) return;
      _showBannerPopup(
        banners,
        today,
      );
    } catch (_) {}
  }

  void _showBannerPopup(
    List<HomeBannerModel> banners,
    String today,
  ) {
    _isBannerShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => HomeBannerPopup(
        banners: banners,
        onClose: () async {
          final prefs = await SharedPreferences.getInstance();

          await prefs.setString(
            _bannerDateKey,
            today,
          );

          _isBannerShowing = false;

          if (mounted) {
            Navigator.pop(context);
          }
        },
      ),
    ).then((_) {
      _isBannerShowing = false;
    });
  }

  // ================= VERSION CHECK =================
  /* Future<void> _checkAppUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final res = await http.get(
        Uri.parse("https://grabitt.in/Webservice.asmx/GetCustomerAppVersion"),
      );
      if (res.statusCode != 200) return;

      final cleanedBody = res.body
          .replaceAll(RegExp(r'<\?xml.*?\?>'), '')
          .replaceAll(RegExp(r'<string[^>]*>'), '')
          .replaceAll('</string>', '')
          .trim();

      debugPrint("Version API Response => $cleanedBody");

      final jsonData = jsonDecode(cleanedBody);

      final data = jsonData["data"];

      final latestVersion = data["latest_version"].toString();
      final forceUpdate = data["force_update"] ?? false;

      final serverBuild = int.tryParse(data["build"].toString()) ?? 0;
      final prefs = await SharedPreferences.getInstance();
      final skippedVersion = prefs.getString("skipped_version");

      final shouldUpdate = serverBuild > currentBuild;

      if (!_isDialogShowing &&
          shouldUpdate &&
          skippedVersion != latestVersion) {
        _isDialogShowing = true;

        _showUpdatePopup(
          latestVersion: latestVersion,
          force: forceUpdate,
        );
      }
    } catch (e) {
      debugPrint("Version check error: $e");
    }
  }*/

  // ================= POPUP =================

  // ignore: unused_element
  void _showUpdatePopup({
    required String latestVersion,
    required bool force,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdatePopup(
        latestVersion: latestVersion,

        // ✅ Skip (only if not force)
        onSkip: force
            ? null
            : () {
                _handleSkip(latestVersion);
              },

        // ✅ Update
        onUpdate: () async {
          if (mounted) {
            Navigator.pop(context);
          }

          await _openPlayStore();
        },
      ),
    ).then((_) async {
      // ✅ Reset only after popup closes
      _isDialogShowing = false;
      //await _checkHomeBanner(); // important
    });
  }

  // ================= SKIP =================
  Future<void> _handleSkip(String latestVersion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("skipped_version", latestVersion);

    if (mounted) Navigator.pop(context);
  }

  // ================= PLAY STORE =================

  Future<void> _openPlayStore() async {
    const packageName = "com.infisoft.grabit";

    final Uri marketUri = Uri.parse("market://details?id=$packageName");
    final Uri webUri = Uri.parse(
      "https://play.google.com/store/apps/details?id=$packageName",
    );

    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("PlayStore launch error: $e");
    }
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return StorePage(
          onSelectTab: (i) => setState(() => _index = i),
          onScrollDirection: (scrollingDown) {
            setState(() => _hideBottomBar = scrollingDown);
          },
        );
      case 2:
      default:
        return ProfilePage(
          onSelectTab: (i) => setState(() => _index = i),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBottomBar = _index != 0 || !_hideBottomBar;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF4F5F7),
      body: Stack(
        children: [
          Positioned.fill(child: _buildPage(_index)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              offset: showBottomBar ? Offset.zero : const Offset(0, 1),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _BottomBar(
                  index: _index,
                  onChanged: (i) => setState(() {
                    _index = i;
                    _hideBottomBar = false;
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      _BarItem(
          icon: Icons.home_filled,
          inactive: Icons.home_outlined,
          label: l10n.store),
      _BarItem(
          icon: Icons.person_rounded,
          inactive: Icons.person_outline_rounded,
          label: l10n.profile),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < items.length; i++)
              _BottomBarButton(
                item: items[i],
                selected: i == index,
                onTap: () => onChanged(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _BarItem {
  final IconData icon;
  final IconData inactive;
  final String label;
  _BarItem({required this.icon, required this.inactive, required this.label});
}

class _BottomBarButton extends StatelessWidget {
  const _BottomBarButton(
      {required this.item, required this.selected, required this.onTap});
  final _BarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? StoreProfileTheme.accentPink : Colors.grey[600]!;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 36,
                    width: 46,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFFF0000).withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Icon(selected ? item.icon : item.inactive,
                      color: color, size: 24),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
