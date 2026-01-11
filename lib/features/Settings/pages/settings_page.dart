import 'package:flutter/material.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:myattendance/core/widgets/custom_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myattendance/features/auth/services/auth_service.dart';
import 'package:myattendance/features/Settings/widgets/confirmation_popup.dart';
import 'package:myattendance/core/services/sync_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';
  bool _isSyncing = false;
  String _lastSyncTime = 'Never';
  String _syncStatusMessage = 'Checking sync status...';
  SyncStatus? _currentSyncStatus;

  @override
  void initState() {
    super.initState();
    // Log local data when settings is opened to help debug sync state
    AppDatabase.instance.logAllStudents();
    AppDatabase.instance.logAllSubjectsAndOfferings();
    AppDatabase.instance.logAllSubjectStudents();
    AppDatabase.instance.logAttendanceSessionScheduleCounts();
    AppDatabase.instance.logDeletionQueue();
    _loadUserSettings();
    _checkSyncStatus();
  }

  Future<void> _loadUserSettings() async {
    // In a real app, you would load these from SharedPreferences or a database
    // For now, we'll use default values
    setState(() {
      _isLoading = false;
    });
  }

  final syncService = SyncService(
    db: AppDatabase.instance,
    supabase: Supabase.instance.client,
  );

  Future<void> _checkSyncStatus() async {
    try {
      final status = await syncService.checkSyncStatus();
      setState(() {
        _currentSyncStatus = status.status;
        _syncStatusMessage = status.message;
        if (status.localUnsyncedCount > 0) {
          _syncStatusMessage += ' (${status.localUnsyncedCount} unsynced)';
        }
      });
    } catch (e) {
      setState(() {
        _syncStatusMessage = 'Error checking status: $e';
        _currentSyncStatus = SyncStatus.unknown;
      });
    }
  }

  Future<void> _handleSync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      // Use smart sync which handles bidirectional sync
      await syncService.smartSync();

      // Update last sync time
      final now = DateTime.now();
      final formattedTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Refresh sync status
      await _checkSyncStatus();

      setState(() {
        _lastSyncTime = 'Today at $formattedTime';
        _isSyncing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synced successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Special handling for "missing remote record" conflicts.
      if (e is RemoteRecordMissingException) {
        setState(() {
          _isSyncing = false;
        });
        await _handleMissingRemoteRecord(e);
        return;
      }

      setState(() {
        _isSyncing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    await ConfirmationPopup(
      context: context,
      onConfirm: _performSignOut,
      onCancel: () async => Navigator.of(context).pop(),
      isLoading: _isLoading,
    ).showConfirmationDialog();
  }

  Future<void> _performSignOut() async {
    setState(() {
      _isLoading = true;
    });
    final authService = AuthService();
    try {
      // Clear all database data before signing out
      await AppDatabase.instance.clearAllDatabaseData();

      final success = await authService.signOut();
      if (mounted && success) {
        // Ensure the confirmation dialog is closed
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } catch (e) {
      if (mounted) {
        // Close the dialog if it's still open
        Navigator.of(context, rootNavigator: true).maybePop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  User? get _currentUser => Supabase.instance.client.auth.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Settings', icon: Icons.settings_rounded),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Section
                  _buildUserInfoSection(),
                  const SizedBox(height: 32),

                  // Settings Section
                  _buildSettingsSection(),
                  const SizedBox(height: 32),

                  // Sign Out Button
                  _buildSignOutButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoSection() {
    final user = _currentUser;
    final userMetadata = user?.userMetadata ?? {};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Profile Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              _getInitials(
                userMetadata['first_name'] ?? '',
                userMetadata['last_name'] ?? '',
              ),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // User Name
          Text(
            '${userMetadata['first_name'] ?? 'Unknown'} ${userMetadata['last_name'] ?? 'User'}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Student ID
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${userMetadata['account_type'] == 'student' ? 'Student ID' : 'Teacher Email'}: ${userMetadata['student_id'] ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Email
          Text(
            user?.email ?? 'No email',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferences',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Notifications Setting
        _buildSettingTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Receive attendance reminders',
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
        ),

        const Divider(),

        _buildSettingTile(
          icon: Icons.dark_mode_outlined,
          title: 'Dark Mode',
          subtitle: 'Use dark theme',
          trailing: Switch(
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
          ),
        ),

        const Divider(),

        // Sync Setting
        _buildSettingTile(
          icon: _getSyncIcon(),
          title: 'Sync Data',
          subtitle: _isSyncing
              ? 'Syncing...'
              : _syncStatusMessage.isEmpty
              ? 'Last sync: $_lastSyncTime'
              : _syncStatusMessage,
          trailing: _isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _checkSyncStatus,
                  tooltip: 'Refresh sync status',
                ),
          onTap: _isSyncing ? null : _handleSync,
        ),
        const Divider(),

        _buildSettingTile(
          icon: Icons.language_outlined,
          title: 'Language',
          subtitle: _selectedLanguage,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showLanguageDialog();
          },
        ),

        const Divider(),

        // About Setting
        _buildSettingTile(
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'App version and info',
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            _showAboutDialog();
          },
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleSignOut,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.logout),
        label: Text(_isLoading ? 'Signing out...' : 'Sign Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _getInitials(String firstName, String lastName) {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'English',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Spanish'),
              leading: Radio<String>(
                value: 'Spanish',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSyncIcon() {
    switch (_currentSyncStatus) {
      case SyncStatus.serverNewer:
        return Icons.download_outlined;
      case SyncStatus.localNewer:
        return Icons.upload_outlined;
      case SyncStatus.bothNewer:
        return Icons.sync_problem_outlined;
      case SyncStatus.upToDate:
        return Icons.check_circle_outline;
      case SyncStatus.unknown:
      case null:
        return Icons.sync_outlined;
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'My Attendance',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.school, size: 48, color: Colors.blue),
      children: [
        const Text(
          'A simple attendance tracking app for students and teachers.',
        ),
      ],
    );
  }

  /// Handles cases where a record was deleted from the cloud on another device
  /// but still exists locally. Prompts the user to either re-sync it as a new
  /// record or delete it locally.
  Future<void> _handleMissingRemoteRecord(
    RemoteRecordMissingException exception,
  ) async {
    final localId = exception.localId;

    String title;
    String description;

    if (exception.tableName == 'subject_offerings') {
      title = 'Subject not found in cloud';
      description =
          'This subject appears to have been deleted from another device.\n\n'
          'Would you like to sync it again to the cloud as a new subject, '
          'or delete it locally?';
    } else if (exception.tableName == 'students') {
      title = 'Student not found in cloud';
      description =
          'This student appears to have been deleted from another device.\n\n'
          'Would you like to sync it again to the cloud as a new student, '
          'or delete it locally (including related data)?';
    } else {
      title = 'Record not found in cloud';
      description =
          'This record appears to have been deleted from another device.\n\n'
          'Would you like to sync it again to the cloud as a new record, '
          'or delete it locally?';
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('delete'),
            child: const Text('Delete locally'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('resync'),
            child: const Text('Sync again'),
          ),
        ],
      ),
    );

    if (!mounted || choice == null) return;

    if (choice == 'resync') {
      if (exception.tableName == 'subject_offerings') {
        await AppDatabase.instance.resetSubjectGraphForResync(localId);
      } else if (exception.tableName == 'students') {
        await AppDatabase.instance.resetStudentGraphForResync(localId);
      }

      // Re-run sync to push the fresh records.
      await _handleSync();
    } else if (choice == 'delete') {
      if (exception.tableName == 'subject_offerings') {
        await AppDatabase.instance.deleteSubject(localId);
      } else if (exception.tableName == 'students') {
        await AppDatabase.instance.deleteStudentWithRelations(localId);
      }

      await _checkSyncStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record deleted locally.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
