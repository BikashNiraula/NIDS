
import 'package:nidswebapp/go_api/urls.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  late WebSocketChannel channel;

  // Private constructor
  AlertService._internal() {
    try {
      // IMPORTANT: Update this with your actual WebSocket URL
      channel =
          WebSocketChannel.connect(Uri.parse(alertURL));
      print("🔥 WebSocket Connected Successfully");
    } catch (e) {
      print("❌ WebSocket Connection Failed: $e");
    }
  }

  // Factory constructor to return the singleton instance
  factory AlertService() {
    return _instance;
  }

  // Expose the stream
  Stream get alertStream => channel.stream;

  // Close the connection
  void close() {
    channel.sink.close();
  }
}
