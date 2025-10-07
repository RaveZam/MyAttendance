import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:myattendance/features/QRFeature/widgets/custom_border_painter.dart';
import 'package:myattendance/core/database/app_database.dart';

class TeacherQrReader extends StatefulWidget {
  final Function(String)? onQRCodeDetected;
  final String sessionID;

  const TeacherQrReader({
    super.key,
    this.onQRCodeDetected,
    required this.sessionID,
  });

  @override
  State<TeacherQrReader> createState() => TeacherQrReaderState();
}

class TeacherQrReaderState extends State<TeacherQrReader> {
  final MobileScannerController controller = MobileScannerController();
  bool _hasScanned = false;
  DateTime? _lastScanAt;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Rect scanWindow = const Rect.fromLTWH(0, 0, 250, 250);

    return SizedBox(
      height: 250,
      width: 250,
      child: Stack(
        children: [
          MobileScanner(
            controller: controller,
            scanWindow: scanWindow,
            onDetect: (capture) async {
              final now = DateTime.now();

              if (_lastScanAt == null ||
                  now.difference(_lastScanAt!).inMilliseconds > 2000) {
                _lastScanAt = now;

                final rawQr = capture.barcodes.first.rawValue;

                debugPrint("QR code detected: $rawQr");

                if (rawQr != null) {
                  final attendance = await AppDatabase.instance
                      .insertAttendance(
                        AttendanceCompanion.insert(
                          studentId: rawQr,
                          sessionId: int.parse(widget.sessionID),
                          status: 'present',
                          synced: false,
                        ),
                      );
                  debugPrint('Attendance loaded: ${attendance.toString()}');
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QR Code Scanned Successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(milliseconds: 500),
                  ),
                );

                Future.delayed(const Duration(milliseconds: 1000), () {
                  if (!mounted) return;
                  setState(() {
                    _hasScanned = false;
                  });
                });

                if (rawQr != null) {
                  setState(() {
                    _hasScanned = true;
                  });

                  // Call the callback if provided
                  if (widget.onQRCodeDetected != null) {
                    widget.onQRCodeDetected!(rawQr);
                  }
                }
              } else {
                debugPrint('Debounced');
              }
            },
          ),
          CustomPaint(
            painter: CornerBorderPainter(scanWindow: scanWindow),
            size: Size.infinite,
          ),
          // Overlay with scanning indicator
          if (_hasScanned)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Position QR code within the frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Success overlay
          if (_hasScanned)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'QR Code Scanned!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Method to reset the scanner
  void resetScanner() {
    setState(() {
      _hasScanned = false;
    });
  }
}
