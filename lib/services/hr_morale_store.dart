import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/checksheet_models.dart';
import '../models/hr_morale_models.dart';
import 'ub_web_api.dart';

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
  // 1. BACA DOA ASARE — 1:1 with /api/hr/bacadoa (GET / PUT)
  // ===========================================================================
  Future<Map<int, BacaDoaAssignment>> loadBacaDoa(String ym, String shift) async {
    final res = await UbWebApi.instance.getJson('/api/hr/bacadoa', query: {'ym': ym, 'shift': shift});
    if (res.ok && res.map['data'] is Map && (res.map['data'] as Map)['records'] is Map) {
      final rawRecs = Map<String, dynamic>.from((res.map['data'] as Map)['records'] as Map);
      final out = <int, BacaDoaAssignment>{};
      rawRecs.forEach((k, v) {
        final day = int.tryParse(k);
        if (day != null && v is Map) {
          out[day] = BacaDoaAssignment.fromJson(Map<String, dynamic>.from(v));
        }
      });
      await _saveBacaDoaLocal(ym, shift, out);
      return out;
    }

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

  Future<void> _saveBacaDoaLocal(String ym, String shift, Map<int, BacaDoaAssignment> records) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{};
    records.forEach((k, v) => encoded['$k'] = v.toJson());
    await prefs.setString(_bacaDoaKey(ym, shift), jsonEncode(encoded));
  }

  Future<void> saveBacaDoa(String ym, String shift, Map<int, BacaDoaAssignment> records) async {
    await _saveBacaDoaLocal(ym, shift, records);
    final encoded = <String, dynamic>{};
    records.forEach((k, v) => encoded['$k'] = v.toJson());
    await UbWebApi.instance.putJson('/api/hr/bacadoa', {
      'ym': ym,
      'shift': shift,
      'records': encoded,
    });
  }

  // ===========================================================================
  // 2. RANK MP CUSTOM HR EVALS — 1:1 with /api/hr/rankmp (GET / POST)
  // ===========================================================================
  Future<Map<int, RankMpCustomEval>> loadRankEvals(String ym, String shift) async {
    final res = await UbWebApi.instance.getJson('/api/hr/rankmp', query: {'ym': ym, 'shift': shift});
    if (res.ok && res.map['status'] == 'success' && res.map['data'] is List) {
      final out = <int, RankMpCustomEval>{};
      for (final rawItem in res.map['data'] as List) {
        if (rawItem is Map) {
          final id = rawItem['memberId'] is num ? (rawItem['memberId'] as num).toInt() : 0;
          final pts = rawItem['customHrPoints'] is num ? (rawItem['customHrPoints'] as num).toInt() : 0;
          final notes = '${rawItem['hrNotes'] ?? ''}';
          if (id > 0 && (pts != 0 || notes.isNotEmpty)) {
            out[id] = RankMpCustomEval(customPoints: pts, notes: notes);
          }
        }
      }
      await _saveRankEvalsLocal(ym, shift, out);
      return out;
    }

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

  Future<void> _saveRankEvalsLocal(String ym, String shift, Map<int, RankMpCustomEval> evals) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{};
    evals.forEach((k, v) => encoded['$k'] = v.toJson());
    await prefs.setString(_rankEvalKey(ym, shift), jsonEncode(encoded));
  }

  Future<void> saveRankEvals(String ym, String shift, Map<int, RankMpCustomEval> evals) async {
    await _saveRankEvalsLocal(ym, shift, evals);
    final customEvaluations = <String, dynamic>{};
    evals.forEach((k, v) => customEvaluations['$k'] = v.toJson());
    await UbWebApi.instance.postJson('/api/hr/rankmp', {
      'ym': ym,
      'shift': shift,
      'customEvaluations': customEvaluations,
    });
  }

  // ===========================================================================
  // 3. MONTHLY IDEA RECORD — 1:1 with /api/hr/idea (GET / PATCH)
  // ===========================================================================
  Future<HrIdeaMonth> loadHrIdea(String ym) async {
    final res = await UbWebApi.instance.getJson('/api/hr/idea', query: {'month': ym});
    if (res.ok && res.map['data'] is Map) {
      final rawData = Map<String, dynamic>.from(res.map['data'] as Map);
      // Normalize Next.js field names (`idea`/`maker` vs `dailyIdea`/`dailyMaker`)
      Map<String, dynamic> normTeam(dynamic rawT) {
        if (rawT is! Map) return {};
        final m = Map<String, dynamic>.from(rawT);
        return {
          'mp': m['mp'],
          'totalIdeaManual': m['totalIdea'] ?? m['totalIdeaManual'],
          'totalMakerManual': m['totalMaker'] ?? m['totalMakerManual'],
          'dailyIdea': m['idea'] ?? m['dailyIdea'],
          'dailyMaker': m['maker'] ?? m['dailyMaker'],
        };
      }

      final parsed = HrIdeaMonth.fromJson(ym, {
        'targetIdea': rawData['targetIdea'],
        'targetPart': rawData['targetPart'],
        'red': normTeam(rawData['red']),
        'white': normTeam(rawData['white']),
      });
      await _saveHrIdeaLocal(parsed);
      return parsed;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_hrIdeaKey(ym));
    if (raw != null && raw.isNotEmpty) {
      try {
        return HrIdeaMonth.fromJson(ym, Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {}
    }
    final empty = HrIdeaMonth.empty(ym);
    await _saveHrIdeaLocal(empty);
    return empty;
  }

  Future<void> _saveHrIdeaLocal(HrIdeaMonth data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hrIdeaKey(data.ym), jsonEncode(data.toJson()));
  }

  Future<void> saveHrIdea(HrIdeaMonth data) async {
    await _saveHrIdeaLocal(data);
  }

  Future<bool> patchHrIdeaRemote(String ym, Map<String, dynamic> patchBody) async {
    final res = await UbWebApi.instance.patchJson('/api/hr/idea', {'month': ym, ...patchBody});
    return res.ok;
  }

  // ===========================================================================
  // 4. IDNU (INNOVATION PORTAL) — 1:1 with /api/idnu/items
  // ===========================================================================
  Future<List<IdnuIdeaItem>> loadIdnuItems() async {
    final res = await UbWebApi.instance.getJson('/api/idnu/items');
    if (res.ok && res.map['items'] is List) {
      final list = (res.map['items'] as List)
          .whereType<Map>()
          .map((m) {
            final j = Map<String, dynamic>.from(m);
            return IdnuIdeaItem(
              uid: '${j['uid'] ?? ''}',
              area: '${j['area'] ?? 'P'}',
              date: '${j['date'] ?? ''}',
              title: '${j['title'] ?? ''}',
              beforeText: '${j['beforeText'] ?? ''}',
              afterText: '${j['afterText'] ?? ''}',
              pic: '${j['pic'] ?? ''}',
              process: '${j['process'] ?? ''}',
              status: '${j['ideaStatus'] ?? 'belum'}',
              portalStatus: '${j['ideaPortalStatus'] ?? 'Belum Dikirim'}',
              transactionId: '${j['ideaTransactionId'] ?? j['ideaNoreg'] ?? ''}',
              reward: j['ideaReward'] is num ? (j['ideaReward'] as num).toInt() : 0,
              isDraft: j['ideaIsDraft'] == null ? true : j['ideaIsDraft'] == true,
            );
          })
          .toList();
      if (list.isNotEmpty) {
        await saveIdnuItems(list);
        return list;
      }
    }

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
  // 5. HR TEMUAN & KAIZEN — 1:1 with /api/hr/findings (GET / POST / PUT / DELETE)
  // ===========================================================================
  Future<List<HrFindingItem>> loadHrFindings(String ym) async {
    final res = await UbWebApi.instance.getJson('/api/hr/findings', query: {'month': ym});
    if (res.ok && res.map['items'] is List) {
      final list = (res.map['items'] as List)
          .whereType<Map>()
          .map((m) => HrFindingItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      await _saveHrFindingsLocal(ym, list);
      return list;
    }

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

  Future<void> _saveHrFindingsLocal(String ym, List<HrFindingItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hrFindingsKey(ym), jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> saveHrFindings(String ym, List<HrFindingItem> list) async {
    await _saveHrFindingsLocal(ym, list);
  }

  Future<bool> syncUpsertHrFinding(HrFindingItem item, {required bool isEdit}) async {
    final res = isEdit
        ? await UbWebApi.instance.putJson('/api/hr/findings/${Uri.encodeComponent(item.id)}', item.toJson())
        : await UbWebApi.instance.postJson('/api/hr/findings', item.toJson());
    return res.ok;
  }

  Future<bool> syncDeleteHrFinding(String id) async {
    final res = await UbWebApi.instance.deleteJson('/api/hr/findings/${Uri.encodeComponent(id)}');
    return res.ok;
  }
}
