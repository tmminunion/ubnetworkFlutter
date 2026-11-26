import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/safety_finding_models.dart';
import 'ub_web_api.dart';

class SafetyFindingsResult {
  const SafetyFindingsResult({
    required this.items,
    required this.source,
    this.error,
  });

  final List<SafetyFinding> items;
  final String source; // 'atlas' | 'default' | 'local'
  final String? error;
}

class SafetyFindingsStore {
  SafetyFindingsStore._();
  static final SafetyFindingsStore instance = SafetyFindingsStore._();

  static const _kFindings = 'ubf_safety_findings_v1';

  /// Fetches all findings 1:1 from Next.js `GET /api/findings?filter=all&sort=open&limit=200`
  /// (including multi-page pagination if >200 items exist in MongoDB Atlas),
  /// falling back cleanly to local cache when offline.
  Future<SafetyFindingsResult> fetchFindings() async {
    final firstRes = await UbWebApi.instance.getJson(
      '/api/findings',
      query: const {
        'filter': 'all',
        'sort': 'open',
        'limit': '200',
        'page': '1',
      },
    );

    if (firstRes.ok) {
      final rawList = firstRes.map['items'] is List
          ? firstRes.map['items'] as List
          : (firstRes.data is List ? firstRes.list : null);
      if (rawList != null) {
        final remote = <SafetyFinding>[
          ...rawList.whereType<Map>().map((m) {
            final f = SafetyFinding.fromJson(Map<String, dynamic>.from(m));
            f.syncStatus = 'synced';
            return f;
          }),
        ];

        final totalPages = (firstRes.map['pages'] is num)
            ? (firstRes.map['pages'] as num).toInt()
            : (int.tryParse('${firstRes.map['pages'] ?? 1}') ?? 1);

        if (totalPages > 1) {
          for (var p = 2; p <= totalPages && p <= 10; p++) {
            final nextRes = await UbWebApi.instance.getJson(
              '/api/findings',
              query: {
                'filter': 'all',
                'sort': 'open',
                'limit': '200',
                'page': '$p',
              },
            );
            if (!nextRes.ok || nextRes.map['items'] is! List) break;
            for (final m in (nextRes.map['items'] as List).whereType<Map>()) {
              final f = SafetyFinding.fromJson(Map<String, dynamic>.from(m));
              f.syncStatus = 'synced';
              remote.add(f);
            }
          }
        }

        final source = (firstRes.map['source'] ?? 'atlas').toString();
        if (remote.isNotEmpty || source == 'atlas') {
          await _saveAll(remote);
          return SafetyFindingsResult(items: remote, source: source);
        }
      }
    }

    final local = await _loadLocal();
    return SafetyFindingsResult(
      items: local,
      source: 'local',
      error: firstRes.ok ? null : firstRes.error,
    );
  }

  Future<List<SafetyFinding>> listFindings() async {
    final res = await fetchFindings();
    return res.items;
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

  /// 1:1 Next.js mutation:
  /// - Existing Atlas finding (`_id` matching `/^[sSfF]\d{1,9}$/`): `PATCH /api/findings/[id]`
  /// - New finding: `POST /api/findings` (adopts server-generated `_id`, `no`, `closedAt`)
  Future<SafetyFinding> upsertFinding(SafetyFinding item) async {
    final todayIso = DateTime.now().toIso8601String().substring(0, 10);
    if (item.status == 'closed' && item.closedAt.trim().isEmpty) {
      item.closedAt = todayIso;
    } else if (item.status != 'closed') {
      item.closedAt = '';
    }

    final items = await _loadLocal();
    final idx = items.indexWhere((e) => e.id == item.id || (item.no.isNotEmpty && e.no == item.no));
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

    final payload = item.toServerPayload();
    final targetServerId = item.isServerId
        ? item.id.trim()
        : (idx >= 0 && items[idx].isServerId ? items[idx].id.trim() : '');

    final res = targetServerId.isNotEmpty
        ? await UbWebApi.instance.patchJson(
            '/api/findings/${Uri.encodeComponent(targetServerId)}',
            payload,
          )
        : await UbWebApi.instance.postJson('/api/findings', payload);

    if (res.ok) {
      SafetyFinding synced = item;
      if (res.map['item'] is Map) {
        synced = SafetyFinding.fromJson(Map<String, dynamic>.from(res.map['item'] as Map));
      }
      synced.syncStatus = 'synced';
      final replaceIdx = items.indexWhere((e) => e.id == item.id || e.id == synced.id);
      if (replaceIdx >= 0) {
        items[replaceIdx] = synced;
      } else {
        items.insert(0, synced);
      }
      await _saveAll(items);
      return synced;
    }

    return item;
  }

  Future<bool> deleteFinding(String id, {String? no}) async {
    final items = await _loadLocal();
    items.removeWhere((e) => e.id == id || (no != null && no.isNotEmpty && e.no == no));
    await _saveAll(items);

    final cleanId = RegExp(r'^[sSfF]\d{1,9}$').hasMatch(id.trim())
        ? id.trim()
        : (no != null && RegExp(r'^\d{1,9}$').hasMatch(no.trim()) ? 's${no.trim()}' : '');
    if (cleanId.isEmpty) return true;

    final res = await UbWebApi.instance.deleteJson('/api/findings/${Uri.encodeComponent(cleanId)}');
    return res.ok;
  }
}
