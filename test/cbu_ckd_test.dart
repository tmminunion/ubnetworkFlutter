import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/data/hub_catalog.dart';
import 'package:ubnetwork_flutter/models/cbu_ckd_models.dart';
import 'package:ubnetwork_flutter/models/checksheet_models.dart';

void main() {
  test('CbuCkdMath aggregates CBU models and CKD parts across 1-31 accurately', () {
    final models = UbMasterData.defaultCbuModels();
    final parts = UbMasterData.defaultCkdParts();
    final rawReports = [
      {
        'tanggal': '2026-11-10',
        'shift': 'WHITE',
        'model_cbu_source': 'ratio',
        'models_cbu': [
          {'code': 'zenix', 'qty': 120},
          {'code': 'fortuner', 'qty': 80},
        ],
        'ckd_parts': [
          {'part_no': '57403-KK010', 'qty': 40},
          {'part_no': '57404-KK010', 'qty': 35},
        ],
      },
    ];

    final cbuDays = CbuCkdMath.aggregateCbu(
      ym: '2026-11',
      shiftFilter: 'ALL',
      modelsConfig: models,
      rawReports: rawReports,
    );
    final cbuSum = CbuCkdMath.summarizeCbu(cbuDays, models);
    expect(cbuSum.grandTotal, 200);
    expect(cbuSum.topModelName, 'INNOVA ZENIX');
    expect(cbuSum.ratioDays, 1);

    final ckdDays = CbuCkdMath.aggregateCkd(
      ym: '2026-11',
      shiftFilter: 'ALL',
      partsConfig: parts,
      rawReports: rawReports,
    );
    final ckdSum = CbuCkdMath.summarizeCkd(ckdDays, parts);
    expect(ckdSum.grandTotal, 75);
    expect(ckdSum.topPartNo, '57403-KK010');
  });

  test('Productivity sub-hub marks cbu and ckd as native ready', () {
    final prod = HubCatalog.subHubs['productivity']!;
    final ready = prod.modules.where((m) => m.isNativeReady).map((m) => m.route).toSet();
    expect(ready, containsAll(['/productivity/cbu', '/productivity/ckd']));
  });
}
