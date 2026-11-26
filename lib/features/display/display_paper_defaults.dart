// 1:1 Dart port of ubnetwork/app/display/data.ts, fyData.ts, defaults.ts & safety-proses-data.ts
import 'dart:math' as math;

import '../../models/safety_finding_models.dart';

const double kDisplayPaperW = 1600.0;
const double kDisplayPaperH = 900.0;

const List<String> kIndoMonths = [
  'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des', 'Jan', 'Feb', 'Mar',
];

const List<String> kEngMonths = [
  'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar',
];

const List<String> kCostMonthNames = [
  'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr',
];

const List<String> kCalAbbr = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const List<String> kCalFullId = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

const Map<String, String> kStaticPaperTitles = {
  'safety-proses': 'LIST UP PROBLEM FINDINGS UB ASSY',
  'productivity-sub': 'EFISIENSI',
  'quality-sub': 'DEFECT',
  'cost-main': 'COST UNDER BODY ASSY',
  'cost-sub': 'CONTROL COST DAILY',
  'cost-proses': 'TEMUAN COST',
};

const Map<String, String> kDefaultPocketTitles = {
  'hoshin-main': 'HOSHIN STATEMENT',
  'hoshin-sub': 'MILL HEAD',
  'hoshin-proses': 'KPI TREE',
  'hoshin-kaizen': 'STRATEGY',
  'safety-main': 'SAFETY PERFORMANCE',
  'safety-sub': 'SAFETY ACTIVITY (KYT)',
  'safety-proses': 'NEAR MISS PER PENYEBAB',
  'safety-kaizen': 'LIST UP PROBLEM SAFETY',
  'quality-main': 'IN-PROCESS DEFECT',
  'quality-sub': 'DEFECT DETAIL / UNIT',
  'quality-proses': 'STRATIFIKASI DEFECT',
  'quality-kaizen': 'LIST UP PROBLEM QUALITY',
  'productivity-main': 'EFISIENSI LINE',
  'productivity-sub': 'DOWNTIME LINE',
  'productivity-proses': 'PARETO LOSS TIME',
  'productivity-kaizen': 'KAIZEN REPORT PRODUCTIVITY',
  'cost-main': 'BIAYA SCRAP (JUTA)',
  'cost-sub': 'CONSUMABLE VS BUDGET',
  'cost-proses': 'PARETO BIAYA SCRAP',
  'cost-kaizen': 'KAIZEN REPORT COST',
  'hr-dev-main': 'KEHADIRAN',
  'hr-dev-sub': 'SKILL MATRIX',
  'hr-dev-proses': 'PARETO ABSEN',
  'hr-dev-kaizen': 'KAIZEN REPORT HR',
  'env-main': 'AIR LEAKAGE',
  'env-sub': 'ENERGI HARIAN',
  'env-proses': 'TEMUAN LINGKUNGAN',
  'env-kaizen': 'KAIZEN REPORT ENV',
};

String resolvePaperHeaderTitle({
  required String slug,
  required String shortName,
  required String rowKey,
  String? customTitle,
}) {
  if (rowKey == 'kaizen') return 'KAIZEN REPORT · $shortName';
  final rowName = switch (rowKey) {
    'main' => 'MAIN KPI',
    'sub' => 'SUB KPI',
    'proses' => 'PROSES KPI',
    _ => rowKey.toUpperCase(),
  };
  final id = '$slug-$rowKey';
  final staticTitle = kStaticPaperTitles[id];
  if (staticTitle != null) return '$rowName · $staticTitle';
  final clean = (customTitle ?? '').trim();
  if (clean.isNotEmpty) return '$rowName · $clean';
  final def = kDefaultPocketTitles[id] ?? shortName;
  return '$rowName · $def';
}

class DisplayFyMath {
  DisplayFyMath._();

  static DateTime wibNow() => DateTime.now().toUtc().add(const Duration(hours: 7));

