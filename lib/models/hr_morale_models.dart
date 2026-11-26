import 'dart:math';

int hrDaysInMonth(String ym) {
  final p = ym.split('-');
  if (p.length < 2) return 31;
  return DateTime.utc(int.tryParse(p[0]) ?? 2026, (int.tryParse(p[1]) ?? 1) + 1, 0).day;
}

String hrTodayYmd() {
  final wib = DateTime.now().toUtc().add(const Duration(hours: 7));
  return '${wib.year}-${wib.month.toString().padLeft(2, '0')}-${wib.day.toString().padLeft(2, '0')}';
}

// =============================================================================
// 1. BACA DOA ASARE MODELS & ROTATION ENGINE
// =============================================================================
class BacaDoaAssignment {
  const BacaDoaAssignment({
    required this.day,
    required this.memberId,
    required this.memberName,
    this.noreg = '',
    this.pos = 'Pos 1',
    this.status = 'scheduled', // scheduled | done | replaced | off
    this.substituteName = '',
    this.note = '',
  });

  final int day;
  final int memberId;
  final String memberName;
  final String noreg;
  final String pos;
  final String status;
  final String substituteName;
  final String note;

  BacaDoaAssignment copyWith({
    int? memberId,
    String? memberName,
    String? noreg,
    String? pos,
    String? status,
    String? substituteName,
    String? note,
  }) {
    return BacaDoaAssignment(
      day: day,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      noreg: noreg ?? this.noreg,
      pos: pos ?? this.pos,
      status: status ?? this.status,
      substituteName: substituteName ?? this.substituteName,
      note: note ?? this.note,
    );
  }

  factory BacaDoaAssignment.fromJson(Map<String, dynamic> j) => BacaDoaAssignment(
        day: j['day'] is num ? (j['day'] as num).toInt() : 1,
        memberId: j['memberId'] is num ? (j['memberId'] as num).toInt() : 0,
        memberName: '${j['memberName'] ?? ''}',
        noreg: '${j['noreg'] ?? ''}',
        pos: '${j['pos'] ?? 'Pos 1'}',
        status: '${j['status'] ?? 'scheduled'}',
        substituteName: '${j['substituteName'] ?? ''}',
        note: '${j['note'] ?? ''}',
      );

  Map<String, dynamic> toJson() => {
        'day': day,
        'memberId': memberId,
        'memberName': memberName,
        'noreg': noreg,
        'pos': pos,
        'status': status,
        'substituteName': substituteName,
        'note': note,
      };
}

class BacaDoaOperator {
  const BacaDoaOperator({
    required this.id,
    required this.name,
    this.noreg = '',
    this.pos = 'Pos 1',
  });

  final int id;
  final String name;
  final String noreg;
  final String pos;
}

class BacaDoaEngine {
  BacaDoaEngine._();

  /// Returns weekday: 1=Mon .. 7=Sun (Dart DateTime.weekday).
  static int weekdayOf(String ym, int day) {
    final p = ym.split('-');
    final y = int.tryParse(p[0]) ?? 2026;
    final m = int.tryParse(p[1]) ?? 1;
    return DateTime.utc(y, m, day).weekday;
  }

  static bool isMonday(String ym, int day) => weekdayOf(ym, day) == DateTime.monday;
  static bool isWeekend(String ym, int day) {
    final wd = weekdayOf(ym, day);
    return wd == DateTime.saturday || wd == DateTime.sunday;
  }

  /// 1:1 with `handleAutoSchedule` in `ubnetwork/app/hr/bacadoa/page.tsx`:
  /// Skips Saturday, Sunday, AND Monday (Briefing Masal).
  static Map<int, BacaDoaAssignment> generateTueToFriRotation({
    required String ym,
    required List<BacaDoaOperator> operators,
  }) {
    if (operators.isEmpty) return {};
    final dim = hrDaysInMonth(ym);
    final out = <int, BacaDoaAssignment>{};
    var idx = 0;
    for (var d = 1; d <= dim; d++) {
      if (isWeekend(ym, d) || isMonday(ym, d)) continue;
      final op = operators[idx % operators.length];
      out[d] = BacaDoaAssignment(
        day: d,
        memberId: op.id,
        memberName: op.name,
        noreg: op.noreg,
        pos: op.pos,
        status: 'scheduled',
      );
      idx++;
    }
    return out;
  }
}

// =============================================================================
// 2. RANK MP MODELS & SCORING ENGINE
// =============================================================================
class RankMpCustomEval {
  const RankMpCustomEval({
    this.customPoints = 0,
    this.notes = '',
  });

