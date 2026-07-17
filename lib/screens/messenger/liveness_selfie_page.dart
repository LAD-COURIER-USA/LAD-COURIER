import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ AÑADIDO PARA defaultTargetPlatform
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:lad_courier/l10n/app_localizations.dart';

class LivenessSelfiePage extends StatefulWidget {
  const LivenessSelfiePage({super.key});

  @override
  State<LivenessSelfiePage> createState() => _LivenessSelfiePageState();
}

class _LivenessSelfiePageState extends State<LivenessSelfiePage> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isBusy = false;
  bool _canCapture = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    if (!kIsWeb) {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true, // Para detectar ojos abiertos/cerrados
          enableTracking: true,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );
    }
  }

  Future<void> _initializeCamera() async {
    // 🛡️ REFUERZO V18.6: Gestión de permisos inteligente
    if (!kIsWeb) {
      final status = await Permission.camera.request();
      if (status.isDenied) {
        if (mounted) Navigator.pop(context);
        return;
      }
    }
    // En Web (iPad/PC), el permiso se pide automáticamente al inicializar el controlador.

    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: kIsWeb ? null : ((defaultTargetPlatform == TargetPlatform.android) ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888),
    );

    try {
      await _cameraController?.initialize();
      if (!mounted) return;

      // 🛡️ REFUERZO V18.2: Evitamos crash en Web
      if (!kIsWeb) {
        _cameraController?.startImageStream(_processCameraImage);
      }
      
      setState(() {});
    } catch (e) {
      debugPrint("Error cámara: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al iniciar cámara: $e")),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController?.stopImageStream();
    }
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  void _processCameraImage(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector?.processImage(inputImage);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      
      if (faces != null && faces.isNotEmpty) {
        final face = faces.first;
        
        bool eyesOpen = (face.leftEyeOpenProbability ?? 0) > 0.4 && 
                         (face.rightEyeOpenProbability ?? 0) > 0.4;
        
        setState(() {
          if (!eyesOpen) {
            _statusMessage = l10n.liveness_eyes_closed;
            _canCapture = false;
          } else {
            _statusMessage = l10n.liveness_face_detected;
            _canCapture = true;
          }
        });
      } else {
        setState(() {
          _canCapture = false;
          _statusMessage = l10n.liveness_searching;
        });
      }
    } catch (e) {
      debugPrint("Error procesando imagen: $e");
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final sensorOrientation = _cameraController!.description.sensorOrientation;
    InputImageRotation? rotation;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // 🛡️ LÓGICA ROBUSTA LAD: Compensación de rotación nativa
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // En Android usamos NV21 y en iOS BGRA8888 por defecto con el plugin camera
    if (format == null) return null;

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _captureSelfie() async {
    // 🛡️ REFUERZO V17.19: En Web permitimos captura manual para auditoría en nube
    if (_cameraController == null || _isBusy) return;
    if (!kIsWeb && !_canCapture) return; // En Android sigue bloqueado si no hay parpadeo

    _isBusy = true; // 🛡️ Bloqueamos para evitar múltiples clics

    try {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController?.stopImageStream();
      }
      
      final XFile photo = await _cameraController!.takePicture();
      if (mounted) {
        Navigator.pop(context, photo.path);
      }
    } catch (e) {
      debugPrint("Error captura: $e");
      _isBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentStatus = _statusMessage ?? l10n.liveness_prompt;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 📹 PREVIEW DE CÁMARA
          if (_cameraController != null && _cameraController!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: 1 / _cameraController!.value.aspectRatio,
                child: CameraPreview(_cameraController!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // 🛡️ CAPA DE UI LAD (MÁSCARA DE PROTECCIÓN)
          _buildOverlayMask(),

          // 🚩 MENSAJE DE ESTADO
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: (kIsWeb || _canCapture) ? Colors.green.withValues(alpha: 0.8) : Colors.black54,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: (kIsWeb || _canCapture) ? Colors.green : Colors.white24, width: 2),
              ),
              child: Text(
                kIsWeb ? "MODO iPAD: CAPTURA TU SELFIE PARA AUDITORÍA EN LA NUBE" : currentStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),

          // 🔘 BOTÓN DE CAPTURA (DISPARADOR INTELIGENTE)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                // 🛡️ REFUERZO V17.18: En Web permitimos el clic para enviar al servidor. 
                // En Android, sigue bloqueado hasta que parpadees.
                onTap: (kIsWeb || _canCapture) ? _captureSelfie : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white, // El interior siempre blanco para que resalte el icono
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (kIsWeb || _canCapture) ? Colors.greenAccent : Colors.grey, 
                      width: 6
                    ),
                    boxShadow: [
                      if (kIsWeb || _canCapture) BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.5), blurRadius: 20)
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt, 
                    color: (kIsWeb || _canCapture) ? Colors.black : Colors.white30,
                    size: 35
                  ),
                ),
              ),
            ),
          ),

          // ❌ BOTÓN CERRAR
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayMask() {
    return IgnorePointer(
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: 0.7),
          BlendMode.srcOut,
        ),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                backgroundBlendMode: BlendMode.dstOut,
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.only(bottom: 100),
                height: 300,
                width: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(150),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
