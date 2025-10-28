import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../enums/directions.dart';

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

  double _getRotationAngle() {
    switch (direction) {
      case Directions.UP:
        return -90 * math.pi / 180;
      case Directions.DOWN:
        return 90 * math.pi / 180;
      case Directions.LEFT:
        return 180 * math.pi / 180;
      case Directions.RIGHT:
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5, // faded if disabled
      child: Material(
        color: enabled?color:Colors.grey,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTapDown: enabled
              ? (_) {
            if (onPressed != null) onPressed!(direction);
          }
              : null,
          onTapUp: enabled
              ? (_) {
            if (onReleased != null) onReleased!(direction);
          }
              : null,
          onTapCancel: enabled
              ? () {
            if (onReleased != null) onReleased!(direction);
          }
              : null,
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
