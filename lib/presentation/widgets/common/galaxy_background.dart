import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Galaxy background with pulsar ripple effects - used throughout the app
class GalaxyBackground extends StatefulWidget {
  final Widget child;
  final bool showRipples;
  final bool showCricketLogos;

  const GalaxyBackground({
    super.key,
    required this.child,
    this.showRipples = true,
    this.showCricketLogos = false,
  });

  @override
  State<GalaxyBackground> createState() => _GalaxyBackgroundState();
}

class _GalaxyBackgroundState extends State<GalaxyBackground>
    with TickerProviderStateMixin {
  late AnimationController _rippleController1;
  late AnimationController _rippleController2;
  late Animation<double> _rippleAnimation1;
  late Animation<double> _rippleAnimation2;

  @override
  void initState() {
    super.initState();

    // First ripple animation (top)
    _rippleController1 = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _rippleAnimation1 = Tween<double>(begin: 0.6, end: 1.5).animate(
      CurvedAnimation(parent: _rippleController1, curve: Curves.easeInOut),
    );

    // Second ripple animation (bottom) - delayed by 5 seconds
    _rippleController2 = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _rippleController2.repeat();
      }
    });

    _rippleAnimation2 = Tween<double>(begin: 0.6, end: 1.5).animate(
      CurvedAnimation(parent: _rippleController2, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rippleController1.dispose();
    _rippleController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // Base gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF111111),
                  Color(0xFF0D0D0D),
                ],
              ),
            ),
          ),

          // Ripple effects
          if (widget.showRipples) ...[
            // Top ripple
            AnimatedBuilder(
              animation: _rippleAnimation1,
              builder: (context, child) {
                return Positioned.fill(
                  child: CustomPaint(
                    painter: RipplePainter(
                      scale: _rippleAnimation1.value,
                      opacity: _getOpacity(_rippleAnimation1.value),
                      center: const Alignment(0, -0.7),
                      color: AppColors.purple,
                    ),
                  ),
                );
              },
            ),

            // Bottom ripple
            AnimatedBuilder(
              animation: _rippleAnimation2,
              builder: (context, child) {
                return Positioned.fill(
                  child: CustomPaint(
                    painter: RipplePainter(
                      scale: _rippleAnimation2.value,
                      opacity: _getOpacity(_rippleAnimation2.value),
                      center: const Alignment(0, 0.7),
                      color: AppColors.purple,
                    ),
                  ),
                );
              },
            ),
          ],

          // Main content
          widget.child,
        ],
      ),
    );
  }

  double _getOpacity(double scale) {
    // Fade in from 0.6 to 1.0, then fade out from 1.0 to 1.5
    if (scale < 0.8) {
      return ((scale - 0.6) / 0.2).clamp(0.0, 1.0);
    } else if (scale > 1.3) {
      return ((1.5 - scale) / 0.2).clamp(0.0, 1.0);
    }
    return 1.0;
  }
}

/// Custom painter for ripple effect
class RipplePainter extends CustomPainter {
  final double scale;
  final double opacity;
  final Alignment center;
  final Color color;

  RipplePainter({
    required this.scale,
    required this.opacity,
    required this.center,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerOffset = Offset(
      size.width * (0.5 + center.x * 0.5),
      size.height * (0.5 + center.y * 0.5),
    );

    // Draw multiple concentric circles for ripple effect
    for (int i = 3; i >= 1; i--) {
      final radius = size.width * 0.3 * scale * (1 + i * 0.1);
      final paint = Paint()
        ..color = color.withOpacity(0.03 * opacity / i)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(centerOffset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.scale != scale || oldDelegate.opacity != opacity;
  }
}

/// Scaffold with galaxy background - use this instead of regular Scaffold
class GalaxyScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool showRipples;
  final bool extendBodyBehindAppBar;

  const GalaxyScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.showRipples = true,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      body: GalaxyBackground(
        showRipples: showRipples,
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
