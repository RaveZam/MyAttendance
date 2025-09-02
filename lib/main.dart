import 'package:flutter/material.dart';
import 'package:myattendance/features/Home/pages/homepage.dart';
import 'package:myattendance/features/QRFeature/states/qr_data_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: ChangeNotifierProvider(
        create: (_) => QrDataProvider(),
        child: DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text('My Attendance'),
              bottom: TabBar(
                tabs: [
                  Tab(text: 'Home'),
                  Tab(text: 'Schedule'),
                  Tab(text: 'Settings'),
                ],
              ),
            ),
            body: TabBarView(
              children: [Homepage(), Text('Schedule'), Text('Settings')],
            ),
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Hello World')],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
