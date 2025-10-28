import 'dart:async';
import 'package:flutter/material.dart';

/// Static logger for small projects
class DebugLogger {
  static final List<String> _messages = [];
  static final _controller = StreamController<String>.broadcast();

  static Stream<String> get stream => _controller.stream;
  static List<String> get messages => List.unmodifiable(_messages);



  static final _pingController = StreamController<int>.broadcast();
  static Stream<int> get pingStream => _pingController.stream;
  static int _ping = 0;
  static int get ping => _ping;




  /// Add a new message
  static void log(String message) {
    _messages.add(message);
    _controller.sink.add(message);
  }

  /// Update ping value
  static void updatePing(int value) {
    _ping = value;
    _pingController.sink.add(value);
  }

  /// Clear all messages
  static void clear() {
    _messages.clear();
    _controller.sink.add("");
  }

  /// Dispose the controller when app closes (optional)
  static void dispose() {
    _controller.close();
    _pingController.close();
  }
}

/// Widget to display the debug console
class DebugConsole extends StatefulWidget {
  const DebugConsole({super.key});

  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    DebugLogger.stream.listen((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row: Ping + Clear button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Ping
                StreamBuilder<int>(
                  stream: DebugLogger.pingStream,
                  initialData: DebugLogger.ping,
                  builder: (context, snapshot) {
                    return Text(
                      "Ping: ${snapshot.data} ms",
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                // Clear button
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: DebugLogger.clear,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.cancel_presentation,
                      size: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Messages
          Expanded(
            child: StreamBuilder<String>(
              stream: DebugLogger.stream,
              builder: (context, snapshot) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(6),
                  itemCount: DebugLogger.messages.length,
                  itemBuilder: (context, index) {
                    return Text(
                      DebugLogger.messages[index],
                      style: const TextStyle(
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}
