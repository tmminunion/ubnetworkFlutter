// 1:1 Dart port of ubnetwork/app/productivity/members/page.tsx & attendance/page.tsx

import 'checksheet_models.dart';

class RosterMember {
  RosterMember({
    required this.id,
    required this.name,
    this.noreg = '',
    this.phone = '',
    this.idCard = '',
    this.rfidCode = '',
    this.role = 'TM',
    this.shift = 'RED',
    this.defaultPos = 'Pos 1',
    this.statusKaryawan = 'PERMANEN',
    this.isActive = true,
    this.notes = '',
  });

  final int id;
  final String name;
  final String noreg;
  final String phone;
  final String idCard;
  final String rfidCode;
  final String role; // GL | TL | TM
  final String shift; // RED | WHITE
  final String defaultPos;
  final String statusKaryawan; // PERMANEN | KONTRAK | VOKASI
  final bool isActive;
  final String notes;

  static String inferStatus(Map<String, dynamic> m) {
    final raw = '${m['status_karyawan'] ?? ''}'.toUpperCase().trim();
    if (raw == 'PERMANEN' || raw == 'KONTRAK' || raw == 'VOKASI') return raw;
    final notes = '${m['notes'] ?? ''}'.toLowerCase();
    if (notes.contains('vokasi') || notes.contains('magang')) return 'VOKASI';
    if (notes.contains('kontrak')) return 'KONTRAK';
    return 'PERMANEN';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'noreg': noreg,
        'phone': phone,
        'id_card': idCard,
        'rfid_code': rfidCode,
        'role': role,
        'shift': shift,
        'default_pos': defaultPos,
        'status_karyawan': statusKaryawan,
        'is_active': isActive ? 1 : 0,
        'notes': notes,
      };

