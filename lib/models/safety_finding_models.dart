// 1:1 Dart port of ubnetwork/app/lib/safetyRisk.ts & safety-proses-data.ts
// Standar Resmi Penilaian Resiko Bahaya (Toyota Welding Shop Karawang Plant)

class RiskOption {
  const RiskOption({
    required this.key,
    required this.label,
    required this.desc,
    required this.point,
  });

  final String key;
  final String label;
  final String desc;
  final int point;
}

class Stop6Option {
  const Stop6Option({required this.code, required this.name});

  final String code;
  final String name;
}

class RiskEvaluation {
  const RiskEvaluation({
    required this.total,
    required this.rank,
    required this.category,
    required this.levelName,
    required this.injuryKey,
  });

  final int? total;
  final String rank; // Aa, Ab, Ba, Bb, Bc, Cc, or ""
  final String category; // A, B, C, or ""
  final String levelName;
  final String? injuryKey; // a, b, c
}

class SafetyRiskMaster {
  SafetyRiskMaster._();

  static const List<String> hazards = [
    'Abnormal',
    'Operation Delay',
    'Low Frequency',
    'Existing hazard / Regular process',
  ];

  static const List<String> flatSources = [
    'Yokoten Accident',
    'TOP Management Patrol',
    'Safety Close Up',
    'Work Risk Assessment',
    'Safety Patrol Internal',
    'Safety Patrol SHE',
    'KYT',
    'Hyarihatto',
    'Voice Member',
    'Changing Point / Henkaten',
    'Machine Safety Audit',
    'Safety Device Check',
  ];

  static const List<Stop6Option> stop6Options = [
    Stop6Option(code: 'A', name: 'Apparatus (Mesin)'),
    Stop6Option(code: 'B', name: 'Big Heavy (Tertimpa)'),
    Stop6Option(code: 'C', name: 'Car / Kendaraan'),
    Stop6Option(code: 'D', name: 'Drop (Ketinggian)'),
    Stop6Option(code: 'E', name: 'Electricity (Listrik)'),
    Stop6Option(code: 'F', name: 'Fire (Kebakaran)'),
    Stop6Option(code: 'O', name: 'Others (Lain-lain)'),
  ];

  static const List<RiskOption> injuryLevels = [
    RiskOption(key: 'a', label: 'Level a (Fatal)', desc: 'Kecelakaan fatal ( a )', point: 12),
    RiskOption(key: 'b', label: 'Level b (Cuti)', desc: 'Kecelakaan yang memerlukan cuti ( b )', point: 6),
    RiskOption(key: 'c', label: 'Level c (Tanpa Cuti)', desc: 'Kecelakaan tanpa cuti ( c )', point: 2),
  ];

  static const List<RiskOption> frequencyLevels = [
    RiskOption(key: 'tinggi', label: 'Tinggi (1x/Minggu)', desc: 'Tinggi = 1x / Minggu', point: 5),
    RiskOption(key: 'sedang', label: 'Sedang (1x/Bulan)', desc: 'Sedang = 1x / Bulan', point: 4),
    RiskOption(key: 'rendah', label: 'Rendah (1x/Tahun)', desc: 'Rendah = 1x / Tahun', point: 3),
  ];

  static const List<RiskOption> countermeasureLevels = [
    RiskOption(
      key: 'rendah',
      label: 'Rendah (8 pt)',
      desc: 'Level rendah (tidak ada CM safety, tergantung kehati-hatian orang)',
      point: 8,
    ),
    RiskOption(
      key: 'sedang',
      label: 'Sedang (4 pt)',
      desc: 'Level sedang (countermeasure tergantung sebagian orang)',
      point: 4,
    ),
    RiskOption(
      key: 'tinggi',
      label: 'Tinggi (1 pt)',
      desc: 'Level tinggi (pokayoke / tidak tergantung orang)',
      point: 1,
    ),
  ];

  static const Map<String, String> statusLabels = {
    'open': 'Belum',
    'progress': 'Proses',
    'closed': 'Selesai',
  };

  static const Map<String, int> rankSeverityWeight = {
    'Aa': 6,
    'Ab': 5,
    'Ba': 4,
    'Bb': 3,
    'Bc': 2,
    'Cc': 1,
  };

