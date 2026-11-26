import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/models/checksheet_models.dart';
import 'package:ubnetwork_flutter/services/local_store.dart';

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

  test('parseServerReportPayload restores MySQL get_report payload 1:1 with Next.js', () {
    final decoded = <String, dynamic>{
      'status': 'success',
      'found': true,
      'laporan': {
        'id': 147,
        'tanggal': '2026-11-26',
        'shift': 'WHITE',
        'line_name': 'UB ASSY',
        'pic_name': 'DWI MULYONO',
        'spv_name': 'DADANG SURYADI / NUNU FATULAH / FERDIANSYAH',
        'takt_time': 2.4,
        'template_code': 'pagi_normal',
        'total_plan': 230,
        'total_act': 222,
        'total_diff': -8,
        'int_delay_min': 0,
        'ext_delay_min': 17,
        'no_body_start': '40348',
        'no_body_finish': '40569',
        'jam_stop_produksi': '17:53',
        'act_ot_hours': '1.5',
        'act_ot_units': 48,
        'ccr_plan': 221,
        'ot_plan_hours': '1.5',
        'ot_plan_units': 48,
        'model_cbu_source': 'ratio',
        'models_cbu': [
          {'code': 'innova', 'name': 'KIJANG INNOVA', 'ratio': 0.048, 'qty': 11},
          {'code': 'fortuner', 'name': 'FORTUNER', 'ratio': 0.401, 'qty': 89},
          {'code': 'zenix', 'name': 'INNOVA ZENIX', 'ratio': 0.551, 'qty': 122},
        ],
        'ckd_parts': [
          {'part_no': '57403-KK010', 'part_name': 'Member Floor Side Inner RR RH', 'qty': 40},
          {'part_no': '57404-KK010', 'part_name': 'Member Floor Side Inner RR LH', 'qty': 40},
        ],
      },
      'members': [
        {'id': 12, 'name': 'DWI MULYONO', 'noreg': '00011044', 'status': 'Hadir', 'note': 'GL • GL'},
        {'id': 19, 'name': 'FERDIANSYAH', 'noreg': '01121564', 'status': 'Cuti', 'note': 'TL • Senior Member'},
      ],
      'issues': [
        {'slot_no': 1, 'time_range': '07:20 - 08:20', 'plan': 25, 'act': 25, 'is_blocked': 0},
        {
          'slot_no': 4,
          'time_range': '10:40 - 11:45',
          'plan': 27,
          'act': 24,
          'category': 'EXT',
          'delay_min': 7,
          'loss_units': 3,
          'is_blocked': 0,
          'problems': [
            {
              'id': 'p-1',
              'line_station': 'UB ENC',
              'machine_name': 'UB ENC',
              'loss_units': 3,
              'delay_min': 7,
              'problem': 'Part Melengkung',
              'category': 'EXT',
            },
          ],
        },
        {'slot_no': 9, 'time_range': '16:15 - 17:15', 'plan': 25, 'act': 25, 'is_blocked': 0},
        {'slot_no': 10, 'time_range': '17:15 - 18:15', 'plan': 16, 'act': 16, 'is_blocked': 0},
        {'slot_no': 11, 'time_range': '18:30 - 19:30', 'plan': 0, 'act': null, 'is_blocked': 1},
      ],
    };

    final cfg = UbSettings();
    final rep = LocalStore.instance.parseServerReportPayload(
      decoded: decoded,
      lap: Map<String, dynamic>.from(decoded['laporan'] as Map),
      fallbackDate: '2026-11-26',
      fallbackShift: 'WHITE',
      effectiveLine: 'UB ASSY',
      effectiveTakt: 2.4,
      cfg: cfg,
      struct: (
        gl: 'DWI MULYONO',
        tl: 'DADANG SURYADI / NUNU FATULAH',
        members: UbMasterData.defaultMembers('WHITE'),
      ),
      masterCbu: null,
      masterCkd: null,
      templates: UbMasterData.masterTemplates,
      prevCarry: null,
    );

    final stats = UbMasterData.computeStats(rep);
    expect(rep.syncStatus, 'synced');
    expect(rep.noBodyStart, '40348');
    expect(rep.noBodyFinish, '40569');
    expect(rep.ccrPlan, 221);
    expect(stats.extDelayMin, 17.0);
    expect(stats.intDelayMin, 0.0);
    expect(stats.otPlanHours, 1.5);
    expect(stats.otPlanUnits, 48);
    expect(stats.absentCount, 1);
    expect(stats.totalCbu, 222);
  });

  test('createTemplateReport applies fractional monthly_plan OT hours and units accurately', () {
    final cfg = UbSettings(lineName: 'UB ASSY', taktTime: 2.4, ccrTargetWhite: 220);
    final rep = UbMasterData.createTemplateReport(
      date: '2026-11-27',
      shift: 'WHITE',
      cfg: cfg,
      sessionOverride: 'day',
      overtimeHours: 1,
      planOtHoursOverride: 0.5,
      planOtUnitsOverride: 16,
      ccrOverride: 197,
      prevCarry: (finish: '40777', label: 'RED Malam (2026-11-26)'),
    );
    final stats = UbMasterData.computeStats(rep);
    expect(rep.noBodyStart, '40778');
    expect(rep.noBodyFinish, '40974');
    expect(stats.effectiveCcrPlan, 197);
    expect(stats.otPlanHours, 0.5);
    expect(stats.otPlanUnits, 16);
    expect(rep.slots.firstWhere((s) => s.no == 9).plan, 16);
  });
}
