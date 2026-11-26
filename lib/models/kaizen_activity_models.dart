// 1:1 Models & Seed Data for Fase 7.2 Aktivitas Kaizen:
// - QCC (Quality Control Circle — 8 Langkah PDCA Risalah A3)
// - TPM (Total Productive Maintenance — Jishu Hozen & OEE)
// - 5R / 5S (Audit 5 Pilar, Red-Tag Register, Shadow Board)
// - SW Observasi (TSKK / SWCS & Genba Time Study 10 Siklus + EIS)

class QccMember {
  QccMember({
    required this.name,
    required this.role,
    required this.section,
    required this.shift,
  });

  final String name;
  final String role; // LEADER | FACILITATOR | SECRETARY | MEMBER
  final String section;
  final String shift; // RED | WHITE

  factory QccMember.fromJson(Map<String, dynamic> j) => QccMember(
        name: (j['name'] ?? '').toString(),
        role: (j['role'] ?? 'MEMBER').toString(),
        section: (j['section'] ?? '').toString(),
        shift: (j['shift'] ?? 'RED').toString(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
        'section': section,
        'shift': shift,
      };
}

class QccCircle {
  QccCircle({
    required this.id,
    required this.circleName,
    required this.motto,
    required this.plant,
    required this.lineCode,
    required this.shift,
    required this.level,
    required this.establishedDate,
    required this.leaderPic,
    required this.facilitatorPic,
    required this.secretaryPic,
    required this.activeThemeId,
    required this.members,
  });

  final String id;
  final String circleName;
  final String motto;
  final String plant;
  final String lineCode;
  final String shift;
  final String level; // BRONZE | SILVER | GOLD | PLATINUM
  final String establishedDate;
  final String leaderPic;
  final String facilitatorPic;
  final String secretaryPic;
  final String activeThemeId;
  final List<QccMember> members;

  factory QccCircle.fromJson(Map<String, dynamic> j) => QccCircle(
        id: (j['id'] ?? '').toString(),
        circleName: (j['circleName'] ?? '').toString(),
        motto: (j['motto'] ?? '').toString(),
        plant: (j['plant'] ?? 'Welding Plant #1').toString(),
        lineCode: (j['lineCode'] ?? 'WELD-UB01').toString(),
        shift: (j['shift'] ?? 'RED').toString(),
        level: (j['level'] ?? 'GOLD').toString(),
        establishedDate: (j['establishedDate'] ?? '2024-03-15').toString(),
        leaderPic: (j['leaderPic'] ?? '').toString(),
        facilitatorPic: (j['facilitatorPic'] ?? '').toString(),
        secretaryPic: (j['secretaryPic'] ?? '').toString(),
        activeThemeId: (j['activeThemeId'] ?? '').toString(),
        members: (j['members'] as List?)
                ?.whereType<Map>()
                .map((e) => QccMember.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'circleName': circleName,
        'motto': motto,
        'plant': plant,
        'lineCode': lineCode,
        'shift': shift,
        'level': level,
        'establishedDate': establishedDate,
        'leaderPic': leaderPic,
        'facilitatorPic': facilitatorPic,
        'secretaryPic': secretaryPic,
        'activeThemeId': activeThemeId,
        'members': members.map((m) => m.toJson()).toList(),
      };
}

class QccActionPlan5W2H {
  QccActionPlan5W2H({
    required this.id,
    required this.factor,
    required this.what,
    required this.why,
    required this.where,
    required this.when,
    required this.who,
    required this.how,
    required this.howMuch,
    required this.status,
  });

  String id;
  String factor; // MAN | MACHINE | MATERIAL | METHOD | ENVIRONMENT
  String what;
  String why;
  String where;
  String when;
  String who;
  String how;
  String howMuch;
  String status; // PLANNED | IN_PROGRESS | COMPLETED

  factory QccActionPlan5W2H.fromJson(Map<String, dynamic> j) => QccActionPlan5W2H(
        id: (j['id'] ?? '').toString(),
        factor: (j['factor'] ?? 'MACHINE').toString(),
        what: (j['what'] ?? '').toString(),
        why: (j['why'] ?? '').toString(),
        where: (j['where'] ?? '').toString(),
        when: (j['when'] ?? '').toString(),
        who: (j['who'] ?? '').toString(),
        how: (j['how'] ?? '').toString(),
        howMuch: (j['howMuch'] ?? 'Rp 0').toString(),
        status: (j['status'] ?? 'PLANNED').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'factor': factor,
        'what': what,
        'why': why,
        'where': where,
        'when': when,
        'who': who,
        'how': how,
        'howMuch': howMuch,
        'status': status,
      };
}

class QccFishboneBranch {
  QccFishboneBranch({
    required this.category,
    required this.primaryCause,
    required this.rootCause,
    required this.isRootCause,
  });

  final String category;
  String primaryCause;
  String rootCause;
  bool isRootCause;

