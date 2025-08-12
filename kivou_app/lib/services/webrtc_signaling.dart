import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Client de signalisation WebSocket minimaliste pour WebRTC
class WebRtcSignalingClient {
  final Uri serverUri;
  WebSocketChannel? _ch;
  void Function(Map<String, dynamic> msg)? onMessage;
  void Function()? onOpen;
  void Function()? onClose;
  void Function(Object error)? onError;

  WebRtcSignalingClient(String url) : serverUri = Uri.parse(url);

  Future<void> connect() async {
    try {
      _ch = WebSocketChannel.connect(serverUri);
      onOpen?.call();
      _ch!.stream.listen((event) {
        if (event is String) {
          try {
            final m = json.decode(event) as Map<String, dynamic>;
            onMessage?.call(m);
          } catch (_) {}
        }
      }, onError: (e) => onError?.call(e), onDone: () => onClose?.call());
    } catch (e) {
      onError?.call(e);
      rethrow;
    }
  }

  void send(Map<String, dynamic> data) {
    _ch?.sink.add(json.encode(data));
  }

  void join(String room, String userId) {
    send({'type': 'join', 'room': room, 'userId': userId});
  }

  void leave(String room, String userId) {
    send({'type': 'leave', 'room': room, 'userId': userId});
  }

  void close() {
    _ch?.sink.close();
  }
}
