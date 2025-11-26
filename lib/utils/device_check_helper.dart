import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DeviceCheckHelper {
  static bool isMobileDevice(BuildContext context) {
    if (kIsWeb) {
      final width = MediaQuery.of(context).size.width;
      return width < 800;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }

  static bool isDesktopDevice(BuildContext context) {
    return !isMobileDevice(context);
  }
}
