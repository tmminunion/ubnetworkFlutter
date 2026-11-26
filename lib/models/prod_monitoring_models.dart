// 1:1 Dart port of ubnetwork/app/productivity/monitoring/page.tsx models & KPI math

import 'checksheet_models.dart';

class TeamDayMetrics {
  TeamDayMetrics({
    this.session = 'day',
    this.regPlan = 0,
    this.otHours = 0,
    this.actOtHours = 0,
    this.plan = 0,
    this.act = 0,
    this.diff = 0,
    this.efficiency = 0,
    this.effExt = 100,
    this.effTotal = 0,
    this.minusUnits = 0,
    this.delayMin = 0,
    this.intDelayMin = 0,
    this.extDelayMin = 0,
    this.attendanceRate,
    this.isSaved = false,
  });

  final String session; // day | night | off
  final int regPlan;
  final double otHours;
  final double actOtHours;
  final int plan;
  final int act;
  final int diff;
  final double efficiency; // Eff INT %
  final double effExt;
  final double effTotal;
  final int minusUnits;
  final int delayMin;
  final int intDelayMin;
  final int extDelayMin;
  final double? attendanceRate;
  final bool isSaved;

  static int _asInt(dynamic v, [int fb = 0]) =>
      v is num ? v.toInt() : (int.tryParse('${v ?? ''}') ?? fb);

  static double _asDouble(dynamic v, [double fb = 0]) =>
      v is num ? v.toDouble() : (double.tryParse('${v ?? ''}') ?? fb);

  factory TeamDayMetrics.fromJson(Map<String, dynamic>? json) {
    if (json == null) return TeamDayMetrics();
    final plan = _asInt(json['plan']);
    final act = _asInt(json['act']);
    final eff = _asDouble(json['effInt'] ?? json['efficiency']);
    return TeamDayMetrics(
      session: (json['session'] ?? 'off').toString(),
      regPlan: _asInt(json['regPlan']),
      otHours: _asDouble(json['otHours']),
      actOtHours: _asDouble(json['actOtHours']),
      plan: plan,
      act: act,
      diff: json['diff'] != null ? _asInt(json['diff']) : (act - plan),
      efficiency: eff,
      effExt: _asDouble(json['effExt'], 100),
      effTotal: _asDouble(json['effTotal'], eff),
      minusUnits: _asInt(json['minusUnits'], act > 0 && act < plan ? plan - act : 0),
      delayMin: _asInt(json['delayMin']),
      intDelayMin: _asInt(json['intDelayMin'], _asInt(json['delayMin'])),
      extDelayMin: _asInt(json['extDelayMin']),
      attendanceRate: json['attendanceRate'] == null ? null : _asDouble(json['attendanceRate']),
      isSaved: json['isSaved'] == true,
    );
  }
}

class DayMonitoringRow {
  DayMonitoringRow({
    required this.date,
    required this.dayNumber,
    required this.dayName,
    required this.weekNumber,
    required this.isWeekend,
    required this.isSaturday,
    required this.isSunday,
    required this.white,
    required this.red,
  });

  final String date;
  final int dayNumber;
  final String dayName;
  final int weekNumber;
  final bool isWeekend;
  final bool isSaturday;
  final bool isSunday;
  final TeamDayMetrics white;
  final TeamDayMetrics red;

  TeamDayMetrics forShift(String shift) => shift == 'RED' ? red : white;

  factory DayMonitoringRow.fromJson(Map<String, dynamic> json) => DayMonitoringRow(
        date: (json['date'] ?? '').toString(),
        dayNumber: json['dayNumber'] is num ? (json['dayNumber'] as num).toInt() : 1,
        dayName: (json['dayName'] ?? '').toString(),
        weekNumber: json['weekNumber'] is num ? (json['weekNumber'] as num).toInt() : 1,
        isWeekend: json['isWeekend'] == true,
        isSaturday: json['isSaturday'] == true,
        isSunday: json['isSunday'] == true,
        white: TeamDayMetrics.fromJson(json['white'] is Map ? Map<String, dynamic>.from(json['white'] as Map) : null),
        red: TeamDayMetrics.fromJson(json['red'] is Map ? Map<String, dynamic>.from(json['red'] as Map) : null),
      );
}

class MonthlyTeamKpi {
  const MonthlyTeamKpi({
    required this.totalPlan,
    required this.totalAct,
    required this.totalDiff,
    required this.avgEff,
    required this.avgEffExt,
    required this.avgEffTotal,
    required this.totalOtHours,
    required this.totalActOtHours,
    required this.totalMinusUnits,
    required this.totalDelayMin,
    required this.totalIntDelay,
    required this.totalExtDelay,
    required this.avgAttendanceRate,
    required this.daySessions,
    required this.nightSessions,
  });

  final int totalPlan;
  final int totalAct;
  final int totalDiff;
  final double avgEff;
  final double avgEffExt;
  final double avgEffTotal;
  final double totalOtHours;
  final double totalActOtHours;
  final int totalMinusUnits;
  final int totalDelayMin;
  final int totalIntDelay;
  final int totalExtDelay;
  final double avgAttendanceRate;
  final int daySessions;
  final int nightSessions;
}

