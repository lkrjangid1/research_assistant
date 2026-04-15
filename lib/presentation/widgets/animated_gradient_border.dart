import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

/// Wraps [child] with a continuously-rotating conic-gradient border.
///
/// Matches the Google AI Studio / Gemini search bar aesthetic.
class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Duration duration;
  final bool active;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = 28,
    this.borderWidth = 2,
    this.duration = const Duration(seconds: 3),
    this.active = true,
  });

  @override
  State<AnimatedGradientBorder> createState() =>
      _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(AnimatedGradientBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _GradientBorderPainter(
            progress: _controller.value,
            borderRadius: widget.borderRadius,
            borderWidth: widget.borderWidth,
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.borderWidth),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(widget.borderRadius - widget.borderWidth),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final double progress;
  final double borderRadius;
  final double borderWidth;

  _GradientBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    final gradient = SweepGradient(
      startAngle: progress * 2 * math.pi,
      endAngle: progress * 2 * math.pi + 2 * math.pi,
      colors: AppColors.gradientBorderColors,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter old) =>
      old.progress != progress;
}
