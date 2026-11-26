import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/models/checksheet_models.dart';

void main() {
  test('Hamilton-Hare CBU ratio distribution sums exactly to target', () {
    final models = UbMasterData.defaultCbuModels();
    final res = UbMasterData.calculateCbuByRatio(220, models);
    final total = res.fold<int>(0, (a, m) => a + m.qty);
    expect(total, 220);
    expect(res.firstWhere((m) => m.code == 'zenix').qty, greaterThan(100));
  });

  test('addNumberPreservePad increments and preserves leading zeros', () {
    expect(UbMasterData.addNumberPreservePad('39515', 1), '39516');
    expect(UbMasterData.addNumberPreservePad('00999', 1), '01000');
  });

  test('defaultCkdParts uses real master CKD parts', () {
    final parts = UbMasterData.defaultCkdParts();
    expect(parts.length, 2);
    expect(parts[0].partNo, '57403-KK010');
    expect(parts[1].partNo, '57404-KK010');
  });

  test('computeStats aggregates plan, act, diff, and internal efficiency', () {
    final slots = UbMasterData.buildSlotsFromTemplate('pagi_normal', 1.9, 2);
    slots[0].act = slots[0].plan;
    slots[1].act = slots[1].plan - 2;
    slots[1].problems.add(ChokoteiProblem(
      id: 'p1',
      lineStation: 'ST 10',
      problem: 'Sensor kotor',
      lossUnits: 2,
      delayMin: 3.8,
      category: 'INT',
    ));

    final rep = ChecksheetReport(
      id: '2026-11-26_WHITE_UB_ASSY',
      tanggal: '2026-11-26',
      shift: 'WHITE',
      taktTime: 1.9,
      cbuModels: UbMasterData.defaultCbuModels(),
      ckdParts: UbMasterData.defaultCkdParts(),
      members: UbMasterData.defaultMembers('WHITE'),
      slots: slots,
    );

    final st = UbMasterData.computeStats(rep);
    expect(st.totalAct, slots[0].plan + slots[1].plan - 2);
    expect(st.diff, -2);
    expect(st.intDelayMin, 3.8);
    expect(st.intProblems.length, 1);
  });
}
