import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prod_monitoring_models.dart';
import 'local_store.dart';

class ProdMonitoringStore {
  ProdMonitoringStore._();
  static final ProdMonitoringStore instance = ProdMonitoringStore._();

  Future<({List<DayMonitoringRow> days, double taktTime, bool fromServer})> fetchMonthly(
    int year,
    int month,
  ) async {
    final cfg = await LocalStore.instance.getSettings();
    final base = cfg.serverApiUrl.split('?').first.trim();
    final monthStr = month.toString().padLeft(2, '0');

    if (base.isNotEmpty) {
      try {
        final uri = Uri.parse('$base?action=get_monthly_monitoring&year=$year&month=$monthStr');
        final res = await http.get(uri, headers: const {'Accept': 'application/json'}).timeout(const Duration(seconds: 12));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final json = jsonDecode(res.body);
          if (json is Map && json['status'] == 'success' && json['days'] is List) {
            final days = (json['days'] as List)
                .whereType<Map>()
                .map((m) => DayMonitoringRow.fromJson(Map<String, dynamic>.from(m)))
                .toList();
            final tt = json['taktTime'] is num ? (json['taktTime'] as num).toDouble() : cfg.taktTime;
            if (days.isNotEmpty) {
              return (days: days, taktTime: tt, fromServer: true);
            }
          }
        }
      } catch (_) {}
    }

    final localReports = await LocalStore.instance.listReports();
    final fallback = ProdMonitoringMath.buildLocalFallbackDays(
      year,
      month,
      localReports,
      taktTime: cfg.taktTime,
    );
    return (days: fallback, taktTime: cfg.taktTime, fromServer: false);
  }
}