  factory RosterMember.fromJson(Map<String, dynamic> json) {
    final r = '${json['role'] ?? 'TM'}'.toUpperCase();
    final safeRole = (r == 'GL' || r == 'TL') ? r : 'TM';
    return RosterMember(
      id: json['id'] is num ? (json['id'] as num).toInt() : (int.tryParse('${json['id'] ?? 0}') ?? 0),
      name: (json['name'] ?? '').toString(),
      noreg: (json['noreg'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      idCard: (json['id_card'] ?? '').toString(),
      rfidCode: (json['rfid_code'] ?? '').toString(),
      role: safeRole,
      shift: '${json['shift'] ?? 'RED'}'.toUpperCase() == 'WHITE' ? 'WHITE' : 'RED',
      defaultPos: (json['default_pos'] ?? 'Pos 1').toString(),
      statusKaryawan: inferStatus(json),
      isActive: json['is_active'] == null ? true : (json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1'),
      notes: (json['notes'] ?? '').toString(),
    );
  }
}

class RosterStats {
  const RosterStats({
    required this.total,
    required this.gl,
    required this.tl,
    required this.tm,
    required this.permanen,
    required this.kontrak,
    required this.vokasi,
  });

  final int total;
  final int gl;
  final int tl;
  final int tm;
  final int permanen;
  final int kontrak;
  final int vokasi;
}

class MemberAttendanceRow {
  MemberAttendanceRow({
    required this.id,
    required this.name,
    this.noreg = '',
    this.role = 'TM',
    this.shift = 'WHITE',
    this.defaultPos = 'Pos 1',
    this.hadirCount = 0,
    this.sakitCount = 0,
    this.izinCount = 0,
    this.cutiCount = 0,
    this.dinasCount = 0,
    this.alpaCount = 0,
    this.totalAbsent = 0,
    this.attendanceRate = 100,
    Map<String, String>? history,
  }) : history = history ?? <String, String>{};

  final int id;
  final String name;
  final String noreg;
  final String role;
  final String shift;
  final String defaultPos;
  final int hadirCount;
  final int sakitCount;
  final int izinCount;
  final int cutiCount;
  final int dinasCount;
  final int alpaCount;
  final int totalAbsent;
  final double attendanceRate;
  final Map<String, String> history; // YYYY-MM-DD -> Hadir/Sakit/Izin/Cuti/Dinas/Alpa

  static int _asInt(dynamic v) => v is num ? v.toInt() : (int.tryParse('${v ?? 0}') ?? 0);
  static double _asDouble(dynamic v, [double fb = 100]) => v is num ? v.toDouble() : (double.tryParse('${v ?? ''}') ?? fb);

  factory MemberAttendanceRow.fromJson(Map<String, dynamic> json) {
    final hist = <String, String>{};
    if (json['history'] is Map) {
      (json['history'] as Map).forEach((k, v) {
        if (v != null && '$v'.isNotEmpty) hist['$k'] = '$v';
      });
    }
    return MemberAttendanceRow(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      noreg: (json['noreg'] ?? '').toString(),
      role: (json['role'] ?? 'TM').toString().toUpperCase(),
      shift: (json['shift'] ?? 'WHITE').toString().toUpperCase(),
      defaultPos: (json['default_pos'] ?? 'Pos 1').toString(),
      hadirCount: _asInt(json['hadirCount']),
      sakitCount: _asInt(json['sakitCount']),
      izinCount: _asInt(json['izinCount']),
      cutiCount: _asInt(json['cutiCount']),
      dinasCount: _asInt(json['dinasCount']),
      alpaCount: _asInt(json['alpaCount']),
      totalAbsent: _asInt(json['totalAbsent']),
      attendanceRate: _asDouble(json['attendanceRate'], 100),
      history: hist,
    );
  }
}

class AttendanceSummaryKpi {
  const AttendanceSummaryKpi({
    required this.avgAttendanceRate,
    required this.totalHadir,
    required this.totalSakit,
    required this.totalIzin,
    required this.totalCuti,
    required this.totalDinas,
    required this.totalAlpa,
    required this.totalAbsent,
    required this.perfectMembersCount,
    required this.totalMembers,
  });

  final double avgAttendanceRate;
  final int totalHadir;
  final int totalSakit;
  final int totalIzin;
  final int totalCuti;
  final int totalDinas;
  final int totalAlpa;
  final int totalAbsent;
  final int perfectMembersCount;
  final int totalMembers;
}

class RosterAttendanceMath {
  RosterAttendanceMath._();

  static RosterStats computeRosterStats(List<RosterMember> list) {
    var gl = 0;
    var tl = 0;
    var tm = 0;
    var perm = 0;
    var kont = 0;
    var vok = 0;
    for (final m in list) {
      if (m.role == 'GL') {
        gl++;
      } else if (m.role == 'TL') {
        tl++;
      } else {
        tm++;
      }
      if (m.statusKaryawan == 'KONTRAK') {
        kont++;
      } else if (m.statusKaryawan == 'VOKASI') {
        vok++;
      } else {
        perm++;
      }
    }
    return RosterStats(total: list.length, gl: gl, tl: tl, tm: tm, permanen: perm, kontrak: kont, vokasi: vok);
  }

  static ({List<MemberAttendanceRow> members, AttendanceSummaryKpi kpi}) buildLocalAttendance(
    String ym,
    String shift,
    List<ChecksheetReport> reports,
  ) {
    final defaults = UbMasterData.defaultMembers(shift);
    final byName = <String, Map<String, String>>{
      for (final d in defaults) d.name: <String, String>{},
    };
    final posByName = <String, String>{
      for (final d in defaults) d.name: d.pos,
    };
    final roleByName = <String, String>{
      for (final d in defaults) d.name: d.role,
    };

    for (final rep in reports) {
      if (!rep.tanggal.startsWith(ym) || rep.shift.toUpperCase() != shift.toUpperCase()) continue;
      for (final m in rep.members) {
        byName.putIfAbsent(m.name, () => <String, String>{});
        posByName[m.name] = m.pos;
        roleByName[m.name] = m.role;
        byName[m.name]![rep.tanggal] = m.status;
      }
    }

    var idx = 1;
    final rows = <MemberAttendanceRow>[];
    var sumHadir = 0;
    var sumSakit = 0;
    var sumIzin = 0;
    var sumCuti = 0;
    var sumDinas = 0;
    var sumAlpa = 0;
    var perfect = 0;

    byName.forEach((name, hist) {
      var h = 0;
      var s = 0;
      var i = 0;
      var c = 0;
      var d = 0;
      var a = 0;
      hist.forEach((_, st) {
        final low = st.toLowerCase();
        if (low.contains('sakit')) {
          s++;
        } else if (low.contains('izin') || low.contains('ijin')) {
          i++;
        } else if (low.contains('cuti')) {
          c++;
        } else if (low.contains('dinas') || low.contains('train')) {
          d++;
        } else if (low.contains('alpa') || low.contains('mangkir')) {
          a++;
        } else {
          h++;
        }
      });
      final absent = s + i + c + a;
      final rec = h + absent + d;
      final rate = rec > 0 ? double.parse((((h + d) / rec) * 100).toStringAsFixed(1)) : 100.0;
      if (absent == 0) perfect++;
      sumHadir += h;
      sumSakit += s;
      sumIzin += i;
      sumCuti += c;
      sumDinas += d;
      sumAlpa += a;

      rows.add(
        MemberAttendanceRow(
          id: idx++,
          name: name,
          role: roleByName[name] ?? 'TM',
          shift: shift.toUpperCase(),
          defaultPos: posByName[name] ?? 'Pos 1',
          hadirCount: h,
          sakitCount: s,
          izinCount: i,
          cutiCount: c,
          dinasCount: d,
          alpaCount: a,
          totalAbsent: absent,
          attendanceRate: rate,
          history: hist,
        ),
      );
    });

    final totalAbsent = sumSakit + sumIzin + sumCuti + sumAlpa;
    final totalRec = sumHadir + sumDinas + totalAbsent;
    final avgRate = totalRec > 0 ? double.parse((((sumHadir + sumDinas) / totalRec) * 100).toStringAsFixed(1)) : 100.0;

    return (
      members: rows,
      kpi: AttendanceSummaryKpi(
        avgAttendanceRate: avgRate,
        totalHadir: sumHadir,
        totalSakit: sumSakit,
        totalIzin: sumIzin,
        totalCuti: sumCuti,
        totalDinas: sumDinas,
        totalAlpa: sumAlpa,
        totalAbsent: totalAbsent,
        perfectMembersCount: perfect,
        totalMembers: rows.length,
      ),
    );
  }
}