  static String nowYm() {
    final w = wibNow();
    return '${w.year}-${w.month.toString().padLeft(2, '0')}';
  }

  static String todayYmd() {
    final w = wibNow();
    return '${w.year}-${w.month.toString().padLeft(2, '0')}-${w.day.toString().padLeft(2, '0')}';
  }

  static int currentFy([DateTime? now]) {
    final w = now != null ? now.toUtc().add(const Duration(hours: 7)) : wibNow();
    return w.month >= 4 ? w.year : w.year - 1;
  }

  static int costCurrentFy([DateTime? now]) {
    final w = now != null ? now.toUtc().add(const Duration(hours: 7)) : wibNow();
    return w.month >= 5 ? w.year : w.year - 1;
  }

  static String fyLabel(int fy) => 'FY $fy/${fy + 1}';

  static List<String> fyMonths(int fy) => List.generate(
        12,
        (i) => '${kEngMonths[i]}-${((i < 9 ? fy : fy + 1) % 100).toString().padLeft(2, '0')}',
      );

  static List<String> costMonths(int fy) => List.generate(
        12,
        (i) => '${kCostMonthNames[i]}-${((i < 8 ? fy : fy + 1) % 100).toString().padLeft(2, '0')}',
      );

  static String fyYm(int fy, int index) {
    if (index < 9) {
      return '$fy-${(index + 4).toString().padLeft(2, '0')}';
    }
    return '${fy + 1}-${(index - 8).toString().padLeft(2, '0')}';
  }

  static String shiftYm(String ym, int delta) {
    final parts = ym.split('-');
    final y = int.tryParse(parts[0]) ?? 2026;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
    final total = y * 12 + (m - 1) + delta;
    final ny = total ~/ 12;
    final nm = (total % 12) + 1;
    return '$ny-${nm.toString().padLeft(2, '0')}';
  }

  static String labelOfYm(String ym) {
    final parts = ym.split('-');
    if (parts.length < 2) return ym;
    final m = (int.tryParse(parts[1]) ?? 1).clamp(1, 12);
    final yy = parts[0].length >= 4 ? parts[0].substring(2, 4) : parts[0];
    return '${kCalAbbr[m - 1]}-$yy';
  }

  static String longLabelOfYm(String ym) {
    final parts = ym.split('-');
    if (parts.length < 2) return ym;
    final m = (int.tryParse(parts[1]) ?? 1).clamp(1, 12);
    return '${kCalFullId[m - 1]} ${parts[0]}';
  }

  static String bulanId(String? ymOrDate) {
    if (ymOrDate == null || ymOrDate.length < 7) return '-';
    final m = RegExp(r'^(\d{4})-(\d{2})').firstMatch(ymOrDate);
    if (m == null) return '-';
    final month = (int.tryParse(m.group(2)!) ?? 1).clamp(1, 12);
    return '${kCalFullId[month - 1]} ${m.group(1)}';
  }

  static String daySlashMonth(String? ymd) {
    if (ymd == null || ymd.length < 10) return '';
    return '${ymd.substring(8, 10)}/${ymd.substring(5, 7)}';
  }

  static int daysInMonth(String ym) {
    final parts = ym.split('-');
    if (parts.length < 2) return 31;
    final y = int.tryParse(parts[0]) ?? 2026;
    final m = int.tryParse(parts[1]) ?? 1;
    return DateTime.utc(y, m + 1, 0).day;
  }

  static bool isWeekend(String ym, int day1Based) {
    final parts = ym.split('-');
    if (parts.length < 2) return false;
    final y = int.tryParse(parts[0]) ?? 2026;
    final m = int.tryParse(parts[1]) ?? 1;
    final wd = DateTime.utc(y, m, day1Based).weekday;
    return wd == DateTime.saturday || wd == DateTime.sunday;
  }

  static int costMonthDays(int fy, int i) {
    final m = ((4 + i) % 12) + 1;
    final y = i < 8 ? fy : fy + 1;
    return DateTime.utc(y, m + 1, 0).day;
  }

