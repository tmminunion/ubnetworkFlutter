import 'dart:math' as math;

class ChokoteiProblem {
  ChokoteiProblem({
    required this.id,
    this.lineStation = '',
    this.machineName = '',
    this.problem = '',
    this.countermeasure = '',
    this.lossUnits = 0,
    this.delayMin = 0,
    this.category = 'EXT',
  });

  String id;
  String lineStation;
  String machineName;
  String problem;
  String countermeasure;
  int lossUnits;
  double delayMin;
  String category; // INT | EXT

  factory ChokoteiProblem.fromJson(Map<String, dynamic> j) => ChokoteiProblem(
        id: (j['id'] ?? 'p-${DateTime.now().millisecondsSinceEpoch}').toString(),
        lineStation: (j['line_station'] ?? j['machine'] ?? '').toString(),
        machineName: (j['machine_name'] ?? '').toString(),
        problem: (j['problem'] ?? '').toString(),
        countermeasure: (j['countermeasure'] ?? '').toString(),
        lossUnits: (j['loss_units'] as num?)?.toInt() ?? 0,
        delayMin: (j['delay_min'] ?? j['delay_minutes'] as num?)?.toDouble() ?? 0,
        category: ((j['category'] ?? 'INT').toString().toUpperCase() == 'EXT') ? 'EXT' : 'INT',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'line_station': lineStation,
        'machine_name': machineName,
        'machine': lineStation.isNotEmpty ? lineStation : machineName,
        'problem': problem,
        'countermeasure': countermeasure,
        'loss_units': lossUnits,
        'delay_min': delayMin,
        'delay_minutes': delayMin,
        'category': category,
      };

  ChokoteiProblem copy() => ChokoteiProblem(
        id: id,
        lineStation: lineStation,
        machineName: machineName,
        problem: problem,
        countermeasure: countermeasure,
        lossUnits: lossUnits,
        delayMin: delayMin,
        category: category,
      );
}

class HourlySlot {
  HourlySlot({
    required this.no,
    required this.timeRange,
    required this.plan,
    this.act,
    this.isOvertime = false,
    this.isEarlyOvertime = false,
    this.isBlocked = false,
    this.lineStation = '',
    this.problem = '',
    this.countermeasure = '',
    this.delayMin = 0,
    this.delayCategory = 'INT',
    this.lossUnits = 0,
    List<ChokoteiProblem>? problems,
  }) : problems = problems ?? [];

  int no;
  String timeRange;
  int plan;
  int? act;
  bool isOvertime;
  bool isEarlyOvertime;
  bool isBlocked;
  String lineStation;
  String problem;
  String countermeasure;
  double delayMin;
  String delayCategory;
  int lossUnits;
  List<ChokoteiProblem> problems;

  bool get hasFilled => !isBlocked && act != null;

  factory HourlySlot.fromJson(Map<String, dynamic> j) => HourlySlot(
        no: (j['no'] ?? j['slot_no'] as num?)?.toInt() ?? 1,
        timeRange: (j['timeRange'] ?? j['time_range'] ?? '').toString(),
        plan: (j['plan'] as num?)?.toInt() ?? 0,
        act: j['act'] == null || j['act'] == '' ? null : (j['act'] as num?)?.toInt(),
        isOvertime: j['isOvertime'] == true || j['is_overtime'] == true,
        isEarlyOvertime: j['isEarlyOvertime'] == true,
        isBlocked: j['isBlocked'] == true || j['is_blocked'] == true,
        lineStation: (j['lineStation'] ?? j['line_station'] ?? '').toString(),
        problem: (j['problem'] ?? '').toString(),
        countermeasure: (j['countermeasure'] ?? '').toString(),
        delayMin: (j['delayMin'] ?? j['delay_min'] as num?)?.toDouble() ?? 0,
        delayCategory: (j['delayCategory'] ?? j['category'] ?? 'INT').toString(),
        lossUnits: (j['loss_units'] as num?)?.toInt() ?? 0,
        problems: (j['problems'] as List?)
                ?.whereType<Map>()
                .map((e) => ChokoteiProblem.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'no': no,
        'slot_no': no,
        'timeRange': timeRange,
        'time_range': timeRange,
        'plan': plan,
        'act': act,
        'isOvertime': isOvertime,
        'isEarlyOvertime': isEarlyOvertime,
        'isBlocked': isBlocked,
        'is_blocked': isBlocked,
        'lineStation': lineStation,
        'line_station': lineStation,
        'problem': problem,
        'countermeasure': countermeasure,
        'delayMin': delayMin,
        'delay_min': delayMin,
        'delayCategory': delayCategory,
        'category': delayCategory,
        'loss_units': lossUnits,
        'problems': problems.map((p) => p.toJson()).toList(),
      };

  HourlySlot copy() => HourlySlot(
        no: no,
        timeRange: timeRange,
        plan: plan,
        act: act,
        isOvertime: isOvertime,
        isEarlyOvertime: isEarlyOvertime,
        isBlocked: isBlocked,
        lineStation: lineStation,
        problem: problem,
        countermeasure: countermeasure,
        delayMin: delayMin,
        delayCategory: delayCategory,
        lossUnits: lossUnits,
        problems: problems.map((p) => p.copy()).toList(),
      );
}

class ComputedSlot {
  ComputedSlot({
    required this.slot,
    required this.cumPlan,
    required this.cumAct,
    required this.cumDiff,
    required this.hourEff,
    required this.cumEff,
  });

  final HourlySlot slot;
  final int cumPlan;
  final int? cumAct;
  final int? cumDiff;
  final String hourEff;
  final String cumEff;
}

class CbuModelItem {
  CbuModelItem({
    required this.code,
    required this.name,
    this.qty = 0,
    this.ratio = 1.0,
  });

  String code;
  String name;
  int qty;
  double ratio;

