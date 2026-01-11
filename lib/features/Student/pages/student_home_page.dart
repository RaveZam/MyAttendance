import 'package:flutter/material.dart';
import 'package:myattendance/features/QRFeature/states/qr_data_provider.dart';
import 'package:myattendance/features/QRFeature/widgets/qr_reader.dart';
import 'package:myattendance/features/QRFeature/widgets/student_qr.dart';
import 'package:provider/provider.dart';

class StudentHomepage extends StatefulWidget {
  const StudentHomepage({super.key});

  @override
  State<StudentHomepage> createState() => _StudentHomePageState();
}

enum _StudentQrMode { show, scan }

class _StudentHomePageState extends State<StudentHomepage> {
  _StudentQrMode _mode = _StudentQrMode.show;

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
          child: SafeArea(child: qrSection(qrDataProvider)),
        );
      },
    );
  }

  Widget qrSection(QrDataProvider qrDataProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.blueGrey.shade50),
              ),
              child: ToggleButtons(
                isSelected: [
                  _mode == _StudentQrMode.show,
                  _mode == _StudentQrMode.scan,
                ],
                onPressed: (index) {
                  setState(() {
                    _mode = _StudentQrMode.values[index];
                  });
                },
                fillColor: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(30),
                constraints: const BoxConstraints(minWidth: 100, minHeight: 44),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text('Show QR'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Text('Scan QR'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _mode == _StudentQrMode.show
                ? _buildShowQrCard()
                : _buildScanCard(qrDataProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildShowQrCard() {
    return Column(
      key: const ValueKey('showQr'),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const StudentQr(),
        ),
        const SizedBox(height: 20),
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
    );
  }

  Widget _buildScanCard(QrDataProvider provider) {
    return Column(
      key: const ValueKey('scanQr'),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.qr_code_scanner,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Scan teacher QR to join BLE attendance',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SizedBox(
                height: 260,
                width: double.infinity,
                child: Center(child: QrReader()),
              ),
              const SizedBox(height: 16),
              Text(
                provider.scanSuccess
                    ? 'Broadcasting your attendance via BLE'
                    : 'Position the class QR inside the frame to start broadcasting.',
                style: TextStyle(
                  color: provider.scanSuccess
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        if (provider.scanSuccess) ...[
          const SizedBox(height: 16),
          _buildSessionInfo(provider),
        ],
      ],
    );
  }

  Widget _buildSessionInfo(QrDataProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text(
                'Session detected',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SessionInfoRow(
            label: 'Class',
            value: provider.classCode.isEmpty
                ? '-'
                : '${provider.classCode} • ${provider.instructorName}',
          ),
          _SessionInfoRow(
            label: 'Session',
            value: provider.classSessionId.isEmpty
                ? '-'
                : provider.classSessionId,
          ),
          _SessionInfoRow(
            label: 'Duration',
            value: provider.startTime.isEmpty && provider.endTime.isEmpty
                ? '-'
                : '${provider.startTime} - ${provider.endTime}',
          ),
        ],
      ),
    );
  }
}

class _SessionInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _SessionInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
