import 'package:flutter/material.dart';
import 'package:GrabIt/pages/components/app_drawer.dart';

class ProfilePage extends StatelessWidget {
  final ValueChanged<int> onSelectTab;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ProfilePage({super.key, required this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: AppDrawer(onSelectTab: onSelectTab, currentTabIndex: 4),
      body: CustomScrollView(
        slivers: [
          // 🔹 AppBar
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            title: const Text(
              'Profile',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontSize: 18,
              ),
            ),
          ),

          // 🔹 Header Section with Banner + Avatar
          SliverToBoxAdapter(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF7F00), Color(0xFFFFB074)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 42,
                      backgroundImage: AssetImage('assets/images/profile.png'),
                    ),
                  ),
                ),
                Positioned(
                  top: 60,
                  right: 16,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.edit, size: 16, color: Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 60)),

          // 🔹 User Name and Role
          SliverToBoxAdapter(
            child: Column(
              children: const [
                Text(
                  'Anya Sharma',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Student',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),

          // 🔹 Personal Details Section
          _buildSectionHeader('Personal Details'),
          _buildInfoRow('Email', 'anya.sharma@email.com'),
          _buildInfoRow('Phone', '+91 98765 43210'),
          _buildInfoRow('Gender', 'Female'),
          _buildInfoRow('Address', '123 Main Street, Anytown'),

          // 🔹 My Courses Section
          _buildSectionHeader('My Courses'),
          _buildListItem('View Courses'),

          // 🔹 Orders Section
          _buildSectionHeader('Orders'),
          _buildListItem('View Orders'),

          // 🔹 Settings Section
          _buildSectionHeader('Settings'),
          _buildListItem('Notifications'),
          _buildListItem('Privacy'),
          _buildListItem('Logout'),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
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
          color: Colors.pink.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
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

  static SliverToBoxAdapter _buildListItem(String title) {
    return SliverToBoxAdapter(
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}