  /// 1:1 `fmtNum` in `fyData.ts` (Indonesian comma decimal, max 4 decimals, no trailing zeros)
  static String fmtNum(num? v) {
    if (v == null) return '';
    final d = v.toDouble();
    if (d == d.roundToDouble()) {
      return formatInt(d.round());
    }
    var s = d.toStringAsFixed(4);
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return s.replaceAll('.', ',');
  }

  static String fmtDec(num? v, [int dec = 1]) {
    if (v == null) return '';
    if (dec <= 0) return formatInt(v.round());
    return v.toDouble().toStringAsFixed(dec).replaceAll('.', ',');
  }

  static String fmtDu(double? v, [String empty = '']) {
    if (v == null) return empty;
    if (v == 0) return '0';
    final t = v.toStringAsFixed(3);
    final res = double.tryParse(t) == 0 ? v.toStringAsFixed(4) : t;
    return res.replaceAll('.', ',');
  }

  static String formatInt(num? v) {
    if (v == null) return '';
    final n = v.round();
    final absStr = n.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < absStr.length; i++) {
      final rev = absStr.length - i;
      buf.write(absStr[i]);
      if (rev > 1 && rev % 3 == 1) buf.write('.');
    }
    return '${n < 0 ? '-' : ''}$buf';
  }

  /// 1:1 `chartAxis` in `fyData.ts`
  static ({double ymax, double step}) chartAxis(double rawMax, bool fractional) {
    if (!fractional) {
      final step = rawMax > 6 ? (rawMax / 6).ceilToDouble() : 1.0;
      final ymax = math.max(3.0, (rawMax / step).ceilToDouble() * step);
      return (ymax: ymax, step: step);
    }
    final want = (math.max(rawMax, 1e-6) * 1.1) / 4.0;
    final exp = (math.log(want) / math.ln10).floor();
    final mag = math.pow(10.0, exp).toDouble();
    const mults = [1.0, 2.0, 2.5, 5.0, 10.0];
    var step = mag * 10.0;
    for (final m in mults) {
      if (m * mag >= want) {
        step = m * mag;
        break;
      }
    }
    final ymax = step * math.max(4, ((rawMax / step) - 1e-9).ceil());
    return (ymax: ymax, step: step);
  }
}

// =============================================================================
// 1:1 DEFAULT DATA FOR HOSHIN KANRI (4 SHEETS)
// =============================================================================

const Map<String, dynamic> kHoshinMainDefault = {
  'pillar': 'Pillar 0',
  'pillarTitle': 'Basic Foundation',
  'page': '1/8',
  'coy': '0.1 To create safe place where everyone have room to grow : Build in Safety, Quality & Compliance',
  'dir': 'SAFETY :Enhance safety performance through',
  'kpiTarget': 'Zero Accident & Incident',
  'reflection': [
    {
      'title': '1. SAFETY',
      'lines': [
        'Accident 0, Near miss : 1 case,',
        'Traffic Accident : 2 Case',
        'Safety Awareness, SGA implementation need to level up as daily activity.',
      ],
    },
    {
      'title': '2. COMPLIANCE',
      'lines': [
        'no nonconformance item but Observations have been raised to further improve',
      ],
    },
  ],
  'strategy': [
    {
      'heading': 'Excellent Safety Workplace & Member Awareness by Genba Based Monitoring',
      'lettered': true,
      'items': [
        'Strengthen SGA Implementation to Identified unsafe action & condition ( Close up & Member Voice) utilize SGA Assesment Tools.',
        'Massive Yarinikui Elimination by Optimize Internal Master Assesor',
        'Sustain 4S 3 Pillar Implementation at Prod, and Level up for Supporting Team.',
      ],
    },
    {
      'heading': 'Comply to audit requirement through Excellent Daily Management',
      'lettered': false,
      'items': [
        'Periodical Internal Audit by Division Key Person ( 1x/ 6 month)',
      ],
    },
  ],
  'kpi': [
    {
      'label': '0 Accident & Near Miss',
      'hl': true,
      'lines': ['Gold : +3 SGA (4/45)', 'Silver : +7 SGA (17/35)', 'Bronze : Finish (14/35)'],
    },
    {
      'label': 'Zero Rank A/High Burden',
      'hl': false,
      'lines': ['Gold : +7 (11/44)', 'Silver : +11 (19/44)', 'Bronze : +6 (6/44)', 'Dev : 8/44'],
    },
    {
      'label': '0 Non Compliance',
      'hl': true,
      'lines': ['100% Done'],
    },
  ],
};

