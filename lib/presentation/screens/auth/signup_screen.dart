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

/// Sign up screen - new user registration with phone
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _referralController = TextEditingController();

  String _selectedCountryCode = '+91';
  bool _isLoading = false;
  bool _agreeToTerms = false;
  String? _nameError;
  String? _phoneError;

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
    _nameController.dispose();
    _phoneController.dispose();
    _referralController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    bool isValid = true;

    // Validate name
    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = 'Please enter your name');
      isValid = false;
    } else if (_nameController.text.trim().length < 2) {
      setState(() => _nameError = 'Name must be at least 2 characters');
      isValid = false;
    } else {
      setState(() => _nameError = null);
    }

    // Validate phone
    final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) {
      setState(() => _phoneError = 'Please enter your phone number');
      isValid = false;
    } else if (phone.length != 10) {
      setState(() => _phoneError = 'Phone number must be 10 digits');
      isValid = false;
    } else {
      setState(() => _phoneError = null);
    }

    // Validate terms
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms of Service'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleSignUp() async {
    if (!_validateForm()) return;

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
            'name': _nameController.text.trim(),
            'referralCode': _referralController.text.trim(),
            'isNewUser': true,
          },
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
          content: const Text('Failed to sign up. Please try again.'),
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

                // Name input
                _buildNameInput(),

                const SizedBox(height: AppSpacing.lg),

                // Phone input
                _buildPhoneInput(),

                const SizedBox(height: AppSpacing.lg),

                // Referral code input
                _buildReferralInput(),

                const SizedBox(height: AppSpacing.lg),

                // Terms checkbox
                _buildTermsCheckbox(),

                const SizedBox(height: AppSpacing.xl),

                // Get Started Button
                PrimaryButton(
                  text: 'Get Started',
                  onPressed: _handleSignUp,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Login link
                _buildLoginLink(),

                const SizedBox(height: AppSpacing.lg),
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
          // Sign Up tab (active)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Sign Up',
                textAlign: TextAlign.center,
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Login tab
          Expanded(
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.login),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Login',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Full Name',
          style: AppTypography.labelMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _nameController,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            errorText: _nameError,
            prefixIcon: const Icon(
              Icons.person_outline,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          onChanged: (_) {
            if (_nameError != null) {
              setState(() => _nameError = null);
            }
          },
        ),
      ],
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
                  errorText: _phoneError,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                onChanged: (_) {
                  if (_phoneError != null) {
                    setState(() => _phoneError = null);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReferralInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referral Code (Optional)',
          style: AppTypography.labelMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _referralController,
          textCapitalization: TextCapitalization.characters,
          style: AppTypography.bodyMedium,
          decoration: const InputDecoration(
            hintText: 'Enter referral code',
            prefixIcon: Icon(
              Icons.card_giftcard_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (value) {
              setState(() => _agreeToTerms = value ?? false);
            },
            activeColor: AppColors.primary,
            checkColor: Colors.black,
            side: const BorderSide(color: AppColors.border, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _agreeToTerms = !_agreeToTerms);
            },
            child: RichText(
              text: TextSpan(
                text: 'I agree to the ',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  TextSpan(
                    text: ' and ',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.login),
        child: RichText(
          text: TextSpan(
            text: 'Already have an account? ',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(
                text: 'Login',
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
