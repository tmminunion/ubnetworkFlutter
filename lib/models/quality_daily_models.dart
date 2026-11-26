// 1:1 Dart port of ubnetwork/app/display/qualityDaily.ts & DefectKindPage.tsx

class QualityFinding {
  QualityFinding({
    required this.id,
    required this.date,
    required this.team,
    required this.kind,
    required this.problem,
    this.process = '',
    this.foundWhere = '',
    this.qty = 1,
    this.countermeasure = '',
    this.pic = '',
    this.hasKaizen = false,
  });

  final String id;
  final String date; // YYYY-MM-DD
  final String team; // red | white
  final String kind; // out | in
  final String problem;
  final String process;
  final String foundWhere;
  final int qty;
  final String countermeasure;
  final String pic;
  final bool hasKaizen;

  int get dayNumber => int.tryParse(date.length >= 10 ? date.substring(8, 10) : '0') ?? 0;

  QualityFinding copyWith({
    String? id,
    String? date,
    String? team,
    String? kind,
    String? problem,
    String? process,
    String? foundWhere,
    int? qty,
    String? countermeasure,
    String? pic,
    bool? hasKaizen,
  }) =>
      QualityFinding(
        id: id ?? this.id,
        date: date ?? this.date,
        team: team ?? this.team,
        kind: kind ?? this.kind,
        problem: problem ?? this.problem,
        process: process ?? this.process,
        foundWhere: foundWhere ?? this.foundWhere,
        qty: qty ?? this.qty,
        countermeasure: countermeasure ?? this.countermeasure,
        pic: pic ?? this.pic,
        hasKaizen: hasKaizen ?? this.hasKaizen,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'team': team,
        'kind': kind,
        'problem': problem,
        'process': process,
        'foundWhere': foundWhere,
        'qty': qty,
        'countermeasure': countermeasure,
        'pic': pic,
        'hasKaizen': hasKaizen,
      };

  factory QualityFinding.fromJson(Map<String, dynamic> json) => QualityFinding(
        id: (json['id'] ?? '').toString(),
        date: (json['date'] ?? '').toString(),
        team: (json['team'] ?? 'red').toString().toLowerCase() == 'white' ? 'white' : 'red',
        kind: (json['kind'] ?? 'out').toString().toLowerCase() == 'in' ? 'in' : 'out',
        problem: (json['problem'] ?? '').toString(),
        process: (json['process'] ?? '').toString(),
        foundWhere: (json['foundWhere'] ?? '').toString(),
        qty: json['qty'] is num ? (json['qty'] as num).toInt() : (int.tryParse('${json['qty'] ?? 1}') ?? 1),
        countermeasure: (json['countermeasure'] ?? '').toString(),
        pic: (json['pic'] ?? '').toString(),
        hasKaizen: json['hasKaizen'] == true,
      );
}

class MonthlyProdData {
  MonthlyProdData({
    required this.red,
    required this.white,
    required this.weekend,
  });

  final List<int?> red;
  final List<int?> white;
  final List<bool> weekend;
}

class QualityMonthlyRecord {
  QualityMonthlyRecord({
    required this.ym,
    required this.kind,
    this.targetDu = 0.025,
    Set<int>? redZeroDays,
    Set<int>? whiteZeroDays,
    List<QualityFinding>? findings,
  })  : redZeroDays = redZeroDays ?? <int>{},
        whiteZeroDays = whiteZeroDays ?? <int>{},
        findings = findings ?? <QualityFinding>[];

  final String ym; // YYYY-MM
  final String kind; // out | in
  double targetDu;
  final Set<int> redZeroDays; // 1..31
  final Set<int> whiteZeroDays; // 1..31
  final List<QualityFinding> findings;

  Set<int> zeroDaysFor(String team) => team == 'white' ? whiteZeroDays : redZeroDays;

