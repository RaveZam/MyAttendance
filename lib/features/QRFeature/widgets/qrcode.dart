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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Class Info Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classdata["class_name"]!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Text(
                            "${classdata["class_code"]} • ${classdata["day"]}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // QR Code
              PrettyQrView.data(
                data: jsonString,
                decoration: const PrettyQrDecoration(
                  quietZone: PrettyQrQuietZone.standart,
                ),
              ),
              const SizedBox(height: 16),
              // Time Info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTimeInfo(
                      "Start",
                      classdata["start_time"]!,
                      Colors.green,
                    ),
                    Container(
                      height: 20,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    _buildTimeInfo("End", classdata["end_time"]!, Colors.red),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Scanner Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bluetooth_connected_rounded,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "BLE Scanner",
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TeacherScannerPage(qrPayload: jsonString),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(String label, String time, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
