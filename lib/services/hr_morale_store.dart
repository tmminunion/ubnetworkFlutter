import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/checksheet_models.dart';
import '../models/hr_morale_models.dart';

class HrMoraleStore {
  HrMoraleStore._();
  static final HrMoraleStore instance = HrMoraleStore._();

  static String _bacaDoaKey(String ym, String shift) => 'ubf_bacadoa_v1_${ym}_$shift';
  static String _rankEvalKey(String ym, String shift) => 'ubf_rank_eval_v1_${ym}_$shift';
  static String _hrIdeaKey(String ym) => 'ubf_hr_idea_v1_$ym';
  static const String _idnuKey = 'ubf_idnu_v1';
  static String _hrFindingsKey(String ym) => 'ubf_hr_findings_v1_$ym';

  List<BacaDoaOperator> operatorsForShift(String shift) {
    return UbMasterData.defaultMembers(shift)
        .asMap()
        .entries
        .map(
          (e) => BacaDoaOperator(
            id: e.key + 1,
            name: e.value.name,
            noreg: e.value.noreg,
            pos: 'Pos ${(e.key % 8) + 1}',
          ),
        )
        .toList();
  }

  // ===========================================================================
  // 1. BACA DOA ASARE
  // ===========================================================================
  Future<Map<int, BacaDoaAssignment>> loadBacaDoa(String ym, String shift) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bacaDoaKey(ym, shift));
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final out = <int, BacaDoaAssignment>{};
      map.forEach((k, v) {
        final day = int.tryParse(k);
        if (day != null && v is Map) {
          out[day] = BacaDoaAssignment.fromJson(Map<String, dynamic>.from(v));
        }
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveBacaDoa(String ym, String shift, Map<int, BacaDoaAssignment> records) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{};
    records.forEach((k, v) => encoded['$k'] = v.toJson());
    await prefs.setString(_bacaDoaKey(ym, shift), jsonEncode(encoded));
  }

  // ===========================================================================
  // 2. RANK MP CUSTOM HR EVALS
  // ===========================================================================
  Future<Map<int, RankMpCustomEval>> loadRankEvals(String ym, String shift) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rankEvalKey(ym, shift));
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final out = <int, RankMpCustomEval>{};
      map.forEach((k, v) {
        final id = int.tryParse(k);
        if (id != null && v is Map) {
          out[id] = RankMpCustomEval.fromJson(Map<String, dynamic>.from(v));
        }
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveRankEvals(String ym, String shift, Map<int, RankMpCustomEval> evals) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{};
    evals.forEach((k, v) => encoded['$k'] = v.toJson());
    await prefs.setString(_rankEvalKey(ym, shift), jsonEncode(encoded));
  }

  // ===========================================================================
  // 3. MONTHLY IDEA RECORD
  // ===========================================================================
  Future<HrIdeaMonth> loadHrIdea(String ym) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_hrIdeaKey(ym));
    if (raw != null && raw.isNotEmpty) {
      try {
        return HrIdeaMonth.fromJson(ym, Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {}
    }
    final empty = HrIdeaMonth.empty(ym);
    await saveHrIdea(empty);
    return empty;
  }

  Future<void> saveHrIdea(HrIdeaMonth data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hrIdeaKey(data.ym), jsonEncode(data.toJson()));
  }

  // ===========================================================================
  // 4. IDNU (INNOVATION PORTAL)
  // ===========================================================================
  Future<List<IdnuIdeaItem>> loadIdnuItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_idnuKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.whereType<Map>().map((m) => IdnuIdeaItem.fromJson(Map<String, dynamic>.from(m))).toList();
      } catch (_) {}
    }

    final today = hrTodayYmd();
    final seed = [
      IdnuIdeaItem(
        uid: 'KZ-P-001',
        area: 'P',
        date: today,
        title: 'Bracket Pelindung Spatter Sensor Clamp Jig RR',
        beforeText: 'Sensor sering error terkena spatter las (chokotei 15 mnt/shift).',
        afterText: 'Cover tembaga anti-spatter menurunkan chokotei menjadi 0 mnt.',
        pic: 'TL Shift Red',
        process: 'UB Assy Robot 202',
        status: 'belum',
      ),
      IdnuIdeaItem(
        uid: 'KZ-S-002',
        area: 'S',
        date: today,
        title: 'Pemasangan Kaca Cembung Blindspot Jalur Forklift UB',
        beforeText: 'Blindspot di tikungan jalur suplai part berpotensi tertabrak.',
        afterText: 'Visibilitas 180 derajat sebelum melintas jalur utama.',
        pic: 'SGA Safety White',
        process: 'Jalur AGV / Forklift',
        status: 'sudah',
        portalStatus: 'Menunggu LH',
        transactionId: 'ID26110042',
        isDraft: false,
      ),
      IdnuIdeaItem(
        uid: 'KZ-E-003',
        area: 'E',
        date: today,
        title: 'Pengunci Quick Coupler Pneumatic Anti Air Leakage',
        beforeText: 'Coupler selang angin kendor menyebabkan kebocoran udara 4 bar.',
        afterText: 'Zero air leakage pada Pos 3 & hemat listrik kompresor.',
        pic: 'PIC Environment',
        process: 'UB Assy Pos 3',
        status: 'sudah',
        portalStatus: 'Paid',
        transactionId: 'ID26100188',
        reward: 75000,
        isDraft: false,
      ),
    ];
    await saveIdnuItems(seed);
    return seed;
  }

  Future<void> saveIdnuItems(List<IdnuIdeaItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idnuKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  // ===========================================================================
  // 5. HR TEMUAN & KAIZEN
  // ===========================================================================
  Future<List<HrFindingItem>> loadHrFindings(String ym) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_hrFindingsKey(ym));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<Map>().map((m) => HrFindingItem.fromJson(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveHrFindings(String ym, List<HrFindingItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hrFindingsKey(ym), jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}
