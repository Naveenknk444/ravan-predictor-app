import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/common/galaxy_background.dart';
import '../../widgets/buttons/primary_button.dart';

/// OTP verification screen - 6-digit code input with resend timer
class OTPScreen extends StatefulWidget {
  final String phone;
  final String? name;
  final String? referralCode;
  final bool isNewUser;

  const OTPScreen({
    super.key,
    required this.phone,
    this.name,
    this.referralCode,
    this.isNewUser = false,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isVerifying = false;
  String? _errorText;
  int _resendSeconds = 60;
  Timer? _resendTimer;

  final _authService = AuthService();

  // Animation for floating icon
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Start resend timer
    _startResendTimer();

    // Setup floating animation
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Focus first input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _resendTimer?.cancel();
    _floatController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _formattedPhone {
    // Format phone for display
    final phone = widget.phone;
    if (phone.length > 10) {
      final countryCode = phone.substring(0, phone.length - 10);
      final number = phone.substring(phone.length - 10);
      return '$countryCode ${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
    }
    return phone;
  }

  String get _otpCode {
    return _controllers.map((c) => c.text).join();
  }

  bool get _isOtpComplete {
    return _otpCode.length == 6;
  }

  void _onOtpChanged(int index, String value) {
    // Clear error when typing
    if (_errorText != null) {
      setState(() => _errorText = null);
    }

    if (value.isNotEmpty) {
      // Move to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field filled, unfocus and auto-verify
        _focusNodes[index].unfocus();
        if (_isOtpComplete) {
          _handleVerify();
        }
      }
    }
  }

  void _onKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          // Move to previous field on backspace if current is empty
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].clear();
        }
      }
    }
  }

  void _handlePaste(String? pastedText) {
    if (pastedText == null || pastedText.isEmpty) return;

    // Extract only digits
    final digits = pastedText.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    // Fill in the OTP fields
    for (int i = 0; i < 6 && i < digits.length; i++) {
      _controllers[i].text = digits[i];
    }

    // Focus last filled or next empty field
    final lastIndex = digits.length >= 6 ? 5 : digits.length;
    if (lastIndex == 5 && digits.length >= 6) {
      _focusNodes[5].unfocus();
      if (_isOtpComplete) {
        _handleVerify();
      }
    } else {
      _focusNodes[lastIndex].requestFocus();
    }

    setState(() {});
  }

  Future<void> _handleVerify() async {
    if (!_isOtpComplete || _isVerifying) return;

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    try {
      // Verify OTP with Supabase
      final response = await _authService.verifyOTP(widget.phone, _otpCode);

      if (mounted && response.user != null) {
        // Check if new user and create profile
        if (widget.isNewUser) {
          await _authService.createUserProfile(
            userId: response.user!.id,
            phone: widget.phone,
            name: widget.name,
            referralCode: widget.referralCode,
          );
          // Go to welcome bonus
          context.go(AppRoutes.welcomeBonus);
        } else {
          // Existing user - go to dashboard
          context.go(AppRoutes.dashboard);
        }
      }
    } on AuthServiceException catch (e) {
      setState(() {
        _errorText = e.message;
        // Clear inputs on error
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      });
    } catch (e) {
      setState(() {
        _errorText = 'Invalid OTP. Please try again.';
        // Clear inputs on error
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      });
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Future<void> _handleResend() async {
    if (_resendSeconds > 0 || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Resend OTP via Supabase
      await _authService.sendOTP(widget.phone);

      if (mounted) {
        // Clear current OTP
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();

        // Restart timer
        _startResendTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('OTP sent successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } on AuthServiceException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to resend OTP'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GalaxyScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            _buildHeader(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // Lock icon
                    _buildIcon(),

                    const SizedBox(height: AppSpacing.xl),

                    // Title and subtitle
                    _buildTitle(),

                    const SizedBox(height: AppSpacing.xxxl),

                    // OTP inputs
                    _buildOtpInputs(),

                    if (_errorText != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _errorText!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // Timer and resend
                    _buildResendSection(),

                    const SizedBox(height: AppSpacing.xxxl),

                    // Verify button
                    PrimaryButton(
                      text: 'Verify & Continue',
                      onPressed: _isOtpComplete ? _handleVerify : null,
                      isLoading: _isVerifying,
                      isDisabled: !_isOtpComplete,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Help text
                    _buildHelpText(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.purple.withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.lock_outline,
                size: 36,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Verify Your Number',
          style: AppTypography.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          "We've sent a 6-digit code to",
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _formattedPhone,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final hasValue = _controllers[index].text.isNotEmpty;
        final hasError = _errorText != null;

        return Container(
          width: 48,
          height: 56,
          margin: EdgeInsets.only(
            left: index > 0 ? 8 : 0,
          ),
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (event) => _onKeyPressed(index, event),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: hasError
                    ? AppColors.error.withOpacity(0.1)
                    : hasValue
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surfaceDark.withOpacity(0.9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError
                        ? AppColors.error
                        : hasValue
                            ? AppColors.primary
                            : AppColors.border,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError
                        ? AppColors.error
                        : hasValue
                            ? AppColors.primary
                            : AppColors.border,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) => _onOtpChanged(index, value),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        if (_resendSeconds > 0)
          Text(
            'Resend code in ${_resendSeconds.toString().padLeft(2, '0')}s',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive code? ",
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: _resendSeconds == 0 ? _handleResend : null,
              child: Text(
                'Resend OTP',
                style: AppTypography.bodySmall.copyWith(
                  color: _resendSeconds == 0
                      ? AppColors.primary
                      : AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHelpText() {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to help/support
      },
      child: RichText(
        text: TextSpan(
          text: 'Having trouble? ',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          children: [
            TextSpan(
              text: 'Contact Support',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
