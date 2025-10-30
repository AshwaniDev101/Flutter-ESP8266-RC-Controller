import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rc_controller/widgets/remote_button.dart';
import 'package:rc_controller/widgets/vertical_slider.dart';
import 'control_panel_viewmodel.dart';
import 'debug_console.dart';
import 'enums/directions.dart';

class ControlPanelPage extends StatelessWidget {
  const ControlPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ControlPanelViewModel(),
      child: MaterialApp(
        title: 'Flutter Controller',
        home: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.teal,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: const ControllerScreen(),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class ControllerScreen extends StatelessWidget {
  const ControllerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The Consumer widget will listen for changes in the ViewModel
    // and automatically rebuild the UI.
    return Consumer<ControlPanelViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_outline_rounded, color: Colors.deepOrange),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: viewModel.isLockSpeeds,
                          activeColor: Colors.white,
                          activeTrackColor: Colors.teal[300],
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey,
                          onChanged: viewModel.setLockSpeeds,
                        ),
                      ),
                      const Icon(Icons.local_fire_department_sharp, color: Colors.amber),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: viewModel.isHotMode,
                          activeColor: Colors.white,
                          activeTrackColor: Colors.teal[300],
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey,
                          onChanged: viewModel.setHotMode,
                        ),
                      ),
                      const Spacer(),
                      connectingLabel(viewModel.connectionStatus),
                      const SizedBox(width: 8),
                      connectingButton(viewModel.connectionStatus, viewModel.connect, viewModel.disconnect),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Slider
                      Column(
                        children: [
                          getLabel(viewModel.leftSliderValue, viewModel.mapSliderToPWM),
                          SizedBox(
                            height: 200,
                            child: VerticalStepSlider(
                              value: viewModel.leftSliderValue,
                              onChanged: (value) => viewModel.onLeftSliderChanged(value as double),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Left Buttons
                      Column(
                        children: [
                          RemoteButton(
                            direction: Directions.UP,
                            enabled: !viewModel.isHotMode,
                            onPressed: (_) => viewModel.setButtonState('BLF', true),
                            onReleased: (_) => viewModel.setButtonState('BLF', false),
                          ),
                          const SizedBox(height: 20),
                          RemoteButton(
                            direction: Directions.DOWN,
                            enabled: !viewModel.isHotMode,
                            onPressed: (_) => viewModel.setButtonState('BLB', true),
                            onReleased: (_) => viewModel.setButtonState('BLB', false),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: SizedBox(
                          height: 200,
                          child: DebugConsole(),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Right Buttons
                      Column(
                        children: [
                          RemoteButton(
                            direction: Directions.UP,
                            enabled: !viewModel.isHotMode,
                            onPressed: (_) => viewModel.setButtonState('BRF', true),
                            onReleased: (_) => viewModel.setButtonState('BRF', false),
                          ),
                          const SizedBox(height: 20),
                          RemoteButton(
                            direction: Directions.DOWN,
                            enabled: !viewModel.isHotMode,
                            onPressed: (_) => viewModel.setButtonState('BRB', true),
                            onReleased: (_) => viewModel.setButtonState('BRB', false),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Right Slider
                      Column(
                        children: [
                          getLabel(viewModel.rightSliderValue, viewModel.mapSliderToPWM),
                          SizedBox(
                            height: 200,
                            child: VerticalStepSlider(
                              value: viewModel.rightSliderValue,
                              onChanged: (value) => viewModel.onRightSliderChanged(value as double),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget getLabel(double sliderValue, int Function(double) mapSliderToPWM) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    width: 60,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey, width: 1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Center(
      child: Text(
        mapSliderToPWM(sliderValue).toString(),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );

  Widget connectingButton(ConnectionStatus connectionStatus, VoidCallback connect, VoidCallback disconnect) {
    switch (connectionStatus) {
      case ConnectionStatus.CONNECTED:
        return getButton("Disconnect", Colors.redAccent, disconnect);
      case ConnectionStatus.DISCONNECTED:
        return getButton("Connect", Colors.teal, connect);
      case ConnectionStatus.CONNECTING:
        return getButton("Connecting...", Colors.grey, null);
    }
  }

  Widget getButton(String text, Color btnColor, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: btnColor,
        minimumSize: const Size(120, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget connectingLabel(ConnectionStatus connectionStatus) {
    switch (connectionStatus) {
      case ConnectionStatus.CONNECTED:
        return getLabelText("🟢 Connected", Colors.green);
      case ConnectionStatus.DISCONNECTED:
        return getLabelText("🔴 Disconnected", Colors.red);
      case ConnectionStatus.CONNECTING:
        return getLabelText("🔄 Connecting...", Colors.grey);
    }
  }

  Widget getLabelText(String text, Color color) =>
      Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold));
}
