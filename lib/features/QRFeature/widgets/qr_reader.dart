import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:myattendance/features/QRFeature/widgets/custom_border_painter.dart';

class QrReader extends StatefulWidget {
  const QrReader({super.key});

  @override
  State<QrReader> createState() => _QrReaderState();
}

class _QrReaderState extends State<QrReader> {
  final MobileScannerController controller = MobileScannerController();

  @override
  void initState() {
    super.initState();
    // make sure no old advertiser is still running
    FlutterBlePeripheral().stop();
  }

  @override
  void dispose() {
    FlutterBlePeripheral().stop();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Rect scanWindow = const Rect.fromLTWH(0, 0, 200, 200);

    return SizedBox(
      height: 200,
      width: 200,
      child: Stack(
        children: [
          MobileScanner(
            controller: controller,
            scanWindow: scanWindow,
            onDetect: (capture) async {
              final rawQr = capture.barcodes.first.rawValue;
              debugPrint("QR code detected: $rawQr");

              if (rawQr != null) {
                await FlutterBlePeripheral().stop();
                debugPrint("🛑 Stopped previous advertising");
                final classdata = jsonDecode(rawQr);

                final studentId = "Raven"; // from login/profile
                final payload =
                    "STUDENT:$studentId|SESSION:${classdata['class_session_id']}|CLASS:${classdata['class_code']}";

                final advertiseData = AdvertiseData(
                  includeDeviceName: true,
                  manufacturerId: 2,
                  manufacturerData: Uint8List.fromList(payload.codeUnits),
                );

                await FlutterBlePeripheral().start(
                  advertiseData: advertiseData,
                );
                debugPrint("📡 Advertising: $payload");
              }
            },
          ),
          CustomPaint(
            painter: CornerBorderPainter(scanWindow: scanWindow),
            size: Size.infinite,
          ),
        ],
      ),
    );
  }
}
