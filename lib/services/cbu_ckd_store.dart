import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/checksheet_models.dart';
import 'local_store.dart';

class CbuCkdStore {
  CbuCkdStore._();
  static final CbuCkdStore instance = CbuCkdStore._();

  Future<({
    List<CbuModelItem> models,
    List<CkdPartItem> ckdParts,
    List<Map<String, dynamic>> reports,
    bool fromServer,
  })> fetchMonthlyBundle(String ym) async {
    final cfg = await LocalStore.instance.getSettings();
    final base = cfg.serverApiUrl.split('?').first.trim();

    var models = UbMasterData.defaultCbuModels();
    var ckdParts = UbMasterData.defaultCkdParts();

    if (base.isNotEmpty) {
      try {
        final setRes = await http
            .get(Uri.parse('$base?action=get_settings'), headers: const {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 10));
        if (setRes.statusCode >= 200 && setRes.statusCode < 300) {
          final sj = jsonDecode(setRes.body);
          if (sj is Map && sj['status'] == 'success' && sj['data'] is Map) {
            final data = Map<String, dynamic>.from(sj['data'] as Map);
            if (data['models'] is List) {
              final parsed = (data['models'] as List)
                  .whereType<Map>()
                  .map((m) => CbuModelItem.fromJson(Map<String, dynamic>.from(m)))
                  .where((m) => m.code != 'ckd')
                  .toList();
              if (parsed.isNotEmpty) models = parsed;
            }
            if (data['ckd_parts'] is List) {
              final parsed = (data['ckd_parts'] as List)
                  .whereType<Map>()
                  .map((m) => CkdPartItem.fromJson(Map<String, dynamic>.from(m)))
                  .toList();
              if (parsed.isNotEmpty) ckdParts = parsed;
            }
          }
        }

        final repRes = await http
            .get(Uri.parse('$base?action=monthly_reports&year_month=$ym'), headers: const {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 12));
        if (repRes.statusCode >= 200 && repRes.statusCode < 300) {
          final rj = jsonDecode(repRes.body);
          if (rj is Map && rj['status'] == 'success' && rj['data'] is List) {
            final reps = (rj['data'] as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
            return (models: models, ckdParts: ckdParts, reports: reps, fromServer: true);
          }
        }
      } catch (_) {}
    }

    // Fallback to local Checksheet A3 reports
    final localReps = await LocalStore.instance.listReports();
    final mapped = localReps
        .where((r) => r.tanggal.startsWith(ym))
        .map((r) => <String, dynamic>{
              'tanggal': r.tanggal,
              'shift': r.shift,
              'model_cbu_source': r.cbuSource,
              'models_cbu': r.cbuModels.map((m) => m.toJson()).toList(),
              'ckd_parts': r.ckdParts.map((p) => p.toJson()).toList(),
            })
        .toList();
    return (models: models, ckdParts: ckdParts, reports: mapped, fromServer: false);
  }
}