  final int customPoints;
  final String notes;

  factory RankMpCustomEval.fromJson(Map<String, dynamic> j) => RankMpCustomEval(
        customPoints: j['customPoints'] is num ? (j['customPoints'] as num).toInt() : 0,
        notes: '${j['notes'] ?? ''}',
      );

  Map<String, dynamic> toJson() => {
        'customPoints': customPoints,
        'notes': notes,
      };
}

class MemberRankRow {
  const MemberRankRow({
    required this.rank,
    required this.memberId,
    required this.name,
    required this.noreg,
    required this.shift,
    required this.pos,
    required this.doaScheduled,
    required this.doaDone,
    required this.doaPoints,
    required this.multiDutyBonus,
    required this.disciplinePoints,
    required this.customHrPoints,
    required this.totalPoints,
    required this.tier, // S | A | B | C
    this.hrNotes = '',
  });

  final int rank;
  final int memberId;
  final String name;
  final String noreg;
  final String shift;
  final String pos;
  final int doaScheduled;
  final int doaDone;
  final int doaPoints;
  final int multiDutyBonus;
  final int disciplinePoints;
  final int customHrPoints;
  final int totalPoints;
  final String tier;
  final String hrNotes;

  bool get isMultiDuty => doaDone >= 2;
}

class RankMpEngine {
  RankMpEngine._();

  static String tierForPoints(int total) {
    if (total >= 50) return 'S';
    if (total >= 35) return 'A';
    if (total >= 20) return 'B';
    return 'C';
  }

  static List<MemberRankRow> computeRankings({
    required String shift,
    required List<BacaDoaOperator> operators,
    required Map<int, BacaDoaAssignment> bacaDoaRecords,
    required Map<int, RankMpCustomEval> customEvals,
  }) {
    final schedCounts = <int, int>{};
    final doneCounts = <int, int>{};
    for (final rec in bacaDoaRecords.values) {
      schedCounts[rec.memberId] = (schedCounts[rec.memberId] ?? 0) + 1;
      if (rec.status == 'done') {
        doneCounts[rec.memberId] = (doneCounts[rec.memberId] ?? 0) + 1;
      }
    }

    final rows = <MemberRankRow>[];
    for (final op in operators) {
      final sched = schedCounts[op.id] ?? 0;
      final done = doneCounts[op.id] ?? 0;
      final doaPts = done * 15;
      final pendingPts = sched > done ? (sched - done) * 5 : 0;
      final multiBonus = done >= 2 ? 15 : 0;
      const disciplinePts = 10;
      final eval = customEvals[op.id] ?? const RankMpCustomEval();
      final total = doaPts + pendingPts + multiBonus + disciplinePts + eval.customPoints;

      rows.add(
        MemberRankRow(
          rank: 0,
          memberId: op.id,
          name: op.name,
          noreg: op.noreg,
          shift: shift,
          pos: op.pos,
          doaScheduled: sched,
          doaDone: done,
          doaPoints: doaPts,
          multiDutyBonus: multiBonus,
          disciplinePoints: disciplinePts,
          customHrPoints: eval.customPoints,
          totalPoints: total,
          tier: tierForPoints(total),
          hrNotes: eval.notes,
        ),
      );
    }

    rows.sort((a, b) {
      final c = b.totalPoints.compareTo(a.totalPoints);
      if (c != 0) return c;
      final d = b.doaDone.compareTo(a.doaDone);
      if (d != 0) return d;
      return a.name.compareTo(b.name);
    });

    return rows.asMap().entries.map((e) {
      final r = e.value;
      return MemberRankRow(
        rank: e.key + 1,
        memberId: r.memberId,
        name: r.name,
        noreg: r.noreg,
        shift: r.shift,
        pos: r.pos,
        doaScheduled: r.doaScheduled,
        doaDone: r.doaDone,
        doaPoints: r.doaPoints,
        multiDutyBonus: r.multiDutyBonus,
        disciplinePoints: r.disciplinePoints,
        customHrPoints: r.customHrPoints,
        totalPoints: r.totalPoints,
        tier: r.tier,
        hrNotes: r.hrNotes,
      );
    }).toList();
  }
}

// =============================================================================
// 3. MONTHLY IDEA RECORD MODELS & MATH
// =============================================================================
class HrIdeaTeamData {
  const HrIdeaTeamData({
    this.mp = 20,
    this.totalIdeaManual,
    this.totalMakerManual,
    required this.dailyIdea,
    required this.dailyMaker,
  });

  final int? mp;
  final int? totalIdeaManual;
  final int? totalMakerManual;
  final List<int?> dailyIdea;
  final List<int?> dailyMaker;

