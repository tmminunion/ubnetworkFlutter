import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/data/hub_catalog.dart';
import 'package:ubnetwork_flutter/models/checksheet_models.dart';
import 'package:ubnetwork_flutter/models/roster_attendance_models.dart';

void main() {
  test('RosterAttendanceMath computes roster stats and local attendance fallback', () {
    final roster = [
      RosterMember(id: 1, name: 'A', role: 'GL', statusKaryawan: 'PERMANEN'),
      RosterMember(id: 2, name: 'B', role: 'TL', statusKaryawan: 'KONTRAK'),
      RosterMember(id: 3, name: 'C', role: 'TM', statusKaryawan: 'VOKASI'),
    ];
    final st = RosterAttendanceMath.computeRosterStats(roster);
    expect(st.total, 3);
    expect(st.gl, 1);
    expect(st.tl, 1);
    expect(st.tm, 1);
    expect(st.permanen, 1);
    expect(st.kontrak, 1);
    expect(st.vokasi, 1);

    final members = UbMasterData.defaultMembers('WHITE');
    members.first.status = 'Sakit';
    final rep = ChecksheetReport(
      id: '2026-11-10_WHITE_UB_ASSY',
      tanggal: '2026-11-10',
      shift: 'WHITE',
      taktTime: 2.4,
      cbuModels: UbMasterData.defaultCbuModels(),
      ckdParts: UbMasterData.defaultCkdParts(),
      members: members,
      slots: UbMasterData.buildSlotsFromTemplate('pagi_normal', 2.4, 2),
    );

    final att = RosterAttendanceMath.buildLocalAttendance('2026-11', 'WHITE', [rep]);
    expect(att.kpi.totalSakit, 1);
    expect(att.kpi.totalHadir, members.length - 1);
  });

  test('Productivity sub-hub marks roster and absensi as native ready', () {
    final prod = HubCatalog.subHubs['productivity']!;
    final ready = prod.modules.where((m) => m.isNativeReady).map((m) => m.route).toSet();
    expect(ready, containsAll(['/productivity/roster', '/productivity/absensi']));
  });
}
