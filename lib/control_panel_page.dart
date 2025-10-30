import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rc_controller/widgets/remote_button.dart';
import 'package:rc_controller/widgets/vertical_slider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'config/config.dart';
import 'debug_console.dart';
import 'enums/directions.dart';

class ControlPanelPage extends StatelessWidget {
  const ControlPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}

enum ConnectionStatus { CONNECTED, DISCONNETED, CONNECTING }

class ControllerScreen extends StatefulWidget {
  const ControllerScreen({super.key});

  @override
  State<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends State<ControllerScreen> {
  final DebugConsole debugConsole = DebugConsole();
  double leftSliderValue = 0;
  double rightSliderValue = 0;
  bool isLockSpeeds = false;
  bool isHotMode = false;

  ConnectionStatus _connectionStatus = ConnectionStatus.DISCONNETED;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;

  final String ip =  Config.ip;
  final int port = Config.port;
  String get _url => "ws://$ip:$port";

  bool btnLeftForwardPressed = false,
      btnLeftBackwardPressed = false,
      btnRightForwardPressed = false,
      btnRightBackwardPressed = false;

  void connect() {
    if (_connectionStatus == ConnectionStatus.CONNECTED) return;
    DebugLogger.log('Connecting to $_url...');
    setState(() => _connectionStatus = ConnectionStatus.CONNECTING);

    _channel = WebSocketChannel.connect(Uri.parse(_url));
    _subscription = _channel!.stream.listen(
          (message) {
        if (_connectionStatus != ConnectionStatus.CONNECTED) {
          DebugLogger.log('Connection established.');
          setState(() => _connectionStatus = ConnectionStatus.CONNECTED);
          // Start a periodic ping to measure round-trip latency.
          _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) => _sendPingRequest());
        }
        
        try {
          final data = jsonDecode(message);
          // Handle pong responses separately to calculate latency.
          if (data is Map<String, dynamic> && data.containsKey('pong_timestamp')) {
            final timestamp = data['pong_timestamp'];
            if (timestamp is int) {
              final latency = DateTime.now().millisecondsSinceEpoch - timestamp;
              DebugLogger.updatePing(latency);
            }
          } else {
            DebugLogger.log('RX: $message');
          }
        } catch (e) {
          // If it's not valid JSON, just log the raw message.
          DebugLogger.log('RX: $message');
        }
      },
      onDone: () {
        DebugLogger.log('Connection closed.');
        setState(() => _connectionStatus = ConnectionStatus.DISCONNETED);
      },
      onError: (error) {
        DebugLogger.log('Error: $error');
        setState(() => _connectionStatus = ConnectionStatus.DISCONNETED);
      },
      cancelOnError: true,
    );
  }

  void _sendPingRequest() {
    final payload = {'ping_timestamp': DateTime.now().millisecondsSinceEpoch};
    final jsonPayload = jsonEncode(payload);
    _channel?.sink.add(jsonPayload);
  }

  void sendMotorCommand() {
    final command = {
      "BLF": btnLeftForwardPressed,
      "BLB": btnLeftBackwardPressed,
      "BRF": btnRightForwardPressed,
      "BRB": btnRightBackwardPressed,
      "LS": mapSliderToPWM(leftSliderValue),
      "RS": mapSliderToPWM(rightSliderValue),
    };
    final jsonCommand = jsonEncode(command);
    _channel?.sink.add(jsonCommand);
    DebugLogger.log('TX: $jsonCommand');
  }

  void disconnect() {
    DebugLogger.log('Disconnecting...');
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    setState(() => _connectionStatus = ConnectionStatus.DISCONNETED);
  }

  /// Maps a slider value from 0-10 to a PWM signal from 0-255.
  int mapSliderToPWM(double sliderValue) => (sliderValue * (255 / 10)).round();

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      value: isLockSpeeds,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.teal[300],
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey,
                      onChanged: (value) {
                        setState(() {
                          isLockSpeeds = value;
                          if (isLockSpeeds) rightSliderValue = leftSliderValue;
                        });
                      },
                    ),
                  ),
                  const Icon(Icons.local_fire_department_sharp, color: Colors.amber),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: isHotMode,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.teal[300],
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey,
                      onChanged: (value) => setState(() => isHotMode = value),
                    ),
                  ),
                  const Spacer(),
                  connectingLabel(),
                  const SizedBox(width: 8),
                  connectingButton(),
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
                      getLabel(leftSliderValue),
                      SizedBox(
                        height: 200,
                        child: VerticalStepSlider(
                          value: leftSliderValue,
                          onChanged: (v) {
                            setState(() {
                              leftSliderValue = v;
                              if (isLockSpeeds) rightSliderValue = v;
                            });
                          },
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
                        enabled: !isHotMode,
                        onPressed: (_) {
                          btnLeftForwardPressed = true;
                          sendMotorCommand();
                        },
                        onReleased: (_) {
                          btnLeftForwardPressed = false;
                          sendMotorCommand();
                        },
                      ),
                      const SizedBox(height: 20),
                      RemoteButton(
                        direction: Directions.DOWN,
                        enabled: !isHotMode,
                        onPressed: (_) {
                          btnLeftBackwardPressed = true;
                          sendMotorCommand();
                        },
                        onReleased: (_) {
                          btnLeftBackwardPressed = false;
                          sendMotorCommand();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SizedBox(
                      height: 200,
                      child: debugConsole,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Right Buttons
                  Column(
                    children: [
                      RemoteButton(
                        direction: Directions.UP,
                        enabled: !isHotMode,
                        onPressed: (_) {
                          btnRightForwardPressed = true;
                          sendMotorCommand();
                        },
                        onReleased: (_) {
                          btnRightForwardPressed = false;
                          sendMotorCommand();
                        },
                      ),
                      const SizedBox(height: 20),
                      RemoteButton(
                        direction: Directions.DOWN,
                        enabled: !isHotMode,
                        onPressed: (_) {
                          btnRightBackwardPressed = true;
                          sendMotorCommand();
                        },
                        onReleased: (_) {
                          btnRightBackwardPressed = false;
                          sendMotorCommand();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Right Slider
                  Column(
                    children: [
                      getLabel(rightSliderValue),
                      SizedBox(
                        height: 200,
                        child: VerticalStepSlider(
                          value: rightSliderValue,
                          onChanged: (v) {
                            setState(() {
                              rightSliderValue = v;
                              if (isLockSpeeds) leftSliderValue = v;
                            });
                          },
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
  }

  Widget getLabel(double sliderValue) => Container(
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

  Widget connectingButton() {
    switch (_connectionStatus) {
      case ConnectionStatus.CONNECTED:
        return getButton("Disconnect", Colors.redAccent, disconnect);
      case ConnectionStatus.DISCONNETED:
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

  Widget connectingLabel() {
    switch (_connectionStatus) {
      case ConnectionStatus.CONNECTED:
        return getLabelText("🟢 Connected", Colors.green);
      case ConnectionStatus.DISCONNETED:
        return getLabelText("🔴 Disconnected", Colors.red);
      case ConnectionStatus.CONNECTING:
        return getLabelText("🔄 Connecting...", Colors.grey);
    }
  }

  Widget getLabelText(String text, Color color) =>
      Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold));
}
