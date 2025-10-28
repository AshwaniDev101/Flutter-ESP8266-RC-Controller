import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

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
        stepSize: 1,       // 10 steps total (0, 0.5, 1, ..., 5)
        interval: 1,         // Major tick every 1 unit
        minorTicksPerInterval: 0, // 1 small tick between each major tick
        showTicks: true,
        showLabels: true,
        activeColor: Colors.teal,
        inactiveColor: Colors.grey,
        labelPlacement: LabelPlacement.onTicks,
        labelFormatterCallback: (dynamic actualValue, String formattedText) {
          // Show label only on integers
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