  factory QccFishboneBranch.fromJson(Map<String, dynamic> j) {
    if (j['causes'] is List && (j['causes'] as List).isNotEmpty) {
      final first = Map<String, dynamic>.from((j['causes'] as List).first as Map);
      return QccFishboneBranch(
        category: (j['category'] ?? 'MAN').toString(),
        primaryCause: (first['primaryCause'] ?? '').toString(),
        rootCause: (first['rootCause'] ?? '').toString(),
        isRootCause: first['isRootCause'] == true,
      );
    }
    return QccFishboneBranch(
      category: (j['category'] ?? 'MAN').toString(),
      primaryCause: (j['primaryCause'] ?? '').toString(),
      rootCause: (j['rootCause'] ?? '').toString(),
      isRootCause: j['isRootCause'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'causes': [
          {
            'primaryCause': primaryCause,
            'rootCause': rootCause,
            'isRootCause': isRootCause,
          },
        ],
      };
}

class QccA3Report {
  QccA3Report({
    required this.id,
    required this.circleId,
    required this.themeNo,
    required this.title,
    required this.kpiCategory,
    required this.currentStep,
    required this.status,
    required this.conventionDate,
    required this.advisorName,
    required this.facilitatorName,
    required this.circleLeaderName,
    required this.step1Background,
    required this.step1Problem,
    required this.baselineDefectRate,
    required this.targetDefectRate,
    required this.targetDeadline,
    required this.paretoItems,
    required this.step2Flow,
    required this.step2CriticalArea,
    required this.step2Phenomenon,
    required this.fishboneBranches,
    required this.verifiedRootCauses,
    required this.verificationMethod,
    required this.totalEstimatedBudget,
    required this.actionPlans,
    required this.step5Summary,
    required this.beforeCondition,
    required this.afterCondition,
    required this.pokaYokeImplemented,
    required this.pokaYokeDetails,
    required this.trialDate,
    required this.resultDefectRate,
    required this.reductionPercentage,
    required this.tangibleSavingPerMonth,
    required this.intangibleBenefits,
    required this.isTargetAchieved,
    required this.revisedDocuments,
    required this.yokotenTargets,
    required this.inspectionFrequency,
    required this.nextThemeTitle,
    required this.targetStartDate,
    required this.circleReflections,
  });

  String id;
  String circleId;
  String themeNo;
  String title;
  String kpiCategory;
  int currentStep; // 1..8
  String status;
  String conventionDate;
  String advisorName;
  String facilitatorName;
  String circleLeaderName;

  // Step 1
  String step1Background;
  String step1Problem;
  double baselineDefectRate;
  double targetDefectRate;
  String targetDeadline;
  List<Map<String, dynamic>> paretoItems;

  // Step 2
  String step2Flow;
  String step2CriticalArea;
  String step2Phenomenon;

  // Step 3
  List<QccFishboneBranch> fishboneBranches;
  List<String> verifiedRootCauses;
  String verificationMethod;

  // Step 4
  String totalEstimatedBudget;
  List<QccActionPlan5W2H> actionPlans;

  // Step 5
  String step5Summary;
  String beforeCondition;
  String afterCondition;
  bool pokaYokeImplemented;
  String pokaYokeDetails;
  String trialDate;

  // Step 6
  double resultDefectRate;
  double reductionPercentage;
  String tangibleSavingPerMonth;
  List<String> intangibleBenefits;
  bool isTargetAchieved;

  // Step 7
  List<Map<String, String>> revisedDocuments;
  List<String> yokotenTargets;
  String inspectionFrequency;

  // Step 8
  String nextThemeTitle;
  String targetStartDate;
  String circleReflections;

  factory QccA3Report.fromJson(Map<String, dynamic> j) {
    final s1 = j['step1'] is Map ? Map<String, dynamic>.from(j['step1'] as Map) : <String, dynamic>{};
    final s2 = j['step2'] is Map ? Map<String, dynamic>.from(j['step2'] as Map) : <String, dynamic>{};
    final s3 = j['step3'] is Map ? Map<String, dynamic>.from(j['step3'] as Map) : <String, dynamic>{};
    final s4 = j['step4'] is Map ? Map<String, dynamic>.from(j['step4'] as Map) : <String, dynamic>{};
    final s5 = j['step5'] is Map ? Map<String, dynamic>.from(j['step5'] as Map) : <String, dynamic>{};
    final s6 = j['step6'] is Map ? Map<String, dynamic>.from(j['step6'] as Map) : <String, dynamic>{};
    final s7 = j['step7'] is Map ? Map<String, dynamic>.from(j['step7'] as Map) : <String, dynamic>{};
    final s8 = j['step8'] is Map ? Map<String, dynamic>.from(j['step8'] as Map) : <String, dynamic>{};

    return QccA3Report(
      id: (j['id'] ?? 'theme-01').toString(),
      circleId: (j['circleId'] ?? 'circle-laser-precision').toString(),
      themeNo: (j['themeNo'] ?? 'QCC-TMMIN-UB-2026-01').toString(),
      title: (j['title'] ?? '').toString(),
      kpiCategory: (j['kpiCategory'] ?? 'QUALITY').toString(),
      currentStep: (j['currentStep'] as num?)?.toInt() ?? 6,
      status: (j['status'] ?? 'CONVENTION_READY').toString(),
      conventionDate: (j['conventionDate'] ?? '2026-11-28').toString(),
      advisorName: (j['advisorName'] ?? 'Mgr. Dwi Harsono').toString(),
      facilitatorName: (j['facilitatorName'] ?? 'GL Kamaludin').toString(),
      circleLeaderName: (j['circleLeaderName'] ?? 'TL Ahmad Fauzi').toString(),
      step1Background: (s1['background'] ?? '').toString(),
      step1Problem: (s1['problemStatement'] ?? '').toString(),
      baselineDefectRate: (s1['baselineDefectRate'] as num?)?.toDouble() ?? 4.82,
      targetDefectRate: (s1['targetDefectRate'] as num?)?.toDouble() ?? 0.5,
      targetDeadline: (s1['targetDeadline'] ?? '2026-11-15').toString(),
      paretoItems: (s1['paretoTopProblems'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      step2Flow: (s2['processFlowSummary'] ?? '').toString(),
      step2CriticalArea: (s2['criticalAreaDescription'] ?? '').toString(),
      step2Phenomenon: (s2['phenomenonDescription'] ?? '').toString(),
      fishboneBranches: (s3['fishboneBranches'] as List?)
              ?.whereType<Map>()
              .map((e) => QccFishboneBranch.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      verifiedRootCauses: (s3['verifiedRootCauses'] as List?)?.map((e) => e.toString()).toList() ?? [],
      verificationMethod: (s3['verificationMethod'] ?? '').toString(),
      totalEstimatedBudget: (s4['totalEstimatedBudget'] ?? 'Rp 4.250.000').toString(),
      actionPlans: (s4['actionPlans'] as List?)
              ?.whereType<Map>()
              .map((e) => QccActionPlan5W2H.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      step5Summary: (s5['executionSummary'] ?? '').toString(),
      beforeCondition: (s5['beforeCondition'] ?? '').toString(),
      afterCondition: (s5['afterCondition'] ?? '').toString(),
      pokaYokeImplemented: s5['pokaYokeImplemented'] != false,
      pokaYokeDetails: (s5['pokaYokeDetails'] ?? '').toString(),
      trialDate: (s5['trialDate'] ?? '2026-09-29').toString(),
      resultDefectRate: (s6['resultDefectRate'] as num?)?.toDouble() ?? 0.18,
      reductionPercentage: (s6['reductionPercentage'] as num?)?.toDouble() ?? 96.3,
      tangibleSavingPerMonth: (s6['tangibleSavingPerMonth'] ?? 'Rp 38.600.000 / bulan').toString(),
      intangibleBenefits: (s6['intangibleBenefits'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isTargetAchieved: s6['isTargetAchieved'] != false,
      revisedDocuments: (s7['revisedDocuments'] as List?)
              ?.whereType<Map>()
              .map((e) => {
                    'docCode': (e['docCode'] ?? '').toString(),
                    'docTitle': (e['docTitle'] ?? '').toString(),
                    'revNo': (e['revNo'] ?? '').toString(),
                  })
              .toList() ??
          [],
      yokotenTargets: (s7['yokotenLineTargets'] as List?)?.map((e) => e.toString()).toList() ?? [],
      inspectionFrequency: (s7['inspectionFrequency'] ?? '').toString(),
      nextThemeTitle: (s8['nextThemeTitle'] ?? '').toString(),
      targetStartDate: (s8['targetStartDate'] ?? '2026-12-05').toString(),
      circleReflections: (s8['circleReflections'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'circleId': circleId,
        'themeNo': themeNo,
        'title': title,
        'kpiCategory': kpiCategory,
        'currentStep': currentStep,
        'status': status,
        'conventionDate': conventionDate,
        'advisorName': advisorName,
        'facilitatorName': facilitatorName,
        'circleLeaderName': circleLeaderName,
        'step1': {
          'background': step1Background,
          'problemStatement': step1Problem,
          'baselineDefectRate': baselineDefectRate,
          'targetDefectRate': targetDefectRate,
          'targetDeadline': targetDeadline,
          'paretoTopProblems': paretoItems,
        },
        'step2': {
          'processFlowSummary': step2Flow,
          'criticalAreaDescription': step2CriticalArea,
          'phenomenonDescription': step2Phenomenon,
        },
        'step3': {
          'fishboneBranches': fishboneBranches.map((b) => b.toJson()).toList(),
          'verifiedRootCauses': verifiedRootCauses,
          'verificationMethod': verificationMethod,
        },
        'step4': {
          'totalEstimatedBudget': totalEstimatedBudget,
          'actionPlans': actionPlans.map((p) => p.toJson()).toList(),
        },
        'step5': {
          'executionSummary': step5Summary,
          'beforeCondition': beforeCondition,
          'afterCondition': afterCondition,
          'pokaYokeImplemented': pokaYokeImplemented,
          'pokaYokeDetails': pokaYokeDetails,
          'trialDate': trialDate,
        },
        'step6': {
          'resultDefectRate': resultDefectRate,
          'reductionPercentage': reductionPercentage,
          'tangibleSavingPerMonth': tangibleSavingPerMonth,
          'intangibleBenefits': intangibleBenefits,
          'isTargetAchieved': isTargetAchieved,
        },
        'step7': {
          'revisedDocuments': revisedDocuments,
          'yokotenLineTargets': yokotenTargets,
          'inspectionFrequency': inspectionFrequency,
        },
        'step8': {
          'nextThemeTitle': nextThemeTitle,
          'targetStartDate': targetStartDate,
          'circleReflections': circleReflections,
        },
      };
}

// ============================================================================
// TPM MODELS
// ============================================================================

class TpmMetric {
  const TpmMetric({
    required this.label,
    required this.value,
    required this.unit,
    required this.change,
    required this.statusText,
  });

  final String label;
  final String value;
  final String unit;
  final String change;
  final String statusText;
}

class TpmSopItem {
  const TpmSopItem({
    required this.id,
    required this.title,
    required this.desc,
    required this.standard,
  });

  final String id;
  final String title;
  final String desc;
  final String standard;
}

class TpmActionPlan {
  TpmActionPlan({
    required this.id,
    required this.title,
    required this.pic,
    required this.dueDate,
    required this.status,
    required this.category,
  });

  final String id;
  String title;
  String pic;
  String dueDate;
  String status; // Done | In Progress | Pending
  String category;

  factory TpmActionPlan.fromJson(Map<String, dynamic> j) => TpmActionPlan(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        pic: (j['pic'] ?? '').toString(),
        dueDate: (j['dueDate'] ?? '').toString(),
        status: (j['status'] ?? 'Pending').toString(),
        category: (j['category'] ?? 'AM Standards').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'pic': pic,
        'dueDate': dueDate,
        'status': status,
        'category': category,
      };
}

// ============================================================================
// 5R / 5S MODELS
// ============================================================================

class FiveRChecklistItem {
  FiveRChecklistItem({
    required this.id,
    required this.pillar,
    required this.criteriaTitle,
    required this.standardDescription,
    required this.maxScore,
    required this.actualScore,
    this.findingNote = '',
    this.countermeasure = '',
    required this.status,
  });

  final String id;
  final String pillar; // SEIRI | SEITON | SEISO | SEIKETSU | SHITSUKE
  final String criteriaTitle;
  final String standardDescription;
  final int maxScore;
  int actualScore;
  String findingNote;
  String countermeasure;
  String status; // OK | DEVIA | CRITICAL

  factory FiveRChecklistItem.fromJson(Map<String, dynamic> j) => FiveRChecklistItem(
        id: (j['id'] ?? '').toString(),
        pillar: (j['pillar'] ?? 'SEIRI').toString(),
        criteriaTitle: (j['criteriaTitle'] ?? '').toString(),
        standardDescription: (j['standardDescription'] ?? '').toString(),
        maxScore: (j['maxScore'] as num?)?.toInt() ?? 10,
        actualScore: (j['actualScore'] as num?)?.toInt() ?? 10,
        findingNote: (j['findingNote'] ?? '').toString(),
        countermeasure: (j['countermeasure'] ?? '').toString(),
        status: (j['status'] ?? 'OK').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'pillar': pillar,
        'criteriaTitle': criteriaTitle,
        'standardDescription': standardDescription,
        'maxScore': maxScore,
        'actualScore': actualScore,
        'findingNote': findingNote,
        'countermeasure': countermeasure,
        'status': status,
      };
}

class FiveRRedTag {
  FiveRRedTag({
    required this.id,
    required this.tagNumber,
    required this.itemName,
    required this.category,
    required this.stationLocation,
    required this.taggedDate,
    required this.expiryDate,
    required this.reason,
    required this.assignedPic,
    required this.dispositionAction,
    required this.status,
  });

  final String id;
  final String tagNumber;
  final String itemName;
  final String category; // TOOL | MATERIAL_PART | JIG_FIXTURE | DOCUMENT | EQUIPMENT
  final String stationLocation;
  final String taggedDate;
  final String expiryDate;
  final String reason; // RUSAK | TIDAK_TERPAKAI | BERLEBIH | KEDALUWARSA | SALAH_TEMPAT
  String assignedPic;
  String dispositionAction; // SCRAP | PINDAH_GUDANG | REPARASI | KEMBALIKAN_SUPPLIER
  String status; // OPEN | IN_PROGRESS | DISPOSED | CLOSED

  factory FiveRRedTag.fromJson(Map<String, dynamic> j) => FiveRRedTag(
        id: (j['id'] ?? '').toString(),
        tagNumber: (j['tagNumber'] ?? '').toString(),
        itemName: (j['itemName'] ?? '').toString(),
        category: (j['category'] ?? 'EQUIPMENT').toString(),
        stationLocation: (j['stationLocation'] ?? '').toString(),
        taggedDate: (j['taggedDate'] ?? '').toString(),
        expiryDate: (j['expiryDate'] ?? '').toString(),
        reason: (j['reason'] ?? 'RUSAK').toString(),
        assignedPic: (j['assignedPic'] ?? '').toString(),
        dispositionAction: (j['dispositionAction'] ?? 'SCRAP').toString(),
        status: (j['status'] ?? 'OPEN').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tagNumber': tagNumber,
        'itemName': itemName,
        'category': category,
        'stationLocation': stationLocation,
        'taggedDate': taggedDate,
        'expiryDate': expiryDate,
        'reason': reason,
        'assignedPic': assignedPic,
        'dispositionAction': dispositionAction,
        'status': status,
      };
}

class FiveRShadowBoardTool {
  FiveRShadowBoardTool({
    required this.id,
    required this.toolCode,
    required this.toolName,
    required this.stationLocation,
    required this.shadowAddress,
    required this.condition,
    required this.isPresent,
    this.borrowerPic,
  });

  final String id;
  final String toolCode;
  final String toolName;
  final String stationLocation;
  final String shadowAddress;
  String condition; // GOOD | NEED_REPAIR | DAMAGED
  bool isPresent;
  String? borrowerPic;

  factory FiveRShadowBoardTool.fromJson(Map<String, dynamic> j) => FiveRShadowBoardTool(
        id: (j['id'] ?? '').toString(),
        toolCode: (j['toolCode'] ?? '').toString(),
        toolName: (j['toolName'] ?? '').toString(),
        stationLocation: (j['stationLocation'] ?? '').toString(),
        shadowAddress: (j['shadowAddress'] ?? '').toString(),
        condition: (j['condition'] ?? 'GOOD').toString(),
        isPresent: j['isPresent'] != false,
        borrowerPic: j['borrowerPic']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'toolCode': toolCode,
        'toolName': toolName,
        'stationLocation': stationLocation,
        'shadowAddress': shadowAddress,
        'condition': condition,
        'isPresent': isPresent,
        if (borrowerPic != null) 'borrowerPic': borrowerPic,
      };
}

class FiveRAuditMaster {
  FiveRAuditMaster({
    required this.id,
    required this.auditCode,
    required this.lineCode,
    required this.stationName,
    required this.shift,
    required this.auditDate,
    required this.auditorName,
    required this.teamLeaderPic,
    required this.seiri,
    required this.seiton,
    required this.seiso,
    required this.seiketsu,
    required this.shitsuke,
    required this.totalScore,
    required this.rankGrade,
    required this.checklists,
    required this.redTagCount,
  });

  final String id;
  final String auditCode;
  final String lineCode;
  String stationName;
  String shift;
  String auditDate;
  String auditorName;
  String teamLeaderPic;
  int seiri;
  int seiton;
  int seiso;
  int seiketsu;
  int shitsuke;
  int totalScore;
  String rankGrade; // A | B | C | D
  List<FiveRChecklistItem> checklists;
  int redTagCount;

  void recalculate(List<FiveRRedTag> redTags) {
    seiri = checklists.where((c) => c.pillar == 'SEIRI').fold(0, (a, b) => a + b.actualScore);
    seiton = checklists.where((c) => c.pillar == 'SEITON').fold(0, (a, b) => a + b.actualScore);
    seiso = checklists.where((c) => c.pillar == 'SEISO').fold(0, (a, b) => a + b.actualScore);
    seiketsu = checklists.where((c) => c.pillar == 'SEIKETSU').fold(0, (a, b) => a + b.actualScore);
    shitsuke = checklists.where((c) => c.pillar == 'SHITSUKE').fold(0, (a, b) => a + b.actualScore);
    totalScore = seiri + seiton + seiso + seiketsu + shitsuke;
    if (totalScore >= 95) {
      rankGrade = 'A';
    } else if (totalScore >= 85) {
      rankGrade = 'B';
    } else if (totalScore >= 70) {
      rankGrade = 'C';
    } else {
      rankGrade = 'D';
    }
    redTagCount = redTags.where((r) => r.status == 'OPEN' || r.status == 'IN_PROGRESS').length;
  }

  factory FiveRAuditMaster.fromJson(Map<String, dynamic> j) {
    final sc = j['scores'] is Map ? Map<String, dynamic>.from(j['scores'] as Map) : <String, dynamic>{};
    return FiveRAuditMaster(
      id: (j['id'] ?? 'audit-5r-202611-01').toString(),
      auditCode: (j['auditCode'] ?? 'AUDIT-5R-TMMIN-UB-2026-11').toString(),
      lineCode: (j['lineCode'] ?? 'WELD-UB01').toString(),
      stationName: (j['stationName'] ?? 'Pos 1: Sub-Assy Underbody Front Floor (#3737)').toString(),
      shift: (j['shift'] ?? 'RED').toString(),
      auditDate: (j['auditDate'] ?? '2026-11-12').toString(),
      auditorName: (j['auditorName'] ?? 'GL Kamaludin').toString(),
      teamLeaderPic: (j['teamLeaderPic'] ?? 'TL Ahmad Fauzi').toString(),
      seiri: (sc['seiri'] as num?)?.toInt() ?? 19,
      seiton: (sc['seiton'] as num?)?.toInt() ?? 19,
      seiso: (sc['seiso'] as num?)?.toInt() ?? 19,
      seiketsu: (sc['seiketsu'] as num?)?.toInt() ?? 19,
      shitsuke: (sc['shitsuke'] as num?)?.toInt() ?? 20,
      totalScore: (j['totalScore'] as num?)?.toInt() ?? 96,
      rankGrade: (j['rankGrade'] ?? 'A').toString(),
      checklists: (j['checklists'] as List?)
              ?.whereType<Map>()
              .map((e) => FiveRChecklistItem.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      redTagCount: (j['redTagCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'auditCode': auditCode,
        'lineCode': lineCode,
        'stationName': stationName,
        'shift': shift,
        'auditDate': auditDate,
        'auditorName': auditorName,
        'teamLeaderPic': teamLeaderPic,
        'scores': {
          'seiri': seiri,
          'seiton': seiton,
          'seiso': seiso,
          'seiketsu': seiketsu,
          'shitsuke': shitsuke,
        },
        'totalScore': totalScore,
        'rankGrade': rankGrade,
        'checklists': checklists.map((c) => c.toJson()).toList(),
        'redTagCount': redTagCount,
      };
}

// ============================================================================
// SW OBSERVASI (TSKK & GENBA TIME STUDY) MODELS
// ============================================================================

class SwProfile {
  const SwProfile({
    required this.id,
    required this.title,
    required this.taktTime,
    required this.taktTimeSec,
    required this.totalJobs,
    required this.lineCode,
    required this.lineName,
    required this.version,
  });

  final String id;
  final String title;
  final double taktTime;
  final int taktTimeSec;
  final int totalJobs;
  final String lineCode;
  final String lineName;
  final String version;

  factory SwProfile.fromJson(Map<String, dynamic> j) => SwProfile(
        id: (j['id'] ?? 'prof-tt-24').toString(),
        title: (j['title'] ?? '').toString(),
        taktTime: (j['taktTime'] as num?)?.toDouble() ?? 2.4,
        taktTimeSec: (j['taktTimeSec'] as num?)?.toInt() ?? 144,
        totalJobs: (j['totalJobs'] as num?)?.toInt() ?? 14,
        lineCode: (j['lineCode'] ?? 'WELD-UB01').toString(),
        lineName: (j['lineName'] ?? 'Underbody Assembly Line 1').toString(),
        version: (j['version'] ?? 'Rev-08').toString(),
      );
}

class SwJob {
  const SwJob({
    required this.id,
    required this.profileId,
    required this.jobCode,
    required this.posNumber,
    required this.posName,
    required this.partName,
    required this.partNo,
    required this.targetCycleTime,
    required this.operatorPic,
    required this.stationType,
  });

  final String id;
  final String profileId;
  final String jobCode;
  final int posNumber;
  final String posName;
  final String partName;
  final String partNo;
  final int targetCycleTime;
  final String operatorPic;
  final String stationType;

  factory SwJob.fromJson(Map<String, dynamic> j) => SwJob(
        id: (j['id'] ?? '').toString(),
        profileId: (j['profileId'] ?? 'prof-tt-24').toString(),
        jobCode: (j['jobCode'] ?? 'UUD').toString(),
        posNumber: (j['posNumber'] as num?)?.toInt() ?? 1,
        posName: (j['posName'] ?? '').toString(),
        partName: (j['partName'] ?? '').toString(),
        partNo: (j['partNo'] ?? '').toString(),
        targetCycleTime: (j['targetCycleTime'] as num?)?.toInt() ?? 138,
        operatorPic: (j['operatorPic'] ?? 'Operator').toString(),
        stationType: (j['stationType'] ?? 'MANUAL').toString(),
      );
}

class SwElement {
  SwElement({
    required this.id,
    required this.jobId,
    required this.stepNumber,
    required this.title,
    required this.manualTime,
    required this.machineTime,
    required this.walkTime,
    required this.qualityPoint,
    required this.safetyPoint,
    this.hasEIS = false,
    this.eisId,
  });

  String id;
  String jobId;
  int stepNumber;
  String title;
  double manualTime;
  double machineTime;
  double walkTime;
  String qualityPoint;
  String safetyPoint;
  bool hasEIS;
  String? eisId;

  double get totalTime => manualTime + machineTime + walkTime;

  factory SwElement.fromJson(Map<String, dynamic> j) => SwElement(
        id: (j['id'] ?? '').toString(),
        jobId: (j['jobId'] ?? '').toString(),
        stepNumber: (j['stepNumber'] as num?)?.toInt() ?? 1,
        title: (j['title'] ?? '').toString(),
        manualTime: (j['manualTime'] as num?)?.toDouble() ?? 5.0,
        machineTime: (j['machineTime'] as num?)?.toDouble() ?? 0.0,
        walkTime: (j['walkTime'] as num?)?.toDouble() ?? 1.0,
        qualityPoint: (j['qualityPoint'] ?? '').toString(),
        safetyPoint: (j['safetyPoint'] ?? '').toString(),
        hasEIS: j['hasEIS'] == true,
        eisId: j['eisId']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'stepNumber': stepNumber,
        'title': title,
        'manualTime': manualTime,
        'machineTime': machineTime,
        'walkTime': walkTime,
        'totalTime': totalTime,
        'qualityPoint': qualityPoint,
        'safetyPoint': safetyPoint,
        'hasEIS': hasEIS,
        if (eisId != null) 'eisId': eisId,
      };
}

class SwObservation {
  SwObservation({
    required this.id,
    required this.profileId,
    required this.jobId,
    required this.cycleNo,
    required this.observerPic,
    required this.operatorPic,
    required this.observationDate,
    required this.shift,
    required this.actualManualSec,
    required this.actualMachineSec,
    required this.actualWalkSec,
    required this.varianceSec,
    this.wasteMotionNotes = '',
    this.qualityIssueNotes = '',
    this.safetyErgoNotes = '',
    this.countermeasure = '',
    required this.status,
  });

  final String id;
  final String profileId;
  final String jobId;
  final int cycleNo;
  String observerPic;
  String operatorPic;
  String observationDate;
  String shift;
  double actualManualSec;
  double actualMachineSec;
  double actualWalkSec;
  double varianceSec;
  String wasteMotionNotes;
  String qualityIssueNotes;
  String safetyErgoNotes;
  String countermeasure;
  String status; // NORMAL | OVER_CYCLE | KAIZEN_NEEDED

  double get actualTotalSec => actualManualSec + actualMachineSec + actualWalkSec;

  factory SwObservation.fromJson(Map<String, dynamic> j) => SwObservation(
        id: (j['id'] ?? '').toString(),
        profileId: (j['profileId'] ?? 'prof-tt-24').toString(),
        jobId: (j['jobId'] ?? '').toString(),
        cycleNo: (j['cycleNo'] as num?)?.toInt() ?? 1,
        observerPic: (j['observerPic'] ?? 'GL Kamaludin').toString(),
        operatorPic: (j['operatorPic'] ?? 'Ahmad Fauzi').toString(),
        observationDate: (j['observationDate'] ?? '2026-11-12').toString(),
        shift: (j['shift'] ?? 'RED').toString(),
        actualManualSec: (j['actualManualSec'] as num?)?.toDouble() ?? 80.0,
        actualMachineSec: (j['actualMachineSec'] as num?)?.toDouble() ?? 28.0,
        actualWalkSec: (j['actualWalkSec'] as num?)?.toDouble() ?? 26.0,
        varianceSec: (j['varianceSec'] as num?)?.toDouble() ?? 0.0,
        wasteMotionNotes: (j['wasteMotionNotes'] ?? '').toString(),
        qualityIssueNotes: (j['qualityIssueNotes'] ?? '').toString(),
        safetyErgoNotes: (j['safetyErgoNotes'] ?? '').toString(),
        countermeasure: (j['countermeasure'] ?? '').toString(),
        status: (j['status'] ?? 'NORMAL').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'jobId': jobId,
        'cycleNo': cycleNo,
        'observerPic': observerPic,
        'operatorPic': operatorPic,
        'observationDate': observationDate,
        'shift': shift,
        'actualManualSec': actualManualSec,
        'actualMachineSec': actualMachineSec,
        'actualWalkSec': actualWalkSec,
        'actualTotalSec': actualTotalSec,
        'varianceSec': varianceSec,
        'wasteMotionNotes': wasteMotionNotes,
        'qualityIssueNotes': qualityIssueNotes,
        'safetyErgoNotes': safetyErgoNotes,
        'countermeasure': countermeasure,
        'status': status,
      };
}

// ============================================================================
// SEED FACTORY (1:1 NEXT.JS)
// ============================================================================

class KaizenActivitySeeds {
  static List<QccCircle> qccCircles() => [
        QccCircle(
          id: 'circle-laser-precision',
          circleName: 'Laser Precision',
          motto: 'Presisi Tinggi Tanpa Spatter, Mutu Terbaik Kebanggaan Pelanggan',
          plant: 'Welding Plant #1',
          lineCode: 'WELD-UB01',
          shift: 'RED',
          level: 'GOLD',
          establishedDate: '2024-03-15',
          leaderPic: 'Ahmad Fauzi (TL Pos 1)',
          facilitatorPic: 'GL Kamaludin (WELD UB)',
          secretaryPic: 'Budi Santoso',
          activeThemeId: 'theme-spatter-elimination-01',
          members: [
            QccMember(name: 'Ahmad Fauzi', role: 'LEADER', section: 'Underbody Front Pos 1', shift: 'RED'),
            QccMember(name: 'Budi Santoso', role: 'SECRETARY', section: 'Cross Member Pos 2', shift: 'RED'),
            QccMember(name: 'Cecep Suryana', role: 'MEMBER', section: 'Side Member LH Pos 3', shift: 'RED'),
            QccMember(name: 'Dedi Kurniawan', role: 'MEMBER', section: 'Side Member RH Pos 4', shift: 'RED'),
            QccMember(name: 'GL Kamaludin', role: 'FACILITATOR', section: 'Group Leader Welding', shift: 'RED'),
          ],
        ),
        QccCircle(
          id: 'circle-cyber-weld',
          circleName: 'Cyber Weld',
          motto: 'Satu Titik Sempurna, Menembus Target Zero Defect Underbody',
          plant: 'Welding Plant #1',
          lineCode: 'WELD-UB01',
          shift: 'WHITE',
          level: 'SILVER',
          establishedDate: '2024-06-20',
          leaderPic: 'Dwi Mulyono (TL Pos 7)',
          facilitatorPic: 'GL Masruri',
          secretaryPic: 'Fajar Nugraha',
          activeThemeId: 'theme-spot-indentation-02',
          members: [
            QccMember(name: 'Dwi Mulyono', role: 'LEADER', section: 'Rear Floor LH Pos 7', shift: 'WHITE'),
            QccMember(name: 'Fajar Nugraha', role: 'SECRETARY', section: 'Reinforce Floor Pos 6', shift: 'WHITE'),
            QccMember(name: 'Gilang Ramadhan', role: 'MEMBER', section: 'Rear Floor RH Pos 8', shift: 'WHITE'),
            QccMember(name: 'GL Masruri', role: 'FACILITATOR', section: 'Group Leader Welding', shift: 'WHITE'),
          ],
        ),
        QccCircle(
          id: 'circle-titanium-force',
          circleName: 'Titanium Force',
          motto: 'Kuatkan Struktur Sambungan, Eliminasi Celah Perakitan',
          plant: 'Welding Plant #1',
          lineCode: 'WELD-UB01',
          shift: 'RED',
          level: 'PLATINUM',
          establishedDate: '2023-11-10',
          leaderPic: 'Joko Widodo (TL Robot Marriage)',
          facilitatorPic: 'Manager Dwi Harsono',
          secretaryPic: 'Irfan Maulana',
          activeThemeId: 'theme-main-marriage-03',
          members: [
            QccMember(name: 'Joko Widodo', role: 'LEADER', section: 'Robot Marriage Pos 10', shift: 'RED'),
            QccMember(name: 'Irfan Maulana', role: 'SECRETARY', section: 'Tank Bracket Pos 11', shift: 'RED'),
            QccMember(name: 'Lukman Hakim', role: 'MEMBER', section: 'Tire Carrier Pos 12', shift: 'RED'),
          ],
        ),
      ];

  static QccA3Report qccDefaultReport(QccCircle circle) => QccA3Report(
        id: circle.activeThemeId.isNotEmpty ? circle.activeThemeId : 'theme-${circle.id}-01',
        circleId: circle.id,
        themeNo: 'QCC-TMMIN-UB-2026-01',
        title: circle.id == 'circle-laser-precision'
            ? 'Eliminasi Expulsion & Spatter Las Spot Gun Px 10 pada Flange Front Floor #3737'
            : 'Optimalisasi Kualitas & Eliminasi Cacat Gugus ${circle.circleName}',
        kpiCategory: 'QUALITY',
        currentStep: 6,
        status: 'CONVENTION_READY',
        conventionDate: '2026-11-28',
        advisorName: 'Mgr. Dwi Harsono',
        facilitatorName: circle.facilitatorPic,
        circleLeaderName: circle.leaderPic,
        step1Background:
            'Lini Welding Underbody Pos 1 mengalami peningkatan temuan butiran spatter tajam pada flange part 3737 yang berpotensi melukai tangan operator assembly dan memicu temuan BIQ gate.',
        step1Problem: 'Rata-rata defect spatter tajam mencapai 4.82% (target plant maks <= 0.50%).',
        baselineDefectRate: 4.82,
        targetDefectRate: 0.50,
        targetDeadline: '2026-11-15',
        paretoItems: [
          {'label': 'Spatter Flange Depan', 'count': 142, 'percentage': 61.2},
          {'label': 'Kedalaman Indentasi >20%', 'count': 48, 'percentage': 20.7},
          {'label': 'Pitch Spot Tidak Simetris', 'count': 26, 'percentage': 11.2},
          {'label': 'Burr Pinggir Plat', 'count': 16, 'percentage': 6.9},
        ],
        step2Flow:
            'Ambil Part 3737 -> Jig #1 (Datum A & B) -> Clamp Pneumatic -> Spot Gun Px 10 (Titik 1-4) -> Spot Bracket (Titik 5-8) -> Inspeksi Visual -> Transfer Pos 2.',
        step2CriticalArea:
            'Konsentrasi spatter 72.5% pada Titik Spot #2 & #3 akibat variasi sudut kemiringan tip elektroda gun C-Type manual.',
        step2Phenomenon:
            'Percikan expulsion muncul saat squeeze time berakhir dan weld current 9.8 kA dialirkan.',
        fishboneBranches: [
          QccFishboneBranch(
            category: 'MAN',
            primaryCause: 'Lengan operator miring saat tekan trigger',
            rootCause: 'Tension spring balancer tidak dikalibrasi sesuai bobot gun 28 kg',
            isRootCause: true,
          ),
          QccFishboneBranch(
            category: 'MACHINE',
            primaryCause: 'Tekanan pneumatic clamp gun turun < 0.40 MPa',
            rootCause: 'Drain otomatis filter regulator udara macet tersumbat kondensasi',
            isRootCause: true,
          ),
          QccFishboneBranch(
            category: 'MATERIAL',
            primaryCause: 'Anti-rust oil berlebih di flange part 3737',
            rootCause: 'Toleransi film oil supplier belum seragam',
            isRootCause: false,
          ),
          QccFishboneBranch(
            category: 'METHOD',
            primaryCause: 'Urutan pengelasan tidak searah jarum jam',
            rootCause: 'Belum ada visual plate urutan spot 1-2-3-4 di atas jig fixture',
            isRootCause: true,
          ),
        ],
        verifiedRootCauses: [
          'Tension spring balancer kendor sehingga elektroda menekan miring > 5°.',
          'Tekanan pneumatik drop akibat filter regulator tersumbat (< 300 daN).',
          'Belum ada penanda urutan visual nomor titik spot 1-2-3-4 di fixture jig.',
        ],
        verificationMethod: 'Uji rekaman high-speed camera 1000 fps & pengukuran pressure gauge digital.',
        totalEstimatedBudget: 'Rp 4.250.000',
        actionPlans: [
          QccActionPlan5W2H(
            id: '5W2H-01',
            factor: 'MAN',
            what: 'Kalibrasi & pasang penanda visual dial limit tension balancer Pos 1',
            why: 'Menjaga beban gun terasa 0 kg & tip tegak lurus 90°',
            where: 'Pos 1 Underbody',
            when: '2026-09-20',
            who: 'Budi Santoso & Maint',
            how: 'Setel preload spring 28.5 kg + garis batas hijau OK',
            howMuch: 'Rp 250.000',
            status: 'COMPLETED',
          ),
          QccActionPlan5W2H(
            id: '5W2H-02',
            factor: 'MACHINE',
            what: 'Ganti unit Filter Regulator Auto-Drain SMC + sensor low pressure',
            why: 'Mencegah tekanan angin turun < 0.45 MPa (350 daN)',
            where: 'Saluran udara Pos 1',
            when: '2026-09-24',
            who: 'Cecep Suryana & Maint',
            how: 'Pasang digital pressure switch interlock < 0.42 MPa',
            howMuch: 'Rp 2.800.000',
            status: 'COMPLETED',
          ),
          QccActionPlan5W2H(
            id: '5W2H-03',
            factor: 'METHOD',
            what: 'Pasang pelat pemandu urutan spot bernomor 1-2-3-4 warna kontras',
            why: 'Mencegah loncatan urutan pengelasan operator baru',
            where: 'Fixture Jig #1 Pos 1',
            when: '2026-09-27',
            who: 'Ahmad Fauzi & Tooling',
            how: 'Grafir laser kuning cerah di samping locating pin',
            howMuch: 'Rp 1.200.000',
            status: 'COMPLETED',
          ),
        ],
        step5Summary:
            'Seluruh 3 tindakan 5W2H selesai 100% saat weekend shutdown & diuji pada 500 unit produksi Shift Red & White.',
        beforeCondition: 'Gun berat miring, regulator drop 0.38 MPa, urutan spot acak, spatter tajam tinggi.',
        afterCondition: 'Gun seimbang 0 kg, tekanan stabil 0.46 MPa ber-interlock, urutan 1-2-3-4 konsisten.',
        pokaYokeImplemented: true,
        pokaYokeDetails: 'Digital Pressure Switch Interlock: trigger gun terkunci otomatis jika tekanan < 0.42 MPa.',
        trialDate: '2026-09-29',
        resultDefectRate: 0.18,
        reductionPercentage: 96.3,
        tangibleSavingPerMonth: 'Rp 38.600.000 / bulan',
        intangibleBenefits: [
          'Eliminasi 100% risiko luka sayat jari operator assembly.',
          'Frekuensi dressing tip elektroda memanjang dari 50 menjadi 120 siklus.',
          'Raih Zero Defect Award BIQ Gate Oktober 2026.',
        ],
        isTargetAchieved: true,
        revisedDocuments: [
          {'docCode': 'STW-UB01-UUD-01', 'docTitle': 'Standardized Work Instruction Pos 1', 'revNo': 'Rev. 05'},
          {'docCode': 'QA-MAT-WELD-04', 'docTitle': 'Quality Assurance Matrix Spot Welding', 'revNo': 'Rev. 03'},
          {'docCode': 'PM-CHCK-JIG-01', 'docTitle': 'Daily Jig & Regulator Checksheet', 'revNo': 'Rev. 02'},
        ],
        yokotenTargets: [
          'Lini Welding Underbody Line 2 (Pos 1 Sub-Assy Front)',
          'Lini Welding Shell Body Main Gate',
          'Lini Welding Rear Floor Assembly',
        ],
        inspectionFrequency: 'Pemeriksaan 5 menit mandiri setiap awal shift (Jishu Hozen)',
        nextThemeTitle: 'Reduksi Waktu Siklus Penanganan Part Cross Member di Pos 2 (UUA)',
        targetStartDate: '2026-12-05',
        circleReflections:
            'Genchi Genbutsu langsung di fixture jig bersama operator & maintenance + Poka-Yoke interlock memastikan hasil permanen.',
      );

  static const List<TpmMetric> tpmMetrics = [
    TpmMetric(
      label: 'Overall Equipment Effectiveness (OEE)',
      value: '91.4',
      unit: '%',
      change: '+2.1% melampaui standar dunia',
      statusText: 'World Class',
    ),
    TpmMetric(
      label: 'Mean Time Between Failures (MTBF)',
      value: '420',
      unit: 'Jam',
      change: 'Peningkatan keandalan mesin',
      statusText: 'Reliable',
    ),
    TpmMetric(
      label: 'Mean Time to Repair (MTTR)',
      value: '7.5',
      unit: 'Menit',
      change: 'Respons cepat tim maintenance',
      statusText: 'Fast Response',
    ),
    TpmMetric(
      label: 'Autonomous Maintenance Compliance',
      value: '100',
      unit: '%',
      change: 'Checksheet AM terisi penuh',
      statusText: 'Fully Compliant',
    ),
  ];

  static const List<TpmSopItem> tpmSopItems = [
    TpmSopItem(
      id: 'TPM-AM-01',
      title: 'Checksheet Pemeliharaan Mandiri Awal Shift (Jishu Hozen Step 1-3)',
      desc: 'Inspeksi 5 menit sebelum start lini: pembersihan sensor, pelumasan slide guide, cek level oli hidrolik, dan periksa kebocoran selang udara.',
      standard: 'TPM-AM-01 / Wajib setiap pergantian shift',
    ),
    TpmSopItem(
      id: 'TPM-AM-02',
      title: 'Labelisasi Tagging Fuguai (White Tag & Red Tag TPM)',
      desc: 'White Tag untuk kelainan yang diperbaiki mandiri oleh operator, dan Red Tag untuk kerusakan yang membutuhkan teknisi maintenance.',
      standard: 'SLA White Tag < 24 jam / Red Tag < 48 jam',
    ),
    TpmSopItem(
      id: 'TPM-AM-03',
      title: 'Manajemen Pelumasan & Titik Kritis Pengencangan (Torque Match Mark)',
      desc: 'Pemberian tanda garis cat (match mark) pada baut-baut penahan robot dan fixture utama untuk deteksi cepat baut kendur akibat getaran.',
      standard: 'Match Mark Visual Check 100%',
    ),
    TpmSopItem(
      id: 'TPM-AM-04',
      title: 'Penanganan Chokotei & Penggantian Suku Cadang Preventif (PM)',
      desc: 'Pencatatan setiap insiden mesin berhenti sesaat (< 5 menit) dan penggantian suku cadang aus sebelum terjadi breakdown.',
      standard: 'Standar Siklus Penggantian Komponen Aus',
    ),
  ];

  static List<TpmActionPlan> tpmActionPlans() => [
        TpmActionPlan(
          id: 'TPM-01',
          title: 'Restorasi Kondisi Awal (Initial Cleaning) Robot Spot Welder Pos 2',
          pic: 'Shift Merah (GL Kamaludin)',
          dueDate: '23 Sep 2026',
          status: 'Done',
          category: 'Initial Cleaning',
        ),
        TpmActionPlan(
          id: 'TPM-02',
          title: 'Pemasangan Akrilik Pelindung Sensor Proximity dari Cipratan Spatter',
          pic: 'Maintenance Support',
          dueDate: '26 Sep 2026',
          status: 'In Progress',
          category: 'Source of Contamination',
        ),
        TpmActionPlan(
          id: 'TPM-03',
          title: 'Pembuatan Standar Pembersihan & Pelumasan Tentatif (CLIT Sheet)',
          pic: 'Shift Putih (TL Dwi Mulyono)',
          dueDate: '30 Sep 2026',
          status: 'Pending',
          category: 'AM Standards',
        ),
        TpmActionPlan(
          id: 'TPM-04',
          title: 'Audit OPL (One Point Lesson) Penggantian Filter Regulator Udara',
          pic: 'Sub-GL TPM',
          dueDate: '20 Sep 2026',
          status: 'Done',
          category: 'One Point Lesson',
        ),
      ];

  static FiveRAuditMaster fiveRAudit() => FiveRAuditMaster(
        id: 'audit-5r-202611-01',
        auditCode: 'AUDIT-5R-TMMIN-UB-2026-11',
        lineCode: 'WELD-UB01',
        stationName: 'Pos 1: Sub-Assy Underbody Front Floor (#3737)',
        shift: 'RED',
        auditDate: '2026-11-12',
        auditorName: 'GL Kamaludin (Komite 5S Plant)',
        teamLeaderPic: 'TL Ahmad Fauzi',
        seiri: 19,
        seiton: 19,
        seiso: 19,
        seiketsu: 19,
        shitsuke: 20,
        totalScore: 96,
        rankGrade: 'A',
        redTagCount: 3,
        checklists: [
          FiveRChecklistItem(
            id: 'chk-seiri-01',
            pillar: 'SEIRI',
            criteriaTitle: 'Pemisahan Barang Tidak Terpakai & Red-Tag',
            standardDescription: 'Nol kardus sisa, part NG, atau tooling rusak menumpuk > 1 shift.',
            maxScore: 10,
            actualScore: 10,
            findingNote: 'Nol barang tak perlu di sekitar fixture jig.',
            status: 'OK',
          ),
          FiveRChecklistItem(
            id: 'chk-seiri-02',
            pillar: 'SEIRI',
            criteriaTitle: 'Pengendalian Jumlah Pasokan Part (Max 2 Jam)',
            standardDescription: 'Stok part 3737 di rak trolley sesuai Kanban (maks 2 jam produksi).',
            maxScore: 10,
            actualScore: 9,
            findingNote: 'Trolley part terisi 1.5 jam konsumsi, teratur.',
            status: 'OK',
          ),
          FiveRChecklistItem(
            id: 'chk-seiton-01',
            pillar: 'SEITON',
            criteriaTitle: 'Kepatuhan Shadow Board & Alamat Perkakas',
            standardDescription: 'Semua alat bantu tergantung pas pada bayangan & berlabel kode alamat.',
            maxScore: 10,
            actualScore: 10,
            findingNote: 'Perkakas rapi sesuai slot masing-masing.',
            status: 'OK',
          ),
          FiveRChecklistItem(
            id: 'chk-seiton-02',
            pillar: 'SEITON',
            criteriaTitle: 'Demarkasi Jalur Lorong & Posisi Trolley',
            standardDescription: 'Trolley part berada pas di dalam garis demarkasi kuning.',
            maxScore: 10,
            actualScore: 9,
            findingNote: 'Garis demarkasi kuning jelas & bersih.',
            status: 'OK',
          ),
          FiveRChecklistItem(
            id: 'chk-seiso-01',
            pillar: 'SEISO',
            criteriaTitle: 'Kebersihan Fixture Jig & Bebas Spatter Las',
            standardDescription: 'Datum pin A/B & toggle clamp bebas kerak spatter & oli.',
            maxScore: 10,
            actualScore: 10,
            findingNote: 'Pin datum disikat rutin setiap istirahat.',
            status: 'OK',
          ),
          FiveRChecklistItem(
            id: 'chk-seiso-02',
            pillar: 'SEISO',
            criteriaTitle: 'Kebersihan Lantai & Area Kolong Meja',
            standardDescription: 'Lantai kering, bebas genangan oli, debu las, atau kawat las.',
            maxScore: 10,
            actualScore: 9,
            findingNote: 'Lantai bersih mengkilap, zero ceceran oli.',
            status: 'OK',
          ),
          FiveRChecklistItem(
            id: 'chk-seiketsu-01',
            pillar: 'SEIKETSU',
            criteriaTitle: 'Visual Management & Indikator Tekanan Udara',
            standardDescription: 'Pressure gauge bertanda batas hijau normal (0.42 - 0.50 MPa).',
            maxScore: 10,
            actualScore: 10,
            findingNote: 'Dial hijau-merah terpasang jelas.',
            status: 'OK',
          ),
          FiveRChecklistItem(
            id: 'chk-seiketsu-02',
            pillar: 'SEIKETSU',
            criteriaTitle: 'Kerapian Jalur Kabel & Selang Gantung Balancer',
            standardDescription: 'Kabel spot gun & selang udara terikat spiral wrap tanpa menjuntai.',
            maxScore: 10,
            actualScore: 9,
            findingNote: 'Kabel rapi pada rail crane balancer.',
            status: 'OK',
          ),
          FiveRChecklistItem(
            id: 'chk-shitsuke-01',
            pillar: 'SHITSUKE',
            criteriaTitle: 'Kedisiplinan APD Standar & Seragam Kerja',
            standardDescription: 'Sarung tangan Kevlar, goggle, helm tali dagu, & sepatu safety lengkap.',
            maxScore: 10,
            actualScore: 10,
            findingNote: 'Kepatuhan APD 100% disiplin.',
            status: 'OK',
          ),
          FiveRChecklistItem(
            id: 'chk-shitsuke-02',
            pillar: 'SHITSUKE',
            criteriaTitle: 'Pelaksanaan 5 Menit After-Produksi 5S',
            standardDescription: 'Akhir shift menjalankan pembersihan 5 menit & matikan udara/listrik.',
            maxScore: 10,
            actualScore: 10,
            findingNote: 'Checksheet harian 5S lengkap diparaf TL.',
            status: 'OK',
          ),
        ],
      );

  static List<FiveRRedTag> fiveRRedTags() => [
        FiveRRedTag(
          id: 'rt-001',
          tagNumber: 'RT-UB-202611-001',
          itemName: 'Selang Pneumatic Bekas Bocor Halus 10 Meter',
          category: 'EQUIPMENT',
          stationLocation: 'Pos 1 Underbody Front',
          taggedDate: '2026-11-11',
          expiryDate: '2026-11-13',
          reason: 'RUSAK',
          assignedPic: 'Cecep Suryana',
          dispositionAction: 'SCRAP',
          status: 'OPEN',
        ),
        FiveRRedTag(
          id: 'rt-002',
          tagNumber: 'RT-UB-202611-002',
          itemName: 'Fixture Toggle Clamp Manual Model Lama (GH-201)',
          category: 'JIG_FIXTURE',
          stationLocation: 'Rak Samping Pos 1',
          taggedDate: '2026-11-11',
          expiryDate: '2026-11-13',
          reason: 'TIDAK_TERPAKAI',
          assignedPic: 'Ahmad Fauzi (TL)',
          dispositionAction: 'PINDAH_GUDANG',
          status: 'IN_PROGRESS',
        ),
        FiveRRedTag(
          id: 'rt-003',
          tagNumber: 'RT-UB-202611-003',
          itemName: 'Baut M8x25 Sisa Perakitan Bracket (Kelebihan 40 Pcs)',
          category: 'MATERIAL_PART',
          stationLocation: 'Bin Box Trolley Part 3737',
          taggedDate: '2026-11-12',
          expiryDate: '2026-11-14',
          reason: 'BERLEBIH',
          assignedPic: 'Budi Santoso',
          dispositionAction: 'KEMBALIKAN_SUPPLIER',
          status: 'OPEN',
        ),
        FiveRRedTag(
          id: 'rt-004',
          tagNumber: 'RT-UB-202611-004',
          itemName: 'Kabel Las Tembaga Terkelupas Pelindung Karet',
          category: 'EQUIPMENT',
          stationLocation: 'Tiang Gantungan Crane Balancer',
          taggedDate: '2026-11-10',
          expiryDate: '2026-11-12',
          reason: 'RUSAK',
          assignedPic: 'Maintenance Tooling',
          dispositionAction: 'REPARASI',
          status: 'DISPOSED',
        ),
      ];

  static List<FiveRShadowBoardTool> fiveRShadowBoard() => [
        FiveRShadowBoardTool(id: 'sb-01', toolCode: 'TOOL-UB-01', toolName: 'Caliper Dial Gap Gauge 0.1 - 2.0 mm', stationLocation: 'Pos 1 Front', shadowAddress: 'Board A - Slot 01', condition: 'GOOD', isPresent: true),
        FiveRShadowBoardTool(id: 'sb-02', toolCode: 'TOOL-UB-02', toolName: 'Tip Dresser Cutter Manual Px 10', stationLocation: 'Pos 1 Front', shadowAddress: 'Board A - Slot 02', condition: 'GOOD', isPresent: true),
        FiveRShadowBoardTool(id: 'sb-03', toolCode: 'TOOL-UB-03', toolName: 'Chisel Hammer Uji Pahat Spot (Hand-Guard)', stationLocation: 'Pos 1 Front', shadowAddress: 'Board A - Slot 03', condition: 'GOOD', isPresent: true),
        FiveRShadowBoardTool(id: 'sb-04', toolCode: 'TOOL-UB-04', toolName: 'Wire Brass Brush Pembersih Spatter Pin', stationLocation: 'Pos 1 Front', shadowAddress: 'Board A - Slot 04', condition: 'GOOD', isPresent: true),
        FiveRShadowBoardTool(id: 'sb-05', toolCode: 'TOOL-UB-05', toolName: 'Safety Goggle Spare Box & Antifog Wipe', stationLocation: 'Pos 1 Front', shadowAddress: 'Board A - Slot 05', condition: 'GOOD', isPresent: true),
        FiveRShadowBoardTool(id: 'sb-06', toolCode: 'TOOL-UB-06', toolName: 'Kunci Pas 17-19 mm Pengencang Toggle Jig', stationLocation: 'Pos 1 Front', shadowAddress: 'Board A - Slot 06', condition: 'GOOD', isPresent: false, borrowerPic: 'Cecep Suryana'),
        FiveRShadowBoardTool(id: 'sb-07', toolCode: 'TOOL-UB-07', toolName: 'QC Stamp Ink Pad Hijau Inspeksi BIQ', stationLocation: 'Pos 1 Front', shadowAddress: 'Board A - Slot 07', condition: 'GOOD', isPresent: true),
        FiveRShadowBoardTool(id: 'sb-08', toolCode: 'TOOL-UB-08', toolName: 'Air Duster Gun Pembersih Bram & Terak', stationLocation: 'Pos 1 Front', shadowAddress: 'Board A - Slot 08', condition: 'GOOD', isPresent: true),
      ];

  static const List<SwProfile> swProfiles = [
    SwProfile(
      id: 'prof-tt-24',
      title: 'Takt Time 2.4 Menit (14 Jobs)',
      taktTime: 2.4,
      taktTimeSec: 144,
      totalJobs: 14,
      lineCode: 'WELD-UB01',
      lineName: 'Underbody Assembly Line 1',
      version: 'Rev-08 (Normal Volume)',
    ),
    SwProfile(
      id: 'prof-tt-19',
      title: 'Takt Time 1.9 Menit (21 Jobs)',
      taktTime: 1.9,
      taktTimeSec: 114,
      totalJobs: 21,
      lineCode: 'WELD-UB01',
      lineName: 'Underbody Assembly Line 1',
      version: 'Rev-12 (Peak Line Speed)',
    ),
  ];

  static List<SwJob> swJobsForProfile(String profileId) {
    if (profileId == 'prof-tt-19') {
      const codes = [
        'UUD-1', 'UUD-2', 'UUA-1', 'UUA-2', 'UUB-1', 'UUB-2', 'UUC-1',
        'UUC-2', 'UUE', 'UUF-1', 'UUF-2', 'UUG', 'UUH', 'UUI-1',
        'UUI-2', 'UUJ-1', 'UUJ-2', 'UUK', 'UUL', 'UUM', 'UUN',
      ];
      return List.generate(21, (i) {
        final pos = i + 1;
        return SwJob(
          id: 'job-tt19-${pos.toString().padLeft(2, '0')}',
          profileId: 'prof-tt-19',
          jobCode: codes[i],
          posNumber: pos,
          posName: 'Pos $pos: Station ${codes[i]}',
          partName: 'Underbody High Speed Sub-Assy',
          partNo: '57100-TT19-$pos',
          targetCycleTime: 110,
          operatorPic: 'Operator Pos $pos',
          stationType: pos % 4 == 0 ? 'ROBOT' : 'MANUAL',
        );
      });
    }

    return const [
      SwJob(id: 'job-tt24-01', profileId: 'prof-tt-24', jobCode: 'UUD', posNumber: 1, posName: 'Pos 1: Sub-Assy Underbody Front', partName: 'Floor Front Cross Member Complete', partNo: '57101-BZ370', targetCycleTime: 138, operatorPic: 'Ahmad Fauzi (OP 1)', stationType: 'MANUAL'),
      SwJob(id: 'job-tt24-02', profileId: 'prof-tt-24', jobCode: 'UUA', posNumber: 2, posName: 'Pos 2: Cross Member Center & Bracket', partName: 'Center Tunnel Frame Sub-Assy', partNo: '57102-BZ410', targetCycleTime: 139, operatorPic: 'Budi Santoso (OP 2)', stationType: 'SEMI_AUTO'),
      SwJob(id: 'job-tt24-03', profileId: 'prof-tt-24', jobCode: 'UUB', posNumber: 3, posName: 'Pos 3: Front Side Member LH Sub-Assy', partName: 'Front Side Member LH', partNo: '57103-BZ120', targetCycleTime: 137, operatorPic: 'Cecep Suryana', stationType: 'MANUAL'),
      SwJob(id: 'job-tt24-04', profileId: 'prof-tt-24', jobCode: 'UUC', posNumber: 4, posName: 'Pos 4: Front Side Member RH Sub-Assy', partName: 'Front Side Member RH', partNo: '57104-BZ130', targetCycleTime: 136, operatorPic: 'Dedi Kurniawan', stationType: 'MANUAL'),
      SwJob(id: 'job-tt24-05', profileId: 'prof-tt-24', jobCode: 'UUE', posNumber: 5, posName: 'Pos 5: Robot Spot Feed Underbody 1', partName: 'Underbody Main Panel Feed', partNo: '57105-BZ001', targetCycleTime: 140, operatorPic: 'Eko Prasetyo', stationType: 'ROBOT'),
      SwJob(id: 'job-tt24-06', profileId: 'prof-tt-24', jobCode: 'UUF', posNumber: 6, posName: 'Pos 6: Reinforcement Floor Front', partName: 'Reinf Floor Front', partNo: '57106-BZ990', targetCycleTime: 135, operatorPic: 'Fajar Nugraha', stationType: 'MANUAL'),
      SwJob(id: 'job-tt24-07', profileId: 'prof-tt-24', jobCode: 'UUG', posNumber: 7, posName: 'Pos 7: Rear Floor Side LH Welding', partName: 'Rear Floor LH', partNo: '57107-BZ510', targetCycleTime: 138, operatorPic: 'Gilang Ramadhan', stationType: 'MANUAL'),
      SwJob(id: 'job-tt24-08', profileId: 'prof-tt-24', jobCode: 'UUH', posNumber: 8, posName: 'Pos 8: Rear Floor Side RH Welding', partName: 'Rear Floor RH', partNo: '57108-BZ520', targetCycleTime: 139, operatorPic: 'Hendra Saputra', stationType: 'MANUAL'),
      SwJob(id: 'job-tt24-09', profileId: 'prof-tt-24', jobCode: 'UUI', posNumber: 9, posName: 'Pos 9: Seat Cross Member Setting', partName: 'Seat Cross Member Complete', partNo: '57109-BZ200', targetCycleTime: 137, operatorPic: 'Irfan Maulana', stationType: 'MANUAL'),
      SwJob(id: 'job-tt24-10', profileId: 'prof-tt-24', jobCode: 'UUJ', posNumber: 10, posName: 'Pos 10: Robot Spot Main Marriage UB', partName: 'Main Floor Join Complete', partNo: '57110-BZ100', targetCycleTime: 141, operatorPic: 'Joko Widodo (OP 10)', stationType: 'ROBOT'),
      SwJob(id: 'job-tt24-11', profileId: 'prof-tt-24', jobCode: 'UUK', posNumber: 11, posName: 'Pos 11: Fuel Tank Bracket & Heat Shield', partName: 'Tank Bracket Assy', partNo: '57111-BZ770', targetCycleTime: 134, operatorPic: 'Kiki Ramdani', stationType: 'MANUAL'),
      SwJob(id: 'job-tt24-12', profileId: 'prof-tt-24', jobCode: 'UUL', posNumber: 12, posName: 'Pos 12: Spare Tire Carrier & Rear Member', partName: 'Tire Carrier Bracket', partNo: '57112-BZ880', targetCycleTime: 136, operatorPic: 'Lukman Hakim', stationType: 'MANUAL'),
      SwJob(id: 'job-tt24-13', profileId: 'prof-tt-24', jobCode: 'UUM', posNumber: 13, posName: 'Pos 13: Sealer Dispensing & Bead', partName: 'Underbody Sealer Lines', partNo: '57113-SL001', targetCycleTime: 138, operatorPic: 'Muhamad Rizki', stationType: 'SEMI_AUTO'),
      SwJob(id: 'job-tt24-14', profileId: 'prof-tt-24', jobCode: 'UUN', posNumber: 14, posName: 'Pos 14: Final Inspection & BIQ Gate', partName: '100% Quality & Nugget Check', partNo: '57114-QC001', targetCycleTime: 140, operatorPic: 'Nurhadi (Inspector)', stationType: 'MANUAL'),
    ];
  }

  static List<SwElement> swElementsForJob(SwJob job) {
    if (job.id == 'job-tt24-01') {
      return [
        SwElement(id: 'el-uud-01', jobId: job.id, stepNumber: 1, title: 'Ambil part 3737 dari rack trolley & periksa visual', manualTime: 5.0, machineTime: 0.0, walkTime: 2.0, qualityPoint: 'Bebas dent, burr tajam, atau karat pada flange', safetyPoint: 'Sarung tangan Kevlar anti sayat level 5', hasEIS: true, eisId: 'eis-uud-01'),
        SwElement(id: 'el-uud-02', jobId: job.id, stepNumber: 2, title: 'Setting part 3737 ke locating pin Jig #1 (Datum A & B)', manualTime: 8.5, machineTime: 0.0, walkTime: 1.5, qualityPoint: 'Part duduk rapat 100% tanpa celah pada reference pin', safetyPoint: 'Awas titik jepit part & toggle clamp', hasEIS: true, eisId: 'eis-uud-02'),
        SwElement(id: 'el-uud-03', jobId: job.id, stepNumber: 3, title: 'Injak pedal pneumatic clamp jig & kunci tuas sekunder', manualTime: 3.5, machineTime: 2.0, walkTime: 0.5, qualityPoint: 'Lampu sensor pneumatic menyala hijau (clamp locked)', safetyPoint: 'Kedua tangan di luar area bahaya fixture', hasEIS: true, eisId: 'eis-uud-03'),
        SwElement(id: 'el-uud-04', jobId: job.id, stepNumber: 4, title: 'Proses Spot Gun Px 10 (Titik 1 - 4: Flange Luar & Gusset)', manualTime: 18.0, machineTime: 12.0, walkTime: 2.0, qualityPoint: 'Pitch spot 30 ± 2 mm, diameter nugget min 5.5 mm', safetyPoint: 'Wajib kacamata goggle & apron kulit dada', hasEIS: true, eisId: 'eis-uud-04'),
        SwElement(id: 'el-uud-05', jobId: job.id, stepNumber: 5, title: 'BIQ: Buka clamp jig & inspeksi visual titik spot 1-4', manualTime: 4.5, machineTime: 1.5, walkTime: 1.0, qualityPoint: 'Zero burn through, zero excessive spatter', safetyPoint: 'Gantungkan gun seimbang di balancer', hasEIS: true, eisId: 'eis-uud-05'),
        SwElement(id: 'el-uud-06', jobId: job.id, stepNumber: 6, title: 'Ambil Bracket Reinforce LH (Part 3738) ke side guide', manualTime: 6.0, machineTime: 0.0, walkTime: 1.5, qualityPoint: 'Cek orientation hole tidak terbalik LH/RH', safetyPoint: 'Postur punggung ergonomis saat meraih bin', hasEIS: false),
        SwElement(id: 'el-uud-07', jobId: job.id, stepNumber: 7, title: 'Proses Spot Gun Px 10 (Titik 5 - 8: Reinforce Bracket)', manualTime: 19.0, machineTime: 13.0, walkTime: 2.0, qualityPoint: 'Kedalaman indentasi < 20% tebal plat dasar', safetyPoint: 'Tekanan gun stabil 350 daN hingga hold selesai', hasEIS: true, eisId: 'eis-uud-07'),
        SwElement(id: 'el-uud-08', jobId: job.id, stepNumber: 8, title: 'Chisel Check berkala sampel 1/10 siklus pada titik spot 2', manualTime: 9.0, machineTime: 0.0, walkTime: 1.0, qualityPoint: 'Plat tidak lepas/retak saat dipahat sudut 15°', safetyPoint: 'Gunakan hammer safety ber-hand-guard', hasEIS: false),
        SwElement(id: 'el-uud-09', jobId: job.id, stepNumber: 9, title: 'Transfer Sub-Assy ke roller chute menuju Pos 2 (UUA)', manualTime: 7.0, machineTime: 0.0, walkTime: 3.5, qualityPoint: 'Stopper roller terkunci, part meluncur stabil', safetyPoint: 'Angkat dua tangan beban seimbang (< 6 kg)', hasEIS: false),
        SwElement(id: 'el-uud-10', jobId: job.id, stepNumber: 10, title: 'Beri tanda QC stamp hijau & catat checksheet per jam', manualTime: 4.5, machineTime: 0.0, walkTime: 1.0, qualityPoint: 'Stempel jelas pada flange non-appearance', safetyPoint: 'Jaga kebersihan lantai 5S dari spatter', hasEIS: false),
      ];
    }

    final avg = (job.targetCycleTime / 8).floor();
    return List.generate(8, (i) {
      final step = i + 1;
      final m = (avg * 0.65).roundToDouble();
      final mc = step % 3 == 0 ? (avg * 0.25).roundToDouble() : 0.0;
      final w = ((avg * 0.1).round().clamp(1, 5)).toDouble();
      return SwElement(
        id: 'el-${job.id}-$step',
        jobId: job.id,
        stepNumber: step,
        title: 'Langkah $step: Pengerjaan ${job.partName} di ${job.posName}',
        manualTime: m,
        machineTime: mc,
        walkTime: w,
        qualityPoint: 'Inspeksi visual BIQ & fitting langkah $step',
        safetyPoint: 'Wajib APD helm, goggle, & sarung tangan anti sayat',
        hasEIS: step == 2 || step == 4,
      );
    });
  }

  static List<SwObservation> swObservationsForJob(SwJob job) {
    return List.generate(10, (idx) {
      final cycleNo = idx + 1;
      final jitter = ((idx % 3 == 0 ? -1 : (idx % 2 == 0 ? 1 : 0)) * (cycleNo % 4)).toDouble();
      final total = job.targetCycleTime + jitter;
      final m = (total * 0.60).roundToDouble();
      final mc = (total * 0.21).roundToDouble();
      final w = total - m - mc;
      return SwObservation(
        id: 'obs-${job.id}-$cycleNo',
        profileId: job.profileId,
        jobId: job.id,
        cycleNo: cycleNo,
        observerPic: 'GL Kamaludin',
        operatorPic: job.operatorPic,
        observationDate: '2026-11-12',
        shift: 'RED',
        actualManualSec: m,
        actualMachineSec: mc,
        actualWalkSec: w,
        varianceSec: jitter,
        wasteMotionNotes: jitter > 0 ? 'Sedikit deviasi jangkauan part / selang gun' : 'Gerakan ritmis konsisten',
        qualityIssueNotes: 'Nugget spot & pitch 30 mm OK',
        safetyErgoNotes: 'APD lengkap & postur kerja aman',
        countermeasure: jitter > 0 ? 'Rapikan posisi trolley & cord hanger balancer' : 'Pertahankan standar kerja',
        status: jitter > 3 ? 'OVER_CYCLE' : (jitter > 0 ? 'KAIZEN_NEEDED' : 'NORMAL'),
      );
    });
  }
}
