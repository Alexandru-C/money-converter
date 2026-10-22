import 'dart:math';

import 'package:flutter/material.dart';

/// Flags drawn as shapes, so the web build needs no emoji font download.
class Flag extends StatelessWidget {
  const Flag(this.currency, {super.key, this.height = 24});

  final String currency;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 8),
      child: SizedBox(
        width: height * 1.5,
        height: height,
        child: switch (currency) {
          'RON' => const _Stripes(
              [Color(0xFF002B7F), Color(0xFFFCD116), Color(0xFFCE1126)],
              Axis.horizontal),
          'RSD' => const _Stripes(
              [Color(0xFFC6363C), Color(0xFF0C4076), Color(0xFFFFFFFF)],
              Axis.vertical),
          _ => CustomPaint(painter: _EuPainter()),
        },
      ),
    );
  }
}

class _Stripes extends StatelessWidget {
  const _Stripes(this.colors, this.direction);

  final List<Color> colors;
  final Axis direction;

  @override
  Widget build(BuildContext context) => Flex(
        direction: direction,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final c in colors) Expanded(child: ColoredBox(color: c))],
      );
}

class _EuPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF003399));
    final gold = Paint()..color = const Color(0xFFFFCC00);
    final center = size.center(Offset.zero);
    final ring = size.height / 3;
    final r = size.height / 18;
    for (var i = 0; i < 12; i++) {
      final a = i * pi / 6;
      final c = center + Offset(cos(a), sin(a)) * ring;
      final star = Path();
      for (var p = 0; p < 10; p++) {
        final pa = -pi / 2 + p * pi / 5;
        final pr = p.isEven ? r : r * 0.4;
        final pt = c + Offset(cos(pa), sin(pa)) * pr;
        p == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(star..close(), gold);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
