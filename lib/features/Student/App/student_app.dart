import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myattendance/features/Home/pages/student_home_page.dart';
import 'package:myattendance/features/QRFeature/states/qr_data_provider.dart';
import 'package:myattendance/features/Student/pages/student_main_screen.dart';
import 'package:provider/provider.dart';
import 'package:myattendance/features/auth/pages/auth_page.dart';

class StudentApp extends StatelessWidget {
  const StudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    // debugPrint('session: $session');

    // if (session != null) {
    //   final accountType = session.user.userMetadata?['account_type'];
    //   debugPrint('account type: $accountType');
    // }

    return MaterialApp(
      title: 'Student App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      routes: {
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const StudentHomepage(),
        '/student/main': (context) => ChangeNotifierProvider(
          create: (_) => QrDataProvider(),
          child: const StudentMainScreen(),
        ),
      },
      home: session == null
          ? const AuthPage()
          : ChangeNotifierProvider(
              create: (_) => QrDataProvider(),
              child: const StudentMainScreen(),
            ),
    );
  }
}
