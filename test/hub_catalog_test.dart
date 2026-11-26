import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/data/hub_catalog.dart';

void main() {
  test('HubCatalog has 6 SQPCEHR pillars with matching sub-hubs', () {
    expect(HubCatalog.kpiPillars.length, 6);
    expect(
      HubCatalog.kpiPillars.map((e) => e.code).toList(),
      ['S', 'Q', 'P', 'C', 'HR', 'E'],
    );
    for (final p in HubCatalog.kpiPillars) {
      expect(HubCatalog.subHubs.containsKey(p.id), isTrue);
      expect(HubCatalog.subHubs[p.id]!.modules, isNotEmpty);
    }
  });

  test('Productivity sub-hub includes native A3 Checksheet', () {
    final prod = HubCatalog.subHubs['productivity']!;
    expect(prod.modules.length, 14);
    final checksheet = prod.modules.firstWhere((m) => m.route == '/productivity/checksheet');
    expect(checksheet.isNativeReady, isTrue);
  });

  test('Display GL Management Board has 7 pillars x 4 KPI rows', () {
    expect(HubCatalog.displayPillars.length, 7);
    expect(HubCatalog.displayRows.length, 4);
  });
}
