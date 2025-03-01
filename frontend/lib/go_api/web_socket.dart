import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

class WebSocketService {
  final WebSocketChannel _channel;
  final StreamController _streamController = StreamController.broadcast();

WebSocketService(String url)
    : _channel = WebSocketChannel.connect(Uri.parse(url)) {
  _channel.stream.listen(
    (data) {
      print('Received data: $data'); // Log received data
      _streamController.add(data);
    },
    onError: (error) {
      print('WebSocket error: $error'); // Log errors
      _streamController.addError(error);
    },
    onDone: () {
      print('WebSocket connection closed.'); // Log connection closure
      _streamController.close();
    },
  );

  }

  Stream get stream => _streamController.stream;

  void sendMessage(String message) {
    if (_channel.closeCode == null) {
      _channel.sink.add(message);
    } else {
      print('Cannot send message: WebSocket is closed.');
    }
  }

  void dispose() {
    _channel.sink.close();
    _streamController.close();
  }

  bool isConnected() {
    return _channel.closeCode == null;
  }
}
