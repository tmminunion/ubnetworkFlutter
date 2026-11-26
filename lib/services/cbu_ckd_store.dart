import '../models/checksheet_models.dart';
import 'local_store.dart';
import 'ub_web_api.dart';

class CbuCkdStore {
  CbuCkdStore._();
  static final CbuCkdStore instance = CbuCkdStore._();

  Future<({
    List<CbuModelItem> models,
    List<CkdPartItem> ckdParts,
    List<Map<String, dynamic>> reports,
    bool fromServer,
  })> fetchMonthlyBundle(String ym) async {
    var models = UbMasterData.defaultCbuModels();
    var ckdParts = UbMasterData.defaultCkdParts();

    final results = await Future.wait([
      UbWebApi.instance.getUb({'action': 'get_settings'}),
      UbWebApi.instance.getUb({'action': 'monthly_reports', 'year_month': ym}),
    ]);

    final setRes = results[0];
    final repRes = results[1];

    if (setRes.ok && setRes.map['status'] == 'success' && setRes.map['data'] is Map) {
      final data = Map<String, dynamic>.from(setRes.map['data'] as Map);
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

    if (repRes.ok && repRes.map['status'] == 'success' && repRes.map['data'] is List) {
      final reps = (repRes.map['data'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      return (models: models, ckdParts: ckdParts, reports: reps, fromServer: true);
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
