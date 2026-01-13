import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GrabIt/pages/main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      image: 'assets/images/slide1.jpg',
      title: 'Order Food\nIn Just One Tap',
      description: 'Discover nearby restaurants and\norder your favorite meals instantly.',
      decorativeIcons: [
        DecorativeIcon(icon: Icons.library_books, color: Color(0xFFFF6B6B), top: 200, left: 50),
        DecorativeIcon(icon: Icons.edit, color: Color(0xFFFF0000), top: 180, right: 80),
      ],
    ),
    OnboardingData(
      image: 'assets/images/slide2.jpg',
      title: 'Fast Delivery\nAt Your Doorstep',
      description: 'Hot & fresh food delivered quickly\nfrom the best local kitchens.',
      decorativeIcons: [
        DecorativeIcon(icon: Icons.stars, color: Color(0xFFFF6B6B), top: 250, left: 60),
        DecorativeIcon(icon: Icons.library_books, color: Color(0xFFFF0000), bottom: 350, right: 70),
      ],
    ),
    OnboardingData(
      image: 'assets/images/slide3.jpg',
      title: 'Login / Sign-up',
      description: 'Start ordering delicious food with GrabIt',
      isLastPage: true,
      decorativeIcons: [
        DecorativeIcon(icon: Icons.circle, color: Color(0xFF7C4DFF), top: 180, right: 50, size: 15),
        DecorativeIcon(icon: Icons.circle, color: Color(0xFF00BFA5), top: 200, right: 30, size: 12),
        DecorativeIcon(icon: Icons.circle, color: Color(0xFFFF6B6B), top: 300, right: 60, size: 10),
        DecorativeIcon(icon: Icons.circle, color: Color(0xFFFFA726), bottom: 400, left: 80, size: 14),
        DecorativeIcon(icon: Icons.circle_outlined, color: Color(0xFF9E9E9E), top: 240, left: 50, size: 18),
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Column(
        children: [
          const SizedBox(height: 10),

          /// 🔥 LOGO IMAGE
          Image.asset(
            'assets/images/logo.jpeg',
            height: 70,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }


  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ...data.decorativeIcons.map((icon) => _buildDecorativeIcon(icon)),
                Center(
                  child: Image.asset(
                    data.image,
                    height: 280,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.black87, height: 1.3),
          ),
          const SizedBox(height: 20),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700], height: 1.6),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildDecorativeIcon(DecorativeIcon icon) {
    return Positioned(
      top: icon.top,
      bottom: icon.bottom,
      left: icon.left,
      right: icon.right,
      child: Icon(icon.icon, color: icon.color, size: icon.size),
    );
  }

  Widget _buildBottomSection() {
    final isLastPage = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (index) => _buildDot(index)),
          ),
          const SizedBox(height: 32),
          if (isLastPage) ...[
            _buildButton('Existing', true),
            const SizedBox(height: 16),
            _buildButton('Guest', false),
          ] else
            _buildButton('NEXT', false),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFF0000) : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildButton(String text, bool isFilled) {
    return GestureDetector(
      onTap: () {
        if (_currentPage < _pages.length - 1) {
          _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
        }else {
          // On last page, go to the main app shell with bottom navigation
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainShell()),

          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isFilled ? const Color(0xFFFF0000) : Colors.white,
          border: Border.all(color: const Color(0xFFFF0000), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: isFilled ? Colors.white : const Color(0xFFFF0000)),
        ),
      ),
    );
  }
}

class OnboardingData {
  final String image;
  final String title;
  final String description;
  final bool isLastPage;
  final List<DecorativeIcon> decorativeIcons;

  OnboardingData({
    required this.image,
    required this.title,
    required this.description,
    this.isLastPage = false,
    this.decorativeIcons = const [],
  });
}

class DecorativeIcon {
  final IconData icon;
  final Color color;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;

  DecorativeIcon({
    required this.icon,
    required this.color,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.size = 24,
  });
}
