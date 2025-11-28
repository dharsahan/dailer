import 'package:flutter/services.dart';

class CallRepository {
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.flutter_dialer/methods');
  static const EventChannel _eventChannel =
      EventChannel('com.example.flutter_dialer/events');

  Stream<Map<String, dynamic>> get callStateStream {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event));
  }

  Future<void> setDefaultDialer() async {
    try {
      await _methodChannel.invokeMethod('setDefaultDialer');
    } on PlatformException catch (e) {
      // Log error or rethrow specific exception
      throw Exception("Failed to set default dialer: '${e.message}'.");
    }
  }

  Future<void> makeCall(String number) async {
    try {
      await _methodChannel.invokeMethod('makeCall', {'number': number});
    } on PlatformException catch (e) {
      // Log error or rethrow specific exception
      throw Exception("Failed to make call: '${e.message}'.");
    }
  }
}
