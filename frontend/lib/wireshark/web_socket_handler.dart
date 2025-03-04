import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:nidswebapp/wireshark/packet_data.dart';

class WebSocketHandler {
  late WebSocketChannel _channel;
  final String _webSocketUrl;

  WebSocketHandler(this._webSocketUrl);
  void connect(
    Function(PacketData) onPacketReceived,
    void Function() onDone,
    void Function(dynamic) onError,
  ) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_webSocketUrl));
      _channel.stream.listen(
        (data) {
          final packet = PacketData.fromJson(jsonDecode(data));
          onPacketReceived(packet);
        },
        onDone: onDone,
        onError: onError,
      );
    } catch (e) {
      print("Connection error: $e");
      onError(e);
    }
  }

  void sendCommand(String action, {String? filter, String? interface}) {
    Map<String, dynamic> command = {"action": action};
    if (filter != null) command["filter"] = filter;
    if (interface != null) command["interface"] = interface;
    _channel.sink.add(jsonEncode(command));
  }

  void close() {
    _channel.sink.close(status.goingAway);
  }
}
