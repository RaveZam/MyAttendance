import 'package:flutter/material.dart';
import 'package:myattendance/features/QRFeature/states/qr_data_provider.dart';
import 'package:provider/provider.dart';

class ScannedClassDisplay extends StatefulWidget {
  const ScannedClassDisplay({super.key});

  @override
  State<ScannedClassDisplay> createState() => _ScannedClassDisplayState();
}

class _ScannedClassDisplayState extends State<ScannedClassDisplay> {
  @override
  Widget build(BuildContext context) {
    return Consumer<QrDataProvider>(
      builder: (context, qrDataProvider, child) {
        // Check if class data is empty
        if (qrDataProvider.classCode.isEmpty) {
          return const SizedBox.shrink();
        }

        // Display class details card
        return _buildClassDetailsCard(qrDataProvider);
      },
    );
  }

  Widget _buildClassDetailsCard(QrDataProvider qrDataProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Class Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Attendance Details',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Class Code - Highlighted
                _buildHighlightedDetailRow(
                  icon: Icons.qr_code_rounded,
                  label: 'Class Code',
                  value: qrDataProvider.classCode,
                  isHighlighted: true,
                ),

                const SizedBox(height: 20),

                // Session Details
                _buildDetailRow(
                  icon: Icons.confirmation_number_rounded,
                  label: 'Session ID',
                  value: qrDataProvider.classSessionId,
                ),

                _buildDetailRow(
                  icon: Icons.person_rounded,
                  label: 'Instructor',
                  value: qrDataProvider.instructorName,
                ),

                // Time Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Class Schedule',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimeCard(
                              'Start Time',
                              qrDataProvider.startTime,
                              Icons.play_arrow_rounded,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTimeCard(
                              'End Time',
                              qrDataProvider.endTime,
                              Icons.stop_rounded,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Student Information (if available)
                if (qrDataProvider.studentID.isNotEmpty ||
                    qrDataProvider.studentName.isNotEmpty) ...[
                  const SizedBox(height: 24),
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
                              Icons.person_outline_rounded,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Student Information',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (qrDataProvider.studentID.isNotEmpty)
                          _buildDetailRow(
                            icon: Icons.badge_rounded,
                            label: 'Student ID',
                            value: qrDataProvider.studentID,
                          ),

                        if (qrDataProvider.studentName.isNotEmpty)
                          _buildDetailRow(
                            icon: Icons.person_rounded,
                            label: 'Student Name',
                            value: qrDataProvider.studentName,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isHighlighted,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isHighlighted ? Colors.white : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isHighlighted
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isHighlighted
                    ? Theme.of(context).primaryColor
                    : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(String label, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
