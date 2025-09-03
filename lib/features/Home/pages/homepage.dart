import 'package:flutter/material.dart';

import 'package:myattendance/features/QRFeature/widgets/qrcode.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomePageState();
}

class _HomePageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Qrcode()));
  }
}
