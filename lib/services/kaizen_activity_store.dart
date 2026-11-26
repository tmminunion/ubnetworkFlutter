import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/kaizen_activity_models.dart';
import 'auth_service.dart';

class KaizenActivityStore {
  KaizenActivityStore._();
  static final KaizenActivityStore instance = KaizenActivityStore._();

  static const String _kQccPrefix = 'ubf_qcc_report_v1_';
  static const String _kTpmPlans = 'ubf_tpm_plans_v1';
  static const String _kTpmAmChecks = 'ubf_tpm_am_checks_v1';
  static const String _k5RBundle = 'ubf_5r_bundle_v1';
  static const String _kSwElementsPrefix = 'ubf_sw_elements_v1_';
  static const String _kSwObsPrefix = 'ubf_sw_obs_v1_';

  Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final h = <String, String>{'Accept': 'application/json'};
    if (jsonBody) h['Content-Type'] = 'application/json';
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('ubf_gate_cookie_v1') ?? '';
    if (cookie.isNotEmpty) {
      h['Cookie'] = cookie.split(';').first;
    }
    return h;
  }

  // =========================================================================
  // 1. QCC STORE (Online /api/qcc + Offline Cache)
  // =========================================================================
  Future<({List<QccCircle> circles, QccCircle activeCircle, QccA3Report report, bool online})> loadQcc(
    String circleId,
  ) async {
    final defaultCircles = KaizenActivitySeeds.qccCircles();
    final fallbackCircle = defaultCircles.firstWhere(
      (c) => c.id == circleId,
      orElse: () => defaultCircles.first,
    );

    try {
      final uri = Uri.parse(
        '${AuthService.gateBaseUrl}/api/qcc?circleId=${Uri.encodeQueryComponent(circleId)}',
      );
      final res = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['success'] == true && decoded['report'] is Map) {
          final circles = (decoded['circles'] as List?)
                  ?.whereType<Map>()
                  .map((e) => QccCircle.fromJson(Map<String, dynamic>.from(e)))
                  .toList() ??
              defaultCircles;
          final activeId = (decoded['activeCircleId'] ?? circleId).toString();
          final active = circles.firstWhere((c) => c.id == activeId, orElse: () => fallbackCircle);
          final rep = QccA3Report.fromJson(Map<String, dynamic>.from(decoded['report'] as Map));
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('$_kQccPrefix${active.id}', jsonEncode(rep.toJson()));
          return (circles: circles, activeCircle: active, report: rep, online: true);
        }
      }
    } catch (_) {}

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

    try {
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

      final res = await http
          .post(
            Uri.parse('${AuthService.gateBaseUrl}/api/qcc'),
            headers: await _headers(jsonBody: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
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
  // 3. 5R / 5S STORE (Online /api/5r + Offline Cache)
  // =========================================================================
  Future<({FiveRAuditMaster audit, List<FiveRRedTag> redTags, List<FiveRShadowBoardTool> shadowBoard, bool online})> load5R() async {
    try {
      final res = await http
          .get(Uri.parse('${AuthService.gateBaseUrl}/api/5r'), headers: await _headers())
          .timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['success'] == true && decoded['audit'] is Map) {
          final audit = FiveRAuditMaster.fromJson(Map<String, dynamic>.from(decoded['audit'] as Map));
          final tags = (decoded['redTags'] as List?)
                  ?.whereType<Map>()
                  .map((e) => FiveRRedTag.fromJson(Map<String, dynamic>.from(e)))
                  .toList() ??
              KaizenActivitySeeds.fiveRRedTags();
          final tools = (decoded['shadowBoard'] as List?)
                  ?.whereType<Map>()
                  .map((e) => FiveRShadowBoardTool.fromJson(Map<String, dynamic>.from(e)))
                  .toList() ??
              KaizenActivitySeeds.fiveRShadowBoard();
          audit.recalculate(tags);
          await _cache5R(audit, tags, tools);
          return (audit: audit, redTags: tags, shadowBoard: tools, online: true);
        }
      }
    } catch (_) {}

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
    try {
      final res = await http
          .post(
            Uri.parse('${AuthService.gateBaseUrl}/api/5r'),
            headers: await _headers(jsonBody: true),
            body: jsonEncode({'action': action, 'payload': payload}),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // =========================================================================
  // 4. SW OBSERVASI STORE (Online /api/sw-observasi + Offline Cache)
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

    try {
      final uri = Uri.parse(
        '${AuthService.gateBaseUrl}/api/sw-observasi?profileId=${Uri.encodeQueryComponent(defProf.id)}&jobId=${Uri.encodeQueryComponent(defJob.id)}',
      );
      final res = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['success'] == true) {
          final profiles = (decoded['profiles'] as List?)
                  ?.whereType<Map>()
                  .map((e) => SwProfile.fromJson(Map<String, dynamic>.from(e)))
                  .toList() ??
              defProfiles;
          final jobs = (decoded['jobs'] as List?)
                  ?.whereType<Map>()
                  .map((e) => SwJob.fromJson(Map<String, dynamic>.from(e)))
                  .toList() ??
              defJobs;
          final actJobId = (decoded['activeJobId'] ?? defJob.id).toString();
          final actJob = jobs.firstWhere((j) => j.id == actJobId, orElse: () => defJob);
          final elements = (decoded['elements'] as List?)
                  ?.whereType<Map>()
                  .map((e) => SwElement.fromJson(Map<String, dynamic>.from(e)))
                  .toList() ??
              KaizenActivitySeeds.swElementsForJob(actJob);
          final obs = (decoded['observations'] as List?)
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
      }
    } catch (_) {}

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

    try {
      final body = deletedId != null
          ? {
              'action': 'deleteElement',
              'payload': {'id': deletedId},
            }
          : {
              'action': 'saveElement',
              'payload': upserted?.toJson() ?? {},
            };
      final res = await http
          .post(
            Uri.parse('${AuthService.gateBaseUrl}/api/sw-observasi'),
            headers: await _headers(jsonBody: true),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
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

    try {
      final res = await http
          .post(
            Uri.parse('${AuthService.gateBaseUrl}/api/sw-observasi'),
            headers: await _headers(jsonBody: true),
            body: jsonEncode({
              'action': 'saveObservation',
              'payload': updated.toJson(),
            }),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
