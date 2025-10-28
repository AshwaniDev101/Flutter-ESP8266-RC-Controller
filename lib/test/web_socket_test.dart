import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

import '../config/config.dart';


class WebSocketTest extends StatefulWidget {
  const WebSocketTest({super.key});
  @override
  State<WebSocketTest> createState() => _WebSocketTestState();
}

class _WebSocketTestState extends State<WebSocketTest> {
  final TextEditingController _controller = TextEditingController();

  // Create a WebSocket channel. Ensure the IP and port match your ESP8266.

  // This is the IP of the esp8266
  final String ip = Config.ip;
  final int port = Config.port;

  late final Stopwatch _stopwatch;
  late final WebSocketChannel _channel;

  String latency = "no data is sent..";

  @override
  void initState() {
    super.initState();

    _channel = IOWebSocketChannel.connect('ws://$ip:$port');
    _stopwatch = Stopwatch();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP8266 WebSocket',
      home: Scaffold(
        appBar: AppBar(title: Text('ESP8266 WebSocket ($ip:$port)'), ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[

              StreamBuilder(
                stream: _channel.stream,
                builder: (context, snapshot) {
                  String statusText = "Status: Connecting... ⏳";
                  Color statusColor = Colors.orange;

                  if (snapshot.connectionState == ConnectionState.active) {
                    statusText = "Status: CONNECTED! 🟢";
                    statusColor = Colors.green;
                  } else if (snapshot.connectionState == ConnectionState.done) {
                    statusText = "Status: Connection Closed. 🔴";
                    statusColor = Colors.red;
                  }

                  // 👇 Check if we actually received data (like "Welcome" or "PONG")
                  String messageText = "";
                  if (snapshot.hasData) {

                    _stopwatch.stop();
                    final elapsed = _stopwatch.elapsedMilliseconds;

                    // Schedule UI update AFTER the build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          latency = "Latency: $elapsed ms";
                        });
                      }
                    });

                    messageText = "Message: ${snapshot.data}";
                    debugPrint("📩 From ESP: ${snapshot.data}");

                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(messageText, style: const TextStyle(color: Colors.blue)),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),
              Form(
                child: TextFormField(
                  controller: _controller,
                  decoration: const InputDecoration(labelText: 'Send a message to ESP8266'),
                ),
              ),

              Text(latency),



            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _sendMessage,
          tooltip: 'Send message',
          child: const Icon(Icons.send),
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      _channel.sink.add(_controller.text);

      _stopwatch.reset();
      _stopwatch.start();

      _controller.clear();
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }
}