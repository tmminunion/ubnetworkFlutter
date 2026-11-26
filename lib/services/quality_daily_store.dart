import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quality_daily_models.dart';
import 'local_store.dart';

class QualityDailyStore {
  QualityDailyStore._();
  static final QualityDailyStore instance = QualityDailyStore._();

  static String _key(String ym, String kind) => 'ubf_quality_daily_v1_${kind}_$ym';

  Future<QualityMonthlyRecord> loadRecord(String ym, String kind) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(ym, kind));
    if (raw == null || raw.isEmpty) {
      return QualityMonthlyRecord(ym: ym, kind: kind);
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return QualityMonthlyRecord.fromJson(decoded, ym: ym, kind: kind);
    } catch (_) {
      return QualityMonthlyRecord(ym: ym, kind: kind);
    }
  }

  Future<void> saveRecord(QualityMonthlyRecord rec) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(rec.ym, rec.kind), jsonEncode(rec.toJson()));
  }

  Future<MonthlyProdData?> fetchMonthlyProd(String ym) async {
    final cfg = await LocalStore.instance.getSettings();
    final base = cfg.serverApiUrl.split('?').first.trim();
    if (base.isEmpty) return null;

    final parts = ym.split('-');
    if (parts.length < 2) return null;
    try {
      final uri = Uri.parse('$base?action=get_monthly_monitoring&year=${parts[0]}&month=${parts[1]}');
      final res = await http.get(uri, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 10));
      if (res.statusCode < 200 || res.statusCode >= 300) return null;
      final json = jsonDecode(res.body);
      if (json is! Map || json['status'] != 'success' || json['days'] is! List) return null;
      final days = json['days'] as List;

      int? parseAct(dynamic raw) {
        if (raw is! Map) return null;
        if (raw['isSaved'] != true) return null;
        final a = raw['act'];
        return a is num ? a.toInt() : (int.tryParse('${a ?? 0}') ?? 0);
      }

      return MonthlyProdData(
        red: days.map((d) => d is Map ? parseAct(d['red']) : null).toList(),
        white: days.map((d) => d is Map ? parseAct(d['white']) : null).toList(),
        weekend: days.map((d) => d is Map && d['isWeekend'] == true).toList(),
      );
    } catch (_) {
      return null;
    }
  }
}
