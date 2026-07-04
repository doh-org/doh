import 'package:web_socket_channel/web_socket_channel.dart';

class WsClient {
  WsClient._();

  static WebSocketChannel? _channel;

  static WebSocketChannel connect(String tripId, String token) {
    final uri = Uri.parse(
      '$_wsBaseUrl/trips/$tripId/ws?token=$token',
    );
    _channel = WebSocketChannel.connect(uri);
    return _channel!;
  }

  static void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }

  static const _wsBaseUrl = String.fromEnvironment('WS_BASE_URL');
}
