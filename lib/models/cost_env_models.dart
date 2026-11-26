import 'dart:math';

int daysInMonthYm(String ym) {
  final parts = ym.split('-');
  if (parts.length < 2) return 31;
  final y = int.tryParse(parts[0]) ?? 2026;
  final m = int.tryParse(parts[1]) ?? 1;
  return DateTime.utc(y, m + 1, 0).day;
}

String costEnvTodayYmd() {
  final wib = DateTime.now().toUtc().add(const Duration(hours: 7));
  return '${wib.year}-${wib.month.toString().padLeft(2, '0')}-${wib.day.toString().padLeft(2, '0')}';
}

String formatRupiah(int amount) {
  final s = amount.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final rev = s.length - i;
    buf.write(s[i]);
    if (rev > 1 && rev % 3 == 1) buf.write('.');
  }
  return '${amount < 0 ? '-' : ''}Rp $buf';
}

// =============================================================================
// 1. PILAR COST — CONTROL COST DAILY & TEMUAN COST
// =============================================================================
class CostItem {
  const CostItem({
    required this.id,
    required this.name,
    this.targetRed,
    this.targetWhite,
    this.link,
  });

  final String id;
  final String name;
  final double? targetRed;
  final double? targetWhite;
  final String? link;

  double? targetFor(String team) => team == 'red' ? targetRed : targetWhite;

  CostItem copyWith({
    String? name,
    double? targetRed,
    double? targetWhite,
    String? link,
    bool clearTargetRed = false,
    bool clearTargetWhite = false,
  }) {
    return CostItem(
      id: id,
      name: name ?? this.name,
      targetRed: clearTargetRed ? null : (targetRed ?? this.targetRed),
      targetWhite: clearTargetWhite ? null : (targetWhite ?? this.targetWhite),
      link: link ?? this.link,
    );
  }

  factory CostItem.fromJson(Map<String, dynamic> j) => CostItem(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? ''}',
        targetRed: j['targetRed'] is num ? (j['targetRed'] as num).toDouble() : null,
        targetWhite: j['targetWhite'] is num ? (j['targetWhite'] as num).toDouble() : null,
        link: j['link'] == null ? null : '${j['link']}',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetRed': targetRed,
        'targetWhite': targetWhite,
        if (link != null && link!.isNotEmpty) 'link': link,
      };
}

class CostDailyMonth {
  const CostDailyMonth({
    required this.ym,
    required this.items,
    required this.red,
    required this.white,
  });

  final String ym;
  final List<CostItem> items;
  final Map<String, List<double?>> red;
  final Map<String, List<double?>> white;

  Map<String, List<double?>> valuesFor(String team) => team == 'red' ? red : white;

  CostDailyMonth copyWith({
    List<CostItem>? items,
    Map<String, List<double?>>? red,
    Map<String, List<double?>>? white,
  }) {
    return CostDailyMonth(
      ym: ym,
      items: items ?? this.items,
      red: red ?? this.red,
      white: white ?? this.white,
    );
  }

  factory CostDailyMonth.fromJson(String ym, Map<String, dynamic> j) {
    final items = (j['items'] is List ? j['items'] as List : const [])
        .whereType<Map>()
        .map((m) => CostItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    Map<String, List<double?>> parseMap(dynamic raw) {
      final out = <String, List<double?>>{};
      if (raw is Map) {
        raw.forEach((k, v) {
          if (v is List) {
            final arr = List<double?>.filled(31, null);
            for (var i = 0; i < min(31, v.length); i++) {
              arr[i] = v[i] is num ? (v[i] as num).toDouble() : null;
            }
            out['$k'] = arr;
          }
        });
      }
      for (final it in items) {
        out.putIfAbsent(it.id, () => List<double?>.filled(31, null));
      }
      return out;
    }

    return CostDailyMonth(
      ym: ym,
      items: items,
      red: parseMap(j['red']),
      white: parseMap(j['white']),
    );
  }

  Map<String, dynamic> toJson() => {
        'ym': ym,
        'items': items.map((e) => e.toJson()).toList(),
        'red': red,
        'white': white,
      };
}

class CostItemMetrics {
  const CostItemMetrics({
    required this.total,
    required this.pct,
    required this.projection,
    required this.paceLevel, // ok | warn | bad | null
  });

  final double? total;
  final double? pct;
  final double? projection;
  final String? paceLevel;
}

class CostPaceMath {
  CostPaceMath._();

