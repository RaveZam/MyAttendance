import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:myattendance/features/auth/states/account_type_handler.dart';
import 'package:provider/provider.dart';
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
        prefs.setString('session', jsonEncode(session.toJson()));
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
      final session = Session.fromJson(jsonDecode(sessionString ?? '{}'));

      if (session != null) {
        await Supabase.instance.client.auth.setSession(session.accessToken);
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
