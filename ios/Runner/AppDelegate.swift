import Flutter
import UIKit
import Photos
import UserNotifications

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

    // 🛡️ SOLICITAR PERMISOS DE NOTIFICACIÓN EN iOS
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if granted {
            print("SISTEMA LAD iOS: Permisos de notificación concedidos")
        }
    }
    UNUserNotificationCenter.current().delegate = self

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
    // 🛡️ DETECTOR 1: Detección si la App está activa
    NotificationCenter.default.addObserver(
        forName: UIApplication.userDidTakeScreenshotNotification,
        object: nil,
        queue: .main) { _ in
            print("SISTEMA LAD iOS: Screenshot detectado (Active)")
            self.sendBingoNotification(isManual: true)
    }

    // 🛡️ DETECTOR 2: Observador de Librería (Para capturas en segundo plano/otras apps)
    PHPhotoLibrary.shared().register(self)
  }

  private func sendBingoNotification(isManual: Bool) {
    // 🚀 BINGO: Avisamos a Flutter que detectamos la captura
    methodChannel?.invokeMethod("onScreenshotDetected", arguments: nil)

    // 🍎 NOTIFICACIÓN LOCAL: Si la app no está al frente, mandamos un aviso visual
    let content = UNMutableNotificationContent()
    content.title = "🚀 ¡BINGO! TICKET DETECTADO"
    content.body = "Toca aquí para procesar tu ticket de Burger King o similar."
    content.sound = .default

    let request = UNNotificationRequest(identifier: "LAD_BINGO_IOS", content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)
  }
}

// 🐘 Extensión para vigilar la galería como el elefante
extension AppDelegate: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // iOS detecta que algo cambió en las fotos (posible screenshot)
        DispatchQueue.main.async {
            print("SISTEMA LAD iOS: Cambio en galería detectado")
            self.sendBingoNotification(isManual: false)
        }
    }
}
