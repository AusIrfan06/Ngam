import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base Color
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        
        // Animated Blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                _buildBlob(
                  color: const Color(0xFFFF8C00).withValues(alpha: isDark ? 0.3 : 0.5),
                  size: 300,
                  offset: Offset(
                    size.width * 0.2 + sin(_controller.value * 2 * pi) * 100,
                    size.height * 0.1 + cos(_controller.value * 2 * pi) * 100,
                  ),
                ),
                _buildBlob(
                  color: const Color(0xFFE74C3C).withValues(alpha: isDark ? 0.2 : 0.4),
                  size: 250,
                  offset: Offset(
                    size.width * 0.7 + cos(_controller.value * 2 * pi) * 150,
                    size.height * 0.3 + sin(_controller.value * 2 * pi) * 150,
                  ),
                ),
                _buildBlob(
                  color: const Color(0xFFF39C12).withValues(alpha: isDark ? 0.2 : 0.4),
                  size: 350,
                  offset: Offset(
                    size.width * 0.4 - cos(_controller.value * 2 * pi) * 100,
                    size.height * 0.7 - sin(_controller.value * 2 * pi) * 100,
                  ),
                ),
              ],
            );
          },
        ),

        // Blur Filter over the blobs to create the ambient effect
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // The actual page content
        widget.child,
      ],
    );
  }

  Widget _buildBlob({
    required Color color,
    required double size,
    required Offset offset,
  }) {
    return Positioned(
      left: offset.dx - size / 2,
      top: offset.dy - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
