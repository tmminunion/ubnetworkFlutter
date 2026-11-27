import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/hr_morale_models.dart';
import 'ub_web_api.dart';

class BacaDoaHistoryEntry {
  const BacaDoaHistoryEntry({
    required this.ym,
    required this.shift,
    required this.scheduledCount,
    required this.doneCount,
    this.glName = '',
    this.tlName = '',
  });

  final String ym;
  final String shift;
  final int scheduledCount;
  final int doneCount;
  final String glName;
  final String tlName;
}

class HrMoraleStore {
  HrMoraleStore._();
  static final HrMoraleStore instance = HrMoraleStore._();

  static String _bacaDoaKey(String ym, String shift) => 'ubf_bacadoa_v1_${ym}_$shift';
  static String _rosterCacheKey(String shift) => 'ubf_hr_roster_v1_$shift';
  static String _rankEvalKey(String ym, String shift) => 'ubf_rank_eval_v1_${ym}_$shift';
  static String _hrIdeaKey(String ym) => 'ubf_hr_idea_v1_$ym';
  static const String _idnuKey = 'ubf_idnu_v1';
  static String _hrFindingsKey(String ym) => 'ubf_hr_findings_v1_$ym';

  /// 1:1 with `FALLBACK_MEMBERS_RED` & `FALLBACK_MEMBERS_WHITE` in `ubnetwork/app/api/hr/rankmp/route.ts`
  /// Preserves real MySQL `member.id` (`5..43`) so `memberId` matches Atlas `bacadoa` & `hr_rank_mp`.
  List<BacaDoaOperator> operatorsForShift(String shift) {
    if (shift.toUpperCase() == 'WHITE') {
      return const [
        BacaDoaOperator(id: 15, name: 'YANA SUHERYANA', noreg: '01222231', pos: 'Pos 1 Underbody Main'),
        BacaDoaOperator(id: 16, name: 'SUGENG SURYADI', noreg: '01222404', pos: 'Cross Member Fitting'),
        BacaDoaOperator(id: 17, name: 'MOH. CHUMAEDI', noreg: '01020746', pos: 'Pos 3 Spot Welding'),
        BacaDoaOperator(id: 18, name: 'RISWOKO', noreg: '01020747', pos: 'Pos 4 Side Member'),
        BacaDoaOperator(id: 19, name: 'FERDIANSYAH', noreg: '01121564', pos: 'Pos 5 Center Floor'),
        BacaDoaOperator(id: 20, name: 'ERI KOSWANTO', noreg: '01221988', pos: 'Pos 6 Rear Floor'),
        BacaDoaOperator(id: 21, name: 'RITNO', noreg: '01121566', pos: 'Pos 7 Inspection'),
        BacaDoaOperator(id: 22, name: 'AGUS PAJAR', noreg: '01020402', pos: 'Pos 8 Final Check'),
        BacaDoaOperator(id: 23, name: 'DIDIK SUGIONO', noreg: '01020180', pos: 'Front Floor'),
        BacaDoaOperator(id: 24, name: 'ROHIMIN', noreg: '01020679', pos: 'Pos 1'),
        BacaDoaOperator(id: 25, name: 'ASEP TABRONI', noreg: '01223093', pos: 'Pos 1'),
        BacaDoaOperator(id: 39, name: 'FAFAN', noreg: '26000001', pos: 'Pos 1'),
        BacaDoaOperator(id: 40, name: 'EQBAL', noreg: '26000002', pos: 'Pos 1'),
        BacaDoaOperator(id: 41, name: 'FAHRI', noreg: '26000003', pos: 'Pos 1'),
        BacaDoaOperator(id: 42, name: 'AZRYL', noreg: '26000004', pos: 'Pos 1'),
        BacaDoaOperator(id: 43, name: 'FAISAL', noreg: '26000005', pos: 'Pos 1'),
      ];
    }
    return const [
      BacaDoaOperator(id: 5, name: 'SARDI', noreg: '01121689', pos: 'Pos 2 Cross Member'),
      BacaDoaOperator(id: 6, name: 'AGUNG ISKANDAR', noreg: '00919939', pos: 'Pos 3 Spot Welding'),
      BacaDoaOperator(id: 7, name: 'YOYON SUYONO', noreg: '00112433', pos: 'Pos 4 Side Member'),
      BacaDoaOperator(id: 8, name: 'MUHAMMAD MARTALIH', noreg: '01425129', pos: 'Pos 5 Center Floor'),
      BacaDoaOperator(id: 9, name: 'ADIB SETYO BUDI', noreg: '02437420', pos: 'Pos 6 Rear Floor'),
      BacaDoaOperator(id: 10, name: 'CEVIN DANI', noreg: '02538186', pos: 'Pos 7 Inspection'),
      BacaDoaOperator(id: 11, name: 'SULARSO', noreg: '01221995', pos: 'Pos 8 Final Check'),
      BacaDoaOperator(id: 26, name: 'ALFI FAUZAN', noreg: '02639314', pos: 'Pos 1'),
      BacaDoaOperator(id: 27, name: 'GILANG RAMADHAN', noreg: '02639371', pos: 'Pos 1'),
      BacaDoaOperator(id: 28, name: 'RIZKY KHOLIS', noreg: '02639362', pos: 'Pos 1'),
      BacaDoaOperator(id: 29, name: 'IWAN AHDIAN', noreg: '00919943', pos: 'Pos 1'),
      BacaDoaOperator(id: 30, name: 'RIYANTO', noreg: '01324263', pos: 'Pos 1'),
      BacaDoaOperator(id: 31, name: 'DWI SUSANTO', noreg: '01021249', pos: 'Pos 1'),
      BacaDoaOperator(id: 32, name: 'MURYADI', noreg: '01021250', pos: 'Pos 1'),
      BacaDoaOperator(id: 33, name: 'NUR SOLEH', noreg: '01424871', pos: 'Pos 1'),
      BacaDoaOperator(id: 34, name: 'ALI YAFI', noreg: '01223255', pos: 'Pos 1'),
      BacaDoaOperator(id: 35, name: 'YULI WIDIYANTO', noreg: '01324254', pos: 'Pos 1'),
      BacaDoaOperator(id: 36, name: 'JAHID HUSEN', noreg: '01324580', pos: 'Pos 1'),
      BacaDoaOperator(id: 37, name: 'ARDHY CHANDRA', noreg: '02132225', pos: 'Pos 1'),
      BacaDoaOperator(id: 38, name: 'ANDREA HARDEKA', noreg: '02336012', pos: 'Pos 1'),
    ];
  }

