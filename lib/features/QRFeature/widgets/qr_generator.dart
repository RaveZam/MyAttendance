import 'package:flutter/material.dart';
import 'package:myattendance/features/QRFeature/states/qr_data_provider.dart';
import 'package:myattendance/features/QRFeature/widgets/qrcode.dart';
import 'package:provider/provider.dart';

class QrGenerator extends StatefulWidget {
  const QrGenerator({super.key});

  @override
  State<QrGenerator> createState() => _QrGeneratorState();
}

class _QrGeneratorState extends State<QrGenerator> {
  final TextEditingController studentIDController = TextEditingController();
  final TextEditingController studentNameController = TextEditingController();

  String tempstudname = "";
  String tempstudid = "";
  final Map<String, dynamic> classdata = {
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
    final qrdataProvider = Provider.of<QrDataProvider>(context);
    return SizedBox(
      width: 200,
      height: 400,
      child: Column(
        children: [
          TextField(
            controller: studentIDController,
            onChanged: (value) => {tempstudid = value},
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Student ID",
            ),
          ),
          Padding(padding: EdgeInsets.all(12)),
          TextField(
            controller: studentNameController,
            onChanged: (value) => {tempstudname = value},
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Student Name",
            ),
          ),
          Qrcode(classData: classdata),
          ElevatedButton(
            onPressed: () {
              qrdataProvider.setStudentName(tempstudname);
              qrdataProvider.setStudentID(tempstudid);
              print(qrdataProvider.studentID);
              print(qrdataProvider.studentName);
            },
            child: Text("Generate QR"),
          ),
        ],
      ),
    );
  }
}
