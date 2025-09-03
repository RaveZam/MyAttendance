import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrReader extends StatefulWidget {
  const QrReader({super.key});

  @override
  State<QrReader> createState() => _QrReaderState();
}

class _QrReaderState extends State<QrReader> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      child: MobileScanner(
        onDetect: (result) {
          print(result.barcodes.first.rawValue);
        },
      ),
    );
  }
}
