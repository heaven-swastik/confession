import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class SecurityService {
  static const platform = MethodChannel('com.confession.app/security');

  Future<bool> enableSecureMode() async {
    try {
      final result = await platform.invokeMethod('enableSecureMode');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to enable secure mode: ${e.message}');
      return false;
    }
  }

  Future<bool> disableSecureMode() async {
    try {
      final result = await platform.invokeMethod('disableSecureMode');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to disable secure mode: ${e.message}');
      return false;
    }
  }
}
