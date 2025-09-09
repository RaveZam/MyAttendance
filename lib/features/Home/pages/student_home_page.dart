import 'package:flutter/material.dart';
import 'package:myattendance/core/states/scanned_class_display.dart';
import 'package:myattendance/features/QRFeature/states/qr_data_provider.dart';

import 'package:myattendance/features/QRFeature/widgets/qr_reader.dart';
import 'package:provider/provider.dart';

class StudentHomepage extends StatefulWidget {
  const StudentHomepage({super.key});

  @override
  State<StudentHomepage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomepage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<QrDataProvider>(
      builder: (context, qrDataProvider, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.grey[50]!, Colors.white],
            ),
          ),
          child: SafeArea(
            child: qrDataProvider.classCode.isEmpty
                ? _buildQRScanningSection()
                : _buildScannedSection(),
          ),
        );
      },
    );
  }

  Widget _buildQRScanningSection() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Header Section - Compact
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 24,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Scan Classroom QR Code",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Point camera at QR code to mark attendance",
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // QR Scanner Section - No Animation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const QrReader(),
          ),
          const SizedBox(height: 20),
          // Instructions - Compact
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Make sure the QR code is clearly visible and well-lit",
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Success Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.green.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Attendance Marked Successfully!",
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "You have successfully scanned the classroom QR code",
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Class Information
          const ScannedClassDisplay(),
        ],
      ),
    );
  }
}
