import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/services/ub_web_api.dart';

void main() {
  group('UbWebApi.extractCookieHeader', () {
    test('extracts clean ub_gate cookie pair from raw Set-Cookie header', () {
      const raw = 'ub_gate=eyJhbGciOiJIUzI1NiJ9.abc.def; Path=/; HttpOnly; Secure; SameSite=Lax';
      expect(UbWebApi.extractCookieHeader(raw), 'ub_gate=eyJhbGciOiJIUzI1NiJ9.abc.def');
    });

    test('handles multiple cookies combined in a single Set-Cookie header', () {
      const raw = 'ub_gate=tok123; Path=/; HttpOnly, ub_shift=RED; Path=/; Max-Age=3600';
      expect(UbWebApi.extractCookieHeader(raw), 'ub_gate=tok123; ub_shift=RED');
    });

    test('returns empty string for null or empty cookie', () {
      expect(UbWebApi.extractCookieHeader(null), '');
      expect(UbWebApi.extractCookieHeader('   '), '');
    });
  });
}
