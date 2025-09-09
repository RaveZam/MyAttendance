import 'package:flutter/material.dart';
import 'package:myattendance/features/QRFeature/widgets/qrcode.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(children: [Text("Teacher Homepage"), Qrcode()]),
      ),
    );
  }
}
