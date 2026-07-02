import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final bool visible;
  const ConfettiOverlay({super.key, required this.visible});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _controller.addListener(() {
      setState(() {
        for (var p in _particles) {
          p.update();
        }
      });
    });
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _spawnParticles();
      _controller.forward(from: 0.0);
    }
  }

  void _spawnParticles() {
    _particles.clear();
    final colors = [
      const Color(0xffeab308), // Gold
      const Color(0xff10b981), // Green
      const Color(0xff3b82f6), // Blue
      const Color(0xffec4899), // Pink
      const Color(0xfff97316), // Orange
      const Color(0xffa855f7), // Purple
    ];
    // Spawn 120 particles at random top locations
    for (int i = 0; i < 120; i++) {
      _particles.add(
        _ConfettiParticle(
          x: _random.nextDouble() * 400.0, // Will map to canvas width
          y: -_random.nextDouble() * 200.0, // Start above screen
          color: colors[_random.nextInt(colors.length)],
          size: _random.nextDouble() * 8 + 6,
          velocityX: (_random.nextDouble() - 0.5) * 6,
          velocityY: _random.nextDouble() * 8 + 5,
          spinSpeed: (_random.nextDouble() - 0.5) * 0.2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _controller.isCompleted) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(_particles),
        size: Size.infinite,
      ),
    );
  }
}

class _ConfettiParticle {
  double x;
  double y;
  final Color color;
  final double size;
  final double velocityX;
  double velocityY;
  final double spinSpeed;
  double angle = 0.0;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.velocityX,
    required this.velocityY,
    required this.spinSpeed,
  });

  void update() {
    x += velocityX;
    velocityY += 0.15; // Gravity
    y += velocityY;
    angle += spinSpeed;
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      // Adjust x to fit screen width
      final double renderX = p.x % size.width;
      if (p.y > size.height) continue;

      paint.color = p.color;
      canvas.save();
      canvas.translate(renderX, p.y);
      canvas.rotate(p.angle);
      
      // Draw rectangular paper snippet
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
