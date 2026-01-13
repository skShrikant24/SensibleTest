import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SimplePage extends StatelessWidget {
  const SimplePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title page',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
