import 'dart:async';
import 'dart:math';
import 'package:GraBiTT/utils/constants.dart';
import 'package:GraBiTT/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:GraBiTT/pages/main_shell.dart';
import 'package:GraBiTT/pages/signup_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:readotp/readotp.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sms_autofill/sms_autofill.dart';

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
  
  // OTP input (used with PinFieldAutoFill for SMS autofill)
  String _otpCode = '';
  String? _storedOtp;
  Map<String, dynamic>? _loggedInUser;
  bool _isCheckingUser = false;
  bool _isSendingOtp = false;
  bool _isResendingOtp = false;

  // Legacy 4-box OTP (kept for manual entry fallback / animation)
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  List<AnimationController> _otpSlideControllers = [];
  List<Animation<Offset>> _otpSlideAnimations = [];
  
  // Verification success
  AnimationController? _successController;
  Animation<double>? _rotationAnimation;
  Animation<double>? _scaleAnimation;
  bool _isVerifying = false;
  bool _isVerified = false;

  // SMS read (readotp) for OTP autofill when user grants READ_SMS
  ReadOtp? _readOtp;
  StreamSubscription? _smsSubscription;

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

  /// Check user by phone -> if not found show alert and go to signup; else send OTP and go to OTP step.
  Future<void> _sendOtp() async {
    if (!_isPhoneValid) return;
    final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.length < 10) return;

    setState(() => _isCheckingUser = true);
    final result = await AuthService.instance.getUserByPhone(phone);
    if (!mounted) return;

    if (!result.found || result.user == null) {
      setState(() => _isCheckingUser = false);
      _showUserNotFoundAndNavigateToSignup();
      return;
    }

    final otp = '${1000 + Random().nextInt(9000)}';
    setState(() => _isSendingOtp = true);
    final sendResult = await AuthService.instance.sendOtp(phone, otp);
    if (!mounted) return;

    setState(() {
      _isCheckingUser = false;
      _isSendingOtp = false;
    });

    if (!sendResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sendResult.message ?? 'Failed to send OTP')),
      );
      return;
    }

    _storedOtp = otp;
    _loggedInUser = result.user;
    _otpCode = '';
    for (var c in _otpControllers) c.clear();
    setState(() => _currentStep = LoginStep.otp);

    try {
      await SmsAutoFill().listenForCode();
    } catch (_) {}
    _startSmsListener();
  }

  /// Request SMS permission and start listening for incoming SMS to auto-fill OTP.
  void _startSmsListener() async {
    try {
      final status = await Permission.sms.request();
      if (!mounted || status != PermissionStatus.granted) return;
      _readOtp?.dispose();
      _readOtp = ReadOtp();
      _readOtp!.start();
      if (!mounted) return;
      _smsSubscription?.cancel();
      _smsSubscription = _readOtp!.smsStream.listen((sms) {
        final body = sms.body;
        final match = RegExp(r'\d{4}').firstMatch(body);
        if (match != null && mounted && _currentStep == LoginStep.otp && !_isVerified) {
          final code = match.group(0)!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _currentStep == LoginStep.otp) _onPinCodeChanged(code);
          });
        }
      });
    } catch (_) {}
  }

  void _stopSmsListener() {
    _smsSubscription?.cancel();
    _smsSubscription = null;
    _readOtp?.dispose();
    _readOtp = null;
  }

  void _showUserNotFoundAndNavigateToSignup() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('User not registered', style: GoogleFonts.poppins()),
        content: Text(
          'This phone number is not registered. Please sign up to continue.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SignupPage()),
              );
            },
            child: Text('Sign up', style: GoogleFonts.poppins(color: const Color(0xFFFF0000), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Resend OTP: generate new OTP, call API, update _storedOtp.
  Future<void> _resendOtp() async {
    final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.isEmpty || _loggedInUser == null) return;
    setState(() => _isResendingOtp = true);
    final otp = '${1000 + Random().nextInt(9000)}';
    final result = await AuthService.instance.sendOtp(phone, otp);
    if (mounted) {
      setState(() => _isResendingOtp = false);
      if (result.success) {
        _storedOtp = otp;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to resend OTP')),
        );
      }
    }
  }

  /// Verify entered OTP with stored OTP; on match save user and navigate to main app.
  Future<void> _verifyOtp() async {
    final entered = _otpCode.length == 4 ? _otpCode : _otpControllers.map((c) => c.text).join();
    if (entered.length != 4 || _storedOtp == null || _loggedInUser == null) return;
    if (entered != _storedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
      return;
    }

    setState(() => _isVerifying = true);
    await AuthService.instance.saveLoginUser(_loggedInUser!);
    if (!mounted) return;

    setState(() => _isVerified = true);
    _successController?.forward();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  void _onPinCodeChanged(String? code) {
    setState(() => _otpCode = code ?? '');
    for (int i = 0; i < 4; i++) {
      if (i < (code?.length ?? 0)) {
        _otpControllers[i].text = code![i];
        if (_otpSlideControllers[i].value == 0) _otpSlideControllers[i].forward();
      } else {
        _otpControllers[i].clear();
      }
    }
    if ((code?.length ?? 0) == 4) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_isVerifying && !_isVerified) _verifyOtp();
      });
    }
  }

  @override
  void dispose() {
    _stopSmsListener();
    SmsAutoFill().unregisterListener();
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
          const SizedBox(height: 30),
          
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
          const SizedBox(height: 20),
          
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
          const SizedBox(height: 12),
          
          // Continue button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_isPhoneValid && !_isCheckingUser && !_isSendingOtp) ? _sendOtp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isCheckingUser || _isSendingOtp
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Text(
                      'Continue',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SignupPage(),
                    ),
                  );
                },
                child: Text(
                  'Sign up',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF0000),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '';
              final build = snapshot.data?.buildNumber ?? '';
              final text = version.isEmpty ? '' : 'Version $version${build.isNotEmpty ? ' ($build)' : ''}';
              if (text.isEmpty) return const SizedBox.shrink();
              return Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              );
            },
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
                  _stopSmsListener();
                  setState(() {
                    _currentStep = LoginStep.phoneNumber;
                    _isVerifying = false;
                    _storedOtp = null;
                    _loggedInUser = null;
                    _otpCode = '';
                    for (var c in _otpControllers) c.clear();
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
          
          // OTP input with SMS autofill (PinFieldAutoFill) + manual 4 boxes in sync
          PinFieldAutoFill(
            codeLength: 4,
            currentCode: _otpCode,
            onCodeChanged: _onPinCodeChanged,
            decoration: BoxLooseDecoration(
              gapSpace: 12,
              bgColorBuilder: FixedColorBuilder(Colors.grey[50]!),
              strokeColorBuilder: FixedColorBuilder(Colors.grey[300]!),
              strokeWidth: 2,
              radius: Radius.circular(16),
              textStyle: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autoFocus: true,
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
                            if (_otpCode.length == 4) _verifyOtp();
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
            onPressed: _isResendingOtp ? null : _resendOtp,
            child: _isResendingOtp
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
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

