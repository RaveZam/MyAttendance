import 'package:flutter/material.dart';
import 'package:myattendance/features/QRFeature/states/qr_data_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';

class Qrcode extends StatefulWidget {
  const Qrcode({super.key});

  @override
  State<Qrcode> createState() => _QrcodeState();
}

class _QrcodeState extends State<Qrcode> {
  @override
  Widget build(BuildContext context) {
    final qrdataprovider = Provider.of<QrDataProvider>(context);
    return Container(
      child: PrettyQrView.data(
        data:
            'Student ID: ${qrdataprovider.studentID} ,Student Name: ${qrdataprovider.studentName}',
        decoration: const PrettyQrDecoration(
          quietZone: PrettyQrQuietZone.standart,
        ),
      ),
    );
  }
}
