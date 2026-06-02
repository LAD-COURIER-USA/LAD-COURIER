import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(name: "com.laddigital.smartshopper/screenshot",
                                              binaryMessenger: controller.binaryMessenger)

    methodChannel?.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "startScreenshotWatcher" {
        self.startWatchingScreenshots()
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func startWatchingScreenshots() {
    // 🛡️ DETECTOR 1: Detección inmediata si la App está activa
    NotificationCenter.default.addObserver(
        forName: UIApplication.userDidTakeScreenshotNotification,
        object: nil,
        queue: .main) { _ in
            print("SISTEMA LAD iOS: Screenshot detectado (Active)")
            self.sendBingoNotification()
    }

    // 🛡️ DETECTOR 2: Observador de Librería (Para capturas en segundo plano)
    PHPhotoLibrary.shared().register(self)
  }

  private func sendBingoNotification() {
    // 🚀 BINGO: Avisamos a Flutter que detectamos la captura
    methodChannel?.invokeMethod("onScreenshotDetected", arguments: nil)

    // Aquí es donde se puede integrar UNUserNotificationCenter para mandar
    // la notificación visual si la App está en segundo plano.
  }
}

// 🐘 Extensión para vigilar la galería como el elefante
extension AppDelegate: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // iOS detecta que algo cambió en las fotos (posible screenshot)
        DispatchQueue.main.async {
            print("SISTEMA LAD iOS: Cambio en galería detectado")
            self.sendBingoNotification()
        }
    }
}
