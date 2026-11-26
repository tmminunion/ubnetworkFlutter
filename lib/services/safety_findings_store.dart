import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/safety_finding_models.dart';
import 'ub_web_api.dart';

class SafetyFindingsStore {
  SafetyFindingsStore._();
  static final SafetyFindingsStore instance = SafetyFindingsStore._();

  static const _kFindings = 'ubf_safety_findings_v1';

  Future<List<SafetyFinding>> listFindings() async {
    // 1. Live sync 1:1 with Next.js GET /api/findings (MongoDB Atlas)
    final apiRes = await UbWebApi.instance.getJson('/api/findings');
    if (apiRes.ok) {
      final rawList = apiRes.map['items'] is List
          ? apiRes.map['items'] as List
          : (apiRes.data is List ? apiRes.list : null);
      if (rawList != null) {
        final remote = rawList
            .whereType<Map>()
            .map((m) {
              final f = SafetyFinding.fromJson(Map<String, dynamic>.from(m));
              f.syncStatus = 'synced';
              return f;
            })
            .toList();
        if (remote.isNotEmpty) {
          await _saveAll(remote);
          return remote;
        }
      }
    }

    // 2. Offline-first local fallback
    return _loadLocal();
  }

  Future<List<SafetyFinding>> _loadLocal() async {
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
    // Optimistic local save first
    final items = await _loadLocal();
    final idx = items.indexWhere((e) => e.id == item.id);
    final isUpdate = idx >= 0;
    if (isUpdate) {
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

    // 1:1 sync to Next.js /api/findings
    final res = isUpdate
        ? await UbWebApi.instance.putJson('/api/findings/${Uri.encodeComponent(item.id)}', item.toJson())
        : await UbWebApi.instance.postJson('/api/findings', item.toJson());
    if (res.ok) {
      item.syncStatus = 'synced';
      await _saveAll(items);
    }
    return item;
  }

  Future<void> deleteFinding(String id) async {
    final items = await _loadLocal();
    items.removeWhere((e) => e.id == id);
    await _saveAll(items);

    // 1:1 sync DELETE /api/findings/[id]
    await UbWebApi.instance.deleteJson('/api/findings/${Uri.encodeComponent(id)}');
  }
}
