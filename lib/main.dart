import 'package:flutter/material.dart';
import 'package:rc_controller/control_panel_page.dart';

void main() {
  runApp(const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ControlPanelPage();
  }
}