  /// Fetches live active members from `/api/ub?action=get_members&shift=RED|WHITE`,
  /// excluding GL & TL from `operators` (1:1 `BacaDoaA4Viewer.tsx`), while returning
  /// `glName` and `tlNames` for the approval stamp table.
  Future<({List<BacaDoaOperator> operators, String glName, List<String> tlNames, bool fromServer})>
      fetchShiftRoster(String shift) async {
    final cleanShift = shift.toUpperCase() == 'WHITE' ? 'WHITE' : 'RED';
    final defaultGl = cleanShift == 'WHITE' ? 'DWI MULYONO' : 'KAMALUDIN';
    final defaultTls = cleanShift == 'WHITE'
        ? <String>['DADANG SURYADI', 'NUNU FATULAH']
        : <String>['MASRURI', 'TRI RUSTIANTORO'];

    ({List<BacaDoaOperator> operators, String glName, List<String> tlNames}) parseRawMembers(List<dynamic> rawList) {
      final ops = <BacaDoaOperator>[];
      final tls = <String>[];
      var gl = '';
      for (final item in rawList.whereType<Map>()) {
        final m = Map<String, dynamic>.from(item);
        final isActive = m['is_active'] == null || '${m['is_active']}' == '1' || m['is_active'] == true;
        if (!isActive) continue;
        final role = (m['role'] ?? 'TM').toString().trim().toUpperCase();
        final name = (m['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        if (role == 'GL') {
          if (gl.isEmpty) gl = name;
          continue;
        }
        if (role == 'TL') {
          if (!tls.contains(name)) tls.add(name);
          continue;
        }
        final id = m['id'] is num ? (m['id'] as num).toInt() : (int.tryParse('${m['id'] ?? 0}') ?? 0);
        ops.add(
          BacaDoaOperator(
            id: id > 0 ? id : ops.length + 100,
            name: name,
            noreg: (m['noreg'] ?? '').toString().trim(),
            pos: (m['default_pos'] ?? 'Pos 1').toString().trim(),
          ),
        );
      }
      return (
        operators: ops.isNotEmpty ? ops : operatorsForShift(cleanShift),
        glName: gl.isNotEmpty ? gl : defaultGl,
        tlNames: tls.isNotEmpty ? tls : defaultTls,
      );
    }

    final res = await UbWebApi.instance.getUb({'action': 'get_members', 'shift': cleanShift});
    if (res.ok && res.map['status'] == 'success' && res.map['data'] is List) {
      final rawList = res.map['data'] as List;
      if (rawList.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_rosterCacheKey(cleanShift), jsonEncode(rawList));
        final parsed = parseRawMembers(rawList);
        return (
          operators: parsed.operators,
          glName: parsed.glName,
          tlNames: parsed.tlNames,
          fromServer: true,
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_rosterCacheKey(cleanShift));
    if (cached != null && cached.isNotEmpty) {
      try {
        final rawList = jsonDecode(cached) as List<dynamic>;
        final parsed = parseRawMembers(rawList);
        return (
          operators: parsed.operators,
          glName: parsed.glName,
          tlNames: parsed.tlNames,
          fromServer: false,
        );
      } catch (_) {}
    }

    return (
      operators: operatorsForShift(cleanShift),
      glName: defaultGl,
      tlNames: defaultTls,
      fromServer: false,
    );
  }

  // ===========================================================================
  // 1. BACA DOA ASARE — 1:1 with /api/hr/bacadoa (GET / PUT / history)
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

  Future<List<BacaDoaHistoryEntry>> fetchBacaDoaHistory({String shift = 'ALL'}) async {
    final res = await UbWebApi.instance.getJson(
      '/api/hr/bacadoa',
      query: {'action': 'history', 'shift': shift},
    );
    if (!res.ok || res.map['history'] is! List) return const [];
    final out = <BacaDoaHistoryEntry>[];
    for (final raw in (res.map['history'] as List).whereType<Map>()) {
      final m = Map<String, dynamic>.from(raw);
      int sched = m['scheduledCount'] is num ? (m['scheduledCount'] as num).toInt() : 0;
      int done = m['doneCount'] is num ? (m['doneCount'] as num).toInt() : 0;
      if (sched == 0 && m['records'] is Map) {
        final recs = Map<String, dynamic>.from(m['records'] as Map);
        sched = recs.length;
        done = recs.values.where((v) => v is Map && v['status'] == 'done').length;
      }
      out.add(
        BacaDoaHistoryEntry(
          ym: (m['ym'] ?? '').toString(),
          shift: (m['shift'] ?? '').toString(),
          scheduledCount: sched,
          doneCount: done,
          glName: (m['glName'] ?? '').toString(),
          tlName: (m['tlName'] ?? '').toString(),
        ),
      );
    }
    return out;
  }

  Future<void> _saveBacaDoaLocal(String ym, String shift, Map<int, BacaDoaAssignment> records) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = <String, dynamic>{};
    records.forEach((k, v) => encoded['$k'] = v.toJson());
    await prefs.setString(_bacaDoaKey(ym, shift), jsonEncode(encoded));
  }

  Future<bool> saveBacaDoa(
    String ym,
    String shift,
    Map<int, BacaDoaAssignment> records, {
    String glName = '',
    String tlName = '',
  }) async {
    await _saveBacaDoaLocal(ym, shift, records);
    final encoded = <String, dynamic>{};
    records.forEach((k, v) => encoded['$k'] = v.toJson());
    final res = await UbWebApi.instance.putJson('/api/hr/bacadoa', {
      'ym': ym,
      'shift': shift,
      'records': encoded,
      if (glName.isNotEmpty) 'glName': glName,
      if (tlName.isNotEmpty) 'tlName': tlName,
    });
    return res.ok;
  }

  // ===========================================================================
  // 2. RANK MP — 1:1 with /api/hr/rankmp (GET / POST)
  // ===========================================================================
  Future<({List<MemberRankRow> rows, Map<int, RankMpCustomEval> evals, bool fromServer})>
      fetchRankMpData(String ym, String shift) async {
    final res = await UbWebApi.instance.getJson('/api/hr/rankmp', query: {'ym': ym, 'shift': shift});
    if (res.ok && res.map['status'] == 'success' && res.map['data'] is List) {
      final evals = <int, RankMpCustomEval>{};
      final rows = <MemberRankRow>[];
      final list = res.map['data'] as List;
      for (var idx = 0; idx < list.length; idx++) {
        final rawItem = list[idx];
        if (rawItem is! Map) continue;
        final m = Map<String, dynamic>.from(rawItem);
        final id = m['memberId'] is num ? (m['memberId'] as num).toInt() : (int.tryParse('${m['memberId'] ?? 0}') ?? 0);
        final pts = m['customHrPoints'] is num ? (m['customHrPoints'] as num).toInt() : 0;
        final notes = '${m['hrNotes'] ?? ''}';
        if (id > 0 && (pts != 0 || notes.isNotEmpty)) {
          evals[id] = RankMpCustomEval(customPoints: pts, notes: notes);
        }
        rows.add(
          MemberRankRow(
            rank: m['rank'] is num ? (m['rank'] as num).toInt() : idx + 1,
            memberId: id,
            name: '${m['name'] ?? ''}',
            noreg: '${m['noreg'] ?? ''}',
            shift: '${m['shift'] ?? shift}',
            pos: '${m['default_pos'] ?? m['pos'] ?? 'Pos 1'}',
            doaScheduled: m['doaScheduled'] is num ? (m['doaScheduled'] as num).toInt() : 0,
            doaDone: m['doaDone'] is num ? (m['doaDone'] as num).toInt() : 0,
            doaPoints: m['doaPoints'] is num ? (m['doaPoints'] as num).toInt() : 0,
            multiDutyBonus: m['multiDutyBonus'] is num ? (m['multiDutyBonus'] as num).toInt() : 0,
            disciplinePoints: m['disciplinePoints'] is num ? (m['disciplinePoints'] as num).toInt() : 10,
            customHrPoints: pts,
            totalPoints: m['totalPoints'] is num ? (m['totalPoints'] as num).toInt() : 0,
            tier: '${m['tier'] ?? 'C'}',
            hrNotes: notes,
          ),
        );
      }
      await _saveRankEvalsLocal(ym, shift, evals);
      if (rows.isNotEmpty) {
        return (rows: rows, evals: evals, fromServer: true);
      }
    }

    final roster = await fetchShiftRoster(shift);
    final baca = await loadBacaDoa(ym, shift);
    final evals = await loadRankEvals(ym, shift);
    final ranked = RankMpEngine.computeRankings(
      shift: shift,
      operators: roster.operators,
      bacaDoaRecords: baca,
      customEvals: evals,
    );
    return (rows: ranked, evals: evals, fromServer: false);
  }

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
