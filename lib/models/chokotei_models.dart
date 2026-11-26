// 1:1 Dart port of ubnetwork/app/productivity/chokotey/page.tsx & manual/page.tsx

import 'checksheet_models.dart';

class ChokoteiIssue {
  ChokoteiIssue({
    required this.id,
    required this.tanggal,
    required this.shift,
    this.timeRange = '',
    required this.machine,
    this.category = 'INT',
    required this.problem,
    this.countermeasure = '',
    this.lossUnits = 0,
    this.delayMin = 0,
    this.actionPlan = '',
    this.actionPic = '',
    this.actionStatus = 'open',
    this.isManual = false,
  });

  final String id;
  final String tanggal; // YYYY-MM-DD
  final String shift; // RED | WHITE
  final String timeRange;
  final String machine;
  final String category; // INT | EXT
  final String problem;
  final String countermeasure;
  final int lossUnits;
  final int delayMin;
  String actionPlan;
  String actionPic;
  String actionStatus; // open | in_progress | solved
  final bool isManual;

  ChokoteiIssue copyWith({
    String? id,
    String? tanggal,
    String? shift,
    String? timeRange,
    String? machine,
    String? category,
    String? problem,
    String? countermeasure,
    int? lossUnits,
    int? delayMin,
    String? actionPlan,
    String? actionPic,
    String? actionStatus,
    bool? isManual,
  }) =>
      ChokoteiIssue(
        id: id ?? this.id,
        tanggal: tanggal ?? this.tanggal,
        shift: shift ?? this.shift,
        timeRange: timeRange ?? this.timeRange,
        machine: machine ?? this.machine,
        category: category ?? this.category,
        problem: problem ?? this.problem,
        countermeasure: countermeasure ?? this.countermeasure,
        lossUnits: lossUnits ?? this.lossUnits,
        delayMin: delayMin ?? this.delayMin,
        actionPlan: actionPlan ?? this.actionPlan,
        actionPic: actionPic ?? this.actionPic,
        actionStatus: actionStatus ?? this.actionStatus,
        isManual: isManual ?? this.isManual,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tanggal': tanggal,
        'shift': shift,
        'time_range': timeRange,
        'machine': machine,
        'category': category,
        'problem': problem,
        'countermeasure': countermeasure,
        'loss_units': lossUnits,
        'delay_min': delayMin,
        'action_plan': actionPlan,
        'action_pic': actionPic,
        'action_status': actionStatus,
        'is_manual': isManual,
      };

  static int _asInt(dynamic v, [int fb = 0]) =>
      v is num ? v.toInt() : (int.tryParse('${v ?? ''}') ?? fb);

  factory ChokoteiIssue.fromJson(Map<String, dynamic> json, {bool manual = false}) {
    final rawStatus = (json['action_status'] ?? json['status'] ?? 'open').toString();
    final safeStatus = (rawStatus == 'solved' || rawStatus == 'in_progress') ? rawStatus : 'open';
    return ChokoteiIssue(
      id: (json['id'] ?? '').toString(),
      tanggal: (json['tanggal'] ?? '').toString(),
      shift: (json['shift'] ?? 'RED').toString().toUpperCase() == 'WHITE' ? 'WHITE' : 'RED',
      timeRange: (json['time_range'] ?? '').toString(),
      machine: (json['machine_name'] ?? json['machine'] ?? json['line_station'] ?? 'MST').toString(),
      category: (json['category'] ?? 'INT').toString().toUpperCase() == 'EXT' ? 'EXT' : 'INT',
      problem: (json['problem'] ?? 'Line Delay / Stoppage').toString(),
      countermeasure: (json['countermeasure'] ?? '').toString(),
      lossUnits: _asInt(json['loss_units'] ?? json['loss']),
      delayMin: _asInt(json['delay_min'] ?? json['delay_minutes'] ?? json['delay']),
      actionPlan: (json['action_plan'] ?? '').toString(),
      actionPic: (json['action_pic'] ?? json['pic'] ?? json['pic_name'] ?? '').toString(),
      actionStatus: safeStatus,
      isManual: manual || json['is_manual'] == true,
    );
  }
}

class MachineParetoItem {
  const MachineParetoItem({
    required this.machine,
    required this.totalLoss,
    required this.totalDelay,
    required this.count,
    required this.intLoss,
    required this.extLoss,
    required this.problems,
    required this.cumLossPercent,
    required this.isVitalFew,
  });

  final String machine;
  final int totalLoss;
  final int totalDelay;
  final int count;
  final int intLoss;
  final int extLoss;
  final List<String> problems;
  final double cumLossPercent;
  final bool isVitalFew;
}

