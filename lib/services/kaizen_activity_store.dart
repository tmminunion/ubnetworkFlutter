import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/kaizen_activity_models.dart';
import 'ub_web_api.dart';

class KaizenActivityStore {
  KaizenActivityStore._();
  static final KaizenActivityStore instance = KaizenActivityStore._();

  static const String _kQccPrefix = 'ubf_qcc_report_v1_';
  static const String _kTpmPlans = 'ubf_tpm_plans_v1';
  static const String _kTpmAmChecks = 'ubf_tpm_am_checks_v1';
  static const String _k5RBundle = 'ubf_5r_bundle_v1';
  static const String _kSwElementsPrefix = 'ubf_sw_elements_v1_';
  static const String _kSwObsPrefix = 'ubf_sw_obs_v1_';

  // =========================================================================
  // 1. QCC STORE (Online /api/qcc + Offline Cache via UbWebApi)
  // =========================================================================
  Future<({List<QccCircle> circles, QccCircle activeCircle, QccA3Report report, bool online})> loadQcc(
    String circleId,
  ) async {
    final defaultCircles = KaizenActivitySeeds.qccCircles();
    final fallbackCircle = defaultCircles.firstWhere(
      (c) => c.id == circleId,
      orElse: () => defaultCircles.first,
    );

    final res = await UbWebApi.instance.getJson('/api/qcc', query: {'circleId': circleId});
    if (res.ok && res.map['success'] == true && res.map['report'] is Map) {
      final circles = (res.map['circles'] as List?)
              ?.whereType<Map>()
              .map((e) => QccCircle.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          defaultCircles;
      final activeId = (res.map['activeCircleId'] ?? circleId).toString();
      final active = circles.firstWhere((c) => c.id == activeId, orElse: () => fallbackCircle);
      final rep = QccA3Report.fromJson(Map<String, dynamic>.from(res.map['report'] as Map));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_kQccPrefix${active.id}', jsonEncode(rep.toJson()));
      return (circles: circles, activeCircle: active, report: rep, online: true);
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('$_kQccPrefix${fallbackCircle.id}');
    if (cached != null && cached.isNotEmpty) {
      try {
        final rep = QccA3Report.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        return (
          circles: defaultCircles,
          activeCircle: fallbackCircle,
          report: rep,
          online: false,
        );
      } catch (_) {}
    }

    return (
      circles: defaultCircles,
      activeCircle: fallbackCircle,
      report: KaizenActivitySeeds.qccDefaultReport(fallbackCircle),
      online: false,
    );
  }

  Future<bool> saveQccReport(
    QccA3Report report, {
    int? stepNumber,
    QccActionPlan5W2H? savedPlan,
    String? deletedPlanId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kQccPrefix${report.circleId}', jsonEncode(report.toJson()));

    Map<String, dynamic> body;
    if (savedPlan != null) {
      body = {
        'action': 'saveActionPlan',
        'circleId': report.circleId,
        'payload': savedPlan.toJson(),
      };
    } else if (deletedPlanId != null) {
      body = {
        'action': 'deleteActionPlan',
        'circleId': report.circleId,
        'payload': {'actionId': deletedPlanId},
      };
    } else if (stepNumber != null) {
      final full = report.toJson();
      body = {
        'action': 'updateStep',
        'circleId': report.circleId,
        'payload': {
          'stepNumber': stepNumber,
          'stepData': full['step$stepNumber'],
        },
      };
    } else {
      body = {
        'action': 'updateReportMeta',
        'circleId': report.circleId,
        'payload': {
          'title': report.title,
          'kpiCategory': report.kpiCategory,
          'currentStep': report.currentStep,
          'status': report.status,
          'conventionDate': report.conventionDate,
        },
      };
    }

    final res = await UbWebApi.instance.postJson('/api/qcc', body);
    return res.ok;
  }

  // =========================================================================
  // 2. TPM STORE (Offline-First + Persistence)
  // =========================================================================
  Future<List<TpmActionPlan>> loadTpmPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTpmPlans);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        return list
            .whereType<Map>()
            .map((e) => TpmActionPlan.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }
    return KaizenActivitySeeds.tpmActionPlans();
  }

  Future<void> saveTpmPlans(List<TpmActionPlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTpmPlans, jsonEncode(plans.map((p) => p.toJson()).toList()));
  }

