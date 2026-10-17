import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:workshop/workshop.dart' as workshop;

import 'workshop_palette.dart';

/// Célébration d'une Énigme réussie : une gerbe de confettis aux couleurs du jeu qui
/// retombe sur tout l'écran. C'est l'exception volontaire à l'ambiance sobre
/// (`docs/PLAN.md`). Ne capte aucun toucher. Une seule animation, finie.
class SuccessCelebration extends StatefulWidget {
  const SuccessCelebration({super.key});

  @override
  State<SuccessCelebration> createState() => _SuccessCelebrationState();
}

class _SuccessCelebrationState extends State<SuccessCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();

  late final List<_Piece> _pieces = _makePieces();

  static List<_Piece> _makePieces() {
    final random = math.Random(7);
    return [
      for (var i = 0; i < 90; i++)
        _Piece(
          color: flutterColorOf(
            workshop.Color.values[random.nextInt(workshop.Color.values.length)],
          ),
          startX: random.nextDouble(),
          drift: (random.nextDouble() - 0.5) * 0.5,
          speed: 0.55 + random.nextDouble() * 0.6,
          delay: random.nextDouble() * 0.25,
          size: 6 + random.nextDouble() * 8,
          spin: (random.nextDouble() - 0.5) * 12,
          round: random.nextBool(),
        ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) =>
            CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_pieces, _controller.value)),
      ),
    );
  }
}

class _Piece {
  final Color color;
  final double startX;
  final double drift;
  final double speed;
  final double delay;
  final double size;
  final double spin;
  final bool round;

  const _Piece({
    required this.color,
    required this.startX,
    required this.drift,
    required this.speed,
    required this.delay,
    required this.size,
    required this.spin,
    required this.round,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double progress;

  _ConfettiPainter(this.pieces, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final t = ((progress - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
      if (t == 0) continue;
      // Jaillit du haut avec un léger élan vers le haut, puis retombe.
      final y = size.height * (-0.1 + 1.2 * piece.speed * t * t + (-0.35) * t * (1 - t));
      final x = size.width * (piece.startX + piece.drift * t);
      final opacity = t < 0.8 ? 1.0 : (1 - t) / 0.2;
      final paint = Paint()..color = piece.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.spin * t);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: piece.size,
        height: piece.round ? piece.size : piece.size * 0.55,
      );
      if (piece.round) {
        canvas.drawOval(rect, paint);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(2)), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
