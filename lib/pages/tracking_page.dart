import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../services/sound_service.dart';
import '../utils/constants.dart';

enum TrackingPhase {
  roadRibbon, // Phase 1: Road Ribbon
  doorbell,   // Phase 2: Doorbell (within 200m)
  unboxing,   // Phase 3: Unboxing (after OTP)
}

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  TrackingPhase _currentPhase = TrackingPhase.roadRibbon;

  // OTP
  final TextEditingController _otpController = TextEditingController();
  final String _correctOTP = "1234"; // Demo OTP
  bool _showOTPDialog = false;

  // Distance tracking
  double _distance = 500.0; // Start at 500m

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _currentPhase == TrackingPhase.roadRibbon) {
        setState(() {
          _distance -= 50;
        });
        if (_distance <= 200 && _currentPhase == TrackingPhase.roadRibbon) {
          setState(() {
            _currentPhase = TrackingPhase.doorbell;
          });
          SoundService.instance.playWhistle();
        }
        if (_distance > 0) {
          _startTracking();
        }
      }
    });
  }

  void _showOTPEntry() {
    setState(() {
      _showOTPDialog = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OTPDialog(
        otpController: _otpController,
        onVerify: (otp) {
          if (otp == _correctOTP) {
            Navigator.of(context).pop();
            setState(() {
              _currentPhase = TrackingPhase.unboxing;
              _showOTPDialog = false;
            });
            SoundService.instance.playDing();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Incorrect OTP. Please try again."),
                backgroundColor: StoreProfileTheme.ctaAction,
              ),
            );
          }
        },
      ),
    );
  }

  double get _progressValue {
    switch (_currentPhase) {
      case TrackingPhase.roadRibbon:
        return 0.33;
      case TrackingPhase.doorbell:
        return 0.66;
      case TrackingPhase.unboxing:
        return 1.0;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StoreProfileTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),
            
            // Main Content
            Expanded(
              child: _buildPhaseContent(),
            ),
            
            // Bottom Section
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: StoreProfileTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Track Your Order',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: StoreProfileTheme.textPrimary,
              ),
            ),
          ),
          if (_currentPhase == TrackingPhase.doorbell)
            TextButton(
              onPressed: _showOTPEntry,
              child: Text(
                'Enter OTP',
                style: GoogleFonts.poppins(
                  color: StoreProfileTheme.ctaAction,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent() {
    final quote = _getPhaseQuote();
    final statusText = _getPhaseStatusText();
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Phase quote
              Text(
                quote,
                style: GoogleFonts.poppins(
                  fontSize: _currentPhase == TrackingPhase.unboxing ? 22 : 18,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: _currentPhase == TrackingPhase.unboxing
                      ? StoreProfileTheme.successDark
                      : StoreProfileTheme.accentPink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Lottie: Delivery at door
              SizedBox(
                width: 260,
                height: 260,
                child: Lottie.asset(
                  'assets/animations/DeliveryDoor.json',
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                ),
              ),
              const SizedBox(height: 24),
              // Status / distance
              Text(
                statusText,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: _currentPhase == TrackingPhase.doorbell
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: _currentPhase == TrackingPhase.unboxing
                      ? StoreProfileTheme.successDark
                      : StoreProfileTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (_currentPhase == TrackingPhase.doorbell) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _showOTPEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StoreProfileTheme.accentPink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Enter OTP',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getPhaseQuote() {
    switch (_currentPhase) {
      case TrackingPhase.roadRibbon:
        return '"Your happiness is 2 minutes away."';
      case TrackingPhase.doorbell:
        return '"Check your gate!"';
      case TrackingPhase.unboxing:
        return '"GraB iTT! Delivered."';
    }
  }

  String _getPhaseStatusText() {
    switch (_currentPhase) {
      case TrackingPhase.roadRibbon:
        return '${_distance.toInt()}m away';
      case TrackingPhase.doorbell:
        return '${_distance.toInt()}m away - Almost there!';
      case TrackingPhase.unboxing:
        return 'Order Delivered Successfully!';
    }
  }

  Widget _buildBottomSection() {
    if (_currentPhase == TrackingPhase.unboxing) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () {
            // Navigate back to home or store
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: StoreProfileTheme.accentPink,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Continue Shopping',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: _progressValue,
            backgroundColor: StoreProfileTheme.progressTrack,
            valueColor: AlwaysStoppedAnimation<Color>(StoreProfileTheme.accentPink),
          ),
          const SizedBox(height: 10),
          Text(
            '${(_progressValue * 100).toInt()}% Complete',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: StoreProfileTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// OTP Dialog
class _OTPDialog extends StatefulWidget {
  final TextEditingController otpController;
  final Function(String) onVerify;

  const _OTPDialog({
    required this.otpController,
    required this.onVerify,
  });

  @override
  State<_OTPDialog> createState() => _OTPDialogState();
}

class _OTPDialogState extends State<_OTPDialog> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Auto verify when all fields are filled
    if (index == 3 && value.isNotEmpty) {
      final otp = _controllers.map((c) => c.text).join();
      if (otp.length == 4) {
        widget.onVerify(otp);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter OTP',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: StoreProfileTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 50,
                  height: 60,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: StoreProfileTheme.ctaAction,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) => _onChanged(index, value),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final otp = _controllers.map((c) => c.text).join();
                widget.onVerify(otp);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: StoreProfileTheme.ctaAction,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Verify',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

