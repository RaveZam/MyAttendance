import 'package:flutter/material.dart';
import 'package:myattendance/features/QRFeature/widgets/qr_reader.dart';

class QrReadPage extends StatefulWidget {
  const QrReadPage({super.key});

  @override
  State<QrReadPage> createState() => _QrReadPageState();
}

class _QrReadPageState extends State<QrReadPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: QrReader()));
  }
}
