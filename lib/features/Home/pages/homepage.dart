import 'package:flutter/material.dart';
import 'package:myattendance/features/ScanFeature/widgets/qr_generator.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomePageState();
}

class _HomePageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: QrGenerator()));
  }
}
