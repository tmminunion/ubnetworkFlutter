import '../models/prod_monitoring_models.dart';
import 'local_store.dart';
import 'ub_web_api.dart';

class ProdMonitoringStore {
  ProdMonitoringStore._();
  static final ProdMonitoringStore instance = ProdMonitoringStore._();

  Future<({List<DayMonitoringRow> days, double taktTime, bool fromServer})> fetchMonthly(
    int year,
    int month,
  ) async {
    final cfg = await LocalStore.instance.getSettings();
    final monthStr = month.toString().padLeft(2, '0');

    final res = await UbWebApi.instance.getUb({
      'action': 'get_monthly_monitoring',
      'year': '$year',
      'month': monthStr,
    });
    if (res.ok && res.map['status'] == 'success' && res.map['days'] is List) {
      final days = (res.map['days'] as List)
          .whereType<Map>()
          .map((m) => DayMonitoringRow.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      final tt = res.map['taktTime'] is num ? (res.map['taktTime'] as num).toDouble() : cfg.taktTime;
      if (days.isNotEmpty) {
        return (days: days, taktTime: tt, fromServer: true);
      }
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
