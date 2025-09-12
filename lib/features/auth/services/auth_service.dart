import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  Future<bool> signIn(String email, String password) async {
    try {
      final AuthResponse res = await Supabase.instance.client.auth
          .signInWithPassword(email: email.trim(), password: password.trim());
      final session = res.session;
      if (session != null) {
        final prefs = await SharedPreferences.getInstance();
        final storedSession = prefs.setString(
          'session',
          jsonEncode(session.toJson()),
        );
        debugPrint('stored Session: ${storedSession.toString()}');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signUp(
    String email,
    String password,
    String studentID,
    String firstName,
    String lastName,
    String accountType,
  ) async {
    try {
      Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'student_id': studentID,
          'first_name': firstName,
          'last_name': lastName,
          'account_type': accountType,
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signOut() async {
    try {
      Supabase.instance.client.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('session');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionString = prefs.getString('session');

      if (sessionString == null || sessionString.isEmpty) {
        debugPrint('No stored session found');
        return false;
      }

      final sessionData = jsonDecode(sessionString);
      final session = Session.fromJson(sessionData);

      debugPrint('restoring Session: $session');

      if (session != null) {
        await Supabase.instance.client.auth.setSession(sessionData);
      }
      debugPrint('restored Session: $session');
      return true;
    } catch (e) {
      debugPrint('error restoring Session: $e');
      return false;
    }
  }
}