  static CostItemMetrics computeItemMetrics(List<double?> values, int dim, double? target) {
    double sum = 0;
    var filled = 0;
    var lastFilledDay = 0;
    for (var i = 0; i < min(dim, values.length); i++) {
      final v = values[i];
      if (v != null) {
        sum += v;
        filled++;
        lastFilledDay = i + 1;
      }
    }
    if (filled == 0) {
      return const CostItemMetrics(total: null, pct: null, projection: null, paceLevel: null);
    }

    final total = double.parse(sum.toStringAsFixed(2));
    final pct = (target != null && target > 0) ? (total / target) * 100.0 : null;
    final projection = lastFilledDay > 0 ? (total / lastFilledDay) * dim : null;

    String? level;
    if (target != null && target > 0 && projection != null) {
      final ratio = projection / target;
      if (total > target || ratio > 1.10) {
        level = 'bad';
      } else if (ratio > 1.0) {
        level = 'warn';
      } else {
        level = 'ok';
      }
    }
    return CostItemMetrics(total: total, pct: pct, projection: projection, paceLevel: level);
  }
}

class CostFinding {
  const CostFinding({
    required this.id,
    required this.date,
    required this.team, // red | white
    required this.kind, // supply | consumable | other
    required this.process,
    required this.foundWhere,
    required this.problem,
    required this.amount,
    required this.countermeasure,
    required this.pic,
  });

  final String id;
  final String date;
  final String team;
  final String kind;
  final String process;
  final String foundWhere;
  final String problem;
  final int amount;
  final String countermeasure;
  final String pic;

  String get kindLabel {
    switch (kind) {
      case 'supply':
        return 'O. Supply';
      case 'consumable':
        return 'Consumable Tools';
      default:
        return 'Lainnya';
    }
  }

  factory CostFinding.fromJson(Map<String, dynamic> j) => CostFinding(
        id: '${j['id'] ?? ''}',
        date: '${j['date'] ?? ''}',
        team: '${j['team'] ?? 'red'}',
        kind: '${j['kind'] ?? 'consumable'}',
        process: '${j['process'] ?? ''}',
        foundWhere: '${j['foundWhere'] ?? ''}',
        problem: '${j['problem'] ?? ''}',
        amount: j['amount'] is num ? (j['amount'] as num).toInt() : 0,
        countermeasure: '${j['countermeasure'] ?? ''}',
        pic: '${j['pic'] ?? ''}',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'team': team,
        'kind': kind,
        'process': process,
        'foundWhere': foundWhere,
        'problem': problem,
        'amount': amount,
        'countermeasure': countermeasure,
        'pic': pic,
      };
}

// =============================================================================
// 2. PILAR ENVIRONMENT — ENERGY DAILY (kWh), AIR LEAKAGE (#lub/#klub), TEMUAN
// =============================================================================
class EnvEnergyMonth {
  const EnvEnergyMonth({
    required this.ym,
    required this.target,
    required this.red,
    required this.white,
  });

  final String ym;
  final double target;
  final List<double?> red;
  final List<double?> white;

  EnvEnergyMonth copyWith({
    double? target,
    List<double?>? red,
    List<double?>? white,
  }) {
    return EnvEnergyMonth(
      ym: ym,
      target: target ?? this.target,
      red: red ?? this.red,
      white: white ?? this.white,
    );
  }

  factory EnvEnergyMonth.empty(String ym, {double target = 850}) => EnvEnergyMonth(
        ym: ym,
        target: target,
        red: List<double?>.filled(31, null),
        white: List<double?>.filled(31, null),
      );

  factory EnvEnergyMonth.fromJson(String ym, Map<String, dynamic> j) {
    List<double?> parseArr(dynamic raw) {
      final arr = List<double?>.filled(31, null);
      if (raw is List) {
        for (var i = 0; i < min(31, raw.length); i++) {
          arr[i] = raw[i] is num ? (raw[i] as num).toDouble() : null;
        }
      }
      return arr;
    }

    return EnvEnergyMonth(
      ym: ym,
      target: j['target'] is num ? (j['target'] as num).toDouble() : 850,
      red: parseArr(j['red']),
      white: parseArr(j['white']),
    );
  }

  Map<String, dynamic> toJson() => {
        'ym': ym,
        'target': target,
        'red': red,
        'white': white,
      };
}

class EnvEnergySummary {
  const EnvEnergySummary({
    required this.totalRed,
    required this.avgRed,
    required this.rateRed,
    required this.totalWhite,
    required this.avgWhite,
    required this.rateWhite,
    required this.totalCombined,
  });

  final double totalRed;
  final double avgRed;
  final int rateRed;
  final double totalWhite;
  final double avgWhite;
  final int rateWhite;
  final double totalCombined;
}

class EnvEnergyMath {
  EnvEnergyMath._();

  static EnvEnergySummary computeSummary(EnvEnergyMonth data) {
    final dim = daysInMonthYm(data.ym);
    double sumR = 0;
    var cntR = 0;
    var okR = 0;
    double sumW = 0;
    var cntW = 0;
    var okW = 0;

    for (var i = 0; i < dim; i++) {
      final r = data.red[i];
      if (r != null) {
        sumR += r;
        cntR++;
        if (data.target <= 0 || r <= data.target) okR++;
      }
      final w = data.white[i];
      if (w != null) {
        sumW += w;
        cntW++;
        if (data.target <= 0 || w <= data.target) okW++;
      }
    }

    return EnvEnergySummary(
      totalRed: double.parse(sumR.toStringAsFixed(1)),
      avgRed: cntR > 0 ? double.parse((sumR / cntR).toStringAsFixed(1)) : 0,
      rateRed: cntR > 0 ? ((okR / cntR) * 100).round() : 100,
      totalWhite: double.parse(sumW.toStringAsFixed(1)),
      avgWhite: cntW > 0 ? double.parse((sumW / cntW).toStringAsFixed(1)) : 0,
      rateWhite: cntW > 0 ? ((okW / cntW) * 100).round() : 100,
      totalCombined: double.parse((sumR + sumW).toStringAsFixed(1)),
    );
  }
}

class AirCheckPoint {
  const AirCheckPoint({
    required this.code,
    required this.point,
    required this.area,
    this.status = 'OK', // OK | NG
    this.note = '',
  });