class ProdMonitoringMath {
  ProdMonitoringMath._();

  static const List<String> monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static const List<String> dayShort = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

  static MonthlyTeamKpi computeKpi(List<DayMonitoringRow> days, String shift) {
    var totalPlan = 0;
    var totalAct = 0;
    var totalOt = 0.0;
    var totalActOt = 0.0;
    var totalMinus = 0;
    var totalDelay = 0;
    var totalInt = 0;
    var totalExt = 0;
    var daySessions = 0;
    var nightSessions = 0;

    final effInts = <double>[];
    final effExts = <double>[];
    final effTots = <double>[];
    final attRates = <double>[];

    for (final d in days) {
      final t = d.forShift(shift);
      totalPlan += t.plan;
      totalAct += t.act;
      totalOt += t.otHours;
      totalActOt += t.actOtHours;
      totalMinus += t.minusUnits;
      totalDelay += t.delayMin;
      totalInt += t.intDelayMin;
      totalExt += t.extDelayMin;
      if (t.session == 'day') daySessions++;
      if (t.session == 'night') nightSessions++;
      if (t.act > 0) {
        effInts.add(t.efficiency);
        effExts.add(t.effExt);
        effTots.add(t.effTotal);
      }
      if (t.attendanceRate != null) {
        attRates.add(t.attendanceRate!);
      }
    }

    double avg(List<double> list, [double fb = 0]) =>
        list.isEmpty ? fb : double.parse((list.reduce((a, b) => a + b) / list.length).toStringAsFixed(1));

    return MonthlyTeamKpi(
      totalPlan: totalPlan,
      totalAct: totalAct,
      totalDiff: totalAct - totalPlan,
      avgEff: avg(effInts),
      avgEffExt: avg(effExts),
      avgEffTotal: avg(effTots),
      totalOtHours: double.parse(totalOt.toStringAsFixed(1)),
      totalActOtHours: double.parse(totalActOt.toStringAsFixed(1)),
      totalMinusUnits: totalMinus,
      totalDelayMin: totalDelay,
      totalIntDelay: totalInt,
      totalExtDelay: totalExt,
      avgAttendanceRate: avg(attRates, 100),
      daySessions: daySessions,
      nightSessions: nightSessions,
    );
  }

  static List<DayMonitoringRow> buildLocalFallbackDays(
    int year,
    int month,
    List<ChecksheetReport> localReports, {
    double taktTime = 2.4,
  }) {
    final dim = DateTime(year, month + 1, 0).day;
    final uph = taktTime > 0 ? (60 / taktTime).round() : 25;
    final defaultPlan = uph * 8;

    final byKey = <String, ChecksheetReport>{};
    for (final r in localReports) {
      byKey['${r.tanggal}_${r.shift.toUpperCase()}'] = r;
    }

    TeamDayMetrics buildTeam(String dateStr, String shift, bool weekend, int weekNum) {
      final rep = byKey['${dateStr}_$shift'];
      if (rep != null) {
        final st = UbMasterData.computeStats(rep);
        final effInt = double.tryParse(st.internalEfficiency) ?? 0;
        final minus = st.totalAct > 0 && st.totalAct < st.totalPlan ? st.totalPlan - st.totalAct : 0;
        return TeamDayMetrics(
          session: rep.session == 'night' ? 'night' : 'day',
          regPlan: st.totalPlan,
          actOtHours: rep.actOtHours,
          plan: st.totalPlan,
          act: st.totalAct,
          diff: st.diff,
          efficiency: effInt,
          effExt: double.tryParse(st.extEffPct) ?? 100,
          effTotal: double.tryParse(st.totalEffPct) ?? effInt,
          minusUnits: minus,
          delayMin: st.totalDelayMin,
          intDelayMin: st.intDelayMin,
          extDelayMin: st.extDelayMin,
          attendanceRate: 100,
          isSaved: true,
        );
      }
      if (weekend) {
        return TeamDayMetrics(session: 'off');
      }
      final defaultSession = (shift == 'WHITE') == (weekNum % 2 == 1) ? 'day' : 'night';
      return TeamDayMetrics(
        session: defaultSession,
        regPlan: defaultPlan,
        plan: defaultPlan,
        diff: -defaultPlan,
      );
    }

    return List.generate(dim, (i) {
      final dayNum = i + 1;
      final dt = DateTime(year, month, dayNum);
      final wd = dt.weekday; // 1=Mon .. 7=Sun
      final isSat = wd == DateTime.saturday;
      final isSun = wd == DateTime.sunday;
      final isWeekend = isSat || isSun;
      final weekNum = ((dayNum - 1) ~/ 7) + 1;
      final dateStr = '$year-${month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';

      return DayMonitoringRow(
        date: dateStr,
        dayNumber: dayNum,
        dayName: dayShort[wd % 7],
        weekNumber: weekNum,
        isWeekend: isWeekend,
        isSaturday: isSat,
        isSunday: isSun,
        white: buildTeam(dateStr, 'WHITE', isWeekend, weekNum),
        red: buildTeam(dateStr, 'RED', isWeekend, weekNum),
      );
    });
  }
}
