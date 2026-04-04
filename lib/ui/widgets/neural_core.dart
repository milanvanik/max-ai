import 'package:flutter/material.dart';
import 'dart:math' as math;

enum CoreState { idle, listening, thinking, speaking }

class MaxNeuralCore extends StatefulWidget {
  final CoreState state;
  final double size;

  const MaxNeuralCore({
    super.key,
    this.state = CoreState.idle,
    this.size = 200,
  });

  @override
  State<MaxNeuralCore> createState() => _MaxNeuralCoreState();
}

class _MaxNeuralCoreState extends State<MaxNeuralCore> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(MaxNeuralCore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      // Adjust animation speed based on state
      switch (widget.state) {
        case CoreState.idle:
          _controller.duration = const Duration(seconds: 4);
          _controller.repeat(reverse: true);
          break;
        case CoreState.listening:
          _controller.duration = const Duration(milliseconds: 1500);
          _controller.repeat(reverse: true);
          break;
        case CoreState.thinking:
          _controller.duration = const Duration(seconds: 2);
          _controller.repeat(); // Continuous rotation
          break;
        case CoreState.speaking:
          _controller.duration = const Duration(milliseconds: 800);
          _controller.repeat(reverse: true);
          break;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _NeuralCorePainter(
              animationValue: _controller.value,
              state: widget.state,
              color: Theme.of(context).colorScheme.tertiary, // Ice Blue
            ),
          );
        },
      ),
    );
  }
}

class _NeuralCorePainter extends CustomPainter {
  final double animationValue;
  final CoreState state;
  final Color color;

  _NeuralCorePainter({
    required this.animationValue,
    required this.state,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35 + (state == CoreState.listening ? animationValue * 10 : 0);
    
    // Draw the outer glow
    final glowPaint = Paint()
      ..color = color.withValues(
        alpha: state == CoreState.idle ? 0.1 + (animationValue * 0.05) : 0.2 + (animationValue * 0.2)
      )
      ..style = PaintingStyle.fill;
    
    // Pulse size expands dynamically
    double pulseRadius = radius * 1.2;
    if (state == CoreState.speaking || state == CoreState.listening) {
       pulseRadius += animationValue * radius * 0.4;
    }
    canvas.drawCircle(center, pulseRadius, glowPaint);

    // Geometry Paint
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw an abstract dodecahedron/icosahedron projection
    final path = Path();
    final rotation = state == CoreState.thinking ? animationValue * 2 * math.pi : animationValue * 0.2;
    
    // Generate vertices for a hexagon bounding box
    List<Offset> outerVertices = [];
    for (int i = 0; i < 6; i++) {
      double angle = rotation + (i * math.pi / 3);
      double rx = center.dx + radius * math.cos(angle);
      double ry = center.dy + radius * math.sin(angle);
      outerVertices.add(Offset(rx, ry));
    }

    // Generate smaller inner vertices
    List<Offset> innerVertices = [];
    double innerRadius = radius * 0.5;
    for (int i = 0; i < 6; i++) {
      double angle = rotation + (i * math.pi / 3) + (math.pi / 6); // offset by 30 deg
      double rx = center.dx + innerRadius * math.cos(angle);
      double ry = center.dy + innerRadius * math.sin(angle);
      innerVertices.add(Offset(rx, ry));
    }

    // Draw outer lines
    for (int i = 0; i < outerVertices.length; i++) {
      if (i == 0) {
        path.moveTo(outerVertices[i].dx, outerVertices[i].dy);
      } else {
        path.lineTo(outerVertices[i].dx, outerVertices[i].dy);
      }
    }
    path.close();

    // Connect inner and outer
    for (int i = 0; i < 6; i++) {
      path.moveTo(outerVertices[i].dx, outerVertices[i].dy);
      path.lineTo(innerVertices[i].dx, innerVertices[i].dy);
      path.lineTo(innerVertices[(i + 1) % 6].dx, innerVertices[(i + 1) % 6].dy);
    }
    
    // Draw central star
    for (int i = 0; i < innerVertices.length; i++) {
      path.moveTo(center.dx, center.dy);
      path.lineTo(innerVertices[i].dx, innerVertices[i].dy);
    }

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _NeuralCorePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.state != state;
  }
}
