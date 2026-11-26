// 1:1 Dart port of ubnetwork/app/types/sga.ts & KYT 12-Month Monitoring

class SgaMemberItem {
  SgaMemberItem({
    this.memberId,
    required this.name,
    this.noreg = '',
    this.role = '',
  });

  final int? memberId;
  final String name;
  final String noreg;
  final String role;

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'name': name,
        'noreg': noreg,
        'role': role,
      };

  factory SgaMemberItem.fromJson(Map<String, dynamic> json) => SgaMemberItem(
        memberId: json['memberId'] is num ? (json['memberId'] as num).toInt() : int.tryParse('${json['memberId'] ?? ''}'),
        name: (json['name'] ?? '').toString(),
        noreg: (json['noreg'] ?? '').toString(),
        role: (json['role'] ?? '').toString(),
      );
}

class SgaGroup {
  SgaGroup({
    required this.id,
    required this.code,
    required this.name,
    required this.shift,
    this.posArea = '',
    this.circleTema = '',
    this.tlName = '',
    this.tlNoreg = '',
    List<SgaMemberItem>? members,
    this.kytTargetPerYear = 12,
  }) : members = members ?? <SgaMemberItem>[];

  final String id;
  final String code;
  final String name;
  final String shift; // WHITE | RED
  final String posArea;
  final String circleTema;
  final String tlName;
  final String tlNoreg;
  final List<SgaMemberItem> members;
  final int kytTargetPerYear;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'shift': shift,
        'posArea': posArea,
        'circleTema': circleTema,
        'tlName': tlName,
        'tlNoreg': tlNoreg,
        'members': members.map((m) => m.toJson()).toList(),
        'kytTargetPerYear': kytTargetPerYear,
      };

  factory SgaGroup.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'];
    final parsedMembers = rawMembers is List
        ? rawMembers.whereType<Map>().map((m) => SgaMemberItem.fromJson(Map<String, dynamic>.from(m))).toList()
        : <SgaMemberItem>[];
    final rawShift = (json['shift'] ?? 'WHITE').toString().toUpperCase();
    return SgaGroup(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      shift: rawShift == 'RED' ? 'RED' : 'WHITE',
      posArea: (json['posArea'] ?? '').toString(),
      circleTema: (json['circleTema'] ?? '').toString(),
      tlName: (json['tlName'] ?? '').toString(),
      tlNoreg: (json['tlNoreg'] ?? '').toString(),
      members: parsedMembers,
      kytTargetPerYear: (json['kytTargetPerYear'] is num) ? (json['kytTargetPerYear'] as num).toInt() : 12,
    );
  }
}

class MonthlyKytStatus {
  MonthlyKytStatus({
    required this.monthIdx,
    this.status = 'empty',
    this.tanggal = '',
    this.tema = '',
    this.tahap1 = '',
    this.tahap2 = '',
    this.tahap3 = '',
    this.tahap4 = '',
    this.ikrar = '',
    this.createdBy = '',
  });

  final int monthIdx; // 0..11
  String status; // done | pending | empty
  String tanggal;
  String tema;
  String tahap1;
  String tahap2;
  String tahap3;
  String tahap4;
  String ikrar;
  String createdBy;

  int get monthNumber => monthIdx + 1;

  MonthlyKytStatus copyWith({
    String? status,
    String? tanggal,
    String? tema,
    String? tahap1,
    String? tahap2,
    String? tahap3,
    String? tahap4,
    String? ikrar,
    String? createdBy,
  }) =>
      MonthlyKytStatus(
        monthIdx: monthIdx,
        status: status ?? this.status,
        tanggal: tanggal ?? this.tanggal,
        tema: tema ?? this.tema,
        tahap1: tahap1 ?? this.tahap1,
        tahap2: tahap2 ?? this.tahap2,
        tahap3: tahap3 ?? this.tahap3,
        tahap4: tahap4 ?? this.tahap4,
        ikrar: ikrar ?? this.ikrar,
        createdBy: createdBy ?? this.createdBy,
      );

  Map<String, dynamic> toJson() => {
        'monthIdx': monthIdx,
        'month': monthNumber,
        'status': status,
        'tanggal': tanggal,
        'tema': tema,
        'tahap1': tahap1,
        'tahap2': tahap2,
        'tahap3': tahap3,
        'tahap4': tahap4,
        'ikrar': ikrar,
        'createdBy': createdBy,
      };

