import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/kyt_models.dart';
import 'ub_web_api.dart';

class KytStore {
  KytStore._();
  static final KytStore instance = KytStore._();

  static String _cacheKey(int year) => 'ubf_kyt_monitoring_v1_$year';

  Future<({List<SgaMonitoringRow> rows, bool fromServer})> fetchMonitoring(int year) async {
    final res = await UbWebApi.instance.getUb({
      'action': 'get_kyt_monitoring',
      'year': '$year',
      'shift': 'ALL',
      '_t': '${DateTime.now().millisecondsSinceEpoch}',
    });
    if (res.ok && res.map['status'] == 'success' && res.map['data'] is List) {
      final rows = (res.map['data'] as List)
          .whereType<Map>()
          .map((m) => SgaMonitoringRow.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      if (rows.isNotEmpty) {
        await _saveCache(year, rows);
        return (rows: rows, fromServer: true);
      }
    }

    final cached = await _loadCache(year);
    if (cached.isNotEmpty) {
      return (rows: cached, fromServer: false);
    }

    final seed = KytMaster.defaultSeedRows();
    await _saveCache(year, seed);
    return (rows: seed, fromServer: false);
  }

  Future<({bool synced, String message})> saveKytCell({
    required int year,
    required SgaMonitoringRow row,
    required MonthlyKytStatus updatedMonth,
  }) async {
    final cached = await _loadCache(year);
    final rows = cached.isNotEmpty ? cached : KytMaster.defaultSeedRows();
    final rIdx = rows.indexWhere((r) => r.group.id == row.group.id);
    if (rIdx >= 0) {
      rows[rIdx].months[updatedMonth.monthIdx] = updatedMonth;
      await _saveCache(year, rows);
    }

    final payload = {
      'year': year,
      'month': updatedMonth.monthNumber,
      'sgaGroupId': int.tryParse(row.group.id) ?? 0,
      'status': updatedMonth.status,
      'tanggal': updatedMonth.tanggal,
      'tema': updatedMonth.tema,
      'tahap1': updatedMonth.tahap1,
      'tahap2': updatedMonth.tahap2,
      'tahap3': updatedMonth.tahap3,
      'tahap4': updatedMonth.tahap4,
      'ikrar': updatedMonth.ikrar,
      'createdBy': updatedMonth.createdBy.isNotEmpty ? updatedMonth.createdBy : row.group.tlName,
    };

    final res = await UbWebApi.instance.postUb('save_kyt_status', payload);
    if (res.ok && res.map['status'] == 'success') {
      return (
        synced: true,
        message: 'KYT ${KytMaster.monthNames[updatedMonth.monthIdx]} $year tersimpan ke MySQL!',
      );
    }
    return (
      synced: false,
      message: res.statusCode > 0
          ? 'Tersimpan di lokal (MySQL HTTP ${res.statusCode}).'
          : 'Tersimpan di lokal (offline — sync saat online).',
    );
  }

  Future<List<SgaMonitoringRow>> _loadCache(int year) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(year));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((m) => SgaMonitoringRow.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCache(int year, List<SgaMonitoringRow> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey(year), jsonEncode(rows.map((r) => r.toJson()).toList()));
  }
}
