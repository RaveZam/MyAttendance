import 'package:flutter/material.dart';
import 'package:myattendance/features/Home/pages/homepage.dart';
import 'package:myattendance/features/QRFeature/pages/qr_read_page.dart';
import 'package:myattendance/features/QRFeature/states/qr_data_provider.dart';
import 'package:myattendance/features/auth/pages/auth_page.dart';
import 'package:myattendance/features/Settings/pages/settings_page.dart';
import 'package:provider/provider.dart';
// import 'package:myattendance/features/BLE/pages/teacher_scanner_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://crabanoguftvirdjsabh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNyYWJhbm9ndWZ0dmlyZGpzYWJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY5NTMzMDQsImV4cCI6MjA3MjUyOTMwNH0.LAsaiYmX_ivFc7uLYxp4zU3CfzACspSa4YZq7OyVgn8',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    debugPrint('session: $session');
    return MaterialApp(
      title: 'My Attendance',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      routes: {
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const Homepage(),
        '/main': (context) => ChangeNotifierProvider(
          create: (_) => QrDataProvider(),
          child: const MainScreen(),
        ),
      },
      home: session == null
          ? const AuthPage()
          : ChangeNotifierProvider(
              create: (_) => QrDataProvider(),
              child: const MainScreen(),
            ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Homepage(),
    const QrReadPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Attendance")),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: "QR",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
