import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rc_controller/control_panel_page.dart';

void main() async {
  // It's important to ensure that the Flutter binding is initialized before
  // setting the preferred orientation.
  WidgetsFlutterBinding.ensureInitialized();

  // This line locks the app to landscape mode.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

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