class ChokoteiStats {
  const ChokoteiStats({
    required this.totalRecords,
    required this.totalLoss,
    required this.totalDelay,
    required this.intCount,
    required this.extCount,
    required this.solvedCount,
    required this.inProgCount,
    required this.openCount,
    required this.solvedPercent,
  });

  final int totalRecords;
  final int totalLoss;
  final int totalDelay;
  final int intCount;
  final int extCount;
  final int solvedCount;
  final int inProgCount;
  final int openCount;
  final int solvedPercent;
}

class ChokoteiMath {
  ChokoteiMath._();

  static ChokoteiStats computeStats(List<ChokoteiIssue> issues) {
    final total = issues.length;
    var loss = 0;
    var delay = 0;
    var intC = 0;
    var extC = 0;
    var solved = 0;
    var inProg = 0;
    var open = 0;

    for (final it in issues) {
      loss += it.lossUnits;
      delay += it.delayMin;
      if (it.category == 'EXT') {
        extC++;
      } else {
        intC++;
      }
      if (it.actionStatus == 'solved') {
        solved++;
      } else if (it.actionStatus == 'in_progress') {
        inProg++;
      } else {
        open++;
      }
    }
    final pct = total > 0 ? ((solved / total) * 100).round() : 0;
    return ChokoteiStats(
      totalRecords: total,
      totalLoss: loss,
      totalDelay: delay,
      intCount: intC,
      extCount: extC,
      solvedCount: solved,
      inProgCount: inProg,
      openCount: open,
      solvedPercent: pct,
    );
  }

  static List<MachineParetoItem> computePareto(List<ChokoteiIssue> issues) {
    final map = <String, _MutableMach>{};
    for (final p in issues) {
      final key = p.machine.trim().isEmpty ? 'MST' : p.machine.trim();
      final m = map.putIfAbsent(key, () => _MutableMach(key));
      m.totalLoss += p.lossUnits;
      m.totalDelay += p.delayMin;
      m.count += 1;
      if (p.category == 'EXT') {
        m.extLoss += p.lossUnits;
      } else {
        m.intLoss += p.lossUnits;
      }
      if (p.problem.trim().isNotEmpty && !m.problems.contains(p.problem.trim())) {
        m.problems.add(p.problem.trim());
      }
    }

    final sorted = map.values.toList()
      ..sort((a, b) {
        if (b.totalLoss != a.totalLoss) return b.totalLoss.compareTo(a.totalLoss);
        return b.totalDelay.compareTo(a.totalDelay);
      });

    final sumLoss = sorted.fold<int>(0, (acc, e) => acc + e.totalLoss);
    var running = 0;

    return sorted.map((m) {
      running += m.totalLoss;
      final cum = sumLoss > 0 ? double.parse(((running / sumLoss) * 100).toStringAsFixed(1)) : 0.0;
      return MachineParetoItem(
        machine: m.machine,
        totalLoss: m.totalLoss,
        totalDelay: m.totalDelay,
        count: m.count,
        intLoss: m.intLoss,
        extLoss: m.extLoss,
        problems: m.problems,
        cumLossPercent: cum,
        isVitalFew: cum <= 80.0,
      );
    }).toList();
  }

  static List<ChokoteiIssue> extractFromLocalChecksheets(
    List<ChecksheetReport> reports,
    String ym,
    String shift,
  ) {
    final out = <ChokoteiIssue>[];
    for (final rep in reports) {
      if (!rep.tanggal.startsWith(ym)) continue;
      if (rep.shift.toUpperCase() != shift.toUpperCase()) continue;
      for (final slot in rep.slots) {
        for (var i = 0; i < slot.problems.length; i++) {
          final p = slot.problems[i];
          out.add(
            ChokoteiIssue(
              id: '${rep.id}_${slot.no}_$i',
              tanggal: rep.tanggal,
              shift: rep.shift.toUpperCase(),
              timeRange: slot.timeRange,
              machine: p.lineStation.isEmpty ? 'MST' : p.lineStation,
              category: p.category.toUpperCase() == 'EXT' ? 'EXT' : 'INT',
              problem: p.problem.isEmpty ? 'Line Delay / Stoppage' : p.problem,
              countermeasure: p.countermeasure,
              lossUnits: p.lossUnits,
              delayMin: p.delayMin.round(),
              actionPic: rep.picName,
              actionStatus: 'open',
            ),
          );
        }
      }
    }
    return out;
  }
}

class _MutableMach {
  _MutableMach(this.machine);

  final String machine;
  int totalLoss = 0;
  int totalDelay = 0;
  int count = 0;
  int intLoss = 0;
  int extLoss = 0;
  final List<String> problems = [];
}