  factory MonthlyKytStatus.fromJson(Map<String, dynamic> json, {int fallbackIdx = 0}) {
    final idx = json['monthIdx'] is num
        ? (json['monthIdx'] as num).toInt()
        : (json['month'] is num ? (json['month'] as num).toInt() - 1 : fallbackIdx);
    final rawStatus = (json['status'] ?? 'empty').toString().toLowerCase();
    final safeStatus = (rawStatus == 'done' || rawStatus == 'pending') ? rawStatus : 'empty';
    return MonthlyKytStatus(
      monthIdx: idx.clamp(0, 11),
      status: safeStatus,
      tanggal: (json['tanggal'] ?? '').toString(),
      tema: (json['tema'] ?? '').toString(),
      tahap1: (json['tahap1'] ?? '').toString(),
      tahap2: (json['tahap2'] ?? '').toString(),
      tahap3: (json['tahap3'] ?? '').toString(),
      tahap4: (json['tahap4'] ?? '').toString(),
      ikrar: (json['ikrar'] ?? '').toString(),
      createdBy: (json['createdBy'] ?? '').toString(),
    );
  }
}

class SgaMonitoringRow {
  SgaMonitoringRow({
    required this.group,
    required this.months,
  });

  final SgaGroup group;
  final List<MonthlyKytStatus> months;

  int get completedCount => months.where((m) => m.status == 'done').length;

  Map<String, dynamic> toJson() => {
        'group': group.toJson(),
        'months': months.map((m) => m.toJson()).toList(),
      };

  factory SgaMonitoringRow.fromJson(Map<String, dynamic> json) {
    final group = SgaGroup.fromJson(Map<String, dynamic>.from(json['group'] as Map));
    final rawMonths = json['months'];
    final mapByIdx = <int, MonthlyKytStatus>{};
    if (rawMonths is List) {
      for (var i = 0; i < rawMonths.length; i++) {
        final item = rawMonths[i];
        if (item is Map) {
          final parsed = MonthlyKytStatus.fromJson(Map<String, dynamic>.from(item), fallbackIdx: i);
          mapByIdx[parsed.monthIdx] = parsed;
        }
      }
    }
    final normalized = List.generate(12, (idx) => mapByIdx[idx] ?? MonthlyKytStatus(monthIdx: idx));
    return SgaMonitoringRow(group: group, months: normalized);
  }
}

class KytShiftStats {
  const KytShiftStats({
    required this.targetYear,
    required this.completedYtd,
    required this.compliancePercent,
  });

  final int targetYear;
  final int completedYtd;
  final int compliancePercent;
}

class KytMaster {
  KytMaster._();

  static const List<String> monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static const List<int> availableYears = [2024, 2025, 2026, 2027, 2028];

  static KytShiftStats computeShiftStats(List<SgaMonitoringRow> rows) {
    final target = rows.length * 12;
    final done = rows.fold<int>(0, (acc, r) => acc + r.completedCount);
    final pct = target > 0 ? ((done / target) * 100).round() : 0;
    return KytShiftStats(targetYear: target, completedYtd: done, compliancePercent: pct);
  }

  static List<SgaMonitoringRow> defaultSeedRows() {
    final groups = [
      SgaGroup(
        id: '1',
        code: 'SGA-W01',
        name: 'SGA Underbody Main',
        shift: 'WHITE',
        tlName: 'NUNU FATULAH',
        tlNoreg: '00408012',
        posArea: 'Pos 1 Underbody Main Floor',
        circleTema: 'Pencegahan Bahaya Terjepit Klem Pneumatik & Peningkatan Ergonomi',
      ),
      SgaGroup(
        id: '2',
        code: 'SGA-W02',
        name: 'SGA Front Floor Circle',
        shift: 'WHITE',
        tlName: 'DADANG SURYADI',
        tlNoreg: '00009978',
        posArea: 'Pos 2 Front Floor & Dash Panel',
        circleTema: 'Zero Spatter & Safety Eye Protection di Area Robot Spot Welding',
      ),
      SgaGroup(
        id: '3',
        code: 'SGA-W03',
        name: 'SGA Cross Member & Export',
        shift: 'WHITE',
        tlName: 'DADANG SURYADI',
        tlNoreg: '00009978',
        posArea: 'Pos 3 Cross Member & Sub-Assy CKD',
        circleTema: 'Pencegahan Bahaya Sayatan Tepi Plat Tajam & Penataan Rak Material Dolly',
      ),
      SgaGroup(
        id: '4',
        code: 'SGA-R01',
        name: 'SGA Main Floor Red',
        shift: 'RED',
        tlName: 'MASRURI',
        tlNoreg: '00009988',
        posArea: 'Pos 1 Underbody Main Floor Red',
        circleTema: 'Penanganan Kondisi Darurat Andon & Kepatuhan LOTO Robot Cell',
      ),
      SgaGroup(
        id: '5',
        code: 'SGA-R02',
        name: 'SGA Respot & Finishing Red',
        shift: 'RED',
        tlName: 'TRI RUSTIANTORO',
        tlNoreg: '09405969',
        posArea: 'Pos 2 Cross Member & Respot Red',
        circleTema: 'Pencegahan Kejatuhan Komponen Berat & Verifikasi Safety Pin Jig',
      ),
    ];

    return groups
        .map(
          (g) => SgaMonitoringRow(
            group: g,
            months: List.generate(12, (idx) => MonthlyKytStatus(monthIdx: idx)),
          ),
        )
        .toList();
  }
}
