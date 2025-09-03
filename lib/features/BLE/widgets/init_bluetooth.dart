import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothHelper {
  static Future<void> initBluetooth() async {
    // 1. Check if device supports Bluetooth
    if (await FlutterBluePlus.isSupported == false) {
      print("❌ Bluetooth not supported by this device");
      return;
    }

    // 2. Listen for Bluetooth state changes
    var subscription = FlutterBluePlus.adapterState.listen((
      BluetoothAdapterState state,
    ) {
      print("Bluetooth state: $state");

      if (state == BluetoothAdapterState.on) {
        print("✅ Bluetooth is ON, ready to scan.");
        // you can trigger scanning here if you want
      } else {
        print("⚠️ Bluetooth is OFF or unavailable.");
      }
    });

    // 3. Try turning on Bluetooth (Android only, not iOS)
    if (!kIsWeb && Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

    // 4. Cancel subscription after first update (avoid duplicate listeners)
    Future.delayed(Duration(seconds: 3), () {
      subscription.cancel();
    });
  }
}
