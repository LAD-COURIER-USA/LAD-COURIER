package com.elmensajero.app.messenger

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.database.ContentObserver
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.laddigital.smartshopper/screenshot"
    private val WALKIE_CHANNEL = "com.ladcourier.app/walkie_talkie"
    private val AUDIO_EVENT_CHANNEL = "com.ladcourier.app/audio_stream"
    
    private var methodChannel: MethodChannel? = null
    
    // 🛡️ VIGILANTE PERSISTENTE
    private var screenshotObserver: ContentObserver? = null

    // 🎙️ WALKIE-TALKIE ASSETS
    private val sampleRate = 16000
    private var isRecording = false
    private var audioRecord: AudioRecord? = null
    private var audioTrack: AudioTrack? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 📸 CANAL SCREENSHOT
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "startScreenshotWatcher") {
                startWatchingScreenshots()
                result.success(true)
            } else {
                result.notImplemented()
            }
        }

        // 🎙️ CANAL WALKIE-TALKIE (MÉTODOS)
        initAudioTrack()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WALKIE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    isRecording = true
                    result.success(null)
                }
                "stopRecording" -> {
                    isRecording = false
                    audioRecord?.stop()
                    audioRecord?.release()
                    audioRecord = null
                    result.success(null)
                }
                "playChunk" -> {
                    val chunk = call.argument<ByteArray>("data")
                    if (chunk != null) {
                        audioTrack?.write(chunk, 0, chunk.size)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // 🎙️ CANAL WALKIE-TALKIE (STREAM DE AUDIO)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    val bufferSize = AudioRecord.getMinBufferSize(sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
                    audioRecord = AudioRecord(MediaRecorder.AudioSource.MIC, sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, bufferSize)
                    audioRecord?.startRecording()

                    CoroutineScope(Dispatchers.IO).launch {
                        val buffer = ByteArray(bufferSize)
                        while (isRecording) {
                            val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                            if (read > 0 && events != null) {
                                launch(Dispatchers.Main) {
                                    events.success(buffer.copyOf(read))
                                }
                            }
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    isRecording = false
                }
            }
        )
    }

    private fun initAudioTrack() {
        val bufferSize = AudioTrack.getMinBufferSize(sampleRate, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_16BIT)
        audioTrack = AudioTrack.Builder()
            .setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build())
            .setAudioFormat(AudioFormat.Builder()
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setSampleRate(sampleRate)
                .setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
            .setBufferSizeInBytes(bufferSize)
            .setTransferMode(AudioTrack.MODE_STREAM).build()
        audioTrack?.play()
    }

    // 🎯 RECEPTOR DE CLICKS
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
        if (intent.getBooleanExtra("BINGO_ACTION", false)) {
            Log.i("SISTEMA LAD NATIVO", "🎯 BINGO: Click en notificación detectado")
            methodChannel?.invokeMethod("onScreenshotDetected", null)
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        if (Intent.ACTION_SEND == intent.action && intent.type?.startsWith("image/") == true) {
            val imageUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_STREAM)
            }
            
            imageUri?.let { uri ->
                Log.i("SISTEMA LAD NATIVO", "📩 Imagen recibida vía SHARE: $uri")
                val path = saveUriToTempFile(uri)
                path?.let {
                    // Pequeño delay para asegurar que FlutterEngine esté listo
                    Handler(Looper.getMainLooper()).postDelayed({
                        methodChannel?.invokeMethod("onImageShared", it)
                    }, 500)
                }
            }
        }
    }

    private fun saveUriToTempFile(uri: Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri)
            val tempFile = java.io.File(cacheDir, "shared_ticket_${System.currentTimeMillis()}.jpg")
            val outputStream = java.io.FileOutputStream(tempFile)
            inputStream?.use { input ->
                outputStream.use { output ->
                    input.copyTo(output)
                }
            }
            tempFile.absolutePath
        } catch (e: Exception) {
            Log.e("SISTEMA LAD NATIVO", "❌ Error guardando imagen compartida: ${e.message}")
            null
        }
    }

    private fun startWatchingScreenshots() {
        if (screenshotObserver != null) return
        
        Log.i("SISTEMA LAD NATIVO", "🛰️ Vigilante BINGO 360° ACTIVADO - GRADO MILITAR")

        screenshotObserver = object : ContentObserver(Handler(Looper.getMainLooper())) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                super.onChange(selfChange, uri)
                // 🛡️ FILTRO DE DETECCIÓN REFORZADO
                val uriString = uri?.toString()?.lowercase() ?: ""
                if (uriString.contains("screenshots") || uriString.contains("images") || uriString.contains("media")) {
                    Log.i("SISTEMA LAD NATIVO", "📸 Captura Detectada: $uri")
                    showBingoNotification()
                }
            }
        }
        
        // Vigilamos todas las rutas posibles de imágenes (Interna y Externa)
        contentResolver.registerContentObserver(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, true, screenshotObserver!!)
        contentResolver.registerContentObserver(MediaStore.Images.Media.INTERNAL_CONTENT_URI, true, screenshotObserver!!)
    }

    private fun showBingoNotification() {
        val channelId = "LAD_BINGO_CHANNEL"
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Canal de Alta Prioridad
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, "LAD BINGO DETECTOR", NotificationManager.IMPORTANCE_HIGH)
            channel.description = "Detección de misiones BINGO"
            channel.enableVibration(true)
            channel.vibrationPattern = longArrayOf(0, 500, 250, 500)
            notificationManager.createNotificationChannel(channel)
        }

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("BINGO_ACTION", true)
        }

        val pendingIntent = PendingIntent.getActivity(this, 1001, intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setContentTitle("🚀 ¡BINGO! TICKET DETECTADO")
            .setContentText("Toca aquí para generar tu misión de entrega.")
            .setStyle(NotificationCompat.BigTextStyle().bigText("Hemos detectado una captura de Burger King o similar. Haz click para procesarla en el búnker de LAD."))
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setFullScreenIntent(pendingIntent, true) // Salta en pantalla
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify(1001, notification)
    }

    override fun onDestroy() {
        screenshotObserver?.let {
            contentResolver.unregisterContentObserver(it)
        }
        super.onDestroy()
    }
}
