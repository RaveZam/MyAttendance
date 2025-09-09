import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:myattendance/features/QRFeature/widgets/custom_border_painter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final Rect scanWindow = const Rect.fromLTWH(0, 0, 250, 250);
    final userMetadata =
        Supabase.instance.client.auth.currentUser?.userMetadata;

    debugPrint("userMetadata: $userMetadata");
    return SizedBox(
      height: 250,
      width: 250,
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

                final studentId =
                    userMetadata?['student_id'] ?? ''; // from login/profile
                final studentName =
                    userMetadata?['first_name'] ?? ''; // from login/profile
                final payload =
                    "STUDENT:$studentId|NAME:$studentName|SESSION:${classdata['class_session_id']}|CLASS:${classdata['class_code']}";

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
