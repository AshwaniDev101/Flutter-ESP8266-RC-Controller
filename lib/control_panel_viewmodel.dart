import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'config/config.dart';
import 'debug_console.dart';

// This enum is now defined here to be used by the ViewModel and the View.
enum ConnectionStatus { CONNECTED, DISCONNECTED, CONNECTING }

class ControlPanelViewModel extends ChangeNotifier {
  // --- State Variables ---
  double _leftSliderValue = 0;
  double _rightSliderValue = 0;
  bool _isLockSpeeds = false;
  bool _isHotMode = false;
  ConnectionStatus _connectionStatus = ConnectionStatus.DISCONNECTED;
  bool _isEditingIp = false;
  String _ip = Config.ip;
  final int _port = Config.port;

  // --- Controllers ---
  late TextEditingController ipAddressController;

  // --- WebSocket & Timers ---
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;

  // --- Button States ---
  bool _btnLeftForwardPressed = false;
  bool _btnLeftBackwardPressed = false;
  bool _btnRightForwardPressed = false;
  bool _btnRightBackwardPressed = false;

  // --- Public Getters ---
  double get leftSliderValue => _leftSliderValue;
  double get rightSliderValue => _rightSliderValue;
  bool get isLockSpeeds => _isLockSpeeds;
  bool get isHotMode => _isHotMode;
  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isEditingIp => _isEditingIp;
  String get _url => "ws://$_ip:$_port";

  ControlPanelViewModel() {
    ipAddressController = TextEditingController(text: _ip);
  }

  // --- UI Actions ---

  void setLockSpeeds(bool value) {
    _isLockSpeeds = value;
    if (_isLockSpeeds) {
      _rightSliderValue = _leftSliderValue;
    }
    notifyListeners();
  }

  void setHotMode(bool value) {
    _isHotMode = value;
    notifyListeners();
  }

  void onLeftSliderChanged(double value) {
    _leftSliderValue = value;
    if (_isLockSpeeds) {
      _rightSliderValue = value;
    }
    notifyListeners();
  }

  void onRightSliderChanged(double value) {
    _rightSliderValue = value;
    if (_isLockSpeeds) {
      _leftSliderValue = value;
    }
    notifyListeners();
  }

  void setButtonState(String button, bool isPressed) {
    switch (button) {
      case 'BLF': _btnLeftForwardPressed = isPressed; break;
      case 'BLB': _btnLeftBackwardPressed = isPressed; break;
      case 'BRF': _btnRightForwardPressed = isPressed; break;
      case 'BRB': _btnRightBackwardPressed = isPressed; break;
    }
    sendMotorCommand();
  }

  void toggleIpEditMode() {
    if (_isEditingIp) {
      // If we were editing, now we are saving.
      _ip = ipAddressController.text;
      DebugLogger.log('IP Address updated to: $_ip');
    }
    _isEditingIp = !_isEditingIp;
    notifyListeners();
  }

  // --- WebSocket Logic ---

  void connect() {
    if (_connectionStatus == ConnectionStatus.CONNECTED) return;
    DebugLogger.log('Connecting to $_url...');
    _connectionStatus = ConnectionStatus.CONNECTING;
    notifyListeners();

    _channel = WebSocketChannel.connect(Uri.parse(_url));
    _subscription = _channel!.stream.listen(
      (message) {
        if (_connectionStatus != ConnectionStatus.CONNECTED) {
          DebugLogger.log('Connection established.');
          _connectionStatus = ConnectionStatus.CONNECTED;
          _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) => _sendPingRequest());
          notifyListeners();
        }

        try {
          final data = jsonDecode(message);
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
          DebugLogger.log('RX: $message');
        }
      },
      onDone: () {
        DebugLogger.log('Connection closed.');
        _connectionStatus = ConnectionStatus.DISCONNECTED;
        _pingTimer?.cancel();
        notifyListeners();
      },
      onError: (error) {
        DebugLogger.log('Error: $error');
        _connectionStatus = ConnectionStatus.DISCONNECTED;
        _pingTimer?.cancel();
        notifyListeners();
      },
      cancelOnError: true,
    );
  }

  void _sendPingRequest() {
    if (_channel == null) return;
    final payload = {'ping_timestamp': DateTime.now().millisecondsSinceEpoch};
    final jsonPayload = jsonEncode(payload);
    _channel!.sink.add(jsonPayload);
  }

  void sendMotorCommand() {
    if (_channel == null) return;
    final command = {
      "BLF": _btnLeftForwardPressed,
      "BLB": _btnLeftBackwardPressed,
      "BRF": _btnRightForwardPressed,
      "BRB": _btnRightBackwardPressed,
      "LS": mapSliderToPWM(_leftSliderValue),
      "RS": mapSliderToPWM(_rightSliderValue),
    };
    final jsonCommand = jsonEncode(command);
    _channel!.sink.add(jsonCommand);
    DebugLogger.log('TX: $jsonCommand');
  }

  void disconnect() {
    if (_connectionStatus == ConnectionStatus.DISCONNECTED) return;
    DebugLogger.log('Disconnecting...');
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _connectionStatus = ConnectionStatus.DISCONNECTED;
    notifyListeners();
  }

  int mapSliderToPWM(double sliderValue) => (sliderValue * (255 / 10)).round();

  @override
  void dispose() {
    disconnect();
    ipAddressController.dispose();
    super.dispose();
  }
}
