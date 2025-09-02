import 'package:flutter/material.dart';

class QrGenerator extends StatefulWidget {
  const QrGenerator({super.key});

  @override
  State<QrGenerator> createState() => _QrGeneratorState();
}

class _QrGeneratorState extends State<QrGenerator> {
  final TextEditingController studentIDController = TextEditingController();
  final TextEditingController studentNameController = TextEditingController();
  String studentID = "";
  String studentName = "";
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Column(
        children: [
          Text("Student ID"),
          TextField(),
          Text("Student Name"),
          TextField(),
        ],
      ),
    );
  }
}
