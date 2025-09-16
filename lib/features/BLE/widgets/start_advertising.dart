import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'dart:typed_data';

class StudentAdvertiserPage extends StatefulWidget {
  const StudentAdvertiserPage({super.key});

  @override
  State<StudentAdvertiserPage> createState() => _StudentAdvertiserPageState();
}

class _StudentAdvertiserPageState extends State<StudentAdvertiserPage> {
  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();
  String payloadInput = "";

  bool isAdvertising = false;
  final TextEditingController payloadController = TextEditingController();

  @override
  void dispose() {
    blePeripheral.stop();
    super.dispose();
  }

  void startAdvertising() async {
    String payload = "STUDENT:$payloadInput";
    AdvertiseData advertiseData = AdvertiseData(
      includeDeviceName: false,
      // manufacturerId: 123, // pick any 16-bit number for your app
      // manufacturerData: Uint8List.fromList(payload.codeUnits),
    );

    await blePeripheral.start(advertiseData: advertiseData);
    setState(() => isAdvertising = true);
    debugPrint("✅ Started advertising as $payload");
  }

  void stopAdvertising() async {
    await blePeripheral.stop();
    setState(() => isAdvertising = false);
    debugPrint("🛑 Stopped advertising");
    dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Advertiser")),
      body: Center(
        child: Column(
          children: [
            TextField(
              controller: payloadController,
              decoration: InputDecoration(labelText: "Payload"),
              onChanged: (val) => {payloadInput = val},
            ),
            ElevatedButton(
              onPressed: isAdvertising ? stopAdvertising : startAdvertising,
              child: Text(
                isAdvertising ? "Stop Advertising" : "Start Advertising",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
