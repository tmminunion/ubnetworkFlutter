import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quality_daily_models.dart';
import 'local_store.dart';
import 'ub_web_api.dart';

class QualityDailyStore {
  QualityDailyStore._();
  static final QualityDailyStore instance = QualityDailyStore._();

  static String _key(String ym, String kind) => 'ubf_quality_daily_v1_${kind}_$ym';

  Future<QualityMonthlyRecord> loadRecord(String ym, String kind) async {
    final local = await _loadLocal(ym, kind);

    // Live sync 1:1 with Next.js /api/quality/defect & /api/quality/findings
    final results = await Future.wait([
      UbWebApi.instance.getJson('/api/quality/defect', query: {'month': ym, 'kind': kind}),
      UbWebApi.instance.getJson('/api/quality/findings', query: {'month': ym, 'kind': kind}),
    ]);

    final defectRes = results[0];
    final findRes = results[1];
    var changed = false;

    List<int?> red = local.red;
    List<int?> white = local.white;
    double targetDu = local.targetDu;
    List<QualityFinding> findings = local.findings;

    if (defectRes.ok && defectRes.map['data'] is Map) {
      final d = Map<String, dynamic>.from(defectRes.map['data'] as Map);
      List<int?> parse31(dynamic raw, List<int?> fallback) {
        if (raw is! List) return fallback;
        return List<int?>.generate(31, (i) => i < raw.length && raw[i] is num ? (raw[i] as num).toInt() : null);
      }

      red = parse31(d['red'], red);
      white = parse31(d['white'], white);
      if (d['target'] is num) targetDu = (d['target'] as num).toDouble();
      changed = true;
    }

    if (findRes.ok && findRes.map['items'] is List) {
      findings = (findRes.map['items'] as List)
          .whereType<Map>()
          .map((m) => QualityFinding.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      changed = true;
    }

    if (changed) {
      final merged = QualityMonthlyRecord(
        ym: ym,
        kind: kind,
        red: red,
        white: white,
        targetDu: targetDu,
        findings: findings,
      );
      await _saveLocal(merged);
      return merged;
    }

    return local;
  }

  Future<QualityMonthlyRecord> _loadLocal(String ym, String kind) async {
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

  Future<void> _saveLocal(QualityMonthlyRecord rec) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(rec.ym, rec.kind), jsonEncode(rec.toJson()));
  }

  Future<void> saveRecord(QualityMonthlyRecord rec) async {
    await _saveLocal(rec);
    // Sync 1:1 to Next.js PUT /api/quality/defect
    await UbWebApi.instance.putJson('/api/quality/defect', {
      'month': rec.ym,
      'kind': rec.kind,
      'data': {
        'red': rec.red,
        'white': rec.white,
        'target': rec.targetDu,
      },
    });
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
