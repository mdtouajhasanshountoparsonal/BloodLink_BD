import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/animation_pref.dart';
import '../theme/app_colors.dart';

/// পানিতে মাছের মতো হালকা দোলা: অবতারটা উপরে-নিচে + সামান্য কাত হয়ে "সাঁতার কাটে"।
/// settings-এ বন্ধ করলে (AnimationPref) শুধু child-ই দেখানো হয়।
class SwimmingAvatar extends StatelessWidget {
  const SwimmingAvatar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AnimationPref.instance.enabled,
      builder: (context, on, _) => on ? _SwimTicker(child: child) : child,
    );
  }
}

class _SwimTicker extends StatefulWidget {
  const _SwimTicker({required this.child});

  final Widget child;

  @override
  State<_SwimTicker> createState() => _SwimTickerState();
}

class _SwimTickerState extends State<_SwimTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = _c.value;
        final dy = math.sin(t * 2 * math.pi) * 2.4;
        final rot = math.sin(t * 2 * math.pi + 0.9) * 0.055;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(angle: rot, child: widget.child),
        );
      },
    );
  }
}

/// কার্ডের নিচে হালকা "পানি-ঢেউ" — মাছ যেন পানির ভেতর ভাসে।
/// settings-এ বন্ধ করলে (AnimationPref) শুধু ফাঁকা জায়গা থাকে।
class WaterRipple extends StatelessWidget {
  const WaterRipple({super.key, this.color, this.height = 8});

  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AnimationPref.instance.enabled,
      builder: (context, on, _) => on
          ? _RippleTicker(color: color ?? AppColors.primary, height: height)
          : SizedBox(height: height / 2),
    );
  }
}

class _RippleTicker extends StatefulWidget {
  const _RippleTicker({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  State<_RippleTicker> createState() => _RippleTickerState();
}

class _RippleTickerState extends State<_RippleTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        size: Size(double.infinity, widget.height),
        painter: _WavePainter(
          progress: _c.value,
          color: widget.color,
          height: widget.height,
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.progress,
    required this.color,
    required this.height,
  });

  final double progress;
  final Color color;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final amp = height / 3.2;

    final front = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.4);

    final back = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.18);

    final p1 = Path();
    final p2 = Path();
    for (double x = 0; x <= w; x += 2) {
      final y1 =
          height / 2 + math.sin((x / w) * 6.283 * 1.9 + progress * 6.283) * amp;
      final y2 =
          height / 2 +
          math.sin((x / w) * 6.283 * 2.5 + progress * 6.283 * 1.35 + 0.7) *
              amp *
              0.55;
      if (x == 0) {
        p1.moveTo(0, y1);
        p2.moveTo(0, y2);
      } else {
        p1.lineTo(x, y1);
        p2.lineTo(x, y2);
      }
    }
    canvas.drawPath(p1, front);
    canvas.drawPath(p2, back);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.progress != progress || old.color != color || old.height != height;
}
