import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'local_store.dart';

class UbAuthUser {
  const UbAuthUser({
    required this.noreg,
    required this.name,
    required this.role,
    required this.shift,
    this.pos = '',
    this.phone = '',
    this.rfidCode = '',
    this.method = 'roster',
  });

  final String noreg;
  final String name;
  final String role; // GL | TL | TM | ADMIN
  final String shift; // RED | WHITE | ALL
  final String pos;
  final String phone;
  final String rfidCode;
  final String method;

  factory UbAuthUser.fromJson(Map<String, dynamic> j, {String method = 'roster'}) {
    return UbAuthUser(
      noreg: (j['noreg'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      role: (j['role'] ?? 'TM').toString().toUpperCase(),
      shift: (j['shift'] ?? 'ALL').toString().toUpperCase(),
      pos: (j['pos'] ?? '').toString(),
      phone: (j['phone'] ?? '').toString(),
      rfidCode: (j['rfid_code'] ?? j['rfidCode'] ?? '').toString(),
      method: (j['method'] ?? method).toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'noreg': noreg,
        'name': name,
        'role': role,
        'shift': shift,
        'pos': pos,
        'phone': phone,
        'rfid_code': rfidCode,
        'method': method,
      };
}

class AuthResult {
  const AuthResult({
    required this.ok,
    this.message,
    this.user,
  });

  final bool ok;
  final String? message;
  final UbAuthUser? user;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const String gateBaseUrl = 'https://ubnetwork.vercel.app';
  static const String _kAuthUser = 'ubf_auth_user_v1';
  static const String _kGateCookie = 'ubf_gate_cookie_v1';

  UbAuthUser? _currentUser;
  UbAuthUser? get currentUser => _currentUser;

  Future<UbAuthUser?> loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kAuthUser);
    if (raw == null || raw.isEmpty) {
      _currentUser = null;
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> && (decoded['name'] ?? '').toString().isNotEmpty) {
        _currentUser = UbAuthUser.fromJson(decoded);
        return _currentUser;
      }
    } catch (_) {}
    _currentUser = null;
    return null;
  }

  Future<void> _saveSession(UbAuthUser user, {String? cookieHeader}) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAuthUser, jsonEncode(user.toJson()));
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      await prefs.setString(_kGateCookie, cookieHeader);
    }

    // Sinkronkan role shift & nama operator ke UbSettings
    final cfg = await LocalStore.instance.getSettings();
    if (user.shift == 'RED' || user.shift == 'WHITE' || user.shift == 'ALL') {
      cfg.role = user.shift;
    }
    if (user.name.trim().isNotEmpty) {
      cfg.operatorName = user.name.trim();
    }
    await LocalStore.instance.saveSettings(cfg);
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAuthUser);
    await prefs.remove(_kGateCookie);
    try {
      await http
          .delete(Uri.parse('$gateBaseUrl/api/gate'))
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<AuthResult> loginWithRoster({
    required String noreg,
    required String wa6,
  }) async {
    return _postGate({
      'noreg': noreg.trim(),
      'wa6': wa6.replaceAll(RegExp(r'\D'), ''),
    }, method: 'roster');
  }

  Future<AuthResult> requestOtp({required String noreg}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$gateBaseUrl/api/gate'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'otpRequest': noreg.trim()}),
          )
          .timeout(const Duration(seconds: 15));

      final json = _decodeMap(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && json['ok'] == true) {
        return AuthResult(
          ok: true,
          message: (json['message'] ?? 'Kode OTP telah dikirim ke WhatsApp terdaftar.').toString(),
        );
      }
      return AuthResult(
        ok: false,
        message: (json['message'] ?? 'Gagal mengirim kode OTP.').toString(),
      );
    } catch (_) {
      return const AuthResult(
        ok: false,
        message: 'Tidak dapat terhubung ke server UBnetwork. Periksa koneksi internet.',
      );
    }
  }

  Future<AuthResult> verifyOtp({
    required String noreg,
    required String otp,
  }) async {
    return _postGate({
      'noreg': noreg.trim(),
      'otp': otp.replaceAll(RegExp(r'\D'), ''),
    }, method: 'otp');
  }

  Future<AuthResult> loginWithPassword({required String password}) async {
    return _postGate({
      'password': password.trim(),
    }, method: 'password');
  }

  Future<AuthResult> _postGate(
    Map<String, dynamic> body, {
    required String method,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$gateBaseUrl/api/gate'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final json = _decodeMap(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && json['ok'] == true && json['user'] is Map) {
        final user = UbAuthUser.fromJson(
          Map<String, dynamic>.from(json['user'] as Map),
          method: (json['method'] ?? method).toString(),
        );
        final setCookie = res.headers['set-cookie'];
        await _saveSession(user, cookieHeader: setCookie);
        return AuthResult(ok: true, user: user);
      }

      return AuthResult(
        ok: false,
        message: (json['message'] ??
                (res.statusCode == 401
                    ? 'Kredensial tidak valid.'
                    : res.statusCode == 429
                        ? 'Terlalu banyak percobaan. Coba lagi nanti.'
                        : 'Gagal login (HTTP ${res.statusCode}).'))
            .toString(),
      );
    } catch (_) {
      return const AuthResult(
        ok: false,
        message: 'Tidak bisa terhubung ke server UBnetwork. Pastikan koneksi internet aktif.',
      );
    }
  }

  Map<String, dynamic> _decodeMap(String raw) {
    try {
      final d = jsonDecode(raw);
      if (d is Map<String, dynamic>) return d;
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
    return {};
  }
}
