import 'dart:async';
import 'package:flutter/material.dart';

/// A simple static logger for displaying debug messages in the app.
/// This is a quick and easy way to have a global logger for a small project.
class DebugLogger {
  static final List<String> _messages = [];
  static final _controller = StreamController<List<String>>.broadcast();

  static Stream<List<String>> get stream => _controller.stream;
  static List<String> get messages => List.unmodifiable(_messages);

  // A separate stream is used for ping to avoid rebuilding the message list
  // every time the ping value is updated.
  static final _pingController = StreamController<int>.broadcast();
  static Stream<int> get pingStream => _pingController.stream;
  static int _ping = 0;
  static int get ping => _ping;

  /// Adds a new message to the console.
  static void log(String message) {
    _messages.add(message);
    _controller.sink.add(List.unmodifiable(_messages));
  }

  /// Updates the ping value.
  static void updatePing(int value) {
    _ping = value;
    _pingController.sink.add(value);
  }

  /// Clears all messages from the console.
  static void clear() {
    _messages.clear();
    _controller.sink.add(List.unmodifiable(_messages));
  }

  /// Closes the stream controllers when the app is disposed.
  static void dispose() {
    _controller.close();
    _pingController.close();
  }
}

/// A widget that displays the debug console.
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

  /// Scrolls the ListView to the bottom after the frame has been rendered.
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

          Expanded(
            child: StreamBuilder<List<String>>(
              stream: DebugLogger.stream,
              initialData: DebugLogger.messages,
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(6),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return Text(
                      messages[index],
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