  static RiskEvaluation evaluateSafetyRisk(int? injuryPoint, int? freqPoint, int? cmPoint) {
    if (injuryPoint == null || freqPoint == null || cmPoint == null) {
      return const RiskEvaluation(
        total: null,
        rank: '',
        category: '',
        levelName: '',
        injuryKey: null,
      );
    }

    final sum = injuryPoint + freqPoint + cmPoint;
    final String injuryKey;
    if (injuryPoint >= 12) {
      injuryKey = 'a';
    } else if (injuryPoint >= 6) {
      injuryKey = 'b';
    } else {
      injuryKey = 'c';
    }

    if (sum >= 19) {
      return RiskEvaluation(
        total: sum,
        rank: injuryKey == 'a' ? 'Aa' : 'Ab',
        category: 'A',
        levelName: 'Bahaya besar',
        injuryKey: injuryKey,
      );
    }
    if (sum >= 10) {
      return RiskEvaluation(
        total: sum,
        rank: injuryKey == 'a' ? 'Ba' : (injuryKey == 'b' ? 'Bb' : 'Bc'),
        category: 'B',
        levelName: 'Bahaya sedang',
        injuryKey: injuryKey,
      );
    }
    return RiskEvaluation(
      total: sum,
      rank: 'Cc',
      category: 'C',
      levelName: 'Bahaya kecil',
      injuryKey: injuryKey,
    );
  }

  static bool isRankDown(String? beforeRank, String? afterRank) {
    if (beforeRank == null || afterRank == null) return false;
    final b = beforeRank.replaceAll(RegExp(r'\s+'), '');
    final a = afterRank.replaceAll(RegExp(r'\s+'), '');
    final wb = rankSeverityWeight[b] ?? 0;
    final wa = rankSeverityWeight[a] ?? 0;
    return wb > 0 && wa > 0 && wb > wa;
  }
}

class SafetyRiskPart {
  SafetyRiskPart({this.desc = '', this.point});

  String desc;
  int? point;

  SafetyRiskPart copyWith({String? desc, int? point, bool clearPoint = false}) => SafetyRiskPart(
        desc: desc ?? this.desc,
        point: clearPoint ? null : (point ?? this.point),
      );

  Map<String, dynamic> toJson() => {'desc': desc, 'point': point};

  factory SafetyRiskPart.fromJson(Map<String, dynamic>? json) {
    if (json == null) return SafetyRiskPart();
    final rawPt = json['point'];
    return SafetyRiskPart(
      desc: (json['desc'] ?? '').toString(),
      point: rawPt == null ? null : (rawPt is num ? rawPt.toInt() : int.tryParse(rawPt.toString())),
    );
  }
}

class SafetyRisk {
  SafetyRisk({
    this.accident = '',
    this.code = '',
    this.typeName = '',
    SafetyRiskPart? injury,
    SafetyRiskPart? frequency,
    SafetyRiskPart? countermeasure,
    this.rank = '',
  })  : injury = injury ?? SafetyRiskPart(),
        frequency = frequency ?? SafetyRiskPart(),
        countermeasure = countermeasure ?? SafetyRiskPart();

  String accident;
  String code;
  String typeName;
  SafetyRiskPart injury;
  SafetyRiskPart frequency;
  SafetyRiskPart countermeasure;
  String rank;

  int? get totalPoints {
    final pts = [injury.point, frequency.point, countermeasure.point].whereType<int>().toList();
    if (pts.isEmpty) return null;
    return pts.fold<int>(0, (a, b) => a + b);
  }

  RiskEvaluation get evaluation =>
      SafetyRiskMaster.evaluateSafetyRisk(injury.point, frequency.point, countermeasure.point);

  String get effectiveRank => rank.trim().isNotEmpty ? rank.trim() : evaluation.rank;

  bool get hasData =>
      accident.trim().isNotEmpty || code.trim().isNotEmpty || rank.trim().isNotEmpty || totalPoints != null;

  SafetyRisk copyWith({
    String? accident,
    String? code,
    String? typeName,
    SafetyRiskPart? injury,
    SafetyRiskPart? frequency,
    SafetyRiskPart? countermeasure,
    String? rank,
  }) =>
      SafetyRisk(
        accident: accident ?? this.accident,
        code: code ?? this.code,
        typeName: typeName ?? this.typeName,
        injury: injury ?? this.injury.copyWith(),
        frequency: frequency ?? this.frequency.copyWith(),
        countermeasure: countermeasure ?? this.countermeasure.copyWith(),
        rank: rank ?? this.rank,
      );

  Map<String, dynamic> toJson() => {
        'accident': accident,
        'code': code,
        'typeName': typeName,
        'injury': injury.toJson(),
        'frequency': frequency.toJson(),
        'countermeasure': countermeasure.toJson(),
        'rank': rank,
      };

