import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'dart:typed_data';

class WalkieTalkieService {
  static const _methodChannel = MethodChannel('com.ladcourier.app/walkie_talkie');
  static const _eventChannel = EventChannel('com.ladcourier.app/audio_stream');

  WebSocketChannel? _channel;
  StreamSubscription? _audioStreamSubscription;
  StreamSubscription? _wsSubscription;

  // 🛰️ Conectar al búnker de audio (WebSocket)
  void connect(String url) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      // 🔊 Escuchar mensajes del servidor (Bytes de audio del otro usuario)
      _wsSubscription = _channel!.stream.listen((data) {
        if (data is Uint8List) {
          _playReceivedAudio(data);
        }
      }, onError: (error) {
        print("❌ Error en WalkieTalkie WS: $error");
      }, onDone: () {
        print("🔌 WalkieTalkie WS desconectado");
      });
    } catch (e) {
      print("❌ Fallo al conectar WalkieTalkie: $e");
    }
  }

  // 🎙️ Iniciar grabación y envío (Push-to-Talk)
  Future<void> startTalking() async {
    try {
      await _methodChannel.invokeMethod('startRecording');
      
      // 📡 Escuchar bytes del micrófono nativo y enviarlos al WebSocket
      _audioStreamSubscription = _eventChannel.receiveBroadcastStream().listen((data) {
        if (data is Uint8List && _channel != null) {
          _channel!.sink.add(data);
        }
      });
    } catch (e) {
      print("❌ Error al iniciar habla: $e");
    }
  }

  // 🛑 Detener grabación
  Future<void> stopTalking() async {
    try {
      await _methodChannel.invokeMethod('stopRecording');
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;
    } catch (e) {
      print("❌ Error al detener habla: $e");
    }
  }

  // 🔈 Reproducir bytes en el altavoz nativo
  Future<void> _playReceivedAudio(Uint8List chunk) async {
    try {
      await _methodChannel.invokeMethod('playChunk', {'data': chunk});
    } catch (e) {
      print("❌ Error al reproducir audio: $e");
    }
  }

  void disconnect() {
    _wsSubscription?.cancel();
    _audioStreamSubscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