String _apSup(String main) {
  const pics = ['FS', 'AS', 'RL', 'W', 'MY', 'S', 'A', 'B', 'ALL'];
  final mSet = main.split(' ').toSet();
  return pics.where((c) => !mSet.contains(c)).join(' ');
}

final Map<String, dynamic> kActionPlanDefault = {
  'title': 'BODY PRODUCTION DEPARTEMENT ACTION PLAN 2026~2027',
  'subtitle': 'PRESS & WELDING DIVISION',
  'divHead': 'RENALDI',
  'deptHead': 'Widy K',
  'pics': 'FS AS RL W MY S A B ALL',
  'sups': 'SHE WES TIIN MTN',
  'legend':
      'W : WITO   FS : FITRIADI S   AS : AGUNG S   A : ASEP S   R : REDY L   MY : M. YAHYA   S : SURADI   B : BUYUNG   ALL : ALL LINE HEAD',
  'rows': [
    {
      'no': '1',
      'kra': 'SAFETY & ENVIRONMENT',
      'output': '1.1 Safe Workplace',
      'kpiName': '1.1.1 KY Ability',
      'ref': 'KRW 1A.1.1',
      'target': 'KY Level ≥ 3',
      'current': 'KY Level 2\nstill exist',
      'improvement': [
        'Continue KY Assessment for All Member',
        'Training for All Members to reach KY Ability Level 3 ( every Wednesday )',
      ],
      'activity': ['Participant 100%', "All Members passed Level 3 on Nop '13"],
      'schedule': ['Apr-Mei Assessment#1', 'Jun-Jul Training#1', 'Sep-Okt Assessment#2', 'Feb-Mar Assessment#3'],
      'main': 'MY',
      'sup': _apSup('MY'),
    },
    {
      'no': '',
      'kra': '',
      'output': '',
      'kpiName': '1.1.2 Strengthen SGA',
      'ref': '',
      'target': '1 KY Theme\n/Group/Month',
      'current': '1 KY Theme\n/Group/Month',
      'improvement': [
        'Focus to Implement and Level up " Line safety Level " ( Bottom-up Activity )',
        'Daily Safety Patrol ( Top - Down Activity )',
      ],
      'activity': ['Line Safety Level 3', 'G/L Participation 100%'],
      'schedule': ['Jun-Jul Implementation', 'Sep Eva', 'Nop-Des Implementation'],
      'main': 'MY',
      'sup': _apSup('MY'),
    },
    {
      'no': '',
      'kra': '',
      'output': '1.2 Green Level',
      'kpiName': '1.2.1 Pollutant Reduction',
      'ref': 'KRW 1.A.2.3',
      'target': '',
      'current': '',
      'improvement': [
        'Reduction CO2 and Smoke at Frame Line by maintain Exhause Velocity , Carbon Neutral activity (Air Leakage)',
      ],
      'activity': ['1,2 m3 / Sec ( Keep as TMC reference )'],
      'schedule': ['Apr-Mei Mapping', 'Agu Eva', 'Sep-Nop Maintenance Improvement', 'Feb Eva'],
      'main': 'A',
      'sup': '${_apSup('A')} SHE',
    },
    {
      'no': '2',
      'kra': 'QUALITY',
      'output': '2.1 Welding Body',
      'kpiName': '2.1.1 In Process Dpu\nInnova, Zenix\nFortuner',
      'ref': 'KRW 1.B.2',
      'target': '0,25 dpu',
      'current': '0,35 dpu',
      'improvement': [
        'Develop MP Quality Skill trought FS Training or Advance Training (Morimoto Dojo), Back To Basic',
        'Strengthen BIQ for All proses (member)',
      ],
      'activity': [
        'Participan 100% (GL, TL & New T/M)',
        'All T/Ms can explain potential defect at his/her process',
      ],
      'schedule': ['Jun-Jul Training', 'Sep-Okt Assessment', 'Nop Eva'],
      'main': 'AS',
      'sup': _apSup('AS'),
    },
    {
      'no': '',
      'kra': '',
      'output': '',
      'kpiName': '2.1.2 After ED Dpu\nInnova, Zenix\nFortuner',
      'ref': '',
      'target': '0,1 dpu\n0 rejection A/ED',
      'current': '0,2 dpu',
      'improvement': [
        'Level up Problem Ownership by Line involve',
        'Establish Collaboration Team for Special Task Force → Special Theme (Digitalization kaizen)',
      ],
      'activity': ['Reduce DPU 50%', 'Finished 1 Theme / Team / 1 Mouth'],
      'schedule': ['Apr Eva'],
      'main': 'FS',
      'sup': _apSup('FS'),
    },
    {
      'no': '',
      'kra': '',
      'output': '',
      'kpiName': '2.1.3 Final Assy Dpu\nInnova, Zenix\nFortuner',
      'ref': '',
      'target': 'Challenge "0" SQA\n"0" Out Flow',
      'current': '',
      'improvement': ['Completion SW review for each process'],
      'activity': ['Challange (No defect Out Flow Thoso & Assy)', 'Review SW all process 1X / Mounth'],
      'schedule': ['Apr Eva', 'Apr-Mei Assessment'],
      'main': 'RL',
      'sup': _apSup('RL'),
    },
    {
      'no': '',
      'kra': '',
      'output': '',
      'kpiName': '2.1.4 SQA Dpu\nS/B S/A\nS/M R/L\nM/B , U/B',
      'ref': '',
      'target': '50% from total\n35% from total\n15% from total',
      'current': '',
      'improvement': ['Strengthen GL Role Implementation'],
      'activity': ['G/L & T/L Role Assessment 100%', 'Model Excelent Process by All G/L or T/L'],
      'schedule': ['Jun-Agu Model Proses', 'Okt-Des Yokotan Proses'],
      'main': 'FS MY',
      'sup': _apSup('FS MY'),
    },
    {
      'no': '3',
      'kra': 'PRODUCTIVITY',
      'output': '3.1 Line Efficiency',
      'kpiName': '',
      'ref': 'KRW 1.C.1',
      'target': 'Internal Eff.\n98 %',
      'current': 'Internal Eff.\n97%',
      'improvement': [
        'Improve Cycle Time by Jishuken Activity',
        'Reduce Line Stop at each Process by Conduct Improvement of Common Theme',
      ],
      'activity': ['G/L Participant 100%', '1 Theme / Semester'],
      'schedule': ['Apr-Sep Improvement Theme#1', 'Okt-Mar Improvement Theme#2'],
      'main': 'FS W',
      'sup': _apSup('FS W'),
    },
    {
      'no': '4',
      'kra': 'COST',
      'output': '4.1 Competitive Cost',
      'kpiName': '4.1.1 Cost Reduction',
      'ref': 'KRW 1.D.4',
      'target': 'MPEFF : 94,5%\nMH/Unit :\nBody :',
      'current': 'MPEFF : 93,0%\nMH/Unit :\nBody :',
      'improvement': [
        'Reduce Muda (Waiting Time) by Introduce Shimawari (Working Track) Evaluation System',
        'Increase Automation Ration with Simple Technology (Digitalization)',
        'Continue MH/Unit Control',
      ],
      'activity': [
        'Waiting Time : Max. 2 secon at each process',
        'Automation for All Sealer Application Process.',
        'Data verified within 1 Week',
      ],
      'schedule': [
        'Apr-Mei Intro',
        'Jun-Sep Improvement 1st Cycle',
        'Nop-Mar Improvement 2nd Cycle',
        'Apr-Mei Study',
        'Jun-Agu Fabrication',
        'Sep SVP',
        'Apr Eva',
      ],
      'main': 'FS AS B',
      'sup': _apSup('FS AS B'),
    },
    {
      'no': '5',
      'kra': 'HR DEVELOPMENT',
      'output': '5.1 Qualified Employee',
      'kpiName': '5.1.1 Idea Sugestion',
      'ref': 'KRW 1.E.5',
      'target': '2 Idea / MP\nPartiopan :\nMin. 95%',
      'current': '2 Idea / MP\nParticipation :\n>90%',
      'improvement': [
        'Continue Idea Control (CN idea & Digitalization)',
        'Qualified Idea (Reward more Than Rp. 100.000,-',
      ],
      'activity': ['Data verified within 1 week', '2 Idea/Month'],
      'schedule': ['Apr Eva'],
      'main': 'AS MY',
      'sup': _apSup('AS MY'),
    },
    {
      'no': '',
      'kra': '',
      'output': '',
      'kpiName': '5.1.2 QCC',
      'ref': '',
      'target': '1 Theme/Group/\nYear',
      'current': '1 Theme/\nGroup/Year',
      'improvement': [
        'Training for all Circle Leader to rise up QCC Level',
        'Strengthen Role of QCC Secretary',
      ],
      'activity': ['QCC Level A,B "80%" Level C "20%"', 'No Delay QCC Activity'],
      'schedule': ['Jun-Jul Explanation Assessment Program', 'Agu Q-Clinic', 'Okt QCC Competition', 'Apr Eva'],
      'main': 'S W',
      'sup': _apSup('S W'),
    },
    {
      'no': '',
      'kra': '',
      'output': '',
      'kpiName': '5.1.3 Leader Readiness',
      'ref': '',
      'target': 'G/L & T/L Role\nAssessment\nLevel 3',
      'current': '',
      'improvement': [
        'Continue to Level up Leader (T/L & G/L) Competency by Global Content Training (T/L & G/L Role, TBP, TJI, SW, etc)',
      ],
      'activity': ['Follow all Training Schedule from TIIN'],
      'schedule': ['Apr Eva'],
      'main': 'FS',
      'sup': '${_apSup('FS')} TIIN',
    },
  ],
};

