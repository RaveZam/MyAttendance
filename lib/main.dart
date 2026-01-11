import 'package:flutter/material.dart';
import 'package:myattendance/features/Student/App/student_app.dart';
import 'package:myattendance/features/Teacher/App/teacher_app.dart';
import 'package:myattendance/features/auth/pages/auth_page.dart';
import 'package:myattendance/core/services/periodic_sync_service.dart';
import 'package:myattendance/core/services/sync_service.dart';
import 'package:myattendance/core/database/app_database.dart';

// import 'package:myattendance/features/BLE/pages/teacher_scanner_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://crabanoguftvirdjsabh.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNyYWJhbm9ndWZ0dmlyZGpzYWJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY5NTMzMDQsImV4cCI6MjA3MjUyOTMwNH0.LAsaiYmX_ivFc7uLYxp4zU3CfzACspSa4YZq7OyVgn8',
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
  );

  // try {
  //   final authService = AuthService();
  //   await authService.restoreSession();
  // } catch (e) {
  //   debugPrint('Failed to restore session on startup: $e');
  // }

  runApp(MyAttendanceApp());
}

class MyAttendanceApp extends StatelessWidget {
  const MyAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: _AppWithSyncManager(),
    );
  }
}

/// Widget that manages periodic sync service lifecycle based on auth state
class _AppWithSyncManager extends StatefulWidget {
  @override
  State<_AppWithSyncManager> createState() => _AppWithSyncManagerState();
}

class _AppWithSyncManagerState extends State<_AppWithSyncManager> {
  PeriodicSyncService? _periodicSyncService;

  @override
  void dispose() {
    _periodicSyncService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;
        debugPrint('session: $session');

        // Manage periodic sync service based on auth state
        if (session == null) {
          // User logged out - stop sync service
          _periodicSyncService?.stop();
          _periodicSyncService = null;
          return AuthPage();
        } else {
          // User logged in - start sync service if not already running
          if (_periodicSyncService == null) {
            final syncService = SyncService(
              db: AppDatabase.instance,
              supabase: Supabase.instance.client,
            );
            _periodicSyncService = PeriodicSyncService(
              syncService: syncService,
            );
            _periodicSyncService!.start();
          }

          final accountType = session.user.userMetadata?['account_type'];
          debugPrint('accountType: $accountType');
          if (accountType == 'student') {
            return StudentApp();
          } else {
            return TeacherApp();
          }
        }
      },
    );
  }
}
