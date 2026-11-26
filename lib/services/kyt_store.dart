import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/kyt_models.dart';
import 'local_store.dart';

class KytStore {
  KytStore._();
  static final KytStore instance = KytStore._();

  static String _cacheKey(int year) => 'ubf_kyt_monitoring_v1_$year';

  Future<({List<SgaMonitoringRow> rows, bool fromServer})> fetchMonitoring(int year) async {
    final cfg = await LocalStore.instance.getSettings();
    final base = cfg.serverApiUrl.split('?').first.trim();

    if (base.isNotEmpty) {
      try {
        final uri = Uri.parse('$base?action=get_kyt_monitoring&year=$year&shift=ALL&_t=${DateTime.now().millisecondsSinceEpoch}');
        final res = await http.get(uri, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 12));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final json = jsonDecode(res.body);
          if (json is Map && json['status'] == 'success' && json['data'] is List) {
            final rows = (json['data'] as List)
                .whereType<Map>()
                .map((m) => SgaMonitoringRow.fromJson(Map<String, dynamic>.from(m)))
                .toList();
            if (rows.isNotEmpty) {
              await _saveCache(year, rows);
              return (rows: rows, fromServer: true);
            }
          }
        }
      } catch (_) {
        // Fallback to local cache seamlessly
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
    // 1. Update local cache first (offline-first)
    final cached = await _loadCache(year);
    final rows = cached.isNotEmpty ? cached : KytMaster.defaultSeedRows();
    final rIdx = rows.indexWhere((r) => r.group.id == row.group.id);
    if (rIdx >= 0) {
      rows[rIdx].months[updatedMonth.monthIdx] = updatedMonth;
      await _saveCache(year, rows);
    }

    // 2. Push to MySQL bungtemin.net
    final cfg = await LocalStore.instance.getSettings();
    final base = cfg.serverApiUrl.split('?').first.trim();
    if (base.isEmpty) {
      return (synced: false, message: 'Tersimpan di lokal (Server API kosong).');
    }

    try {
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

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (cfg.apiKey.trim().isNotEmpty) {
        headers['x-ub-api-key'] = cfg.apiKey.trim();
      }

      final res = await http
          .post(
            Uri.parse('$base?action=save_kyt_status'),
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(res.body);
        if (json is Map && json['status'] == 'success') {
          return (
            synced: true,
            message: 'KYT ${KytMaster.monthNames[updatedMonth.monthIdx]} $year tersimpan ke MySQL!',
          );
        }
      }
      return (synced: false, message: 'Tersimpan di lokal (MySQL HTTP ${res.statusCode}).');
    } catch (_) {
      return (synced: false, message: 'Tersimpan di lokal (offline — sync saat online).');
    }
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