const Map<String, dynamic> kKpiTreeDefault = {
  'rows': [
    {
      'pillar': 'Safety',
      'main': '0 Accident',
      'subHead': '',
      'sub': ['Safety Human', 'Safety Device', 'Safety Workplace'],
      'process': ['Hyarihatto', 'SPC Patrol', 'KY Ability', 'Voice Member', 'Safety Patrol', 'SW Compliance ( Safety-Quality )'],
    },
    {
      'pillar': 'Quality',
      'main': '0 Outflow ( Offline\nDefect in Assy)',
      'subHead': '',
      'sub': ['Defect Storing in Assy', 'Defect in SBC', 'Defect Qty Patrol', 'Defect QCIP', 'OK Ratio Spater'],
      'process': [
        'Defect Task Force Internal',
        'Ijiwaru Quality Result',
        'In Process Defect Item',
        '- BIQ',
        '- Kamishibai',
        'Line Kanketsu - Kotei Kanri Mgmt',
      ],
    },
    {
      'pillar': 'Productivity',
      'main': 'Line Efficiency ≥\n97%',
      'subHead': 'Line Stop :',
      'sub': ['Process', 'Quality', 'Equipment', 'Logistic'],
      'process': ['In Process Problem Item', '- Pre Prod Preparation', '- Leader Call (TL-GL)'],
    },
    {
      'pillar': 'Cost',
      'main': 'Reduce Prod. Cost\n7% / year',
      'subHead': '',
      'sub': ['0 Lost Cost', 'On Time Jishuken Activity'],
      'process': [
        'Mieruka Control ( ± 5 % ):',
        '- Operating Supply',
        '- Consumable Tools',
        '- Spare Part (B7)',
        'CR Idea Achievements',
      ],
    },
    {
      'pillar': 'HR',
      'main': 'Flexible MP Skill',
      'subHead': '',
      'sub': <String>[],
      'process': [
        'Tanoko Skill (TM -TL-GL : Internal)',
        'Tanoko Skill : Externall (UB Assy)',
        'TM Performance Sheet (training Status/Development )',
      ],
    },
  ],
};

