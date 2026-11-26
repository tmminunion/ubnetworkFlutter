import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/safety_finding_models.dart';

class SafetyFindingsStore {
  SafetyFindingsStore._();
  static final SafetyFindingsStore instance = SafetyFindingsStore._();

  static const _kFindings = 'ubf_safety_findings_v1';

  Future<List<SafetyFinding>> listFindings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFindings);
    if (raw == null || raw.isEmpty) {
      final seeds = defaultSafetyFindings();
      await _saveAll(seeds);
      return seeds;
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((m) => SafetyFinding.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return defaultSafetyFindings();
    }
  }

  Future<void> _saveAll(List<SafetyFinding> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFindings, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<SafetyFinding> upsertFinding(SafetyFinding item) async {
    final items = await listFindings();
    final idx = items.indexWhere((e) => e.id == item.id);
    if (idx >= 0) {
      items[idx] = item;
    } else {
      if (item.no.trim().isEmpty) {
        final maxNo = items
            .map((e) => int.tryParse(e.no.replaceAll(RegExp(r'\D'), '')) ?? 0)
            .fold<int>(0, (a, b) => b > a ? b : a);
        item.no = '${maxNo + 1}';
      }
      items.insert(0, item);
    }
    await _saveAll(items);
    return item;
  }

  Future<void> deleteFinding(String id) async {
    final items = await listFindings();
    items.removeWhere((e) => e.id == id);
    await _saveAll(items);
  }
}
