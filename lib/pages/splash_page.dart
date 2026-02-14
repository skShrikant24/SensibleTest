import 'dart:async';
import 'package:GraBiTT/pages/main_shell.dart';
import 'package:GraBiTT/pages/onboard_page.dart';
import 'package:GraBiTT/services/auth_service.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _logoOffset;
  late Animation<Offset> _textOffset;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Logo comes from top
    _logoOffset = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Text comes from bottom
    _textOffset = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Fade animation
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);

    _controller.forward();

    // Navigate after splash: if already logged in go to main app, else onboarding
    Timer(const Duration(seconds: 3), () async {
      if (!context.mounted) return;
      final loggedIn = await AuthService.instance.isLoggedIn();
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => loggedIn ? const MainShell() : const OnboardingScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _logoOffset,
                child: Image.asset(
                  'assets/images/newlogo2.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.error,
                      size: 100,
                      color: Colors.red
                    );
                  },
                ),
              ),
            ),

            // const SizedBox(height: 20),
            //
            // // Animated Text
            // FadeTransition(
            //   opacity: _fadeAnimation,
            //   child: SlideTransition(
            //     position: _textOffset,
            //     child: const Text(
            //       'GraBiTT',
            //       style: TextStyle(
            //         color: Colors.black,
            //         fontSize: 22,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
