import 'dart:async';
import 'dart:math';
import 'package:grabitt/services/auth_service.dart';
import 'package:grabitt/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grabitt/pages/main_shell.dart';
import 'package:grabitt/pages/signup_page.dart';
import '../utils/shared_classes.dart';

enum LoginStep { phoneNumber, otp, success }

enum LoginMethod { otp, password }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  LoginStep _currentStep = LoginStep.phoneNumber;
  LoginMethod _loginMethod = LoginMethod.otp;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;
  Animation<double>? _jumpAnimation;

  bool _isPhoneValid = false;
  bool _isPasswordVisible = false;

  String _otpCode = '';
  String? _storedOtp;
  Map<String, dynamic>? _loggedInUser;
  bool _isCheckingUser = false;
  bool _isSendingOtp = false;
  bool _isResendingOtp = false;

  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  final List<AnimationController> _otpSlideControllers = [];
  final List<Animation<Offset>> _otpSlideAnimations = [];

  AnimationController? _successController;
  Animation<double>? _rotationAnimation;
  Animation<double>? _scaleAnimation;
  bool _isVerifying = false;
  bool _isVerified = false;

  Timer? _resendTimer;
  int _resendSeconds = 90;
  bool _canResendOtp = false;

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
      setState(() => _isPhoneValid = isValid);
    }
  }

  void _onPhoneDigitTyped() {
    _pulseController?.forward(from: 0.0).then((_) {
      _pulseController?.reverse();
    });
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendSeconds = 90;
      _canResendOtp = false;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
        setState(() => _canResendOtp = true);
      }
    });
  }

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

    final otp =
        phone == '9158724772' ? '5555' : '${1000 + Random().nextInt(9000)}';

    setState(() => _isSendingOtp = true);
    final sendResult = await AuthService.instance.sendOtp(phone, otp);
    if (!mounted) return;

    setState(() {
      _isCheckingUser = false;
      _isSendingOtp = false;
    });

    if (!sendResult.success) {
      ToastMessage.error(context: context, msg: 'Failed to send OTP');
      return;
    }

    _storedOtp = otp;
    _loggedInUser = result.user;
    _otpCode = '';
    for (var c in _otpControllers) {
      c.clear();
    }
    setState(() => _currentStep = LoginStep.otp);
    _startResendTimer();
  }

  Future<void> _login() async {
    if (!_isPhoneValid) return;
    final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      ToastMessage.error(context: context, msg: 'Please enter password');
      return;
    }

    setState(() => _isCheckingUser = true);
    final userResult = await AuthService.instance.getUserByPhone(phone);
    if (!mounted) return;

    if (!userResult.found || userResult.user == null) {
      setState(() => _isCheckingUser = false);
      _showUserNotFoundAndNavigateToSignup();
      return;
    }

    final loginResult = await AuthService.instance.userLogin(
      phoneno: phone,
      password: password,
    );
    if (!mounted) return;

    setState(() => _isCheckingUser = false);

    if (!loginResult.success) {
      ToastMessage.error(
          context: context, msg: loginResult.message ?? 'Login failed');
      return;
    }

    await AuthService.instance.saveLoginUser(userResult.user!);
    _passwordController.clear();
    if (!mounted) return;

    ToastMessage.success(
        context: context, msg: loginResult.message ?? 'Login successful');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
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
            child:
                Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SignupPage()),
              );
            },
            child: Text('Sign up',
                style: GoogleFonts.poppins(
                    color: const Color(0xFFFF0000),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _resendOtp() async {
    final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.isEmpty || _loggedInUser == null) return;

    setState(() => _isResendingOtp = true);
    final otp =
        phone == '9158724772' ? '5555' : '${1000 + Random().nextInt(9000)}';

    final result = await AuthService.instance.sendOtp(phone, otp);
    if (!mounted) return;

    setState(() => _isResendingOtp = false);
    if (result.success) {
      _storedOtp = otp;
      _startResendTimer();
      ToastMessage.success(context: context, msg: 'OTP resent successfully');
    } else {
      ToastMessage.error(
          context: context, msg: result.message ?? 'Failed to resend OTP');
    }
  }

  Future<void> _verifyOtp() async {
    if (_isVerifying || _isVerified) return; // guard double tap
    final entered = _otpCode.length == 4
        ? _otpCode
        : _otpControllers.map((c) => c.text).join();
    if (entered.length != 4 || _storedOtp == null || _loggedInUser == null) {
      return;
    }
    if (entered != _storedOtp) {
      ToastMessage.error(
          context: context, msg: 'Invalid OTP. Please try again.');
      return;
    }

    setState(() => _isVerifying = true);
    await AuthService.instance.saveLoginUser(_loggedInUser!);
    for (var c in _otpControllers) {
      c.clear();
    }
    _otpCode = '';
    _storedOtp = null;
    if (!mounted) return;

    setState(() => _isVerified = true);
    _successController?.forward();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _pulseController?.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var n in _otpFocusNodes) {
      n.dispose();
    }
    for (var c in _otpSlideControllers) {
      c.dispose();
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
      case LoginStep.success:
        return _buildOtpStep();
    }
  }

  Widget _buildPhoneNumberStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                key: const ValueKey('phone'),
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/newlogo2.png',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Welcome to GraB iTT!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _loginMethod == LoginMethod.otp
                          ? 'Enter your phone number to continue'
                          : 'Enter your phone number and password to continue',
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Login method toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _LoginMethodTab(
                            label: 'Login with OTP',
                            selected: _loginMethod == LoginMethod.otp,
                            onTap: () => setState(() {
                              _loginMethod = LoginMethod.otp;
                              _passwordController.clear();
                            }),
                          ),
                          _LoginMethodTab(
                            label: 'Password Login',
                            selected: _loginMethod == LoginMethod.password,
                            onTap: () => setState(() {
                              _loginMethod = LoginMethod.password;
                              for (var c in _otpControllers) {
                                c.clear();
                              }
                              _otpCode = '';
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Phone field
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
                                    color: Colors.blue.withValues(
                                      alpha: _pulseController!.value * 0.3,
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
                                textInputAction:
                                    _loginMethod == LoginMethod.password
                                        ? TextInputAction.next
                                        : TextInputAction.done,
                                onSubmitted: (_) {
                                  if (_loginMethod == LoginMethod.password) {
                                    FocusScope.of(context)
                                        .requestFocus(_passwordFocusNode);
                                  } else {
                                    FocusScope.of(context).unfocus();
                                  }
                                },
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                onChanged: (_) => _onPhoneDigitTyped(),
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                                decoration: InputDecoration(
                                    hintText: 'Phone Number',
                                    hintStyle: GoogleFonts.inter(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                    ),
                                    prefixIcon: const Icon(Icons.phone,
                                        color: Colors.grey),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 2)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                            color: Colors.blue, width: 3)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 18)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    if (_loginMethod == LoginMethod.password) ...[
                      TextField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: !_isPasswordVisible,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) {
                          if (_isPhoneValid && !_isCheckingUser) _login();
                        },
                        style: GoogleFonts.inter(
                            fontSize: 18, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle:
                                GoogleFonts.inter(color: Colors.grey[400]),
                            prefixIcon:
                                const Icon(Icons.lock, color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () => setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                    color: Colors.grey.shade300, width: 2)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: Colors.blue, width: 3)),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            )),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_isPhoneValid &&
                                !_isCheckingUser &&
                                !_isSendingOtp)
                            ? () {
                                if (_loginMethod == LoginMethod.otp) {
                                  _sendOtp();
                                } else {
                                  _login();
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: StoreProfileTheme.accentPink,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isCheckingUser || _isSendingOtp
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                _loginMethod == LoginMethod.otp
                                    ? 'Send OTP'
                                    : 'Login',
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
                              fontSize: 14, color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const SignupPage()));
                          },
                          child: Text(
                            'Sign up',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: StoreProfileTheme.accentPink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtpStep() {
    return SingleChildScrollView(
      child: Padding(
        key: const ValueKey('otp'),
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () {
                  setState(() {
                    _currentStep = LoginStep.phoneNumber;
                    _isVerifying = false;
                    _storedOtp = null;
                    _loggedInUser = null;
                    _otpCode = '';
                    for (var c in _otpControllers) {
                      c.clear();
                    }
                    _resendSeconds = 90;
                  });
                  _resendTimer?.cancel();
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Enter OTP',
              style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              'We sent a code to\n${_phoneController.text}',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 80),

            // OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 60,
                  height: 60,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: StoreProfileTheme.accentPink, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 3) {
                        _otpFocusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _otpFocusNodes[index - 1].requestFocus();
                      }
                      setState(() {
                        _otpCode = _otpControllers.map((c) => c.text).join();
                      });
                      if (_otpCode.length == 4 &&
                          !_isVerifying &&
                          !_isVerified) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) _verifyOtp();
                        });
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 56),

            // Verify button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: AnimatedBuilder(
                animation: _successController!,
                builder: (context, child) {
                  final isTransforming =
                      _isVerified && _successController!.value > 0;
                  final buttonColor = isTransforming
                      ? Color.lerp(StoreProfileTheme.accentPink, Colors.green,
                          _successController!.value)!
                      : StoreProfileTheme.accentPink;

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
                            borderRadius: BorderRadius.circular(16)),
                        elevation: isTransforming ? 8 : 0,
                      ),
                      child: isTransforming
                          ? Transform.scale(
                              scale: _scaleAnimation!.value,
                              child: const Icon(Icons.home,
                                  color: Colors.white, size: 28),
                            )
                          : _isVerifying
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
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
              onPressed:
                  (_isResendingOtp || !_canResendOtp) ? null : _resendOtp,
              child: _isResendingOtp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _canResendOtp
                          ? 'Resend OTP'
                          : 'Resend OTP in $_resendSeconds sec',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _canResendOtp
                            ? StoreProfileTheme.accentPink
                            : Colors.grey,
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

// Small stateless tab widget extracted to reduce build() nesting
class _LoginMethodTab extends StatelessWidget {
  const _LoginMethodTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? StoreProfileTheme.accentPink : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
