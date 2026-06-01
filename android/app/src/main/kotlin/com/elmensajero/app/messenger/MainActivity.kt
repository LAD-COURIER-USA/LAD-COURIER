package com.elmensajero.app.messenger

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.laddigital.smartshopper/screenshot"
    private var methodChannel: MethodChannel? = null
    private var screenshotObserver: ContentObserver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "startScreenshotWatcher") {
                startWatchingScreenshots()
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    // 🚀 BINGO: Si la App ya estaba abierta, detectamos el click en la notificación aquí
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.getBooleanExtra("BINGO_ACTION", false)) {
            Log.i("SISTEMA LAD NATIVO", "🎯 Click en notificación detectado (onNewIntent)")
            methodChannel?.invokeMethod("onScreenshotDetected", null)
        }
    }

    private fun startWatchingScreenshots() {
        if (screenshotObserver != null) return
        
        Log.i("SISTEMA LAD NATIVO", "🛰️ Vigilante Global ACTIVADO")

        screenshotObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                Log.i("SISTEMA LAD NATIVO", "📸 Cambio en galería detectado: $uri")
                
                // 🛡️ REGLA UNIVERSAL: Si hay un cambio en la base de datos de fotos, avisamos.
                // Quitamos el filtro 'images/media' para máxima compatibilidad con Samsung.
                showBingoNotification()
            }
        }
        
        contentResolver.registerContentObserver(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, true, screenshotObserver!!)
    }

    private fun showBingoNotification() {
        val channelId = "LAD_BINGO_CHANNEL"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "LAD SmartShopper", NotificationManager.IMPORTANCE_HIGH)
            channel.description = "Canal para detección de tickets SmartShopper"
            channel.enableVibration(true)
            // 📳 PATRÓN DE VIBRACIÓN LAD: Espera 0ms, Vibra 500ms, Espera 200ms, Vibra 500ms
            channel.vibrationPattern = longArrayOf(0, 500, 200, 500)
            channel.lightColor = 0xFF6200EE.toInt() // Morado LAD
            channel.enableLights(true)
            notificationManager.createNotificationChannel(channel)
        }

        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        intent.putExtra("BINGO_ACTION", true)

        val pendingIntent = PendingIntent.getActivity(this, 1001, intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setContentTitle("🚀 TICKET DETECTADO")
            .setContentText("Haz click para procesar tu ticket.")
            .setAutoCancel(true)
            .setColor(0xFF6200EE.toInt()) // Tinte de color LAD
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVibrate(longArrayOf(0, 500, 200, 500))
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setFullScreenIntent(pendingIntent, true)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify(1001, notification)
    }
}
