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

  test('defaultTemplateCode selects weekday, Friday, night, and puasa templates 1:1 with Next.js', () {
    // 2026-11-26 is Thursday -> pagi_normal
    expect(UbMasterData.defaultTemplateCode('2026-11-26'), 'pagi_normal');
    // 2026-11-27 is Friday -> jumat_normal
    expect(UbMasterData.defaultTemplateCode('2026-11-27'), 'jumat_normal');
    expect(UbMasterData.defaultTemplateCode('2026-11-27', workMode: 'puasa'), 'jumat_puasa');
    expect(UbMasterData.defaultTemplateCode('2026-11-26', session: 'night'), 'malam_normal');
    expect(UbMasterData.defaultTemplateCode('2026-11-26', session: 'night', workMode: 'puasa'), 'malam_puasa');
  });

  test('createTemplateReport generates clean template draft with zero user edits and auto body start/finish', () {
    final cfg = UbSettings(lineName: 'UB Assy', taktTime: 1.9, ccrTargetWhite: 220);
    final rep = UbMasterData.createTemplateReport(
      date: '2026-11-27', // Friday
      shift: 'WHITE',
      cfg: cfg,
      prevCarry: (finish: '01000', label: 'RED Malam (2026-11-26)'),
    );
    expect(rep.templateCode, 'jumat_normal');
    expect(rep.hasUserEdits, isFalse);
    expect(rep.noBodyStart, '01001');
    expect(rep.noBodyFinish, '01220');
    expect(rep.slots.length, 11);
    expect(rep.slots.where((s) => !s.isBlocked).length, 10); // 8 regular + 2 OT
  });

  test('UbSettings auto-migrates legacy unauthenticated bungtemin URL to Next.js /api/ub gateway', () {
    final migrated = UbSettings.fromJson({
      'lineName': 'UB ASSY',
      'serverApiUrl': 'https://bungtemin.net/ub/api',
      'apiKey': '',
    });
    expect(migrated.serverApiUrl, 'https://ubnetwork.vercel.app/api/ub');
    expect(migrated.lineName, 'UB Assy');
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
