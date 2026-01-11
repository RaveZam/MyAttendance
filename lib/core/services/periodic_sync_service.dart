import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:myattendance/core/network/wifi_checker.dart';
import 'package:myattendance/core/services/sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service that periodically checks WiFi and triggers sync every minute
class PeriodicSyncService {
  Timer? _syncTimer;
  final SyncService _syncService;
  final WifiChecker _wifiChecker;
  bool _isRunning = false;

  PeriodicSyncService({
    required SyncService syncService,
    WifiChecker? wifiChecker,
  })  : _syncService = syncService,
        _wifiChecker = wifiChecker ?? WifiChecker();

  /// Start the periodic sync timer (checks every 1 minute)
  void start() {
    if (_isRunning) {
      debugPrint('⚠️ Periodic sync is already running');
      return;
    }

    _isRunning = true;
    debugPrint('🔄 Starting periodic sync service (every 1 minute)');

    // Trigger initial sync check immediately
    _checkAndSync();

    // Then set up periodic timer for every 1 minute
    _syncTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkAndSync(),
    );
  }

  /// Stop the periodic sync timer
  void stop() {
    if (!_isRunning) {
      return;
    }

    _isRunning = false;
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('⏹️ Stopped periodic sync service');
  }

  /// Check WiFi availability and trigger sync if available
  Future<void> _checkAndSync() async {
    try {
      // Check if user is still logged in
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        debugPrint('⚠️ No active session, skipping sync');
        return;
      }

      // Check WiFi availability
      final isWiFiAvailable = await _wifiChecker.checkWiFi();

      if (isWiFiAvailable) {
        debugPrint('📶 WiFi available, triggering sync...');
        // Use smartSync for bidirectional sync
        await _syncService.smartSync();
      } else {
        debugPrint('📵 WiFi not available, skipping sync');
      }
    } catch (e, st) {
      debugPrint('❌ Error in periodic sync check: $e\n$st');
    }
  }

  /// Dispose resources
  void dispose() {
    stop();
  }
}
