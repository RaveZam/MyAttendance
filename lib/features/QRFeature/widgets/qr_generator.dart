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
          Qrcode(),
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
