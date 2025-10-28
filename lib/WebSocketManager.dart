import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;


/// A simple WebSocket manager for Flutter using `web_socket_channel`.
///
/// This class allows you to:
/// - Connect to a WebSocket server
/// - Send messages
/// - Listen to incoming messages
/// - Disconnect gracefully
/// - Automatically reconnect on failure
///
/// Example usage:
/// ```dart
/// void main() {
///   final ws = WebSocketManager("....", ...);
///
///   // Connect to the server
///   ws.connect();
///
///   // Listen for incoming messages
///   ws.messages.listen((msg) {
///     print("📩 Received: $msg");
///   });
///
///   // Send a message
///   ws.send("Hello ESP8266!");
///
///   // Disconnect after 10 seconds
///   Future.delayed(Duration(seconds: 10), () {
///     ws.disconnect();
///   });
/// }
/// ```
class WebSocketManager {
  final String ip;
  final int port;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _controller = StreamController<String>.broadcast();

  bool _isConnected = false;

  WebSocketManager(this.ip, this.port);

  String get _url => "ws://$ip:$port";

  /// Connect to WebSocket server
  void connect() {
    if (_isConnected) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));
      _isConnected = true;

      _subscription = _channel!.stream.listen(
            (message) {
          _controller.add(message.toString());
        },
        onDone: () {
          _isConnected = false;
          reconnect();
        },
        onError: (error) {
          _isConnected = false;
          reconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      _isConnected = false;
      reconnect();
    }
  }

  /// Stream of incoming messages
  Stream<String> get messages => _controller.stream;

  /// Send a message
  void send(String message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(message);

    }
  }

  /// Disconnect gracefully
  void disconnect() {
    _isConnected = false;
    _subscription?.cancel();
    _channel?.sink.close(status.goingAway);
  }

  /// Auto-reconnect after delay
  void reconnect({Duration delay = const Duration(seconds: 3)}) {
    if (_isConnected) return;
    Future.delayed(delay, () {
      if (!_isConnected) {
        connect();
      }
    });
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _controller.close();
  }
}
