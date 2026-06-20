import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  // Use 10.0.2.2 for Android Emulator, or your local IP for physical devices
  final String _baseUrl = 'https://nyks-system.onrender.com/api/auth';
  
  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = data['user'];
        
        // Save token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        
        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to login');
      }
    } catch (e) {
      rethrow;
    }
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '696088999669-btgqsi7gl0l8cvpjjkdajgg537gaqdc7.apps.googleusercontent.com',
    scopes: ['email'],
  );

  Future<bool> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false; // User cancelled the sign-in

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to retrieve Google ID Token.');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = data['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);

        notifyListeners();
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to authenticate with Google');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    notifyListeners();
  }
}
