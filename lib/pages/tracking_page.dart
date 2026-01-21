import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/sound_service.dart';

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

class _TrackingPageState extends State<TrackingPage>
    with TickerProviderStateMixin {
  TrackingPhase _currentPhase = TrackingPhase.roadRibbon;
  
  // Animation controllers
  late AnimationController _riderController;
  late AnimationController _ribbonController;
  late AnimationController _vibrationController;
  late AnimationController _bellController;
  late AnimationController _boxController;
  late AnimationController _confettiController;
  
  // Animations
  late Animation<double> _riderPosition;
  late Animation<double> _ribbonProgress;
  late Animation<double> _vibrationOffset;
  late Animation<double> _bellScale;
  late Animation<double> _boxScale;
  late Animation<double> _boxRotation;
  
  // OTP
  final TextEditingController _otpController = TextEditingController();
  final String _correctOTP = "1234"; // Demo OTP
  bool _showOTPDialog = false;
  
  // Distance tracking
  double _distance = 500.0; // Start at 500m

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startTracking();
  }

  void _setupAnimations() {
    // Rider movement
    _riderController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    _riderPosition = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _riderController,
        curve: Curves.easeInOut,
      ),
    );

    // Ribbon glow
    _ribbonController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _ribbonProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _riderController,
        curve: Curves.easeInOut,
      ),
    );

    // Vibration
    _vibrationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..repeat(reverse: true);

    _vibrationOffset = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(
        parent: _vibrationController,
        curve: Curves.easeInOut,
      ),
    );

    // Bell ring
    _bellController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _bellScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _bellController,
        curve: Curves.elasticOut,
      ),
    );

    // Box animation
    _boxController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _boxScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _boxController,
        curve: Curves.elasticOut,
      ),
    );

    _boxRotation = Tween<double>(begin: 0.0, end: math.pi * 0.1).animate(
      CurvedAnimation(
        parent: _boxController,
        curve: Curves.easeInOut,
      ),
    );

    // Confetti
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Start rider animation
    _riderController.forward();
  }

  void _startTracking() {
    // Simulate distance decreasing
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _currentPhase == TrackingPhase.roadRibbon) {
        setState(() {
          _distance -= 50; // Decrease by 50m per second
        });
        
        // Check if within 200m
        if (_distance <= 200 && _currentPhase == TrackingPhase.roadRibbon) {
          setState(() {
            _currentPhase = TrackingPhase.doorbell;
          });
          _bellController.repeat(reverse: true);
          // Play whistle sound for rider arrival
          SoundService.instance.playWhistle();
        }
        
        if (_distance > 0) {
          _startTracking();
        }
      }
    });
  }

  Color _getBackgroundColor() {
    switch (_currentPhase) {
      case TrackingPhase.roadRibbon:
        return Colors.grey[200]!; // Light Gray
      case TrackingPhase.doorbell:
        return Colors.yellow[100]!; // Light Yellow
      case TrackingPhase.unboxing:
        return Colors.green[400]!; // Vibrant Green
    }
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
            _boxController.forward();
            _confettiController.forward();
            // Play ding sound for success
            SoundService.instance.playDing();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Incorrect OTP. Please try again."),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _riderController.dispose();
    _ribbonController.dispose();
    _vibrationController.dispose();
    _bellController.dispose();
    _boxController.dispose();
    _confettiController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
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
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Track Your Order',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (_currentPhase == TrackingPhase.doorbell)
            TextButton(
              onPressed: _showOTPEntry,
              child: Text(
                'Enter OTP',
                style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_currentPhase) {
      case TrackingPhase.roadRibbon:
        return _buildRoadRibbonPhase();
      case TrackingPhase.doorbell:
        return _buildDoorbellPhase();
      case TrackingPhase.unboxing:
        return _buildUnboxingPhase();
    }
  }

  // Phase 1: Road Ribbon
  Widget _buildRoadRibbonPhase() {
    return AnimatedBuilder(
      animation: Listenable.merge([_riderController, _ribbonController]),
      builder: (context, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Quote
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  '"Your happiness is 2 minutes away."',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Road with ribbon
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                height: 200,
                child: Stack(
                  children: [
                    // Gray road base
                    Positioned(
                      top: 90,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    
                    // Glowing Gold Ribbon (progressing)
                    Positioned(
                      top: 90,
                      left: 0,
                      width: MediaQuery.of(context).size.width * 0.9 * _ribbonProgress.value,
                      child: Container(
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber[300]!,
                              Colors.amber[600]!,
                              Colors.amber[300]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.6 + _ribbonController.value * 0.4),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Rider icon
                    Positioned(
                      left: (MediaQuery.of(context).size.width * 0.9 - 50) * _riderPosition.value,
                      top: 70,
                      child: Transform.translate(
                        offset: Offset(0, math.sin(_riderController.value * math.pi * 4) * 5),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delivery_dining,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Distance
              Text(
                '${_distance.toInt()}m away',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Phase 2: Doorbell
  Widget _buildDoorbellPhase() {
    return AnimatedBuilder(
      animation: Listenable.merge([_vibrationController, _bellController]),
      builder: (context, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Quote
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  '"Check your gate!"',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Map view with vibrating rider
              SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  children: [
                    // Map background
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.map,
                          size: 100,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                    
                    // Vibrating rider icon
                    Positioned(
                      left: 125 + _vibrationOffset.value,
                      top: 125 + _vibrationOffset.value,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue[600],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delivery_dining,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    
                    // Bell icon 🔔
                    Positioned(
                      right: 20,
                      top: 20,
                      child: Transform.scale(
                        scale: _bellScale.value,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.amber[400],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.6),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_active,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Distance
              Text(
                '${_distance.toInt()}m away - Almost there!',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.orange[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // OTP Button
              ElevatedButton(
                onPressed: _showOTPEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
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
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Phase 3: Unboxing
  Widget _buildUnboxingPhase() {
    return AnimatedBuilder(
      animation: Listenable.merge([_boxController, _confettiController]),
      builder: (context, child) {
        return Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Quote
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      '"GraB iTT! Delivered."',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        color: Colors.green[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // 3D Box
                  Transform.scale(
                    scale: _boxScale.value,
                    child: Transform.rotate(
                      angle: _boxRotation.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Box base
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.brown[400]!,
                                  Colors.brown[600]!,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.brown.withOpacity(0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // Box top (lid) - opens when animation completes
                                if (_boxController.value > 0.5)
                                  Positioned(
                                    top: -20,
                                    left: 0,
                                    right: 0,
                                    child: Transform.rotate(
                                      angle: -math.pi * 0.3 * (_boxController.value - 0.5) * 2,
                                      child: Container(
                                        height: 20,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.brown[500]!,
                                              Colors.brown[700]!,
                                            ],
                                          ),
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                // Box ribbon
                                Positioned(
                                  top: 60,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.red[400],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Success message
                  Text(
                    'Order Delivered Successfully!',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
              
            // Confetti 🎉
            if (_confettiController.value > 0)
              Positioned.fill(
                child: Center(
                  child: SizedBox(
                    width: 400,
                    height: 400,
                    child: Stack(
                      children: List.generate(20, (index) {
                        final angle = (index * math.pi * 2) / 20;
                        final distance = 150 * _confettiController.value;
                        final opacity = (1 - _confettiController.value * 0.8).clamp(0.0, 1.0);
                        final size = 15 + (math.sin(_confettiController.value * math.pi * 2) * 5);
                        
                        return Positioned(
                          left: 200 + math.cos(angle) * distance - size / 2,
                          top: 200 + math.sin(angle) * distance - size / 2,
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.rotate(
                              angle: _confettiController.value * math.pi * 2,
                              child: Container(
                                width: size,
                                height: size,
                                decoration: BoxDecoration(
                                  color: [
                                    Colors.red,
                                    Colors.blue,
                                    Colors.yellow,
                                    Colors.green,
                                    Colors.purple,
                                  ][index % 5],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
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
            backgroundColor: Colors.green[600],
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
            value: _riderPosition.value,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[600]!),
          ),
          const SizedBox(height: 10),
          Text(
            '${(_riderPosition.value * 100).toInt()}% Complete',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
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
                        borderSide: const BorderSide(
                          color: Colors.redAccent,
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
                backgroundColor: Colors.redAccent,
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

