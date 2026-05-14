import 'dart:io';
import 'dart:typed_data'; // 🎯 INDISPENSABLE: Para manejar los bytes de la captura automática
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// 🎯 NUEVO MÉTODO QUIRÚRGICO: Sube la captura directa del WebView (Bytes) a Firebase
  /// Se eliminó el BuildContext para evitar advertencias de seguridad (Async Gaps)
  Future<String?> uploadProductPhotoFromBytes(
      String fileName,
      Uint8List bytes,
      ) async {
    try {
      final String filePath = 'order_photos/$fileName.png';
      final Reference storageRef = _storage.ref().child(filePath);

      // Subida directa de datos binarios
      final UploadTask uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/png')
      );

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error al subir captura de bytes: $e");
      return null;
    }
  }

  /// Método genérico para subir imágenes con selección de origen (Cámara/Galería)
  /// Se mantiene intacto para no romper otras funciones de la App
  Future<String?> _uploadImage(String folder, String fileName, BuildContext context, {String? customTitle, String? customSubtitle, Function(String)? onLocalPathPicked}) async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
              customTitle ?? "ORIGEN DE LA FOTO",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)
          ),
          content: Text(
              customSubtitle ?? "¿Cómo deseas capturar la imagen?",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: const Text("CÁMARA", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.deepPurple))
            ),
            TextButton(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: const Text("GALERÍA", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black))
            ),
          ],
        ),
      );

      if (source == null) return null;

      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 40, // 📉 Reducimos un poco más para ahorrar RAM en el S24
        maxWidth: 720,    // 📉 Tamaño óptimo para IA sin saturar el buffer
      );

      if (image == null) return null;

      // SI HAY UN CALLBACK, PASAMOS LA RUTA LOCAL PARA OCR
      if (onLocalPathPicked != null) {
        onLocalPathPicked(image.path);
      }

      final File imageFile = File(image.path);
      final String filePath = '$folder/$fileName.jpg';

      final Reference storageRef = _storage.ref().child(filePath);

      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();

    } catch (e) {
      debugPrint("Error al subir imagen: $e");
      return null;
    }
  }

  /// Sube una foto de perfil (Sin cambios)
  Future<String?> uploadProfilePicture(String uid, BuildContext context) async {
    return _uploadImage('profile_pics', uid, context);
  }

  /// Sube una foto de producto/orden (Añadido soporte para callback de OCR)
  Future<String?> uploadProductPhoto(String orderId, BuildContext context, {String? customTitle, String? customSubtitle, Function(String)? onLocalPathPicked}) async {
    return _uploadImage('order_photos', orderId, context, customTitle: customTitle, customSubtitle: customSubtitle, onLocalPathPicked: onLocalPathPicked);
  }

  /// Elimina archivos de Storage (Sin cambios)
  Future<void> deleteFile(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      debugPrint("SISTEMA LAD: Archivo efímero eliminado de Storage.");
    } catch (e) {
      debugPrint("Error eliminando archivo: $e");
    }
  }
}