  factory HrIdeaTeamData.empty({int mp = 20}) => HrIdeaTeamData(
        mp: mp,
        dailyIdea: List<int?>.filled(31, null),
        dailyMaker: List<int?>.filled(31, null),
      );

  HrIdeaTeamData copyWith({
    int? mp,
    int? totalIdeaManual,
    int? totalMakerManual,
    List<int?>? dailyIdea,
    List<int?>? dailyMaker,
  }) =>
      HrIdeaTeamData(
        mp: mp ?? this.mp,
        totalIdeaManual: totalIdeaManual ?? this.totalIdeaManual,
        totalMakerManual: totalMakerManual ?? this.totalMakerManual,
        dailyIdea: dailyIdea ?? this.dailyIdea,
        dailyMaker: dailyMaker ?? this.dailyMaker,
      );

  factory HrIdeaTeamData.fromJson(Map<String, dynamic> j) {
    List<int?> parseArr(dynamic raw) {
      final arr = List<int?>.filled(31, null);
      if (raw is List) {
        for (var i = 0; i < min(31, raw.length); i++) {
          arr[i] = raw[i] is num ? (raw[i] as num).toInt() : null;
        }
      }
      return arr;
    }

    return HrIdeaTeamData(
      mp: j['mp'] is num ? (j['mp'] as num).toInt() : 20,
      totalIdeaManual: j['totalIdeaManual'] is num ? (j['totalIdeaManual'] as num).toInt() : null,
      totalMakerManual: j['totalMakerManual'] is num ? (j['totalMakerManual'] as num).toInt() : null,
      dailyIdea: parseArr(j['dailyIdea']),
      dailyMaker: parseArr(j['dailyMaker']),
    );
  }

  Map<String, dynamic> toJson() => {
        'mp': mp,
        'totalIdeaManual': totalIdeaManual,
        'totalMakerManual': totalMakerManual,
        'dailyIdea': dailyIdea,
        'dailyMaker': dailyMaker,
      };
}

class HrIdeaMonth {
  const HrIdeaMonth({
    required this.ym,
    this.targetIdea = 2.0,
    this.targetPart = 100.0,
    required this.red,
    required this.white,
  });

  final String ym;
  final double targetIdea;
  final double targetPart;
  final HrIdeaTeamData red;
  final HrIdeaTeamData white;

  factory HrIdeaMonth.empty(String ym) => HrIdeaMonth(
        ym: ym,
        red: HrIdeaTeamData.empty(mp: 21),
        white: HrIdeaTeamData.empty(mp: 20),
      );

  HrIdeaMonth copyWith({
    double? targetIdea,
    double? targetPart,
    HrIdeaTeamData? red,
    HrIdeaTeamData? white,
  }) =>
      HrIdeaMonth(
        ym: ym,
        targetIdea: targetIdea ?? this.targetIdea,
        targetPart: targetPart ?? this.targetPart,
        red: red ?? this.red,
        white: white ?? this.white,
      );

  factory HrIdeaMonth.fromJson(String ym, Map<String, dynamic> j) => HrIdeaMonth(
        ym: ym,
        targetIdea: j['targetIdea'] is num ? (j['targetIdea'] as num).toDouble() : 2.0,
        targetPart: j['targetPart'] is num ? (j['targetPart'] as num).toDouble() : 100.0,
        red: j['red'] is Map ? HrIdeaTeamData.fromJson(Map<String, dynamic>.from(j['red'] as Map)) : HrIdeaTeamData.empty(),
        white: j['white'] is Map ? HrIdeaTeamData.fromJson(Map<String, dynamic>.from(j['white'] as Map)) : HrIdeaTeamData.empty(),
      );

  Map<String, dynamic> toJson() => {
        'ym': ym,
        'targetIdea': targetIdea,
        'targetPart': targetPart,
        'red': red.toJson(),
        'white': white.toJson(),
      };
}

class HrIdeaMath {
  HrIdeaMath._();

  static ({int? totalIdea, int? totalMaker, double? ideaPerMp, double? partPct}) computeTeamMetrics(
    HrIdeaTeamData t,
    int dim,
  ) {
    final hasDailyIdea = t.dailyIdea.take(dim).any((x) => x != null);
    final hasDailyMaker = t.dailyMaker.take(dim).any((x) => x != null);

    final totIdea = hasDailyIdea
        ? t.dailyIdea.take(dim).fold<int>(0, (acc, e) => acc + (e ?? 0))
        : t.totalIdeaManual;
    final totMaker = hasDailyMaker
        ? t.dailyMaker.take(dim).fold<int>(0, (acc, e) => acc + (e ?? 0))
        : t.totalMakerManual;

    final mp = t.mp;
    final ipm = (totIdea != null && mp != null && mp > 0) ? totIdea / mp : null;
    final pp = (totMaker != null && mp != null && mp > 0) ? (totMaker / mp) * 100.0 : null;
    return (totalIdea: totIdea, totalMaker: totMaker, ideaPerMp: ipm, partPct: pp);
  }
}

