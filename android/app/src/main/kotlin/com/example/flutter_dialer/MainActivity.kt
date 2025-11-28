package com.example.flutter_dialer

import android.content.Context
import android.content.Intent
import android.telecom.TelecomManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.net.Uri

class MainActivity: FlutterActivity() {
    private val METHOD_CHANNEL = "com.example.flutter_dialer/methods"
    private val EVENT_CHANNEL = "com.example.flutter_dialer/events"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setDefaultDialer" -> {
                    val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
                    intent.putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName)
                    startActivity(intent)
                    result.success(null)
                }
                "makeCall" -> {
                    val number = call.argument<String>("number")
                    if (number != null) {
                        placeCall(number)
                        result.success(null)
                    } else {
                        result.error("INVALID_NUMBER", "Number cannot be null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Setup Event Channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    CallService.callListener = { call, state ->
                         // Map the internal state to a simple map/string for Flutter
                         val stateMap = mapOf(
                             "state" to state,
                             "number" to (call.details.handle?.schemeSpecificPart ?: "Unknown")
                         )
                         events?.success(stateMap)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    CallService.callListener = null
                }
            }
        )
    }

    private fun placeCall(number: String) {
        val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        val uri = Uri.fromParts("tel", number, null)
        val extras = android.os.Bundle()
        extras.putBoolean(TelecomManager.EXTRA_START_CALL_WITH_SPEAKERPHONE, false)
        try {
             // requires permission CALL_PHONE or MANAGE_OWN_CALLS depending on context,
             // but strictly speaking, placing a call via TelecomManager might need check
             if (checkSelfPermission(android.Manifest.permission.CALL_PHONE) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                 telecomManager.placeCall(uri, extras)
             }
        } catch (e: SecurityException) {
            e.printStackTrace()
        }
    }
}
