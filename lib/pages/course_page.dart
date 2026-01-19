import 'package:GraBiTT/pages/components/app_drawer.dart';
import 'package:GraBiTT/pages/components/home_header.dart';
import 'package:flutter/material.dart';

class CoursePage extends StatelessWidget {
  final ValueChanged<int> onSelectTab;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  CoursePage({super.key, required this.onSelectTab});

  final List<Map<String, String>> courses = [
    {
      'type': 'Article',
      'title': 'Advanced Digital Marketing',
      'description':
      'Explore how technology is reshaping the educational landscape, offering new opportunities for learning and growth.',
      'image': 'assets/images/digital_marketing.png',
    },
    {
      'type': 'Video',
      'title': 'Effective Study Techniques for Students',
      'description':
      'Learn proven study methods to enhance your learning efficiency and achieve academic success.',
      'image': 'assets/images/study_techniques.png',
    },
    {
      'type': 'Announcement',
      'title': 'New Course Alert: Data Science Fundamentals',
      'description':
      'Enroll now in our latest course covering the basics of data science, from data analysis to visualization.',
      'image': 'assets/images/data_science.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F5F7),
      drawer: AppDrawer(onSelectTab: onSelectTab, currentTabIndex: 1),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: HomeHeader(
              onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
              showGreeting: false,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔍 Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: const TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Search courses',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 🧭 Tabs Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _CategoryTab(title: 'All', isActive: true),
                      _CategoryTab(title: 'Articles'),
                      _CategoryTab(title: 'Videos'),
                      _CategoryTab(title: 'Announcements'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                ],
              ),
            ),
          ),
          // 📚 Courses List
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final course = courses[index];
                return _CourseCard(
                  type: course['type']!,
                  title: course['title']!,
                  description: course['description']!,
                  image: course['image']!,
                );
              },
              childCount: courses.length,
            ),
          ),
        ],
      ),
    );
  }
}

// 📄 Category Tabs
class _CategoryTab extends StatelessWidget {
  final String title;
  final bool isActive;

  const _CategoryTab({required this.title, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        color: isActive ? Colors.black : Colors.grey[600],
      ),
    );
  }
}

// 📚 Course Card
class _CourseCard extends StatelessWidget {
  final String type;
  final String title;
  final String description;
  final String image;

  const _CourseCard({
    required this.type,
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              image,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
