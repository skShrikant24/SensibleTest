import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';

class MyCoursesPage extends StatelessWidget {
  const MyCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Courses',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- TOP SECTION ----------
            Row(
              children: [
                Expanded(
                  child: _AttendanceCard(
                    icon: Icons.qr_code_scanner,
                    title: "Mark Attendance",
                    subtitle: "Scan QR code in your class",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProgressCard(
                    percentage: 0.8,
                    attended: 18,
                    total: 25,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ---------- CURRENT COURSES ----------
            Text(
              "Current Courses",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _CourseTile(
              icon: 'assets/icons/py.png',
              title: 'Adobe XD',
              duration: '10 hours | 19 lessons',
              progress: 0.25,
            ),
            const SizedBox(height: 10),
            _CourseTile(
              icon: 'assets/icons/py.png',
              title: 'Python Tutorial',
              duration: '10 hours | 19 lessons',
              progress: 0.25,
            ),

            const SizedBox(height: 24),
            Text(
              "Other Courses",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _ArticleCard(
              title: "Advanced Digital Marketing",
              description:
              "Explore how technology is reshaping the educational landscape, offering new opportunities for learning and growth.",
              image: "assets/images/digital_marketing.png",
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- COMPONENTS ----------

class _AttendanceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AttendanceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 48),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final double percentage;
  final int attended;
  final int total;

  const _ProgressCard({
    required this.percentage,
    required this.attended,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularPercentIndicator(
            radius: 36.0,
            lineWidth: 8.0,
            percent: percentage,
            progressColor: Colors.deepOrange,
            backgroundColor: Colors.grey.shade200,
            center: Text(
              "${(percentage * 100).toInt()}%\nattended",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$attended / $total",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          Text(
            "Class attended",
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  final String icon;
  final String title;
  final String duration;
  final double progress;

  const _CourseTile({
    required this.icon,
    required this.title,
    required this.duration,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(icon, width: 40, height: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  duration,
                  style:
                  GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            children: [
              CircularPercentIndicator(
                radius: 18,
                lineWidth: 3,
                percent: progress,
                progressColor: Colors.redAccent,
                backgroundColor: Colors.grey.shade200,
                center: const Icon(Icons.play_arrow,
                    color: Colors.redAccent, size: 18),
              ),
              const SizedBox(height: 4),
              Text(
                "${(progress * 100).toInt()}%",
                style: GoogleFonts.poppins(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final String title;
  final String description;
  final String image;

  const _ArticleCard({
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Article",
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(image, width: 90, height: 90, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }
}
