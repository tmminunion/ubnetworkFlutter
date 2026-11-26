import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/data/hub_catalog.dart';
import 'package:ubnetwork_flutter/models/chokotei_models.dart';

void main() {
  test('ChokoteiMath computes Pareto 80/20 ranking and stats accurately', () {
    final issues = [
      ChokoteiIssue(id: '1', tanggal: '2026-11-05', shift: 'RED', machine: 'ST 10', category: 'INT', problem: 'Sensor kotor', lossUnits: 7, delayMin: 17, actionStatus: 'solved'),
      ChokoteiIssue(id: '2', tanggal: '2026-11-06', shift: 'RED', machine: 'ST 10', category: 'INT', problem: 'Clamp macet', lossUnits: 1, delayMin: 3, actionStatus: 'open'),
      ChokoteiIssue(id: '3', tanggal: '2026-11-07', shift: 'RED', machine: 'ST 20', category: 'EXT', problem: 'Material telat', lossUnits: 2, delayMin: 5, actionStatus: 'in_progress'),
    ];

    final stats = ChokoteiMath.computeStats(issues);
    expect(stats.totalRecords, 3);
    expect(stats.totalLoss, 10);
    expect(stats.totalDelay, 25);
    expect(stats.intCount, 2);
    expect(stats.extCount, 1);
    expect(stats.solvedPercent, 33);

    final pareto = ChokoteiMath.computePareto(issues);
    expect(pareto.first.machine, 'ST 10');
    expect(pareto.first.totalLoss, 8);
    expect(pareto.first.cumLossPercent, 80.0);
    expect(pareto.first.isVitalFew, isTrue);
    expect(pareto[1].machine, 'ST 20');
    expect(pareto[1].cumLossPercent, 100.0);
    expect(pareto[1].isVitalFew, isFalse);
  });

  test('Productivity sub-hub marks chokotei and chokotei-manual as native ready', () {
    final prod = HubCatalog.subHubs['productivity']!;
    final ready = prod.modules.where((m) => m.isNativeReady).map((m) => m.route).toSet();
    expect(ready, containsAll(['/productivity/chokotei', '/productivity/chokotei-manual']));
  });
}
