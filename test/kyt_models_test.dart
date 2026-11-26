import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/data/hub_catalog.dart';
import 'package:ubnetwork_flutter/models/kyt_models.dart';

void main() {
  test('KytMaster seed rows separate WHITE and RED shifts with 12 months each', () {
    final rows = KytMaster.defaultSeedRows();
    final white = rows.where((r) => r.group.shift == 'WHITE').toList();
    final red = rows.where((r) => r.group.shift == 'RED').toList();
    expect(white.length, 3);
    expect(red.length, 2);
    for (final r in rows) {
      expect(r.months.length, 12);
    }
  });

  test('KytMaster.computeShiftStats calculates targetYear, completedYtd, and compliancePercent', () {
    final rows = KytMaster.defaultSeedRows().where((r) => r.group.shift == 'RED').toList();
    rows[0].months[0].status = 'done';
    rows[0].months[1].status = 'done';
    rows[1].months[0].status = 'done';
    rows[1].months[1].status = 'pending';

    final stats = KytMaster.computeShiftStats(rows);
    expect(stats.targetYear, 24);
    expect(stats.completedYtd, 3);
    expect(stats.compliancePercent, 13); // round(3/24*100) = 13
  });

  test('SgaMonitoringRow JSON round-trip preserves group and 12 months', () {
    final row = KytMaster.defaultSeedRows().first;
    row.months[5]
      ..status = 'done'
      ..tema = 'Bahaya terjepit jig'
      ..ikrar = 'Zero Accident, Yoshi!';
    final restored = SgaMonitoringRow.fromJson(row.toJson());
    expect(restored.group.code, row.group.code);
    expect(restored.months.length, 12);
    expect(restored.months[5].status, 'done');
    expect(restored.months[5].tema, 'Bahaya terjepit jig');
    expect(restored.completedCount, 1);
  });

  test('Safety sub-hub marks /kyt/monitoring as native ready', () {
    final safety = HubCatalog.subHubs['safety']!;
    final kyt = safety.modules.firstWhere((m) => m.route == '/kyt/monitoring');
    expect(kyt.isNativeReady, isTrue);
  });
}