  factory CbuModelItem.fromJson(Map<String, dynamic> j) => CbuModelItem(
        code: (j['code'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        qty: (j['qty'] as num?)?.toInt() ?? 0,
        ratio: (j['ratio'] as num?)?.toDouble() ?? 1.0,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'qty': qty,
        'ratio': ratio,
      };

  CbuModelItem copy() => CbuModelItem(code: code, name: name, qty: qty, ratio: ratio);
}

class CkdPartItem {
  CkdPartItem({
    required this.partNo,
    required this.partName,
    this.qty = 0,
  });

  String partNo;
  String partName;
  int qty;

  factory CkdPartItem.fromJson(Map<String, dynamic> j) => CkdPartItem(
        partNo: (j['part_no'] ?? '').toString(),
        partName: (j['part_name'] ?? '').toString(),
        qty: (j['qty'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'part_no': partNo,
        'part_name': partName,
        'qty': qty,
      };

  CkdPartItem copy() => CkdPartItem(partNo: partNo, partName: partName, qty: qty);
}

class MemberAbsen {
  MemberAbsen({
    required this.id,
    required this.name,
    this.noreg = '',
    this.status = 'Hadir',
    this.note = '',
  });

  int id;
  String name;
  String noreg;
  String status; // Hadir | Sakit | Izin | Cuti | Dinas | Alpa
  String note;

  factory MemberAbsen.fromJson(Map<String, dynamic> j) => MemberAbsen(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: (j['name'] ?? '').toString(),
        noreg: (j['noreg'] ?? '').toString(),
        status: (j['status'] ?? 'Hadir').toString(),
        note: (j['note'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'noreg': noreg,
        'status': status,
        'note': note,
      };

  MemberAbsen copy() => MemberAbsen(
        id: id,
        name: name,
        noreg: noreg,
        status: status,
        note: note,
      );
}

class TemplateSlotDef {
  const TemplateSlotDef({
    required this.slotNo,
    required this.timeRange,
    required this.durationMin,
    required this.basePlan19,
    required this.basePlan16,
    this.isOvertime = false,
  });

  final int slotNo;
  final String timeRange;
  final int durationMin;
  final int basePlan19;
  final int basePlan16;
  final bool isOvertime;
}

class ShiftTemplate {
  const ShiftTemplate({
    required this.code,
    required this.name,
    required this.subtitle,
    required this.category,
    required this.timeSession,
    required this.slots,
  });

  final String code;
  final String name;
  final String subtitle;
  final String category; // normal | puasa
  final String timeSession; // day | night
  final List<TemplateSlotDef> slots;
}

class UbSettings {
  UbSettings({
    this.lineName = 'UB ASSY',
    this.taktTime = 2.4,
    this.ccrTargetRed = 220,
    this.ccrTargetWhite = 220,
    this.serverApiUrl = 'https://bungtemin.net/ub/api',
    this.apiKey = '',
    this.sharepointSyncUrl = 'https://nudb.bungtemin.net/functions/ub_sp_sync',
    this.enableSharepointSync = true,
    this.role = 'ADMIN',
  });

  String lineName;
  double taktTime;
  int ccrTargetRed;
  int ccrTargetWhite;
  String serverApiUrl;
  String apiKey;
  String sharepointSyncUrl;
  bool enableSharepointSync;
  String role; // ADMIN | RED | WHITE | VIEWER

  bool canEditShift(String shift) {
    if (role == 'ADMIN') return true;
    if (role == 'VIEWER') return false;
    return role == shift;
  }

  factory UbSettings.fromJson(Map<String, dynamic> j) => UbSettings(
        lineName: (j['lineName'] ?? 'UB ASSY').toString(),
        taktTime: (j['taktTime'] as num?)?.toDouble() ?? 2.4,
        ccrTargetRed: (j['ccrTargetRed'] as num?)?.toInt() ?? 220,
        ccrTargetWhite: (j['ccrTargetWhite'] as num?)?.toInt() ?? 220,
        serverApiUrl: (j['serverApiUrl'] ?? 'https://bungtemin.net/ub/api').toString(),
        apiKey: (j['apiKey'] ?? '').toString(),
        sharepointSyncUrl: (j['sharepointSyncUrl'] ?? 'https://nudb.bungtemin.net/functions/ub_sp_sync').toString(),
        enableSharepointSync: j['enableSharepointSync'] != false,
        role: (j['role'] ?? 'ADMIN').toString(),
      );

  Map<String, dynamic> toJson() => {
        'lineName': lineName,
        'taktTime': taktTime,
        'ccrTargetRed': ccrTargetRed,
        'ccrTargetWhite': ccrTargetWhite,
        'serverApiUrl': serverApiUrl,
        'apiKey': apiKey,
        'sharepointSyncUrl': sharepointSyncUrl,
        'enableSharepointSync': enableSharepointSync,
        'role': role,
      };
}

class ChecksheetReport {
  ChecksheetReport({
    required this.id,
    required this.tanggal,
    required this.shift,
    this.session = 'day',
    this.workMode = 'normal',
    this.templateCode = 'pagi_normal',
    this.overtimeHours = 2,
    this.otAwal = 'none',
    this.lineName = 'UB ASSY',
    this.taktTime = 2.4,
    this.ccrPlan = 220,
    this.picName = 'DWI MULYONO',
    this.spvName = 'DADANG SURYADI / NUNU FATULAH',
    this.noBodyStart = '',
    this.noBodyFinish = '',
    this.jamStopProduksi = '',
    this.actOtHours = 0,
    this.actOtUnits = 0,
    this.cbuSource = 'ratio',
    required this.cbuModels,
    required this.ckdParts,
    required this.members,
    required this.slots,
    this.syncStatus = 'draft',
    this.updatedAt = '',
    this.lastSyncedAt = '',
  });

  String id;
  String tanggal;
  String shift; // RED | WHITE
  String session; // day | night
  String workMode; // normal | puasa
  String templateCode;
  int overtimeHours;
  String otAwal; // none | 30m | 1h
  String lineName;
  double taktTime;
  int ccrPlan;
  String picName;
  String spvName;
  String noBodyStart;
  String noBodyFinish;
  String jamStopProduksi;
  double actOtHours;
  int actOtUnits;
  String cbuSource; // ratio | manual
  List<CbuModelItem> cbuModels;
  List<CkdPartItem> ckdParts;
  List<MemberAbsen> members;
  List<HourlySlot> slots;
  String syncStatus; // draft | synced | failed
  String updatedAt;
  String lastSyncedAt;

  factory ChecksheetReport.fromJson(Map<String, dynamic> j) {
    final sh = (j['shift'] ?? 'WHITE').toString().toUpperCase();
    final rawCkd = (j['ckdParts'] as List?)
            ?.whereType<Map>()
            .map((e) => CkdPartItem.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    final isOldDummy = rawCkd.isNotEmpty &&
        rawCkd.every((p) => p.partNo.startsWith('5710') && p.qty == 0);
    return ChecksheetReport(
      id: (j['id'] ?? '').toString(),
      tanggal: (j['tanggal'] ?? UbMasterData.wibToday()).toString(),
      shift: sh == 'RED' ? 'RED' : 'WHITE',
      session: (j['session'] ?? 'day').toString(),
      workMode: (j['workMode'] ?? 'normal').toString(),
      templateCode: (j['templateCode'] ?? 'pagi_normal').toString(),
      overtimeHours: (j['overtimeHours'] as num?)?.toInt() ?? 2,
      otAwal: (j['otAwal'] ?? 'none').toString(),
      lineName: (j['lineName'] ?? 'UB ASSY').toString(),
      taktTime: (j['taktTime'] as num?)?.toDouble() ?? 2.4,
      ccrPlan: (j['ccrPlan'] as num?)?.toInt() ?? 220,
      picName: (j['picName'] ?? (sh == 'RED' ? 'KAMALUDIN' : 'DWI MULYONO')).toString(),
      spvName: (j['spvName'] ?? '').toString(),
      noBodyStart: (j['noBodyStart'] ?? '').toString(),
      noBodyFinish: (j['noBodyFinish'] ?? '').toString(),
      jamStopProduksi: (j['jamStopProduksi'] ?? '').toString(),
      actOtHours: (j['actOtHours'] as num?)?.toDouble() ?? 0,
      actOtUnits: (j['actOtUnits'] as num?)?.toInt() ?? 0,
      cbuSource: (j['cbuSource'] ?? 'ratio').toString(),
      cbuModels: (j['cbuModels'] as List?)
              ?.whereType<Map>()
              .map((e) => CbuModelItem.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          UbMasterData.defaultCbuModels(),
      ckdParts: (rawCkd.isEmpty || isOldDummy) ? UbMasterData.defaultCkdParts() : rawCkd,
      members: (j['members'] as List?)
              ?.whereType<Map>()
              .map((e) => MemberAbsen.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          UbMasterData.defaultMembers(sh),
      slots: (j['slots'] as List?)
              ?.whereType<Map>()
              .map((e) => HourlySlot.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          UbMasterData.buildSlotsFromTemplate('pagi_normal', 2.4, 2),
      syncStatus: (j['syncStatus'] ?? 'draft').toString(),
      updatedAt: (j['updatedAt'] ?? '').toString(),
      lastSyncedAt: (j['lastSyncedAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tanggal': tanggal,
        'shift': shift,
        'session': session,
        'workMode': workMode,
        'templateCode': templateCode,
        'overtimeHours': overtimeHours,
        'otAwal': otAwal,
        'lineName': lineName,
        'taktTime': taktTime,
        'ccrPlan': ccrPlan,
        'picName': picName,
        'spvName': spvName,
        'noBodyStart': noBodyStart,
        'noBodyFinish': noBodyFinish,
        'jamStopProduksi': jamStopProduksi,
        'actOtHours': actOtHours,
        'actOtUnits': actOtUnits,
        'cbuSource': cbuSource,
        'cbuModels': cbuModels.map((m) => m.toJson()).toList(),
        'ckdParts': ckdParts.map((p) => p.toJson()).toList(),
        'members': members.map((m) => m.toJson()).toList(),
        'slots': slots.map((s) => s.toJson()).toList(),
        'syncStatus': syncStatus,
        'updatedAt': updatedAt,
        'lastSyncedAt': lastSyncedAt,
      };
}

class IntProblemSummary {
  IntProblemSummary({
    required this.problem,
    required this.countermeasure,
    required this.totalDelay,
    required this.totalUnits,
    required this.occurrences,
  });

  final String problem;
  final String countermeasure;
  final double totalDelay;
  final int totalUnits;
  final int occurrences;
}

class ChecksheetStats {
  ChecksheetStats({
    required this.computedSlots,
    required this.totalPlan,
    required this.totalAct,
    required this.diff,
    required this.minusUnits,
    required this.efficiency,
    required this.totalDelayMin,
    required this.intDelayMin,
    required this.extDelayMin,
    required this.intLossUnits,
    required this.extLossUnits,
    required this.totalLossUnits,
    required this.intEffPct,
    required this.extEffPct,
    required this.totalEffPct,
    required this.internalEfficiency,
    required this.hadirCount,
    required this.absentCount,
    required this.attendanceRate,
    required this.totalCbu,
    required this.bodyRun,
    required this.effectiveCcrPlan,
    required this.ccrDiff,
    required this.otPlanHours,
    required this.otPlanUnits,
    required this.otActHours,
    required this.otActUnits,
    required this.estimatedFinishTime,
    required this.intProblems,
  });

  final List<ComputedSlot> computedSlots;
  final int totalPlan;
  final int totalAct;
  final int diff;
  final int minusUnits;
  final String efficiency;
  final double totalDelayMin;
  final double intDelayMin;
  final double extDelayMin;
  final int intLossUnits;
  final int extLossUnits;
  final int totalLossUnits;
  final String intEffPct;
  final String extEffPct;
  final String totalEffPct;
  final String internalEfficiency;
  final int hadirCount;
  final int absentCount;
  final double attendanceRate;
  final int totalCbu;
  final int bodyRun;
  final int effectiveCcrPlan;
  final int ccrDiff;
  final double otPlanHours;
  final int otPlanUnits;
  final double otActHours;
  final int otActUnits;
  final String estimatedFinishTime;
  final List<IntProblemSummary> intProblems;
}

class UbMasterData {
  UbMasterData._();

  static String wibToday() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static String makeReportId(String tanggal, String shift, String lineName) {
    return '${tanggal}_${shift}_${lineName.isEmpty ? 'UB_ASSY' : lineName}'
        .replaceAll(RegExp(r'\s+'), '_');
  }

  static String formatDDMMYYYY(String isoDate) {
    final p = isoDate.split('-');
    if (p.length == 3) return '${p[2]}-${p[1]}-${p[0]}';
    return isoDate;
  }

  static String formatEff(double val) {
    final clamped = val < 0 ? 0.0 : val;
    final raw = clamped.toStringAsFixed(1);
    return raw.endsWith('.0') ? raw.substring(0, raw.length - 2) : raw;
  }

  static String addNumberPreservePad(String raw, int delta) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    final numVal = int.tryParse(digits);
    if (numVal == null) return '';
    final next = math.max(0, numVal + delta);
    if (digits.length > 1 && digits.startsWith('0')) {
      return next.toString().padLeft(digits.length, '0');
    }
    return next.toString();
  }

  static List<CbuModelItem> defaultCbuModels() => [
        CbuModelItem(code: 'zenix', name: 'INNOVA ZENIX', qty: 0, ratio: 0.551),
        CbuModelItem(code: 'fortuner', name: 'FORTUNER', qty: 0, ratio: 0.401),
        CbuModelItem(code: 'innova', name: 'KIJANG INNOVA', qty: 0, ratio: 0.048),
      ];

  static List<CkdPartItem> defaultCkdParts() => [
        CkdPartItem(partNo: '57403-KK010', partName: 'Member Floor Side Inner RR RH', qty: 0),
        CkdPartItem(partNo: '57404-KK010', partName: 'Member Floor Side Inner RR LH', qty: 0),
      ];

  static List<CbuModelItem> calculateCbuByRatio(int targetTotal, List<CbuModelItem> models) {
    if (models.isEmpty) return [];
    if (targetTotal <= 0) {
      return models.map((m) => CbuModelItem(code: m.code, name: m.name, qty: 0, ratio: m.ratio)).toList();
    }
    final totalRatio = models.fold<double>(0, (a, m) => a + (m.ratio > 0 ? m.ratio : 1.0));
    if (totalRatio <= 0) {
      return models.map((m) => m.copy()).toList();
    }
    final quotas = models.map((m) {
      final r = m.ratio > 0 ? m.ratio : 1.0;
      final exact = (r / totalRatio) * targetTotal;
      final base = exact.floor();
      return (model: m, base: base, rem: exact - base);
    }).toList();

    final baseSum = quotas.fold<int>(0, (a, q) => a + q.base);
    final diff = targetTotal - baseSum;
    final sorted = [...quotas]..sort((a, b) => b.rem.compareTo(a.rem));
    final bonus = <String>{};
    for (var i = 0; i < diff && i < sorted.length; i++) {
      bonus.add(sorted[i].model.code);
    }
    return quotas
        .map((q) => CbuModelItem(
              code: q.model.code,
              name: q.model.name,
              ratio: q.model.ratio,
              qty: q.base + (bonus.contains(q.model.code) ? 1 : 0),
            ))
        .toList();
  }

  static List<MemberAbsen> defaultMembers(String shift) {
    if (shift.toUpperCase() == 'RED') {
      return [
        MemberAbsen(id: 1, name: 'KAMALUDIN', noreg: '00010207', note: 'GL • GL Office'),
        MemberAbsen(id: 2, name: 'MASRURI', noreg: '00009988', note: 'TL • TL Line'),
        MemberAbsen(id: 3, name: 'TRI RUSTIANTORO', noreg: '09405969', note: 'TL • TL Line (Sub)'),
        MemberAbsen(id: 4, name: 'SAIFUL RACHIM', noreg: '00010816', note: 'TL • Pos 1 Underbody Main'),
        MemberAbsen(id: 5, name: 'SARDI', noreg: '01121689', note: 'TM • Pos 2 Cross Member'),
        MemberAbsen(id: 6, name: 'AGUNG ISKANDAR', noreg: '00919939', note: 'TM • Pos 3 Spot Welding'),
        MemberAbsen(id: 7, name: 'YOYON SUYONO', noreg: '00112433', note: 'TM • Pos 4 Side Member'),
        MemberAbsen(id: 8, name: 'MUHAMMAD MARTALIH', noreg: '01425129', note: 'TM • Pos 5 Center Floor'),
        MemberAbsen(id: 9, name: 'ADIB SETYO BUDI', noreg: '02437420', note: 'TM • Pos 6 Rear Floor'),
        MemberAbsen(id: 10, name: 'CEVIN DANI', noreg: '02538186', note: 'TM • Pos 7 Inspection'),
        MemberAbsen(id: 11, name: 'SULARSO', noreg: '01221995', note: 'TM • Pos 8 Final Check'),
        MemberAbsen(id: 26, name: 'ALFI FAUZAN', noreg: '02639314', note: 'TM • Pos 1'),
        MemberAbsen(id: 27, name: 'GILANG RAMADHAN', noreg: '02639371', note: 'TM • Pos 1'),
        MemberAbsen(id: 28, name: 'RIZKY KHOLIS', noreg: '02639362', note: 'TM • Pos 1'),
        MemberAbsen(id: 29, name: 'IWAN AHDIAN', noreg: '00919943', note: 'TM • Pos 1'),
        MemberAbsen(id: 30, name: 'RIYANTO', noreg: '01324263', note: 'TM • Pos 1'),
        MemberAbsen(id: 31, name: 'DWI SUSANTO', noreg: '01021249', note: 'TM • Pos 1'),
        MemberAbsen(id: 32, name: 'MURYADI', noreg: '01021250', note: 'TM • Pos 1'),
        MemberAbsen(id: 33, name: 'NUR SOLEH', noreg: '01424871', note: 'TM • Pos 1'),
        MemberAbsen(id: 34, name: 'ALI YAFI', noreg: '01223255', note: 'TM • Pos 1'),
        MemberAbsen(id: 35, name: 'YULI WIDIYANTO', noreg: '01324254', note: 'TM • Pos 1'),
        MemberAbsen(id: 36, name: 'JAHID HUSEN', noreg: '01324580', note: 'TM • Pos 1'),
        MemberAbsen(id: 37, name: 'ARDHY CHANDRA', noreg: '02132225', note: 'TM • Pos 1'),
        MemberAbsen(id: 38, name: 'ANDREA HARDEKA', noreg: '02336012', note: 'TM • Pos 1'),
      ];
    }
    return [
      MemberAbsen(id: 12, name: 'DWI MULYONO', noreg: '00011044', note: 'GL • Group Leader'),
      MemberAbsen(id: 13, name: 'DADANG SURYADI', noreg: '00009978', note: 'TL • TL FRONT FLOOR'),
      MemberAbsen(id: 14, name: 'NUNU FATULAH', noreg: '00415024', note: 'TL • Team Leader Support'),
      MemberAbsen(id: 15, name: 'YANA SUHERYANA', noreg: '01222231', note: 'TM • Pos 1 Underbody Main'),
      MemberAbsen(id: 16, name: 'SUGENG SURYADI', noreg: '01222404', note: 'TM • Cross Member Fitting'),
      MemberAbsen(id: 17, name: 'MOH. CHUMAEDI', noreg: '01020746', note: 'TM • Pos 3 Spot Welding'),
      MemberAbsen(id: 18, name: 'RISWOKO', noreg: '01020747', note: 'TM • Pos 4 Side Member'),
      MemberAbsen(id: 19, name: 'FERDIANSYAH', noreg: '01121564', note: 'TM • Pos 5 Center Floor'),
      MemberAbsen(id: 20, name: 'ERI KOSWANTO', noreg: '01221988', note: 'TM • Pos 6 Rear Floor'),
      MemberAbsen(id: 21, name: 'RITNO', noreg: '01121566', note: 'TM • Pos 7 Inspection'),
      MemberAbsen(id: 22, name: 'AGUS PAJAR', noreg: '01020402', note: 'TM • Pos 8 Final Check'),
      MemberAbsen(id: 23, name: 'DIDIK SUGIONO', noreg: '01020180', note: 'TM • Front Floor'),
      MemberAbsen(id: 24, name: 'ROHIMIN', noreg: '01020679', note: 'TM • Pos 1'),
      MemberAbsen(id: 25, name: 'ASEP TABRONI', noreg: '01223093', note: 'TM • Pos 1'),
      MemberAbsen(id: 39, name: 'FAFAN', noreg: '26000001', note: 'TM • Pos 1'),
      MemberAbsen(id: 40, name: 'EQBAL', noreg: '26000002', note: 'TM • Pos 1'),
      MemberAbsen(id: 41, name: 'FAHRI', noreg: '26000003', note: 'TM • Pos 1'),
      MemberAbsen(id: 42, name: 'AZRYL', noreg: '26000004', note: 'TM • Pos 1'),
      MemberAbsen(id: 43, name: 'FAISAL', noreg: '26000005', note: 'TM • Pos 1'),
    ];
  }

  static const List<ShiftTemplate> masterTemplates = [
    ShiftTemplate(
      code: 'pagi_normal',
      name: 'Pagi Normal',
      subtitle: 'Senin - Kamis (07:20-16:00)',
      category: 'normal',
      timeSession: 'day',
      slots: [
        TemplateSlotDef(slotNo: 1, timeRange: '07:20 - 08:20', durationMin: 60, basePlan19: 28, basePlan16: 35),
        TemplateSlotDef(slotNo: 2, timeRange: '08:20 - 09:30', durationMin: 70, basePlan19: 37, basePlan16: 41),
        TemplateSlotDef(slotNo: 3, timeRange: '09:40 - 10:40', durationMin: 60, basePlan19: 32, basePlan16: 36),
        TemplateSlotDef(slotNo: 4, timeRange: '10:40 - 11:45', durationMin: 65, basePlan19: 34, basePlan16: 38),
        TemplateSlotDef(slotNo: 5, timeRange: '12:30 - 13:30', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 6, timeRange: '13:30 - 14:30', durationMin: 60, basePlan19: 31, basePlan16: 35),
        TemplateSlotDef(slotNo: 7, timeRange: '14:40 - 15:40', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 8, timeRange: '15:40 - 16:00', durationMin: 20, basePlan19: 11, basePlan16: 15),
        TemplateSlotDef(slotNo: 9, timeRange: '16:15 - 17:15', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
        TemplateSlotDef(slotNo: 10, timeRange: '17:15 - 18:15', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
        TemplateSlotDef(slotNo: 11, timeRange: '18:30 - 19:30', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
      ],
    ),
    ShiftTemplate(
      code: 'jumat_normal',
      name: 'Pagi Jumat',
      subtitle: 'Jumat Sholat (Pulang 16:30)',
      category: 'normal',
      timeSession: 'day',
      slots: [
        TemplateSlotDef(slotNo: 1, timeRange: '07:20 - 08:20', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 2, timeRange: '08:20 - 09:30', durationMin: 70, basePlan19: 37, basePlan16: 41),
        TemplateSlotDef(slotNo: 3, timeRange: '09:40 - 10:40', durationMin: 60, basePlan19: 32, basePlan16: 36),
        TemplateSlotDef(slotNo: 4, timeRange: '10:40 - 11:45', durationMin: 65, basePlan19: 34, basePlan16: 38),
        TemplateSlotDef(slotNo: 5, timeRange: '13:00 - 14:00', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 6, timeRange: '14:00 - 14:30', durationMin: 30, basePlan19: 16, basePlan16: 17),
        TemplateSlotDef(slotNo: 7, timeRange: '14:40 - 15:40', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 8, timeRange: '15:40 - 16:30', durationMin: 50, basePlan19: 26, basePlan16: 29),
        TemplateSlotDef(slotNo: 9, timeRange: '16:45 - 17:45', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
        TemplateSlotDef(slotNo: 10, timeRange: '17:45 - 18:45', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
        TemplateSlotDef(slotNo: 11, timeRange: '19:00 - 20:00', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
      ],
    ),
    ShiftTemplate(
      code: 'malam_normal',
      name: 'Malam Normal',
      subtitle: 'Masuk 20:05 s/d 07:45',
      category: 'normal',
      timeSession: 'night',
      slots: [
        TemplateSlotDef(slotNo: 1, timeRange: '20:05 - 21:00', durationMin: 55, basePlan19: 29, basePlan16: 32),
        TemplateSlotDef(slotNo: 2, timeRange: '21:00 - 22:00', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 3, timeRange: '22:10 - 23:00', durationMin: 50, basePlan19: 26, basePlan16: 30),
        TemplateSlotDef(slotNo: 4, timeRange: '23:00 - 00:00', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 5, timeRange: '00:30 - 01:30', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 6, timeRange: '01:30 - 02:30', durationMin: 60, basePlan19: 32, basePlan16: 36),
        TemplateSlotDef(slotNo: 7, timeRange: '02:40 - 03:40', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 8, timeRange: '03:40 - 04:45', durationMin: 65, basePlan19: 34, basePlan16: 38),
        TemplateSlotDef(slotNo: 9, timeRange: '04:45 - 05:45', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
        TemplateSlotDef(slotNo: 10, timeRange: '05:45 - 06:45', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
        TemplateSlotDef(slotNo: 11, timeRange: '06:45 - 07:45', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
      ],
    ),
    ShiftTemplate(
      code: 'pagi_puasa',
      name: 'Pagi Puasa',
      subtitle: 'Pulang 15:30 (Ramadhan)',
      category: 'puasa',
      timeSession: 'day',
      slots: [
        TemplateSlotDef(slotNo: 1, timeRange: '07:20 - 08:20', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 2, timeRange: '08:20 - 09:30', durationMin: 70, basePlan19: 37, basePlan16: 41),
        TemplateSlotDef(slotNo: 3, timeRange: '09:40 - 10:40', durationMin: 60, basePlan19: 32, basePlan16: 36),
        TemplateSlotDef(slotNo: 4, timeRange: '10:40 - 11:50', durationMin: 70, basePlan19: 37, basePlan16: 41),
        TemplateSlotDef(slotNo: 5, timeRange: '12:10 - 13:10', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 6, timeRange: '13:10 - 14:10', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 7, timeRange: '14:20 - 15:00', durationMin: 40, basePlan19: 21, basePlan16: 23),
        TemplateSlotDef(slotNo: 8, timeRange: '15:00 - 15:30', durationMin: 30, basePlan19: 16, basePlan16: 18),
        TemplateSlotDef(slotNo: 9, timeRange: '15:45 - 16:45', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
        TemplateSlotDef(slotNo: 10, timeRange: '16:45 - 17:45', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
        TemplateSlotDef(slotNo: 11, timeRange: '18:30 - 19:30', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
      ],
    ),
    ShiftTemplate(
      code: 'jumat_puasa',
      name: 'Jumat Puasa',
      subtitle: 'Jumat Sholat (Pulang 16:00)',
      category: 'puasa',
      timeSession: 'day',
      slots: [
        TemplateSlotDef(slotNo: 1, timeRange: '07:20 - 08:20', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 2, timeRange: '08:20 - 09:30', durationMin: 70, basePlan19: 37, basePlan16: 41),
        TemplateSlotDef(slotNo: 3, timeRange: '09:40 - 10:40', durationMin: 60, basePlan19: 32, basePlan16: 36),
        TemplateSlotDef(slotNo: 4, timeRange: '10:40 - 11:45', durationMin: 65, basePlan19: 34, basePlan16: 38),
        TemplateSlotDef(slotNo: 5, timeRange: '12:45 - 13:45', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 6, timeRange: '13:45 - 14:30', durationMin: 45, basePlan19: 24, basePlan16: 26),
        TemplateSlotDef(slotNo: 7, timeRange: '14:40 - 15:30', durationMin: 50, basePlan19: 26, basePlan16: 29),
        TemplateSlotDef(slotNo: 8, timeRange: '15:30 - 16:00', durationMin: 30, basePlan19: 16, basePlan16: 18),
        TemplateSlotDef(slotNo: 9, timeRange: '16:15 - 17:15', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
        TemplateSlotDef(slotNo: 10, timeRange: '17:15 - 17:45', durationMin: 30, basePlan19: 16, basePlan16: 18, isOvertime: true),
        TemplateSlotDef(slotNo: 11, timeRange: '18:30 - 19:30', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
      ],
    ),
    ShiftTemplate(
      code: 'malam_puasa',
      name: 'Malam Puasa',
      subtitle: 'Sahur & Subuh (03:30-04:15)',
      category: 'puasa',
      timeSession: 'night',
      slots: [
        TemplateSlotDef(slotNo: 1, timeRange: '20:15 - 21:15', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 2, timeRange: '21:15 - 22:15', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 3, timeRange: '22:25 - 23:25', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 4, timeRange: '23:25 - 00:30', durationMin: 65, basePlan19: 34, basePlan16: 38),
        TemplateSlotDef(slotNo: 5, timeRange: '00:45 - 01:45', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 6, timeRange: '01:45 - 02:45', durationMin: 60, basePlan19: 32, basePlan16: 35),
        TemplateSlotDef(slotNo: 7, timeRange: '02:55 - 03:30', durationMin: 35, basePlan19: 18, basePlan16: 21),
        TemplateSlotDef(slotNo: 8, timeRange: '04:15 - 05:00', durationMin: 45, basePlan19: 24, basePlan16: 26),
        TemplateSlotDef(slotNo: 9, timeRange: '05:00 - 06:00', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
        TemplateSlotDef(slotNo: 10, timeRange: '06:00 - 07:00', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
        TemplateSlotDef(slotNo: 11, timeRange: '07:00 - 08:00', durationMin: 60, basePlan19: 32, basePlan16: 35, isOvertime: true),
      ],
    ),
  ];

  static ShiftTemplate getTemplate(String code) {
    return masterTemplates.firstWhere(
      (t) => t.code == code,
      orElse: () => masterTemplates.first,
    );
  }

  static List<HourlySlot> buildSlotsFromTemplate(
    String tmplCode,
    double takt,
    int otHours, {
    List<HourlySlot>? prevSlots,
    String otAwalMode = 'none',
  }) {
    final tmpl = getTemplate(tmplCode);
    final isNight = tmplCode.startsWith('malam') || tmpl.timeSession == 'night';
    final isTt19 = (takt - 1.9).abs() < 0.05;
    final isTt16 = (takt - 1.6).abs() < 0.05;
    final out = <HourlySlot>[];

    for (final sl in tmpl.slots) {
      final prev = prevSlots?.cast<HourlySlot?>().firstWhere(
            (r) => r?.no == sl.slotNo,
            orElse: () => null,
          );

      if (isNight && sl.slotNo == 1 && tmplCode.contains('malam_normal')) {
        if (otAwalMode == 'none') {
          out.add(HourlySlot(
            no: 1,
            timeRange: sl.timeRange,
            plan: 0,
            isOvertime: true,
            isEarlyOvertime: true,
            isBlocked: true,
            lineStation: '-',
          ));
          continue;
        }
        final dur = otAwalMode == '30m' ? 30 : sl.durationMin;
        final tr = otAwalMode == '30m' ? '20:30 - 21:00' : '20:00 - 21:00';
        final p1 = otAwalMode == '30m'
            ? (30 / takt).round()
            : (isTt19 ? sl.basePlan19 : (isTt16 ? sl.basePlan16 : (dur / takt).round()));
        out.add(HourlySlot(
          no: 1,
          timeRange: tr,
          plan: p1,
          act: (prev != null && !prev.isBlocked) ? prev.act : null,
          isOvertime: true,
          isEarlyOvertime: true,
          isBlocked: false,
          lineStation: prev?.lineStation ?? '',
          problem: prev?.problem ?? '',
          countermeasure: prev?.countermeasure ?? '',
          delayMin: prev?.delayMin ?? 0,
          problems: prev?.problems.map((p) => p.copy()).toList() ?? [],
        ));
        continue;
      }

      final isOt = sl.isOvertime || sl.slotNo >= 9;
      var isOtActive = true;
      if (isOt) {
        final otIdx = sl.slotNo - 9;
        if (otIdx >= 0 && otHours <= otIdx) isOtActive = false;
      }
      var calcPlan = 0;
      if (isOtActive) {
        if (isTt19 && sl.basePlan19 > 0) {
          calcPlan = sl.basePlan19;
        } else if (isTt16 && sl.basePlan16 > 0) {
          calcPlan = sl.basePlan16;
        } else {
          calcPlan = (sl.durationMin / takt).round();
        }
      }
      final blocked = isOt ? !isOtActive : (prev?.isBlocked ?? false);
      out.add(HourlySlot(
        no: sl.slotNo,
        timeRange: sl.timeRange,
        plan: blocked ? 0 : calcPlan,
        act: !blocked ? prev?.act : null,
        isOvertime: isOt,
        isBlocked: blocked,
        lineStation: blocked ? '' : (prev?.lineStation ?? ''),
        problem: blocked ? '' : (prev?.problem ?? ''),
        countermeasure: blocked ? '' : (prev?.countermeasure ?? ''),
        delayMin: blocked ? 0 : (prev?.delayMin ?? 0),
        delayCategory: prev?.delayCategory ?? 'INT',
        problems: blocked ? [] : (prev?.problems.map((p) => p.copy()).toList() ?? []),
      ));
    }
    return out;
  }

  static ChecksheetStats computeStats(ChecksheetReport rep) {
    var cumPlan = 0;
    var cumAct = 0;
    var cumPlanFilled = 0;
    var totalDelay = 0.0;
    var intDelay = 0.0;
    var extDelay = 0.0;
    var anyFilled = false;
    final takt = rep.taktTime > 0 ? rep.taktTime : 2.4;

    final computed = <ComputedSlot>[];
    for (final r in rep.slots) {
      if (r.isBlocked) {
        computed.add(ComputedSlot(
          slot: r,
          cumPlan: 0,
          cumAct: null,
          cumDiff: null,
          hourEff: '-',
          cumEff: '-',
        ));
        continue;
      }
      cumPlan += r.plan;
      final isFilled = r.act != null;
      if (isFilled) {
        anyFilled = true;
        cumAct += r.act!;
        cumPlanFilled += r.plan;
      }
      if (r.problems.isNotEmpty) {
        for (final p in r.problems) {
          final d = p.delayMin > 0 ? p.delayMin : double.parse((p.lossUnits * takt).toStringAsFixed(1));
          totalDelay += d;
          if (p.category == 'EXT') {
            extDelay += d;
          } else {
            intDelay += d;
          }
        }
      } else if (r.problem.trim().isNotEmpty) {
        final d = r.delayMin > 0 ? r.delayMin : double.parse((r.lossUnits * takt).toStringAsFixed(1));
        totalDelay += d;
        if (r.delayCategory == 'EXT') {
          extDelay += d;
        } else {
          intDelay += d;
        }
      }
      final hourEff = isFilled && r.plan > 0 ? ((r.act! / r.plan) * 100).toStringAsFixed(0) : '-';
      final cumEff = isFilled && cumPlanFilled > 0 ? formatEff((cumAct / cumPlanFilled) * 100) : '-';
      computed.add(ComputedSlot(
        slot: r,
        cumPlan: cumPlan,
        cumAct: isFilled ? cumAct : null,
        cumDiff: isFilled ? (cumAct - cumPlanFilled) : null,
        hourEff: hourEff,
        cumEff: cumEff,
      ));
    }

    final diff = anyFilled ? (cumAct - cumPlanFilled) : 0;
    final minusUnits = anyFilled ? math.max(0, cumPlanFilled - cumAct) : 0;
    final efficiency = cumPlanFilled > 0 ? formatEff((cumAct / cumPlanFilled) * 100) : (anyFilled ? '100' : '0');
    final fallbackDelay = (totalDelay == 0 && minusUnits > 0)
        ? double.parse((minusUnits * takt).toStringAsFixed(1))
        : double.parse(totalDelay.toStringAsFixed(1));
    final effIntDelay = intDelay > 0
        ? double.parse(intDelay.toStringAsFixed(1))
        : (extDelay == 0 && fallbackDelay > 0 ? fallbackDelay : 0.0);
    final effExtDelay = double.parse(extDelay.toStringAsFixed(1));
    final intLossU = (effIntDelay / takt).round();
    final extLossU = (effExtDelay / takt).round();
    final totLossU = intLossU + extLossU;
    final intEffPct = cumPlanFilled > 0 ? formatEff(((cumPlanFilled - intLossU) / cumPlanFilled) * 100) : '-';
    final extEffPct = cumPlanFilled > 0 ? formatEff(((cumPlanFilled - extLossU) / cumPlanFilled) * 100) : '-';
    final totEffPct = cumPlanFilled > 0 ? formatEff(((cumPlanFilled - totLossU) / cumPlanFilled) * 100) : '-';
    final internalEff = intEffPct != '-' ? intEffPct : efficiency;

    final hadir = rep.members.where((m) => m.status == 'Hadir' || m.status.isEmpty).length;
    final absen = rep.members.length - hadir;
    final attRate = rep.members.isNotEmpty
        ? double.parse(((hadir / rep.members.length) * 100).toStringAsFixed(1))
        : 100.0;

    final sNum = int.tryParse(rep.noBodyStart.replaceAll(RegExp(r'\D'), ''));
    final fNum = int.tryParse(rep.noBodyFinish.replaceAll(RegExp(r'\D'), ''));
    final bodyRun = (sNum != null && fNum != null && fNum >= sNum) ? (fNum - sNum + 1) : cumAct;

    final effCcr = rep.ccrPlan > 0 ? rep.ccrPlan : cumPlan;
    final otSlots = rep.slots.where((r) => r.isOvertime && !r.isBlocked).toList();
    final otPlanH = otSlots.fold<double>(0, (a, r) => a + (r.timeRange.contains('20:30') ? 0.5 : 1.0));
    final otPlanU = otSlots.fold<int>(0, (a, r) => a + r.plan);
    final otActH = rep.actOtHours > 0 ? rep.actOtHours : otPlanH;
    final otActU = rep.actOtUnits > 0
        ? rep.actOtUnits
        : otSlots.fold<int>(0, (a, r) => a + (r.act ?? 0));

    // Estimated finish time
    var estFin = '-';
    final active = rep.slots.where((r) => !r.isBlocked).toList();
    if (active.isNotEmpty) {
      final last = active.last;
      final units = (last.act != null && last.act! > 0) ? last.act! : last.plan;
      final tp = last.timeRange.split('-');
      final st = tp.isNotEmpty ? tp.first.trim() : '';
      final en = tp.length > 1 ? tp[1].trim() : '';
      final tmpl = getTemplate(rep.templateCode);
      final tsl = tmpl.slots.cast<TemplateSlotDef?>().firstWhere(
            (s) => s?.slotNo == last.no,
            orElse: () => null,
          );
      final baseP = tsl != null ? (tsl.basePlan19 > 0 ? tsl.basePlan19 : (tsl.durationMin / takt).round()) : 32;
      if (units >= baseP && en.isNotEmpty) {
        estFin = en;
      } else if (st.contains(':')) {
        final sp = st.split(':');
        final h = int.tryParse(sp[0]) ?? 0;
        final m = int.tryParse(sp[1]) ?? 0;
        var mins = (h * 60 + m + (units * takt).round()) % 1440;
        if (mins < 0) mins += 1440;
        estFin = '${(mins ~/ 60).toString().padLeft(2, '0')}:${(mins % 60).toString().padLeft(2, '0')}';
      }
    }

    // Group INT problems
    final grouped = <String, ({String problem, String cm, double delay, int units, int cnt})>{};
    for (final r in rep.slots) {
      if (r.isBlocked) continue;
      if (r.problems.isNotEmpty) {
        for (final p in r.problems) {
          if (p.category == 'EXT') continue;
          final lbl = (p.problem.isNotEmpty ? p.problem : (p.machineName.isNotEmpty ? p.machineName : '-')).trim();
          final k = lbl.toLowerCase();
          final prev = grouped[k];
          if (prev != null) {
            grouped[k] = (
              problem: prev.problem,
              cm: prev.cm.isNotEmpty ? prev.cm : p.countermeasure,
              delay: prev.delay + p.delayMin,
              units: prev.units + p.lossUnits,
              cnt: prev.cnt + 1,
            );
          } else {
            grouped[k] = (problem: lbl, cm: p.countermeasure, delay: p.delayMin, units: p.lossUnits, cnt: 1);
          }
        }
      } else if (r.problem.trim().isNotEmpty && r.delayCategory != 'EXT') {
        final lbl = r.problem.trim();
        final k = lbl.toLowerCase();
        final prev = grouped[k];
        if (prev != null) {
          grouped[k] = (
            problem: prev.problem,
            cm: prev.cm.isNotEmpty ? prev.cm : r.countermeasure,
            delay: prev.delay + r.delayMin,
            units: prev.units + r.lossUnits,
            cnt: prev.cnt + 1,
          );
        } else {
          grouped[k] = (problem: lbl, cm: r.countermeasure, delay: r.delayMin, units: r.lossUnits, cnt: 1);
        }
      }
    }

    return ChecksheetStats(
      computedSlots: computed,
      totalPlan: cumPlan,
      totalAct: cumAct,
      diff: diff,
      minusUnits: minusUnits,
      efficiency: efficiency,
      totalDelayMin: fallbackDelay,
      intDelayMin: effIntDelay,
      extDelayMin: effExtDelay,
      intLossUnits: intLossU,
      extLossUnits: extLossU,
      totalLossUnits: totLossU,
      intEffPct: intEffPct,
      extEffPct: extEffPct,
      totalEffPct: totEffPct,
      internalEfficiency: internalEff,
      hadirCount: hadir,
      absentCount: absen,
      attendanceRate: attRate,
      totalCbu: rep.cbuModels.fold<int>(0, (a, m) => a + m.qty),
      bodyRun: bodyRun,
      effectiveCcrPlan: effCcr,
      ccrDiff: cumAct - effCcr,
      otPlanHours: otPlanH,
      otPlanUnits: otPlanU,
      otActHours: otActH,
      otActUnits: otActU,
      estimatedFinishTime: estFin,
      intProblems: grouped.values
          .map((g) => IntProblemSummary(
                problem: g.problem,
                countermeasure: g.cm,
                totalDelay: double.parse(g.delay.toStringAsFixed(1)),
                totalUnits: g.units,
                occurrences: g.cnt,
              ))
          .toList(),
    );
  }
}
