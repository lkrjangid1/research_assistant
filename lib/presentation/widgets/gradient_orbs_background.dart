import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

/// Renders three soft blurred gradient orbs as a background decoration.
///
/// Blue orb top-left, pink orb bottom-right, purple orb bottom-center.
/// Wraps [child] in a Stack so content sits above the orbs.
class GradientOrbsBackground extends StatelessWidget {
  final Widget child;

  const GradientOrbsBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final opacity = isDark ? 0.15 : 1.0;

    return Stack(
      children: [
        // Blue orb – top left
        Positioned(
          top: -120,
          left: -120,
          child: _GradientOrb(
            size: 420,
            color: AppColors.gradientBlue.withValues(alpha: 0.28 * opacity),
          ),
        ),
        // Pink orb – right side
        Positioned(
          top: size.height * 0.35,
          right: -90,
          child: _GradientOrb(
            size: 360,
            color: AppColors.gradientFuchsia.withValues(alpha: 0.22 * opacity),
          ),
        ),
        // Purple orb – bottom center
        Positioned(
          bottom: -60,
          left: size.width * 0.35,
          child: _GradientOrb(
            size: 320,
            color: AppColors.gradientPurple.withValues(alpha: 0.18 * opacity),
          ),
        ),
        // Content
        child,
      ],
    );
  }
}

class _GradientOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GradientOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 0.7],
          ),
        ),
      ),
    );
  }
}