const Map<String, dynamic> kStrategyBoardDefault = {
  'title': 'STRATEGY',
  'groups': [
    {
      'letter': 'S',
      'lines': [
        'Rank Down Risk Hazard level In All Process Production',
        '100% Solved Problem In [[Safety Patrol]]',
      ],
    },
    {
      'letter': 'Q',
      'lines': [
        'Reduce Deffect/Unit At Next Process Final Inspection',
        '[[0 defect outflow to Final Assy]]',
      ],
    },
    {
      'letter': 'P',
      'lines': [
        'Reduce And Eliminate [[All Of Potential Line Stop]] At Each Process',
      ],
    },
    {
      'letter': 'C',
      'lines': [
        'On Time CR Realization',
        '[[Mapp & Reduce The Air Leaking]]',
      ],
    },
    {
      'letter': 'HR',
      'lines': [
        'On Time Meeting [[QCC]]',
        '[[100% PBL]] for support Welding#1 KPI',
        '[[100% Bronze Level]] At Welding#1',
      ],
    },
  ],
};

class GanttScheduleBar {
  const GanttScheduleBar({
    required this.start,
    required this.end,
    required this.label,
    required this.lane,
  });

  final int start;
  final int end;
  final String label;
  final int lane;
}

int parseActionPlanMonthIdx(String token) {
  final n = int.tryParse(token);
  if (n != null) return (n >= 1 && n <= 12) ? n - 1 : -1;
  if (token.length < 3) return -1;
  final k = token.toLowerCase().substring(0, 3);
  final norm = k == 'nop' ? 'nov' : (k == 'may' ? 'mei' : (k == 'aug' ? 'agu' : (k == 'oct' ? 'okt' : (k == 'dec' ? 'des' : k))));
  return kIndoMonths.indexWhere((m) => m.toLowerCase() == norm);
}

