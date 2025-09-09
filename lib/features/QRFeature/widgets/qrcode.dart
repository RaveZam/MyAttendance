import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:myattendance/features/QRFeature/states/qr_data_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
// import 'package:provider/provider.dart';
import 'package:myattendance/features/BLE/pages/teacher_scanner_page.dart';

class Qrcode extends StatefulWidget {
  const Qrcode({super.key});

  @override
  State<Qrcode> createState() => _QrcodeState();
}

class _QrcodeState extends State<Qrcode> {
  final classdata = {
    "class_code": "CS101",
    "class_name": "Introduction to Computer Science",
    "class_session_id": "2025-09-03-10AM",
    "service_uuid": "12345678-1234-1234-1234-123456789abc",
    "char_uuid": "abcd1234-5678-90ab-cdef-1234567890ab",
    "instructor_name": "John Facun",
    "start_time": "10:00 AM",
    "end_time": "11:00 AM",
    "day": "Monday",
  };

  @override
  Widget build(BuildContext context) {
    // final qrdataprovider = Provider.of<QrDataProvider>(context);
    final jsonString = jsonEncode(classdata);
    return Container(
      child: Column(
        children: [
          PrettyQrView.data(
            data: jsonString,
            decoration: const PrettyQrDecoration(
              quietZone: PrettyQrQuietZone.standart,
            ),
          ),
          TeacherScannerPage(qrPayload: jsonString),
        ],
      ),
    );
  }
}
