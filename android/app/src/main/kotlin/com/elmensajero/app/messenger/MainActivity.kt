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

    private fun startWatchingScreenshots() {
        if (screenshotObserver != null) {
            Log.i("SISTEMA LAD NATIVO", "⚠️ El vigilante ya estaba activo.")
            return
        }
        
        Log.i("SISTEMA LAD NATIVO", "🛰️ Iniciando registro del vigilante de Screenshots...")

        screenshotObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                Log.i("SISTEMA LAD NATIVO", "📸 Cambio detectado en galería: $uri")
                
                // Filtramos para que solo reaccione a imágenes nuevas
                if (uri.toString().contains("images/media")) {
                    Log.i("SISTEMA LAD NATIVO", "🎯 Screenshot confirmado. Enviando notificación...")
                    showBingoNotification()
                }
            }
        }
        
        // Vigilamos tanto memoria interna como externa para no fallar
        contentResolver.registerContentObserver(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, true, screenshotObserver!!)
        contentResolver.registerContentObserver(MediaStore.Images.Media.INTERNAL_CONTENT_URI, true, screenshotObserver!!)
        
        Log.i("SISTEMA LAD NATIVO", "✅ Vigilante registrado exitosamente en INTERNAL y EXTERNAL URIs")
    }

    private fun showBingoNotification() {
        val channelId = "LAD_BINGO_CHANNEL"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "LAD SmartShopper", NotificationManager.IMPORTANCE_HIGH)
            channel.description = "Canal para detección de tickets SmartShopper"
            channel.enableVibration(true)
            notificationManager.createNotificationChannel(channel)
        }

        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        intent.putExtra("BINGO_ACTION", true)

        val pendingIntent = PendingIntent.getActivity(this, 1001, intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setContentTitle("¡BINGO! TICKET DETECTADO")
            .setContentText("Toca aquí para procesar tu orden automáticamente con LAD.")
            .setAutoCancel(true)
            .setOngoing(false)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setContentIntent(pendingIntent)
            .build()

        Log.i("SISTEMA LAD NATIVO", "🔔 Disparando notificación 1001...")
        notificationManager.notify(1001, notification)
    }
}
