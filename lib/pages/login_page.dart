import 'dart:async';
import 'package:GraBiTT/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GraBiTT/pages/main_shell.dart';
//jjjjjjjjj
enum LoginStep { phoneNumber, otp, success }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  LoginStep _currentStep = LoginStep.phoneNumber;
  
  // Phone number input
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;
  Animation<double>? _jumpAnimation;
  bool _isPhoneValid = false;
  
  // OTP input
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  List<AnimationController> _otpSlideControllers = [];
  List<Animation<Offset>> _otpSlideAnimations = [];
  String _otpCode = '';
  
  // Verification success
  AnimationController? _successController;
  Animation<double>? _rotationAnimation;
  Animation<double>? _scaleAnimation;
  bool _isVerifying = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _setupPhoneAnimations();
    _setupOtpAnimations();
    _setupSuccessAnimations();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _setupPhoneAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
    
    _jumpAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.elasticOut),
    );
  }

  void _setupOtpAnimations() {
    for (int i = 0; i < 4; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _otpSlideControllers.add(controller);
      
      final animation = Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(i * 0.15, 1.0, curve: Curves.easeOutBack),
      ));
      _otpSlideAnimations.add(animation);
    }
  }

  void _setupSuccessAnimations() {
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successController!,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _successController!,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );
  }

  void _onPhoneChanged() {
    final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    final isValid = phone.length >= 10;
    
    if (isValid != _isPhoneValid) {
      setState(() {
        _isPhoneValid = isValid;
      });
    }
  }

  void _onPhoneDigitTyped() {
    _pulseController?.forward(from: 0.0).then((_) {
      _pulseController?.reverse();
    });
  }

  Future<void> _sendOtp() async {
    if (!_isPhoneValid) return;
    
    setState(() {
      _currentStep = LoginStep.otp;
    });
    
    // Simulate OTP auto-read after a delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Auto-fill OTP with animation
    if (mounted && _currentStep == LoginStep.otp) {
      _autoFillOtp('1234'); // In production, get from SMS
    }
  }

  void _autoFillOtp(String otp) {
    for (int i = 0; i < 4 && i < otp.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted && _currentStep == LoginStep.otp) {
          _otpControllers[i].text = otp[i];
          _otpSlideControllers[i].forward();
          if (i < 3) {
            _otpFocusNodes[i + 1].requestFocus();
          }
        }
      });
    }
    
    // Auto-verify after OTP is filled (simulating auto-read SMS)
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && _currentStep == LoginStep.otp) {
        final enteredOtp = _otpControllers.map((c) => c.text).join();
        if (enteredOtp.length == 4) {
          _verifyOtp();
        }
      }
    });
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isVerifying = true;
    });
    
    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) {
      setState(() {
        _isVerified = true;
      });
      
      // Start the transformation animation
      _successController?.forward();
      
      // Navigate to home after animation completes
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    _pulseController?.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    for (var controller in _otpSlideControllers) {
      controller.dispose();
    }
    _successController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case LoginStep.phoneNumber:
        return _buildPhoneNumberStep();
      case LoginStep.otp:
        return _buildOtpStep();
      case LoginStep.success:
        return _buildOtpStep(); // Show OTP step with transformed button
    }
  }

  Widget _buildPhoneNumberStep() {
    return Padding(
      key: const ValueKey('phone'),
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Image.asset(
            'assets/images/newlogo2.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 48),
          
          // Title
          Text(
            "Welcome to GraB iTT!",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your phone number to continue',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          // Phone input with pulse animation
          AnimatedBuilder(
            animation: _pulseController!,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _jumpAnimation?.value ?? 0),
                child: Transform.scale(
                  scale: _pulseAnimation?.value ?? 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(
                            _pulseController!.value * 0.3,
                          ),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onChanged: (_) => _onPhoneDigitTyped(),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Phone Number',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey[400],
                          fontSize: 18,
                        ),
                        prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 3,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          
          // Continue button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isPhoneValid ? _sendOtp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return SingleChildScrollView(
      child: Padding(
        key: const ValueKey('otp'),
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Back button
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () {
                  setState(() {
                    _currentStep = LoginStep.phoneNumber;
                    _isVerifying = false;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Enter OTP',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We sent a code to\n${_phoneController.text}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 80),
          
          // OTP input boxes with slide animation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              return SlideTransition(
                position: _otpSlideAnimations[index],
                child: Container(
                  width: 60,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: SizedBox(
                    height: 70,
                    width: 60,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 21),
                        isDense: true,
                        counterText: '',
                      ),
                      textAlignVertical: TextAlignVertical.center,
                    onChanged: (value) {
                      // Trigger slide animation when manually entering
                      if (value.isNotEmpty && _otpSlideControllers[index].value == 0) {
                        _otpSlideControllers[index].forward();
                      }
                      
                      if (value.isNotEmpty && index < 3) {
                        _otpFocusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _otpFocusNodes[index - 1].requestFocus();
                      }
                      
                      // Check if all fields are filled
                      final otp = _otpControllers.map((c) => c.text).join();
                      if (otp.length == 4 && !_isVerifying) {
                        // Auto-verify when all digits are entered
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted && !_isVerifying) {
                            _verifyOtp();
                          }
                        });
                      }
                    },
                  ),
                ),
                ),
              );
            }),
          ),
          const SizedBox(height: 56),
          
          // Verify button with transformation animation
          SizedBox(
            width: double.infinity,
            height: 56,
            child: AnimatedBuilder(
              animation: _successController!,
              builder: (context, child) {
                final isTransforming = _isVerified && _successController!.value > 0;
                final buttonColor = isTransforming
                    ? Color.lerp(
                        const Color(0xFFFF0000),
                        Colors.green,
                        _successController!.value,
                      )!
                    : const Color(0xFFFF0000);
                
                return Transform.rotate(
                  angle: _rotationAnimation!.value * 2 * 3.14159,
                  child: ElevatedButton(
                    onPressed: _isVerifying || _isVerified
                        ? null
                        : () {
                            final otp = _otpControllers.map((c) => c.text).join();
                            if (otp.length == 4) {
                              _verifyOtp();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      disabledBackgroundColor: buttonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: isTransforming ? 8 : 0,
                    ),
                    child: isTransforming
                        ? Transform.scale(
                            scale: _scaleAnimation!.value,
                            child: const Icon(
                              Icons.home,
                              color: Colors.white,
                              size: 28,
                            ),
                          )
                        : _isVerifying
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Verify',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          
          // Resend OTP
          TextButton(
            onPressed: () {
              _sendOtp();
            },
            child: Text(
              'Resend OTP',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFFFF0000),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

}

