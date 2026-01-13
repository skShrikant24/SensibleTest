import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GrabIt/pages/cart_page.dart';
import 'package:GrabIt/pages/my_courses_page.dart';
import 'package:GrabIt/pages/simple_page.dart';
import 'package:GrabIt/pages/splash_page.dart';
import 'package:GrabIt/utils/constants.dart';
import 'drawer_item.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.onSelectTab,
    this.currentTabIndex = 0,
  });

  final ValueChanged<int> onSelectTab;
  final int currentTabIndex;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                Text(
                  AppConstants.USER_NAME,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Main navigation items
            DrawerItem(
              icon: Icons.home_filled,
              label: 'Home',
              selected: currentTabIndex == 0,
              onTap: () {
                Navigator.pop(context);
                onSelectTab(0);
              },
            ),
            const SizedBox(height: 8),
            DrawerItem(
              icon: Icons.menu_book_rounded,
              label: 'All Courses',
              selected: currentTabIndex == 1,
              onTap: () {
                Navigator.pop(context);
                onSelectTab(1);
              },
            ),
            const SizedBox(height: 8),
            DrawerItem(
              icon: Icons.storefront_rounded,
              label: 'Store',
              selected: currentTabIndex == 2,
              onTap: () {
                Navigator.pop(context);
                onSelectTab(2);
              },
            ),
            const SizedBox(height: 8),
            DrawerItem(
              icon: Icons.rss_feed_rounded,
              label: 'Feed',
              selected: currentTabIndex == 3,
              onTap: () {
                Navigator.pop(context);
                onSelectTab(3);
              },
            ),
            const SizedBox(height: 8),
            DrawerItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              selected: currentTabIndex == 4,
              onTap: () {
                Navigator.pop(context);
                onSelectTab(4);
              },
            ),

            const SizedBox(height: 18),

            // Additional pages
            DrawerItem(
              icon: Icons.menu_book_outlined,
              label: 'My Courses',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyCoursesPage()),
                );
              },
            ),
            const SizedBox(height: 8),
            DrawerItem(
              icon: Icons.design_services_outlined,
              label: 'Resume Builder',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SimplePage(title: 'Resume Builder')),
                );
              },
            ),
            const SizedBox(height: 8),
            DrawerItem(
              icon: Icons.sports_esports_outlined,
              label: 'Play Game',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SimplePage(title: 'Play Game')),
                );
              },
            ),
            const SizedBox(height: 8),
            DrawerItem(
              icon: Icons.shopping_bag_outlined,
              label: 'My Cart',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartPage()),
                );
              },
            ),
            const SizedBox(height: 8),
            DrawerItem(
              icon: Icons.group_add_outlined,
              label: 'Invite Friend',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SimplePage(title: 'Invite Friend')),
                );
              },
            ),

            const SizedBox(height: 18),
            DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SimplePage(title: 'Settings')),
                );
              },
            ),
            const SizedBox(height: 8),
            DrawerItem(
              icon: Icons.support_agent_outlined,
              label: 'Support',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SimplePage(title: 'Support')),
                );
              },
            ),

            const SizedBox(height: 30),
            const Divider(),

            // Logout
            DrawerItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SplashPage()),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
