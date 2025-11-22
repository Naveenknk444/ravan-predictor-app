import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../routes/app_routes.dart';
import '../../widgets/common/galaxy_background.dart';
import '../../widgets/buttons/primary_button.dart';

/// Welcome bonus screen - celebration with 10,000 coins
class WelcomeBonusScreen extends StatefulWidget {
  const WelcomeBonusScreen({super.key});

  @override
  State<WelcomeBonusScreen> createState() => _WelcomeBonusScreenState();
}

class _WelcomeBonusScreenState extends State<WelcomeBonusScreen>
    with TickerProviderStateMixin {
  // Bounce animation for icon
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  // Counter animation for coins
  late AnimationController _counterController;
  late Animation<int> _counterAnimation;

  // Fade in animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Confetti particles
  final List<ConfettiParticle> _confettiParticles = [];
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();

    // Bounce animation for party icon
    _bounceController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Counter animation (0 to 10,000)
    _counterController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _counterAnimation = IntTween(begin: 0, end: 10000).animate(
      CurvedAnimation(parent: _counterController, curve: Curves.easeOut),
    );

    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Generate confetti particles
    _generateConfetti();

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _counterController.forward();
    });
  }

  void _generateConfetti() {
    final random = Random();
    final colors = [
      AppColors.primary,
      AppColors.purple,
      AppColors.success,
      AppColors.primary,
      const Color(0xFF8B5CF6),
    ];

    for (int i = 0; i < 30; i++) {
      _confettiParticles.add(
        ConfettiParticle(
          x: random.nextDouble(),
          delay: random.nextDouble(),
          color: colors[random.nextInt(colors.length)],
          size: 4 + random.nextDouble() * 4,
        ),
      );
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _counterController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return GalaxyScaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti overlay
            _buildConfetti(),

            // Main content
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  children: [
                    const Spacer(flex: 1),

                    // Party icon
                    _buildPartyIcon(),

                    const SizedBox(height: AppSpacing.xl),

                    // Welcome text
                    Text(
                      'Welcome to Ravan!',
                      style: AppTypography.h1,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Your account has been created successfully',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xxxl),

                    // Bonus card
                    _buildBonusCard(),

                    const Spacer(flex: 1),

                    // Start playing button
                    PrimaryButton(
                      text: 'Start Playing',
                      onPressed: () => context.go(AppRoutes.dashboard),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Terms note
                    Text(
                      'Bonus coins are for practice only and cannot be withdrawn.\nUse them to make predictions and win real rewards!',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(
            particles: _confettiParticles,
            progress: _confettiController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildPartyIcon() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🎉',
                style: TextStyle(fontSize: 50),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBonusCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Label
          Text(
            'WELCOME BONUS',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Animated coin amount
          AnimatedBuilder(
            animation: _counterAnimation,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Coin icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'C',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Counter
                  Text(
                    _formatNumber(_counterAnimation.value),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: AppSpacing.sm),

          // Subtitle
          Text(
            'Coins added to your wallet',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Data class for confetti particle
class ConfettiParticle {
  final double x;
  final double delay;
  final Color color;
  final double size;

  ConfettiParticle({
    required this.x,
    required this.delay,
    required this.color,
    required this.size,
  });
}

/// Custom painter for confetti
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Calculate particle progress with delay
      final particleProgress = ((progress + particle.delay) % 1.0);

      // Y position (falls from top to bottom)
      final y = particleProgress * size.height * 0.4;

      // X position (slight horizontal drift)
      final x = particle.x * size.width +
          sin(particleProgress * 4 * pi) * 10;

      // Opacity (fade out as it falls)
      final opacity = (1 - particleProgress).clamp(0.0, 1.0);

      // Rotation
      final rotation = particleProgress * 4 * pi;

      // Draw particle
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