({List<GanttScheduleBar> bars, int lanes}) parseActionPlanBars(List<String> lines) {
  final bars = <GanttScheduleBar>[];
  final laneEnd = <int>[];
  final reg = RegExp(r'^\s*([A-Za-z]+|\d{1,2})(?:\s*-\s*([A-Za-z]+|\d{1,2}))?\s+(.+)$');
  for (final line in lines) {
    final m = reg.firstMatch(line);
    if (m == null) continue;
    final s = parseActionPlanMonthIdx(m.group(1)!);
    final e = m.group(2) != null ? parseActionPlanMonthIdx(m.group(2)!) : s;
    if (s < 0 || e < 0) continue;
    final a = math.min(s, e);
    final b = math.max(s, e);
    var lane = laneEnd.indexWhere((end) => end < a);
    if (lane < 0) {
      lane = laneEnd.length;
      laneEnd.add(b);
    } else {
      laneEnd[lane] = b;
    }
    bars.add(GanttScheduleBar(start: a, end: b, label: m.group(3)!.trim(), lane: lane));
  }
  return (bars: bars, lanes: math.max(laneEnd.length, 1));
}

/// 1:1 `kaizenTag` from `ubnetwork/app/lib/kaizenTag.ts`
String formatKaizenTag(String? rawId, [String? area]) {
  if (rawId == null || rawId.trim().isEmpty) return '';
  final s = rawId.trim();
  if (s.startsWith('#')) return s;
  if (area != null && area.isNotEmpty && RegExp(r'^\d+$').hasMatch(s)) {
    return '#K-${area.toUpperCase()}-$s';
  }
  return '#$s';
}

