import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myattendance/features/Home/pages/teacher_home_page.dart';
import 'package:myattendance/features/QRFeature/states/qr_data_provider.dart';
import 'package:myattendance/features/Teacher/pages/teacher_main_screen.dart';
import 'package:provider/provider.dart';
import 'package:myattendance/features/auth/pages/auth_page.dart';

class TeacherApp extends StatelessWidget {
  const TeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Teacher App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      routes: {
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const TeacherHomePage(),
        '/teacher/main': (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => QrDataProvider()),
            // ChangeNotifierProvider(create: (_) => StudentAttendanceProvider()),
          ],
          child: const TeacherMainScreen(),
        ),
      },
      home: session == null
          ? const AuthPage()
          : MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => QrDataProvider()),
                // ChangeNotifierProvider(
                //   create: (_) => StudentAttendanceProvider(),
                // ),
              ],
              child: const TeacherMainScreen(),
            ),
    );
  }
}
