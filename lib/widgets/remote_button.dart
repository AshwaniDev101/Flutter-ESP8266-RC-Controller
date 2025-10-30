import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../enums/directions.dart';

/// A directional button that provides press and release callbacks.
/// It uses a single rotated icon for all four directions.
class RemoteButton extends StatelessWidget {
  final Directions direction;
  final void Function(Directions)? onPressed;
  final void Function(Directions)? onReleased;
  final Color color;
  final bool enabled;

  const RemoteButton({
    super.key,
    required this.direction,
    this.onPressed,
    this.onReleased,
    this.color = Colors.teal,
    this.enabled = true,
  });

  /// Calculates the rotation for the arrow icon based on the direction.
  double _getRotationAngle() {
    switch (direction) {
      case Directions.UP:
        return -90 * math.pi / 180; // -90 degrees
      case Directions.DOWN:
        return 90 * math.pi / 180;  // 90 degrees
      case Directions.LEFT:
        return 180 * math.pi / 180; // 180 degrees
      case Directions.RIGHT:
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: enabled ? color : Colors.grey,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTapDown: enabled ? (_) => onPressed?.call(direction) : null,
          onTapUp: enabled ? (_) => onReleased?.call(direction) : null,
          // Ensures onReleased is called if the user's finger slides off the button.
          onTapCancel: enabled ? () => onReleased?.call(direction) : null,
          child: SizedBox(
            width: 60,
            height: 60,
            child: Transform.rotate(
              angle: _getRotationAngle(),
              child: const Icon(
                Icons.arrow_forward_ios,
                size: 25,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
