import 'package:flutter/material.dart';

import 'package:myattendance/features/QRFeature/widgets/qr_reader.dart';

class StudentHomepage extends StatefulWidget {
  const StudentHomepage({super.key});

  @override
  State<StudentHomepage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomepage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Scan ClassRoom Qr",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            QrReader(),
          ],
        ),
      ),
    );
  }
}
