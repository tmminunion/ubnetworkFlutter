import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/data/hub_catalog.dart';
import 'package:ubnetwork_flutter/models/checksheet_models.dart';
import 'package:ubnetwork_flutter/models/prod_monitoring_models.dart';

void main() {
  test('ProdMonitoringMath builds 1-31 fallback days and merges local checksheet reports', () {
    final rep = UbMasterData.createBlankReport(tanggal: '2026-11-05', shift: 'WHITE', taktTime: 2.4);
    rep.slots.first.act = 25;
    final days = ProdMonitoringMath.buildLocalFallbackDays(2026, 11, [rep], taktTime: 2.4);
    expect(days.length, 30);

    final day5 = days.firstWhere((d) => d.dayNumber == 5);
    expect(day5.white.isSaved, isTrue);
    expect(day5.white.act, 25);

    final kpi = ProdMonitoringMath.computeKpi(days, 'WHITE');
    expect(kpi.totalAct, 25);
    expect(kpi.totalPlan, greaterThan(0));
  });

  test('Productivity sub-hub marks /productivity/monitoring as native ready', () {
    final prod = HubCatalog.subHubs['productivity']!;
    final mon = prod.modules.firstWhere((m) => m.route == '/productivity/monitoring');
    expect(mon.isNativeReady, isTrue);
  });
}