  Future<Map<String, bool>> loadTpmAmChecks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTpmAmChecks);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map;
        return decoded.map((k, v) => MapEntry(k.toString(), v == true));
      } catch (_) {}
    }
    return {for (final s in KaizenActivitySeeds.tpmSopItems) s.id: true};
  }

  Future<void> saveTpmAmChecks(Map<String, bool> checks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTpmAmChecks, jsonEncode(checks));
  }

  // =========================================================================
  // 3. 5R / 5S STORE (Online /api/5r + Offline Cache via UbWebApi)
  // =========================================================================
  Future<({FiveRAuditMaster audit, List<FiveRRedTag> redTags, List<FiveRShadowBoardTool> shadowBoard, bool online})> load5R() async {
    final res = await UbWebApi.instance.getJson('/api/5r');
    if (res.ok && res.map['success'] == true && res.map['audit'] is Map) {
      final audit = FiveRAuditMaster.fromJson(Map<String, dynamic>.from(res.map['audit'] as Map));
      final tags = (res.map['redTags'] as List?)
              ?.whereType<Map>()
              .map((e) => FiveRRedTag.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          KaizenActivitySeeds.fiveRRedTags();
      final tools = (res.map['shadowBoard'] as List?)
              ?.whereType<Map>()
              .map((e) => FiveRShadowBoardTool.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          KaizenActivitySeeds.fiveRShadowBoard();
      audit.recalculate(tags);
      await _cache5R(audit, tags, tools);
      return (audit: audit, redTags: tags, shadowBoard: tools, online: true);
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_k5RBundle);
    if (cached != null && cached.isNotEmpty) {
      try {
        final j = jsonDecode(cached) as Map<String, dynamic>;
        final audit = FiveRAuditMaster.fromJson(Map<String, dynamic>.from(j['audit'] as Map));
        final tags = (j['redTags'] as List)
            .whereType<Map>()
            .map((e) => FiveRRedTag.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final tools = (j['shadowBoard'] as List)
            .whereType<Map>()
            .map((e) => FiveRShadowBoardTool.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        audit.recalculate(tags);
        return (audit: audit, redTags: tags, shadowBoard: tools, online: false);
      } catch (_) {}
    }

    final audit = KaizenActivitySeeds.fiveRAudit();
    final tags = KaizenActivitySeeds.fiveRRedTags();
    final tools = KaizenActivitySeeds.fiveRShadowBoard();
    audit.recalculate(tags);
    return (audit: audit, redTags: tags, shadowBoard: tools, online: false);
  }

  Future<void> _cache5R(
    FiveRAuditMaster audit,
    List<FiveRRedTag> redTags,
    List<FiveRShadowBoardTool> shadowBoard,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _k5RBundle,
      jsonEncode({
        'audit': audit.toJson(),
        'redTags': redTags.map((t) => t.toJson()).toList(),
        'shadowBoard': shadowBoard.map((t) => t.toJson()).toList(),
      }),
    );
  }

  Future<bool> sync5RAction({
    required FiveRAuditMaster audit,
    required List<FiveRRedTag> redTags,
    required List<FiveRShadowBoardTool> shadowBoard,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    audit.recalculate(redTags);
    await _cache5R(audit, redTags, shadowBoard);
    final res = await UbWebApi.instance.postJson('/api/5r', {'action': action, 'payload': payload});
    return res.ok;
  }

  // =========================================================================
  // 4. SW OBSERVASI STORE (Online /api/sw-observasi + Offline Cache via UbWebApi)
  // =========================================================================
  Future<({
    List<SwProfile> profiles,
    SwProfile activeProfile,
    List<SwJob> jobs,
    SwJob activeJob,
    List<SwElement> elements,
    List<SwObservation> observations,
    bool online,
  })> loadSw({
    required String profileId,
    String? jobId,
  }) async {
    final defProfiles = KaizenActivitySeeds.swProfiles;
    final defProf = defProfiles.firstWhere((p) => p.id == profileId, orElse: () => defProfiles.first);
    final defJobs = KaizenActivitySeeds.swJobsForProfile(defProf.id);
    final defJob = defJobs.firstWhere(
      (j) => jobId != null && j.id == jobId,
      orElse: () => defJobs.first,
    );

    final res = await UbWebApi.instance.getJson(
      '/api/sw-observasi',
      query: {
        'profileId': defProf.id,
        'jobId': defJob.id,
      },
    );
    if (res.ok && res.map['success'] == true) {
      final profiles = (res.map['profiles'] as List?)
              ?.whereType<Map>()
              .map((e) => SwProfile.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          defProfiles;
      final jobs = (res.map['jobs'] as List?)
              ?.whereType<Map>()
              .map((e) => SwJob.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          defJobs;
      final actJobId = (res.map['activeJobId'] ?? defJob.id).toString();
      final actJob = jobs.firstWhere((j) => j.id == actJobId, orElse: () => defJob);
      final elements = (res.map['elements'] as List?)
              ?.whereType<Map>()
              .map((e) => SwElement.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          KaizenActivitySeeds.swElementsForJob(actJob);
      final obs = (res.map['observations'] as List?)
              ?.whereType<Map>()
              .map((e) => SwObservation.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          KaizenActivitySeeds.swObservationsForJob(actJob);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_kSwElementsPrefix${actJob.id}',
        jsonEncode(elements.map((e) => e.toJson()).toList()),
      );
      await prefs.setString(
        '$_kSwObsPrefix${actJob.id}',
        jsonEncode(obs.map((o) => o.toJson()).toList()),
      );

      return (
        profiles: profiles,
        activeProfile: profiles.firstWhere((p) => p.id == defProf.id, orElse: () => defProf),
        jobs: jobs,
        activeJob: actJob,
        elements: elements,
        observations: obs,
        online: true,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    var elements = KaizenActivitySeeds.swElementsForJob(defJob);
    var obs = KaizenActivitySeeds.swObservationsForJob(defJob);

    final rawEl = prefs.getString('$_kSwElementsPrefix${defJob.id}');
    if (rawEl != null && rawEl.isNotEmpty) {
      try {
        elements = (jsonDecode(rawEl) as List)
            .whereType<Map>()
            .map((e) => SwElement.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }

    final rawObs = prefs.getString('$_kSwObsPrefix${defJob.id}');
    if (rawObs != null && rawObs.isNotEmpty) {
      try {
        obs = (jsonDecode(rawObs) as List)
            .whereType<Map>()
            .map((e) => SwObservation.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }

    return (
      profiles: defProfiles,
      activeProfile: defProf,
      jobs: defJobs,
      activeJob: defJob,
      elements: elements,
      observations: obs,
      online: false,
    );
  }

  Future<bool> saveSwElements({
    required String jobId,
    required List<SwElement> elements,
    SwElement? upserted,
    String? deletedId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_kSwElementsPrefix$jobId',
      jsonEncode(elements.map((e) => e.toJson()).toList()),
    );

    final body = deletedId != null
        ? {
            'action': 'deleteElement',
            'payload': {'id': deletedId},
          }
        : {
            'action': 'saveElement',
            'payload': upserted?.toJson() ?? {},
          };
    final res = await UbWebApi.instance.postJson('/api/sw-observasi', body);
    return res.ok;
  }

  Future<bool> saveSwObservation({
    required String jobId,
    required List<SwObservation> observations,
    required SwObservation updated,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_kSwObsPrefix$jobId',
      jsonEncode(observations.map((o) => o.toJson()).toList()),
    );

    final res = await UbWebApi.instance.postJson('/api/sw-observasi', {
      'action': 'saveObservation',
      'payload': updated.toJson(),
    });
    return res.ok;
  }
}