// =============================================================================
// 4. IDNU (IDEA PORTAL) & HR TEMUAN MODELS
// =============================================================================
class IdnuIdeaItem {
  const IdnuIdeaItem({
    required this.uid,
    required this.area, // S | Q | P | C | H | E | VM
    required this.date,
    required this.title,
    required this.beforeText,
    required this.afterText,
    required this.pic,
    required this.process,
    this.status = 'belum', // belum | sudah | gagal
    this.portalStatus = 'Belum Dikirim', // Draft | Menunggu LH | Paid
    this.transactionId = '',
    this.reward = 0,
    this.isDraft = true,
  });

  final String uid;
  final String area;
  final String date;
  final String title;
  final String beforeText;
  final String afterText;
  final String pic;
  final String process;
  final String status;
  final String portalStatus;
  final String transactionId;
  final int reward;
  final bool isDraft;

  IdnuIdeaItem copyWith({
    String? title,
    String? beforeText,
    String? afterText,
    String? status,
    String? portalStatus,
    String? transactionId,
    int? reward,
    bool? isDraft,
  }) =>
      IdnuIdeaItem(
        uid: uid,
        area: area,
        date: date,
        title: title ?? this.title,
        beforeText: beforeText ?? this.beforeText,
        afterText: afterText ?? this.afterText,
        pic: pic,
        process: process,
        status: status ?? this.status,
        portalStatus: portalStatus ?? this.portalStatus,
        transactionId: transactionId ?? this.transactionId,
        reward: reward ?? this.reward,
        isDraft: isDraft ?? this.isDraft,
      );

  factory IdnuIdeaItem.fromJson(Map<String, dynamic> j) => IdnuIdeaItem(
        uid: '${j['uid'] ?? ''}',
        area: '${j['area'] ?? 'P'}',
        date: '${j['date'] ?? ''}',
        title: '${j['title'] ?? ''}',
        beforeText: '${j['beforeText'] ?? ''}',
        afterText: '${j['afterText'] ?? ''}',
        pic: '${j['pic'] ?? ''}',
        process: '${j['process'] ?? ''}',
        status: '${j['status'] ?? 'belum'}',
        portalStatus: '${j['portalStatus'] ?? 'Belum Dikirim'}',
        transactionId: '${j['transactionId'] ?? ''}',
        reward: j['reward'] is num ? (j['reward'] as num).toInt() : 0,
        isDraft: j['isDraft'] == null ? true : j['isDraft'] == true,
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'area': area,
        'date': date,
        'title': title,
        'beforeText': beforeText,
        'afterText': afterText,
        'pic': pic,
        'process': process,
        'status': status,
        'portalStatus': portalStatus,
        'transactionId': transactionId,
        'reward': reward,
        'isDraft': isDraft,
      };
}

class HrFindingItem {
  const HrFindingItem({
    required this.id,
    required this.date,
    required this.team, // red | white
    required this.qty,
    required this.problem,
    required this.process,
    required this.foundWhere,
    required this.countermeasure,
    required this.pic,
    this.hasKaizen = false,
  });

  final String id;
  final String date;
  final String team;
  final int qty;
  final String problem;
  final String process;
  final String foundWhere;
  final String countermeasure;
  final String pic;
  final bool hasKaizen;

  factory HrFindingItem.fromJson(Map<String, dynamic> j) => HrFindingItem(
        id: '${j['id'] ?? ''}',
        date: '${j['date'] ?? ''}',
        team: '${j['team'] ?? 'red'}',
        qty: j['qty'] is num ? (j['qty'] as num).toInt() : 1,
        problem: '${j['problem'] ?? ''}',
        process: '${j['process'] ?? ''}',
        foundWhere: '${j['foundWhere'] ?? ''}',
        countermeasure: '${j['countermeasure'] ?? ''}',
        pic: '${j['pic'] ?? ''}',
        hasKaizen: j['hasKaizen'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'team': team,
        'qty': qty,
        'problem': problem,
        'process': process,
        'foundWhere': foundWhere,
        'countermeasure': countermeasure,
        'pic': pic,
        'hasKaizen': hasKaizen,
      };
}
