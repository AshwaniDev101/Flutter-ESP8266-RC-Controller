import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

/// A vertical slider with discrete steps, used for controlling motor speed.
class VerticalStepSlider extends StatelessWidget {
  final double value;
  final ValueChanged<dynamic> onChanged;

  const VerticalStepSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 40,
      child: SfSlider.vertical(
        min: 0.0,
        max: 10.0,
        value: value,
        stepSize: 1,
        interval: 1,
        minorTicksPerInterval: 0,
        showTicks: true,
        showLabels: true,
        activeColor: Colors.teal,
        inactiveColor: Colors.grey,
        labelPlacement: LabelPlacement.onTicks,
        // Hides labels for non-integer values to keep the UI clean.
        labelFormatterCallback: (dynamic actualValue, String formattedText) {
          if (actualValue % 1 == 0) {
            return actualValue.toInt().toString();
          }
          return '';
        },
        onChanged: onChanged,
      ),
    );
  }
}