  factory SafetyRisk.fromJson(Map<String, dynamic>? json) {
    if (json == null) return SafetyRisk();
    return SafetyRisk(
      accident: (json['accident'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      typeName: (json['typeName'] ?? '').toString(),
      injury: SafetyRiskPart.fromJson(json['injury'] is Map ? Map<String, dynamic>.from(json['injury'] as Map) : null),
      frequency: SafetyRiskPart.fromJson(json['frequency'] is Map ? Map<String, dynamic>.from(json['frequency'] as Map) : null),
      countermeasure: SafetyRiskPart.fromJson(
          json['countermeasure'] is Map ? Map<String, dynamic>.from(json['countermeasure'] as Map) : null),
      rank: (json['rank'] ?? '').toString(),
    );
  }
}

class SafetyFinding {
  SafetyFinding({
    required this.id,
    this.no = '',
    this.status = 'open',
    this.shift = 'white',
    this.foundAt = '',
    this.location = 'UB ASSY',
    this.process = '',
    this.photo = '',
    this.photoAfter = '',
    this.theme = '',
    this.result = '',
    this.caption = '',
    this.hazard = 0,
    List<int>? sources,
    SafetyRisk? before,
    this.standard = '',
    this.pic = '',
    this.date = '',
    this.cm = '',
    SafetyRisk? after,
    this.syncStatus = 'local',
  })  : sources = sources ?? <int>[],
        before = before ?? SafetyRisk(),
        after = after ?? SafetyRisk();

  String id;
  String no;
  String status; // open | progress | closed
  String shift; // red | white
  String foundAt; // YYYY-MM-DD
  String location;
  String process;
  String photo;
  String photoAfter;
  String theme;
  String result;
  String caption;
  int hazard; // 0..3
  List<int> sources;
  SafetyRisk before;
  String standard;
  String pic;
  String date;
  String cm;
  SafetyRisk after;
  String syncStatus; // local | synced

  bool get hasKaizenReport =>
      theme.trim().isNotEmpty ||
      result.trim().isNotEmpty ||
      photoAfter.trim().isNotEmpty ||
      after.rank.trim().isNotEmpty ||
      after.totalPoints != null;

  ({int beforePt, int afterPt, int diff, int pct})? get riskDelta {
    final tb = before.totalPoints;
    final ta = after.totalPoints;
    if (tb == null || ta == null) return null;
    final diff = tb - ta;
    final pct = tb > 0 ? ((diff / tb) * 100).round() : 0;
    return (beforePt: tb, afterPt: ta, diff: diff, pct: pct);
  }

  SafetyFinding copyWith({
    String? id,
    String? no,
    String? status,
    String? shift,
    String? foundAt,
    String? location,
    String? process,
    String? photo,
    String? photoAfter,
    String? theme,
    String? result,
    String? caption,
    int? hazard,
    List<int>? sources,
    SafetyRisk? before,
    String? standard,
    String? pic,
    String? date,
    String? cm,
    SafetyRisk? after,
    String? syncStatus,
  }) =>
      SafetyFinding(
        id: id ?? this.id,
        no: no ?? this.no,
        status: status ?? this.status,
        shift: shift ?? this.shift,
        foundAt: foundAt ?? this.foundAt,
        location: location ?? this.location,
        process: process ?? this.process,
        photo: photo ?? this.photo,
        photoAfter: photoAfter ?? this.photoAfter,
        theme: theme ?? this.theme,
        result: result ?? this.result,
        caption: caption ?? this.caption,
        hazard: hazard ?? this.hazard,
        sources: sources ?? List<int>.from(this.sources),
        before: before ?? this.before.copyWith(),
        standard: standard ?? this.standard,
        pic: pic ?? this.pic,
        date: date ?? this.date,
        cm: cm ?? this.cm,
        after: after ?? this.after.copyWith(),
        syncStatus: syncStatus ?? this.syncStatus,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'no': no,
        'status': status,
        'shift': shift,
        'foundAt': foundAt,
        'location': location,
        'process': process,
        'photo': photo,
        'photoAfter': photoAfter,
        'theme': theme,
        'result': result,
        'caption': caption,
        'hazard': hazard,
        'sources': sources,
        'before': before.toJson(),
        'standard': standard,
        'pic': pic,
        'date': date,
        'cm': cm,
        'after': after.toJson(),
        'syncStatus': syncStatus,
      };

  factory SafetyFinding.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources'];
    final parsedSources = rawSources is List
        ? rawSources.map((e) => e is num ? e.toInt() : int.tryParse(e.toString()) ?? -1).where((e) => e >= 0).toList()
        : <int>[];
    final rawHazard = json['hazard'];
    final parsedHazard = rawHazard is num ? rawHazard.toInt() : (int.tryParse(rawHazard?.toString() ?? '0') ?? 0);

    return SafetyFinding(
      id: (json['_id'] ?? json['id'] ?? DateTime.now().microsecondsSinceEpoch.toString()).toString(),
      no: (json['no'] ?? '').toString(),
      status: (json['status'] ?? 'open').toString(),
      shift: (json['shift'] ?? 'white').toString().toLowerCase() == 'red' ? 'red' : 'white',
      foundAt: (json['foundAt'] ?? '').toString(),
      location: (json['location'] ?? 'UB ASSY').toString(),
      process: (json['process'] ?? '').toString(),
      photo: (json['photo'] ?? '').toString(),
      photoAfter: (json['photoAfter'] ?? '').toString(),
      theme: (json['theme'] ?? '').toString(),
      result: (json['result'] ?? '').toString(),
      caption: (json['caption'] ?? '').toString(),
      hazard: parsedHazard.clamp(0, 3),
      sources: parsedSources,
      before: SafetyRisk.fromJson(json['before'] is Map ? Map<String, dynamic>.from(json['before'] as Map) : null),
      standard: (json['standard'] ?? '').toString(),
      pic: (json['pic'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      cm: (json['cm'] ?? '').toString(),
      after: SafetyRisk.fromJson(json['after'] is Map ? Map<String, dynamic>.from(json['after'] as Map) : null),
      syncStatus: (json['syncStatus'] ?? 'local').toString(),
    );
  }
}

List<SafetyFinding> defaultSafetyFindings() => [
      SafetyFinding(
        id: 'seed_1',
        no: '1',
        status: 'closed',
        shift: 'red',
        foundAt: '2024-08-27',
        location: 'UB ASSY',
        process: 'LINE ASSY',
        caption: 'Operator tidak menggunakan APD Leg Protector',
        hazard: 0,
        sources: [4],
        before: SafetyRisk(
          accident: 'Tersayat, terjepit, terbentur benda, dll',
          code: 'O',
          typeName: 'Others (Lain-lain)',
          injury: SafetyRiskPart(desc: 'Tidak Memerlukan Cuti (Level c)', point: 2),
          frequency: SafetyRiskPart(desc: 'Tinggi = 1x / Minggu', point: 5),
          countermeasure: SafetyRiskPart(desc: 'Level sedang (countermeasure tergantung sebagian orang)', point: 4),
          rank: 'Bc',
        ),
        standard: 'Sosialisasi ke semua member pentingnya menggunakan APD',
        pic: 'MH Anwar',
        date: '05/09/24',
        cm: 'Sosialisasi pentingnya penggunaan APD.',
        after: SafetyRisk(
          accident: 'Tersayat',
          code: 'O',
          typeName: 'Others (Lain-lain)',
          injury: SafetyRiskPart(desc: 'Tidak Memerlukan Cuti (Level c)', point: 2),
          frequency: SafetyRiskPart(desc: 'Tinggi = 1x / Minggu', point: 5),
          countermeasure: SafetyRiskPart(desc: 'Level tinggi (pokayoke / tidak tergantung orang)', point: 1),
          rank: 'Cc',
        ),
        theme: 'MENANGGULANGI PENGGUNAAN APD LEG PROTECTOR',
        result: 'OPERATOR DISIPLIN MENGGUNAKAN APD LEG PROTECTOR, RISIKO TERSAYAT TURUN KE CC.',
      ),
      SafetyFinding(
        id: 'seed_2',
        no: '2',
        status: 'progress',
        shift: 'red',
        foundAt: '2024-08-27',
        location: 'UB ASSY',
        process: 'BUFFER UUU/UUB/UUD',
        caption: 'Lampu Mati Area Buffer UUU, UUB, UUD — Area kurang penerangan',
        hazard: 0,
        sources: [4],
        standard: 'Ganti Lampu yang mati agar penerangan optimal',
        pic: 'MH Anwar',
        date: '09/09/24',
        cm: 'Ganti lampu LED baru area buffer',
      ),
      SafetyFinding(
        id: 'seed_3',
        no: '3',
        status: 'open',
        shift: 'white',
        foundAt: '2026-10-14',
        location: 'UB ASSY',
        process: 'SPOT STATION 3',
        caption: 'Pagar pengaman mesin spot welding renggang',
        hazard: 3,
        sources: [10],
        before: SafetyRisk(
          accident: 'Terjepit robot / mesin spot',
          code: 'A',
          typeName: 'Apparatus (Mesin)',
          injury: SafetyRiskPart(desc: 'Kecelakaan yang memerlukan cuti ( b )', point: 6),
          frequency: SafetyRiskPart(desc: 'Tinggi = 1x / Minggu', point: 5),
          countermeasure: SafetyRiskPart(desc: 'Level rendah (tidak ada CM safety)', point: 8),
          rank: 'Ab',
        ),
        standard: 'Rapatkan pagar pengaman dan pasang interlock gate',
        pic: 'Dedi K.',
      ),
    ];