  final String code;
  final String point;
  final String area;
  final String status;
  final String note;

  AirCheckPoint copyWith({String? status, String? note}) => AirCheckPoint(
        code: code,
        point: point,
        area: area,
        status: status ?? this.status,
        note: note ?? this.note,
      );

  factory AirCheckPoint.fromJson(Map<String, dynamic> j) => AirCheckPoint(
        code: '${j['code'] ?? ''}',
        point: '${j['point'] ?? ''}',
        area: '${j['area'] ?? ''}',
        status: '${j['status'] ?? 'OK'}',
        note: '${j['note'] ?? ''}',
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'point': point,
        'area': area,
        'status': status,
        'note': note,
      };
}

class AirLeakageFinding {
  const AirLeakageFinding({
    required this.id,
    required this.date,
    required this.shift, // red | white
    required this.member,
    required this.area,
    required this.problem,
    this.severity = 'sedang', // kecil | sedang | besar
    this.countermeasure = '',
    this.kaizenTitle = '',
    this.kaizenBenefit = '',
    this.isKaizen = false,
    this.pic = '',
    this.status = 'open', // open | progress | closed
  });

  final String id;
  final String date;
  final String shift;
  final String member;
  final String area;
  final String problem;
  final String severity;
  final String countermeasure;
  final String kaizenTitle;
  final String kaizenBenefit;
  final bool isKaizen;
  final String pic;
  final String status;

  factory AirLeakageFinding.fromJson(Map<String, dynamic> j) => AirLeakageFinding(
        id: '${j['id'] ?? ''}',
        date: '${j['date'] ?? ''}',
        shift: '${j['shift'] ?? 'red'}',
        member: '${j['member'] ?? ''}',
        area: '${j['area'] ?? ''}',
        problem: '${j['problem'] ?? ''}',
        severity: '${j['severity'] ?? 'sedang'}',
        countermeasure: '${j['countermeasure'] ?? ''}',
        kaizenTitle: '${j['kaizenTitle'] ?? ''}',
        kaizenBenefit: '${j['kaizenBenefit'] ?? ''}',
        isKaizen: j['isKaizen'] == true,
        pic: '${j['pic'] ?? ''}',
        status: '${j['status'] ?? 'open'}',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'shift': shift,
        'member': member,
        'area': area,
        'problem': problem,
        'severity': severity,
        'countermeasure': countermeasure,
        'kaizenTitle': kaizenTitle,
        'kaizenBenefit': kaizenBenefit,
        'isKaizen': isKaizen,
        'pic': pic,
        'status': status,
      };
}

class EnvFindingItem {
  const EnvFindingItem({
    required this.id,
    required this.date,
    required this.team, // red | white
    required this.kind, // leak | energy | other
    required this.location,
    required this.problem,
    required this.countermeasure,
    required this.pic,
    required this.due,
    required this.status, // open | closed
    this.hasKaizen = false,
  });

  final String id;
  final String date;
  final String team;
  final String kind;
  final String location;
  final String problem;
  final String countermeasure;
  final String pic;
  final String due;
  final String status;
  final bool hasKaizen;

  String get kindLabel {
    switch (kind) {
      case 'leak':
        return 'Air Leakage';
      case 'energy':
        return 'Energi Listrik';
      default:
        return 'Lainnya / 3R';
    }
  }

  EnvFindingItem copyWith({
    String? status,
    bool? hasKaizen,
  }) =>
      EnvFindingItem(
        id: id,
        date: date,
        team: team,
        kind: kind,
        location: location,
        problem: problem,
        countermeasure: countermeasure,
        pic: pic,
        due: due,
        status: status ?? this.status,
        hasKaizen: hasKaizen ?? this.hasKaizen,
      );

  factory EnvFindingItem.fromJson(Map<String, dynamic> j) => EnvFindingItem(
        id: '${j['id'] ?? ''}',
        date: '${j['date'] ?? ''}',
        team: '${j['team'] ?? 'red'}',
        kind: '${j['kind'] ?? 'leak'}',
        location: '${j['location'] ?? ''}',
        problem: '${j['problem'] ?? ''}',
        countermeasure: '${j['countermeasure'] ?? ''}',
        pic: '${j['pic'] ?? ''}',
        due: '${j['due'] ?? ''}',
        status: '${j['status'] ?? 'open'}',
        hasKaizen: j['hasKaizen'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'team': team,
        'kind': kind,
        'location': location,
        'problem': problem,
        'countermeasure': countermeasure,
        'pic': pic,
        'due': due,
        'status': status,
        'hasKaizen': hasKaizen,
      };
}
