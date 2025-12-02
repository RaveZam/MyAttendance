import 'package:flutter/material.dart';
import 'package:myattendance/features/QRFeature/widgets/student_qr_reader.dart';

class AddStudentPage extends StatefulWidget {
  final String subjectId;
  const AddStudentPage({super.key, required this.subjectId});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final GlobalKey<StudentQrReaderState> _qrReaderKey =
      GlobalKey<StudentQrReaderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Student"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildQRScanner(),
        ),
      ),
    );
  }

  Widget _buildQRScanner() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Scan Student QR Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Center(
                child: StudentQrReader(
                  key: _qrReaderKey,
                  subjectId: widget.subjectId,
                  onStudentAdded: () {
                    // Navigate back with success result
                    Navigator.pop(context, true);
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Position the QR code within the frame to scan',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'QR Code Format',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'The QR code should contain JSON with the following fields:',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(
                '• first_name\n• last_name\n• student_id',
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
