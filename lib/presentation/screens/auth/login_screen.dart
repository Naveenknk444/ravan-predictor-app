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

/// Login screen - phone number login with OTP
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCountryCode = '+91';
  bool _isLoading = false;
  String? _errorText;

  final _authService = AuthService();

  // Animation for floating logo
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  bool _validatePhone() {
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) {
      setState(() => _errorText = 'Please enter your phone number');
      return false;
    }
    if (phone.length != 10) {
      setState(() => _errorText = 'Phone number must be 10 digits');
      return false;
    }
    setState(() => _errorText = null);
    return true;
  }

  Future<void> _handleSendOTP() async {
    if (!_validatePhone()) return;

    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      final fullPhone = '$_selectedCountryCode$phone';

      // Send OTP via Supabase
      await _authService.sendOTP(fullPhone);

      if (mounted) {
        context.push(
          AppRoutes.otp,
          extra: {
            'phone': fullPhone,
            'isNewUser': false,
          },
        );
      }
    } on AuthServiceException catch (e) {
      setState(() {
        _errorText = e.message;
      });
    } catch (e) {
      setState(() {
        _errorText = 'Failed to send OTP. Please try again.';
      });
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // Logo and App Name
                _buildHeader(),

                const SizedBox(height: AppSpacing.xxxl),

                // Tab switcher
                _buildTabSwitcher(),

                const SizedBox(height: AppSpacing.xl),

                // Phone input
                _buildPhoneInput(),

                const SizedBox(height: AppSpacing.lg),

                // Send OTP Button
                PrimaryButton(
                  text: 'Send OTP',
                  onPressed: _handleSendOTP,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Sign up link
                _buildSignUpLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Animated floating logo
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatAnimation.value),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'R',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: AppSpacing.md),

        // App name
        Text(
          'Ravan Predictor',
          style: AppTypography.h3.copyWith(
            color: AppColors.primary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Sign Up tab
          Expanded(
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.signup),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),

          // Login tab (active)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Login',
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: AppTypography.labelMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country code dropdown
            Container(
              width: 90,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  dropdownColor: AppColors.surfaceDark,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  items: const [
                    DropdownMenuItem(value: '+91', child: Text('IN +91')),
                    DropdownMenuItem(value: '+1', child: Text('US +1')),
                    DropdownMenuItem(value: '+44', child: Text('UK +44')),
                    DropdownMenuItem(value: '+61', child: Text('AU +61')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCountryCode = value);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Phone number input
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Enter phone number',
                  errorText: _errorText,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.signup),
        child: RichText(
          text: TextSpan(
            text: "Don't have an account? ",
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(
                text: 'Sign Up',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
