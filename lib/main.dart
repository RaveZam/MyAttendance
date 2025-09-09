import 'package:flutter/material.dart';
import 'package:myattendance/features/Student/App/student_app.dart';
import 'package:myattendance/features/Teacher/App/teacher_app.dart';
import 'package:myattendance/features/auth/pages/auth_page.dart';

// import 'package:myattendance/features/BLE/pages/teacher_scanner_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://crabanoguftvirdjsabh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNyYWJhbm9ndWZ0dmlyZGpzYWJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY5NTMzMDQsImV4cCI6MjA3MjUyOTMwNH0.LAsaiYmX_ivFc7uLYxp4zU3CfzACspSa4YZq7OyVgn8',
  );
  runApp(MyAttendanceApp());
}

class MyAttendanceApp extends StatelessWidget {
  const MyAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session;
          debugPrint('session: $session');

          if (session == null) {
            return AuthPage();
          }

          final accountType = session.user.userMetadata?['account_type'];
          debugPrint('accountType: $accountType');
          if (accountType == 'student') {
            return StudentApp();
          } else {
            return TeacherApp();
          }
        },
      ),
    );
  }
}