/// 1:1 `FINDINGS` fallback from `safety-proses-data.ts`
List<SafetyFinding> buildSafetyProsesFallbackFindings() => [
      ...defaultSafetyFindings(),
      SafetyFinding(
        id: 'sample_4',
        no: '4',
        status: 'closed',
        shift: 'red',
        foundAt: '2026-10-02',
        location: 'UB ASSY',
        process: 'SPOT STATION 3',
        caption: 'Kabel las terkelupas di Station 3',
        theme: 'MENANGGULANGI KABEL LAS TERKELUPAS DI STATION 3',
        result: 'POTENSI TERSENGAT LISTRIK DAPAT TERHINDAR, AREA KERJA LEBIH AMAN.',
        hazard: 0,
        sources: [3],
        before: SafetyRisk(
          accident: 'Tersengat listrik',
          code: 'E',
          typeName: 'Electric',
          injury: SafetyRiskPart(desc: 'Memerlukan cuti (Level b)', point: 6),
          frequency: SafetyRiskPart(desc: '1x/Minggu (Tinggi)', point: 5),
          countermeasure: SafetyRiskPart(desc: 'Tidak ada CM safety (Rendah)', point: 8),
          rank: 'Ab',
        ),
        standard: 'Ganti kabel las dan pasang cable guard',
        pic: 'Budi S.',
        date: '05/10/26',
        cm: 'Kabel diganti, cable guard dipasang.',
        after: SafetyRisk(
          accident: 'Tersengat listrik',
          code: 'E',
          typeName: 'Electric',
          injury: SafetyRiskPart(desc: 'Tidak memerlukan cuti (Level c)', point: 2),
          frequency: SafetyRiskPart(desc: '1x/Bulan (Sedang)', point: 4),
          countermeasure: SafetyRiskPart(desc: 'Pokayoke terpasang (Tinggi)', point: 1),
          rank: 'Cc',
        ),
      ),
      SafetyFinding(
        id: 'sample_7',
        no: '7',
        status: 'closed',
        shift: 'white',
        foundAt: '2026-10-20',
        location: 'UB ASSY',
        process: 'GRINDING',
        caption: 'Sarung tangan tidak sesuai di proses grinding',
        theme: 'MENANGGULANGI RISIKO TERSAYAT DI PROSES GRINDING',
        result: 'POTENSI CEDERA TANGAN DAPAT TERHINDAR, PENGGUNAAN APD SESUAI STANDAR.',
        hazard: 0,
        sources: [2],
        before: SafetyRisk(
          accident: 'Tersayat',
          code: 'C',
          typeName: 'Cut',
          injury: SafetyRiskPart(desc: 'Perlu cuti (Level b)', point: 6),
          frequency: SafetyRiskPart(desc: '1x/Minggu (Tinggi)', point: 5),
          countermeasure: SafetyRiskPart(desc: 'Ada tapi belum efektif (Sedang)', point: 4),
          rank: 'Bb',
        ),
        standard: 'Ganti dengan sarung tangan anti potong level 5',
        pic: 'Rina A.',
        date: '23/10/26',
        cm: 'Sarung tangan diganti, sosialisasi ke member.',
        after: SafetyRisk(
          accident: 'Tersayat',
          code: 'C',
          typeName: 'Cut',
          injury: SafetyRiskPart(desc: 'Tidak memerlukan cuti (Level c)', point: 2),
          frequency: SafetyRiskPart(desc: '1x/Minggu (Tinggi)', point: 5),
          countermeasure: SafetyRiskPart(desc: 'APD Level 5 terpasang (Tinggi)', point: 1),
          rank: 'Cc',
        ),
      ),
    ];
