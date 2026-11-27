import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/quality_daily_models.dart';
import 'ub_web_api.dart';

class QualityDailyStore {
  QualityDailyStore._();
  static final QualityDailyStore instance = QualityDailyStore._();

  static String _key(String ym, String kind) => 'ubf_quality_daily_v1_${kind}_$ym';

  /// 1:1 with `defectKeys(kind)` in `ubnetwork/app/display/qualityDaily.ts`:
  /// - `out` -> `red`, `white`, `target`
  /// - `in`  -> `inRed`, `inWhite`, `inTarget`
  static ({String red, String white, String target}) _keysForKind(String kind) =>
      kind == 'in'
          ? (red: 'inRed', white: 'inWhite', target: 'inTarget')
          : (red: 'red', white: 'white', target: 'target');

  Future<QualityMonthlyRecord> loadRecord(String ym, String kind) async {
    final local = await _loadLocal(ym, kind);
    final keys = _keysForKind(kind);

    final results = await Future.wait([
      UbWebApi.instance.getJson('/api/quality/defect', query: {'month': ym}),
      UbWebApi.instance.getJson('/api/quality/findings', query: {'month': ym, 'kind': kind}),
    ]);

    final defectRes = results[0];
    final findRes = results[1];
    var changed = false;

    double targetDu = local.targetDu;
    Set<int> redZeroDays = Set<int>.from(local.redZeroDays);
    Set<int> whiteZeroDays = Set<int>.from(local.whiteZeroDays);
    List<QualityFinding> findings = List<QualityFinding>.from(local.findings);

    if (defectRes.ok) {
      if (defectRes.map['data'] is Map) {
        final d = Map<String, dynamic>.from(defectRes.map['data'] as Map);
        final rawTarget = d[keys.target];
        if (rawTarget is num && rawTarget > 0) {
          targetDu = rawTarget.toDouble();
        }
        Set<int> extractZeroDays(dynamic raw, Set<int> fallback) {
          if (raw is! List) return fallback;
          final out = <int>{};
          for (var i = 0; i < raw.length && i < 31; i++) {
            if (raw[i] is num && (raw[i] as num).toInt() == 0) out.add(i + 1);
          }
          return out;
        }

        if (d[keys.red] is List) redZeroDays = extractZeroDays(d[keys.red], redZeroDays);
        if (d[keys.white] is List) whiteZeroDays = extractZeroDays(d[keys.white], whiteZeroDays);
      } else if (defectRes.map['source'] == 'atlas' && defectRes.map['data'] == null) {
        redZeroDays = <int>{};
        whiteZeroDays = <int>{};
      }
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
        targetDu: targetDu,
        redZeroDays: redZeroDays,
        whiteZeroDays: whiteZeroDays,
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

  /// Toggle Zero Defect cell 1:1 via `PATCH /api/quality/defect`
  /// so Red & White or Out & In never overwrite each other.
  Future<bool> saveZeroCell(QualityMonthlyRecord rec, String team, int day) async {
    await _saveLocal(rec);
    final val = QualityMath.dayDefect(rec, team, day);
    final res = await UbWebApi.instance.patchJson('/api/quality/defect', {
      'month': rec.ym,
      'kind': rec.kind,
      'team': team,
      'day': day,
      'value': val,
    });
    return res.ok;
  }

  /// Update monthly Target D/U 1:1 via `PATCH /api/quality/defect`.
  Future<bool> saveTargetDu(QualityMonthlyRecord rec) async {
    await _saveLocal(rec);
    final res = await UbWebApi.instance.patchJson('/api/quality/defect', {
      'month': rec.ym,
      'kind': rec.kind,
      'target': rec.targetDu,
    });
    return res.ok;
  }

  /// Upsert Quality Finding 1:1 via `POST /api/quality/findings` (new)
  /// or `PUT /api/quality/findings/[id]` (existing `q<seq>`).
  /// Server automatically recomputes `defect_daily` cell count!
  Future<QualityFinding> upsertFinding(QualityMonthlyRecord rec, QualityFinding item) async {
    final idx = rec.findings.indexWhere((f) => f.id == item.id);
    if (idx >= 0) {
      rec.findings[idx] = item;
    } else {
      rec.findings.insert(0, item);
    }
    await _saveLocal(rec);

    final payload = item.toServerPayload();
    final res = item.isServerId
        ? await UbWebApi.instance.putJson('/api/quality/findings/${Uri.encodeComponent(item.id)}', payload)
        : await UbWebApi.instance.postJson('/api/quality/findings', payload);

    if (res.ok && res.map['item'] is Map) {
      final synced = QualityFinding.fromJson(Map<String, dynamic>.from(res.map['item'] as Map));
      final repIdx = rec.findings.indexWhere((f) => f.id == item.id || f.id == synced.id);
      if (repIdx >= 0) {
        rec.findings[repIdx] = synced;
      } else {
        rec.findings.insert(0, synced);
      }
      await _saveLocal(rec);
      return synced;
    }

    return item;
  }

  /// Delete Quality Finding 1:1 via `DELETE /api/quality/findings/[id]`.
  Future<bool> deleteFinding(QualityMonthlyRecord rec, String id) async {
    rec.findings.removeWhere((f) => f.id == id);
    await _saveLocal(rec);

    if (!RegExp(r'^q\d{1,9}$').hasMatch(id.trim())) return true;
    final res = await UbWebApi.instance.deleteJson('/api/quality/findings/${Uri.encodeComponent(id.trim())}');
    return res.ok;
  }

  Future<void> saveRecord(QualityMonthlyRecord rec) async {
    await _saveLocal(rec);
    final keys = _keysForKind(rec.kind);
    List<int?> buildDailyCounts(String team, Set<int> zeroDays) {
      final arr = List<int?>.filled(31, null);
      for (final d in zeroDays) {
        if (d >= 1 && d <= 31) arr[d - 1] = 0;
      }
      for (final f in rec.findings) {
        if (f.team != team) continue;
        final parts = f.date.split('-');
        final day = parts.length >= 3 ? int.tryParse(parts[2]) : null;
        if (day != null && day >= 1 && day <= 31) {
          arr[day - 1] = (arr[day - 1] ?? 0) + f.qty;
        }
      }
      return arr;
    }

    await UbWebApi.instance.putJson('/api/quality/defect', {
      'month': rec.ym,
      'data': {
        keys.red: buildDailyCounts('red', rec.redZeroDays),
        keys.white: buildDailyCounts('white', rec.whiteZeroDays),
        keys.target: rec.targetDu,
      },
    });
  }

  Future<MonthlyProdData?> fetchMonthlyProd(String ym) async {
    final parts = ym.split('-');
    if (parts.length < 2) return null;
    final res = await UbWebApi.instance.getUb({
      'action': 'get_monthly_monitoring',
      'year': parts[0],
      'month': parts[1],
    });
    if (!res.ok || res.map['status'] != 'success' || res.map['days'] is! List) return null;
    final days = res.map['days'] as List;

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
  }
}
