import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import '../services/walkie_talkie_service.dart';

class WalkieTalkieButton extends StatefulWidget {
  final String channelId;
  final String userId;

  const WalkieTalkieButton({
    super.key,
    required this.channelId,
    required this.userId,
  });

  @override
  State<WalkieTalkieButton> createState() => _WalkieTalkieButtonState();
}

class _WalkieTalkieButtonState extends State<WalkieTalkieButton> {
  final WalkieTalkieService _walkieService = WalkieTalkieService();
  bool _isTalking = false;

  @override
  void initState() {
    super.initState();
    // 🛡️ CONEXIÓN AL BÚNKER DE AUDIO
    // Nota: Sustituir por la URL de tu servidor WebSocket de producción (ej: Railway o Render)
    _walkieService.connect("wss://lad-audio-relay.onrender.com/walkie?orderId=${widget.channelId}&userId=${widget.userId}");
  }

  @override
  void dispose() {
    _walkieService.disconnect();
    super.dispose();
  }

  Future<void> _handleTalkStart() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      Vibrate.feedback(FeedbackType.selection);
      setState(() => _isTalking = true);
      await _walkieService.startTalking();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎙️ LAD: Se requiere micrófono para comunicación segura.")),
        );
      }
    }
  }

  Future<void> _handleTalkStop() async {
    if (!_isTalking) return;
    Vibrate.feedback(FeedbackType.light);
    setState(() => _isTalking = false);
    await _walkieService.stopTalking();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _handleTalkStart(),
      onLongPressEnd: (_) => _handleTalkStop(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: _isTalking ? Colors.red : Colors.green[700],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isTalking ? Colors.red : Colors.green).withOpacity(0.4),
              blurRadius: _isTalking ? 20 : 8,
              spreadRadius: _isTalking ? 5 : 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isTalking ? Icons.mic : Icons.radio,
              color: Colors.white,
              size: 28,
            ),
            const Text(
              "PTT",
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
