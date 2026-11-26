import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cost_env_models.dart';

class CostEnvStore {
  CostEnvStore._();
  static final CostEnvStore instance = CostEnvStore._();

  static String _costDailyKey(String ym) => 'ubf_cost_daily_v1_$ym';
  static String _costFindingsKey(String ym) => 'ubf_cost_findings_v1_$ym';
  static String _envEnergyKey(String ym) => 'ubf_env_energy_v1_$ym';
  static String _airCheckKey(String date, String shift) => 'ubf_air_cs_v1_${date}_$shift';
  static const String _airFindingsKey = 'ubf_air_findings_v1';
  static String _envFindingsKey(String ym) => 'ubf_env_findings_v1_$ym';

  // ===========================================================================
  // 1. COST DAILY
  // ===========================================================================
  Future<CostDailyMonth> loadCostDaily(String ym) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_costDailyKey(ym));
    if (raw != null && raw.isNotEmpty) {
      try {
        return CostDailyMonth.fromJson(ym, Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {}
    }

    final items = _defaultCostItems();
    final red = {for (final it in items) it.id: List<double?>.filled(31, null)};
    final white = {for (final it in items) it.id: List<double?>.filled(31, null)};
    final blank = CostDailyMonth(ym: ym, items: items, red: red, white: white);
    await saveCostDaily(blank);
    return blank;
  }

  Future<void> saveCostDaily(CostDailyMonth month) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_costDailyKey(month.ym), jsonEncode(month.toJson()));
  }

  List<CostItem> _defaultCostItems() => const [
        CostItem(id: 'tip_cap', name: 'Tip Cap Welding 16mm', targetRed: 40, targetWhite: 40),
        CostItem(id: 'gloves', name: 'Sarung Tangan Las / Cotton', targetRed: 60, targetWhite: 60),
        CostItem(id: 'majun', name: 'Kain Majun (Kg)', targetRed: 25, targetWhite: 25),
        CostItem(id: 'anti_spatter', name: 'Anti Spatter Spray (Btl)', targetRed: 15, targetWhite: 15),
        CostItem(id: 'grinding_disc', name: 'Batu Gerinda 4"', targetRed: 30, targetWhite: 30),
        CostItem(id: 'tape_5s', name: 'Isolasi & Marking Tape 5S', targetRed: 12, targetWhite: 12),
      ];

  // ===========================================================================
  // 2. COST FINDINGS (TEMUAN COST)
  // ===========================================================================
  Future<List<CostFinding>> loadCostFindings(String ym) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_costFindingsKey(ym));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<Map>().map((m) => CostFinding.fromJson(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCostFindings(String ym, List<CostFinding> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_costFindingsKey(ym), jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  // ===========================================================================
  // 3. ENV ENERGY DAILY (kWh)
  // ===========================================================================
  Future<EnvEnergyMonth> loadEnvEnergy(String ym) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_envEnergyKey(ym));
    if (raw != null && raw.isNotEmpty) {
      try {
        return EnvEnergyMonth.fromJson(ym, Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {}
    }
    final empty = EnvEnergyMonth.empty(ym);
    await saveEnvEnergy(empty);
    return empty;
  }

  Future<void> saveEnvEnergy(EnvEnergyMonth data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_envEnergyKey(data.ym), jsonEncode(data.toJson()));
  }

  // ===========================================================================
  // 4. ENV AIR LEAKAGE (#lub & #klub)
  // ===========================================================================
  Future<({String inspector, List<AirCheckPoint> points})> loadAirChecksheet(String date, String shift) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_airCheckKey(date, shift));
    if (raw != null && raw.isNotEmpty) {
      try {
        final m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final pts = (m['points'] is List ? m['points'] as List : const [])
            .whereType<Map>()
            .map((e) => AirCheckPoint.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (pts.isNotEmpty) {
          return (inspector: '${m['inspector'] ?? ''}', points: pts);
        }
      } catch (_) {}
    }
    return (inspector: '', points: _defaultAirCheckPoints());
  }

  Future<void> saveAirChecksheet(String date, String shift, String inspector, List<AirCheckPoint> points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _airCheckKey(date, shift),
      jsonEncode({'inspector': inspector, 'points': points.map((e) => e.toJson()).toList()}),
    );
  }

  List<AirCheckPoint> _defaultAirCheckPoints() => const [
        AirCheckPoint(code: 'AL-01', point: 'Regulator & FRL Main Line', area: 'UB Assy Pos 1'),
        AirCheckPoint(code: 'AL-02', point: 'Solenoid Valve Clamp Jig FR', area: 'UB Assy Pos 2'),
        AirCheckPoint(code: 'AL-03', point: 'Selang Pneumatic Gun Spot', area: 'UB Assy Pos 3'),
        AirCheckPoint(code: 'AL-04', point: 'Fitting Elbow & Coupler Robot', area: 'Robot 201–204'),
        AirCheckPoint(code: 'AL-05', point: 'Cylinder Clamp Jig Underbody RR', area: 'UB Assy Pos 5'),
        AirCheckPoint(code: 'AL-06', point: 'Air Blow Gun & Manifold Outlet', area: 'Area Inspection'),
      ];

  Future<List<AirLeakageFinding>> loadAirFindings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_airFindingsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<Map>().map((m) => AirLeakageFinding.fromJson(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAirFindings(List<AirLeakageFinding> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_airFindingsKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  // ===========================================================================
  // 5. ENV TEMUAN & KAIZEN
  // ===========================================================================
  Future<List<EnvFindingItem>> loadEnvFindings(String ym) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_envFindingsKey(ym));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<Map>().map((m) => EnvFindingItem.fromJson(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEnvFindings(String ym, List<EnvFindingItem> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_envFindingsKey(ym), jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}
