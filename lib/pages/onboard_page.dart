import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GraBiTT/pages/main_shell.dart';
import 'package:GraBiTT/pages/login_page.dart';
import 'package:lottie/lottie.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  // Restaurant, Grocery, Medical, Chaats and Snacks, Pesticides, Pick & Deliver and last Login Page.
  final List<OnboardingData> _pages = [
    OnboardingData(
      image: 'assets/images/slide1.jpg',
      lottieAsset:"assets/animations/Delivery.json",
      title: 'Food Delivery',
      description: 'Order your favourite food from your preferred restaurant',
    ),
    OnboardingData(
      image: 'assets/images/slide2.jpg',
      lottieAsset:"assets/animations/Grocery.json",
      title: 'Grocery Delivery',
      description: 'Daily groceries delivered from trusted local stores',
    ),
    OnboardingData(
      image: 'assets/images/slide3.jpg',
      lottieAsset:"assets/animations/Doctor.json",
      title: 'Medicine Delivery',
      description: 'Fast, safe & reliable pharmacy delivery',
    ),
    OnboardingData(
      image: 'assets/images/slide3.jpg',
      lottieAsset:"assets/animations/Food.json",
      title: 'Chaat Items',
      description: 'Delivery of your favorite chaat items across the city',
    ),
    OnboardingData(
      image: 'assets/images/slide3.jpg',
      lottieAsset:"assets/animations/Seed.json",
      title: 'Farmer Supplies',
      description: 'Pesticides, seeds & fertilizers delivered to farms.',
      // isLastPage: true,
    ),OnboardingData(
      image: 'assets/images/slide3.jpg',
      lottieAsset:"assets/animations/DeliveryLast.json",
      title: 'Express Pick & Deliver',
      description: 'Send your important items anywhere in town.',
      isLastPage: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        // Stop timer on last page
        _stopAutoSlide();
      }
    });
  }

  void _stopAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
  }

  void _resetAutoSlide() {
    _stopAutoSlide();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _stopAutoSlide();
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
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  // Reset auto-slide timer when user manually swipes
                  _resetAutoSlide();
                },
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
            'assets/images/newlogo2.png',
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
                // ...data.decorativeIcons.map((icon) => _buildDecorativeIcon(icon)),
                  Center(
                    child: data.lottieAsset != null
                        ? Lottie.asset(
                            data.lottieAsset!,
                            height: 280,
                            fit: BoxFit.contain,
                            repeat: true,
                            animate: true,
                          )
                        : Image.asset(
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
            _buildButton('Login', true),
            // const SizedBox(height: 16),
            // _buildButton('Guest', false),
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
        } else {
          // On last page, navigate based on button
          if (text == 'Login') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          } else {
            // Guest mode - go to main app
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainShell()),
            );
          }
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
  final String? lottieAsset; // Path to Lottie JSON file (e.g., 'assets/animations/animation.json')
  final String title;
  final String description;
  final bool isLastPage;

  OnboardingData({
    required this.image,
    this.lottieAsset,
    required this.title,
    required this.description,
    this.isLastPage = false
  });
}