  Map<String, dynamic> toJson() => {
        'ym': ym,
        'kind': kind,
        'targetDu': targetDu,
        'redZeroDays': redZeroDays.toList()..sort(),
        'whiteZeroDays': whiteZeroDays.toList()..sort(),
        'findings': findings.map((f) => f.toJson()).toList(),
      };

  factory QualityMonthlyRecord.fromJson(Map<String, dynamic> json, {required String ym, required String kind}) {
    Set<int> parseSet(dynamic raw) {
      if (raw is! List) return <int>{};
      return raw.map((e) => e is num ? e.toInt() : int.tryParse('$e') ?? -1).where((e) => e >= 1 && e <= 31).toSet();
    }

    final rawFindings = json['findings'];
    final parsedFindings = rawFindings is List
        ? rawFindings.whereType<Map>().map((m) => QualityFinding.fromJson(Map<String, dynamic>.from(m))).toList()
        : <QualityFinding>[];

    final rawTarget = json['targetDu'];
    final target = rawTarget is num ? rawTarget.toDouble() : (double.tryParse('${rawTarget ?? 0.025}') ?? 0.025);

    return QualityMonthlyRecord(
      ym: ym,
      kind: kind,
      targetDu: target > 0 ? target : 0.025,
      redZeroDays: parseSet(json['redZeroDays']),
      whiteZeroDays: parseSet(json['whiteZeroDays']),
      findings: parsedFindings,
    );
  }
}

class QualityTeamSummary {
  const QualityTeamSummary({
    required this.totalProd,
    required this.totalDefect,
    required this.du,
  });

  final int totalProd;
  final int? totalDefect;
  final double? du;
}

class QualityMath {
  QualityMath._();

  static const List<String> monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static String wibYm() {
    final wib = DateTime.now().toUtc().add(const Duration(hours: 7));
    return '${wib.year}-${wib.month.toString().padLeft(2, '0')}';
  }

  static String shiftYm(String ym, int deltaMonths) {
    final parts = ym.split('-');
    final y = int.tryParse(parts[0]) ?? 2026;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
    final dt = DateTime(y, m + deltaMonths, 1);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
  }

  static String formatYmLabel(String ym) {
    final parts = ym.split('-');
    final y = int.tryParse(parts[0]) ?? 2026;
    final m = (int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1).clamp(1, 12);
    return '${monthLabels[m - 1]} $y';
  }

  static int daysInMonth(String ym) {
    final parts = ym.split('-');
    final y = int.tryParse(parts[0]) ?? 2026;
    final m = (int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1).clamp(1, 12);
    return DateTime(y, m + 1, 0).day;
  }

  static double? defectPerUnit(int? defect, int? prod) {
    if (defect == null || prod == null || prod <= 0) return null;
    return defect / prod;
  }

  static String fmtDu(double? v) => v == null ? '–' : v.toStringAsFixed(3);

  static int? dayDefect(QualityMonthlyRecord rec, String team, int day) {
    final dayFinds = rec.findings.where((f) => f.team == team && f.dayNumber == day).toList();
    if (dayFinds.isNotEmpty) {
      return dayFinds.fold<int>(0, (sum, f) => sum + f.qty);
    }
    if (rec.zeroDaysFor(team).contains(day)) return 0;
    return null;
  }

  static QualityTeamSummary teamSummary(
    QualityMonthlyRecord rec,
    String team,
    int dim,
    List<int?>? prodDays,
  ) {
    var totalProd = 0;
    int? totalDef;
    for (var day = 1; day <= dim; day++) {
      final act = (prodDays != null && day - 1 < prodDays.length) ? prodDays[day - 1] : null;
      if (act != null && act > 0) totalProd += act;
      final df = dayDefect(rec, team, day);
      if (df != null) {
        totalDef = (totalDef ?? 0) + df;
      }
    }
    final du = defectPerUnit(totalDef, totalProd > 0 ? totalProd : null);
    return QualityTeamSummary(totalProd: totalProd, totalDefect: totalDef, du: du);
  }
}
