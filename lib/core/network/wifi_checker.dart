import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class WifiChecker {
  /// Check if WiFi is available (specifically WiFi, not mobile data)
  Future<bool> checkWiFi() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());

    // Only return true for WiFi connections
    if (connectivityResult.contains(ConnectivityResult.wifi)) {
      debugPrint('✅ WiFi is available.');
      return true;
      // Note for Android:
      // When both mobile and Wi-Fi are turned on system will return Wi-Fi only as active network type
    } else if (connectivityResult.contains(ConnectivityResult.none)) {
      // No available network types
      debugPrint('❌ No network connection available');
      return false;
    } else {
      // Mobile, ethernet, VPN, bluetooth, or other connections are not WiFi
      debugPrint('⚠️ WiFi not available (current: $connectivityResult)');
      return false;
    }
  }
}
