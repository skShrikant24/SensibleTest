import 'package:GraBiTT/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GraBiTT/pages/profile_page.dart';
import 'package:GraBiTT/pages/store_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  /// On Store page: hide bottom bar when scrolling down, show when scrolling up.
  bool _hideBottomBar = false;

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

// class _MainShellState extends State<MainShell> {
//   int _index = 0;
//
//   final _pages = const [
//     HomePage(),
//     _PlaceholderPage(title: 'Courses'),
//     _PlaceholderPage(title: 'Store'),
//     _PlaceholderPage(title: 'Feed'),
//     _PlaceholderPage(title: 'Profile'),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBody: true,
//       backgroundColor: const Color(0xFFF4F5F7),
//       body: _pages[_index],
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//         child: _BottomBar(
//           index: _index,
//           onChanged: (i) => setState(() => _index = i),
//         ),
//       ),
//     );
//   }
// }

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
    /*  _BarItem(icon: Icons.home_filled, inactive: Icons.home_outlined, label: 'Home'),
      _BarItem(icon: Icons.menu_book_rounded, inactive: Icons.menu_book_outlined, label: 'Courses'),
      _BarItem(icon: Icons.storefront_rounded, inactive: Icons.storefront_outlined, label: 'Store'),*/
      _BarItem(icon: Icons.home_filled, inactive: Icons.home_outlined, label: 'Store'),
      _BarItem(icon: Icons.person_rounded, inactive: Icons.person_outline_rounded, label: 'Profile'),
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
  const _BottomBarButton({required this.item, required this.selected, required this.onTap});
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
                      color: selected ? const Color(0xFFFF0000).withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Icon(selected ? item.icon : item.inactive, color: color, size: 24),
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

