import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'local_store.dart';

class UbApiResponse {
  const UbApiResponse({
    required this.ok,
    required this.statusCode,
    this.data,
    this.error,
  });

  final bool ok;
  final int statusCode;
  final dynamic data;
  final String? error;

  Map<String, dynamic> get map =>
      data is Map ? Map<String, dynamic>.from(data as Map) : const {};

  List<dynamic> get list => data is List ? data as List<dynamic> : const [];
}

/// Centralized 1:1 API client for Next.js `ubnetwork` (`/api/...` on `https://ubnetwork.vercel.app`).
/// Automatically attaches the authenticated `ub_gate` Cookie, `x-ub-api-key`,
/// and `x-user-noreg` / `x-user-nama` headers, and never throws unhandled errors.
class UbWebApi {
  UbWebApi._();
  static final UbWebApi instance = UbWebApi._();

  static const String _kGateCookie = 'ubf_gate_cookie_v1';
  static const Duration _defaultTimeout = Duration(seconds: 10);

  String get baseUrl => AuthService.gateBaseUrl;

  /// Extracts clean `name=value` cookie pairs from a raw `Set-Cookie` header string.
  static String extractCookieHeader(String? rawSetCookie) {
    if (rawSetCookie == null || rawSetCookie.trim().isEmpty) return '';
    // Split multiple cookies if combined, taking only the first `key=value` segment before `;`
    final parts = rawSetCookie.split(RegExp(r',(?=\s*[^;=,\s]+=)'));
    final pairs = <String>[];
    for (final p in parts) {
      final kv = p.split(';').first.trim();
      if (kv.contains('=')) pairs.add(kv);
    }
    return pairs.join('; ');
  }

  Future<Map<String, String>> buildHeaders({bool jsonBody = false}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawCookie = prefs.getString(_kGateCookie);
      final cleanCookie = extractCookieHeader(rawCookie);
      if (cleanCookie.isNotEmpty) {
        headers['Cookie'] = cleanCookie;
      }
    } catch (_) {}

    try {
      final cfg = await LocalStore.instance.getSettings();
      if (cfg.apiKey.trim().isNotEmpty) {
        headers['x-ub-api-key'] = cfg.apiKey.trim();
      }
    } catch (_) {}

    final user = AuthService.instance.currentUser;
    if (user != null) {
      if (user.noreg.isNotEmpty) headers['x-user-noreg'] = user.noreg;
      if (user.name.isNotEmpty) headers['x-user-nama'] = user.name;
    }

    return headers;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final base = Uri.parse('$baseUrl$normalized');
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: {...base.queryParameters, ...query});
  }

  Future<UbApiResponse> getJson(String path, {Map<String, String>? query}) async {
    try {
      final headers = await buildHeaders();
      final res = await http.get(_uri(path, query), headers: headers).timeout(_defaultTimeout);
      return _wrap(res);
    } catch (e) {
      return UbApiResponse(ok: false, statusCode: 0, error: e.toString());
    }
  }

  Future<UbApiResponse> postJson(String path, Object? body, {Map<String, String>? query}) async {
    try {
      final headers = await buildHeaders(jsonBody: true);
      final res = await http
          .post(_uri(path, query), headers: headers, body: body == null ? null : jsonEncode(body))
          .timeout(_defaultTimeout);
      return _wrap(res);
    } catch (e) {
      return UbApiResponse(ok: false, statusCode: 0, error: e.toString());
    }
  }

  Future<UbApiResponse> putJson(String path, Object? body, {Map<String, String>? query}) async {
    try {
      final headers = await buildHeaders(jsonBody: true);
      final res = await http
          .put(_uri(path, query), headers: headers, body: body == null ? null : jsonEncode(body))
          .timeout(_defaultTimeout);
      return _wrap(res);
    } catch (e) {
      return UbApiResponse(ok: false, statusCode: 0, error: e.toString());
    }
  }

  Future<UbApiResponse> patchJson(String path, Object? body, {Map<String, String>? query}) async {
    try {
      final headers = await buildHeaders(jsonBody: true);
      final res = await http
          .patch(_uri(path, query), headers: headers, body: body == null ? null : jsonEncode(body))
          .timeout(_defaultTimeout);
      return _wrap(res);
    } catch (e) {
      return UbApiResponse(ok: false, statusCode: 0, error: e.toString());
    }
  }

  Future<UbApiResponse> deleteJson(String path, {Map<String, String>? query}) async {
    try {
      final headers = await buildHeaders();
      final res = await http.delete(_uri(path, query), headers: headers).timeout(_defaultTimeout);
      return _wrap(res);
    } catch (e) {
      return UbApiResponse(ok: false, statusCode: 0, error: e.toString());
    }
  }

  /// 1:1 Next.js `/api/ub` gateway helper (attaches `ub_gate` cookie so Vercel
  /// authenticates and injects server-side `X-UB-API-Key` to `bungtemin.net/ub/api`).
  /// Supports custom external `serverApiUrl` if an explicit `apiKey` is configured.
  Future<UbApiResponse> getUb(
    Map<String, String> query, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      final cfg = await LocalStore.instance.getSettings();
      final customUrl = cfg.serverApiUrl.split('?').first.trim();
      final useCustomDirect = customUrl.isNotEmpty &&
          !customUrl.contains('ubnetwork.vercel.app') &&
          cfg.apiKey.trim().isNotEmpty;

      final headers = await buildHeaders();
      final Uri targetUri;
      if (useCustomDirect) {
        final base = Uri.parse(customUrl);
        targetUri = base.replace(queryParameters: {...base.queryParameters, ...query});
      } else {
        targetUri = _uri('/api/ub', query);
      }

      final res = await http.get(targetUri, headers: headers).timeout(timeout);
      return _wrap(res);
    } catch (e) {
      return UbApiResponse(ok: false, statusCode: 0, error: e.toString());
    }
  }

  /// 1:1 Next.js `POST /api/ub?action=...` gateway helper.
  Future<UbApiResponse> postUb(
    String action,
    Object? body, {
    Map<String, String>? extraQuery,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      final cfg = await LocalStore.instance.getSettings();
      final customUrl = cfg.serverApiUrl.split('?').first.trim();
      final useCustomDirect = customUrl.isNotEmpty &&
          !customUrl.contains('ubnetwork.vercel.app') &&
          cfg.apiKey.trim().isNotEmpty;

      final query = <String, String>{
        'action': action,
        ...?extraQuery,
      };
      final headers = await buildHeaders(jsonBody: true);
      final Uri targetUri;
      if (useCustomDirect) {
        final base = Uri.parse(customUrl);
        targetUri = base.replace(queryParameters: {...base.queryParameters, ...query});
      } else {
        targetUri = _uri('/api/ub', query);
      }

      final res = await http
          .post(targetUri, headers: headers, body: body == null ? null : jsonEncode(body))
          .timeout(timeout);
      return _wrap(res);
    } catch (e) {
      return UbApiResponse(ok: false, statusCode: 0, error: e.toString());
    }
  }

  UbApiResponse _wrap(http.Response res) {
    dynamic parsed;
    try {
      parsed = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    } catch (_) {
      parsed = null;
    }
    final ok = res.statusCode >= 200 && res.statusCode < 300;
    String? err;
    if (!ok) {
      if (parsed is Map && parsed['error'] != null) {
        err = '${parsed['error']}';
      } else {
        err = 'HTTP ${res.statusCode}';
      }
    }
    return UbApiResponse(ok: ok, statusCode: res.statusCode, data: parsed, error: err);
  }
}
