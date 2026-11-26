import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/kyt_models.dart';
import 'ub_web_api.dart';

class LineMemberOption {
  const LineMemberOption({
    required this.id,
    required this.name,
    required this.noreg,
    required this.role,
    required this.shift,
    required this.defaultPos,
  });

  final int id;
  final String name;
  final String noreg;
  final String role;
  final String shift; // WHITE | RED
  final String defaultPos;

  factory LineMemberOption.fromJson(Map<String, dynamic> json) => LineMemberOption(
        id: json['id'] is num ? (json['id'] as num).toInt() : (int.tryParse('${json['id'] ?? 0}') ?? 0),
        name: (json['name'] ?? '').toString(),
        noreg: (json['noreg'] ?? '').toString(),
        role: (json['role'] ?? '').toString(),
        shift: (json['shift'] ?? 'WHITE').toString().toUpperCase() == 'RED' ? 'RED' : 'WHITE',
        defaultPos: (json['default_pos'] ?? '').toString(),
      );
}

class SgaGroupStore {
  SgaGroupStore._();
  static final SgaGroupStore instance = SgaGroupStore._();

  static const _kGroups = 'ubf_sga_groups_v1';

  static List<SgaGroup> defaultSeedGroups() => [
        SgaGroup(
          id: '1',
          code: 'SGA-W01',
          name: 'SGA Underbody Main',
          shift: 'WHITE',
          tlName: 'NUNU FATULAH',
          tlNoreg: '00408012',
          posArea: 'Pos 1 Underbody Main Floor',
          circleTema: 'Pencegahan Bahaya Terjepit Klem Pneumatik & Peningkatan Ergonomi',
          members: [
            SgaMemberItem(memberId: 14, name: 'NUNU FATULAH', noreg: '00408012', role: 'TL Support'),
            SgaMemberItem(memberId: 15, name: 'YANA SUHERYANA', noreg: '01222231', role: 'TM Main Fitting'),
            SgaMemberItem(memberId: 16, name: 'SUGENG SURYADI', noreg: '00402102', role: 'TM Pos 1'),
            SgaMemberItem(memberId: 17, name: 'MOH. CHUMAEDI', noreg: '01020746', role: 'TM Spot Welder'),
          ],
        ),
        SgaGroup(
          id: '2',
          code: 'SGA-W02',
          name: 'SGA Front Floor Circle',
          shift: 'WHITE',
          tlName: 'DADANG SURYADI',
          tlNoreg: '00009978',
          posArea: 'Pos 2 Front Floor & Dash Panel',
          circleTema: 'Zero Spatter & Safety Eye Protection di Area Robot Spot Welding',
          members: [
            SgaMemberItem(memberId: 13, name: 'DADANG SURYADI', noreg: '00009978', role: 'TL Front Floor'),
            SgaMemberItem(memberId: 12, name: 'DWI MULYONO', noreg: '00011044', role: 'GL Advisor'),
            SgaMemberItem(memberId: 18, name: 'RISWOKO', noreg: '01020747', role: 'TM Loader'),
            SgaMemberItem(memberId: 19, name: 'FERDIANSYAH', noreg: '01121564', role: 'TM Pos 2'),
          ],
        ),
        SgaGroup(
          id: '3',
          code: 'SGA-W03',
          name: 'SGA Cross Member & Export',
          shift: 'WHITE',
          tlName: 'DADANG SURYADI',
          tlNoreg: '00009978',
          posArea: 'Pos 3 Cross Member & Sub-Assy CKD',
          circleTema: 'Pencegahan Bahaya Sayatan Tepi Plat Tajam & Penataan Rak Material Dolly',
          members: [
            SgaMemberItem(memberId: 20, name: 'ERI KOSWANTO', noreg: '01221988', role: 'TM Sub-Assy'),
            SgaMemberItem(memberId: 21, name: 'RITNO', noreg: '01121566', role: 'TM CKD Packing'),
            SgaMemberItem(memberId: 22, name: 'AGUS PAJAR', noreg: '01020402', role: 'TM Fitting'),
          ],
        ),
        SgaGroup(
          id: '4',
          code: 'SGA-R01',
          name: 'SGA Main Floor Red',
          shift: 'RED',
          tlName: 'MASRURI',
          tlNoreg: '00009988',
          posArea: 'Pos 1 Underbody Main Floor Red',
          circleTema: 'Penanganan Kondisi Darurat Andon & Kepatuhan LOTO Robot Cell',
          members: [
            SgaMemberItem(memberId: 2, name: 'MASRURI', noreg: '00009988', role: 'TL Main Red'),
            SgaMemberItem(memberId: 5, name: 'SARDI', noreg: '01121689', role: 'TM Pos 1'),
            SgaMemberItem(memberId: 6, name: 'AGUNG ISKANDAR', noreg: '00919939', role: 'TM Spot Welder'),
            SgaMemberItem(memberId: 1, name: 'KAMALUDIN', noreg: '00010207', role: 'GL Advisor'),
          ],
        ),
        SgaGroup(
          id: '5',
          code: 'SGA-R02',
          name: 'SGA Respot & Finishing Red',
          shift: 'RED',
          tlName: 'TRI RUSTIANTORO',
          tlNoreg: '09405969',
          posArea: 'Pos 2 Cross Member & Respot Red',
          circleTema: 'Pencegahan Kejatuhan Komponen Berat & Verifikasi Safety Pin Jig',
          members: [
            SgaMemberItem(memberId: 3, name: 'TRI RUSTIANTORO', noreg: '09405969', role: 'TL Respot Red'),
            SgaMemberItem(memberId: 7, name: 'YOYON SUYONO', noreg: '00112433', role: 'TM Respot'),
            SgaMemberItem(memberId: 8, name: 'ADIB SETYO BUDI SANTOSO', noreg: '02437420', role: 'TM Inspection'),
          ],
        ),
      ];

  Future<({List<SgaGroup> groups, bool fromServer})> fetchGroups({int year = 2026}) async {
    final res = await UbWebApi.instance.getUb({
      'action': 'get_sga_groups',
      'shift': 'ALL',
      'year': '$year',
      '_t': '${DateTime.now().millisecondsSinceEpoch}',
    });
    if (res.ok && res.map['status'] == 'success' && res.map['data'] is List) {
      final parsed = (res.map['data'] as List)
          .whereType<Map>()
          .map((m) => SgaGroup.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      if (parsed.isNotEmpty) {
        await _saveCache(parsed);
        return (groups: parsed, fromServer: true);
      }
    }

    final cached = await _loadCache();
    if (cached.isNotEmpty) return (groups: cached, fromServer: false);

    final seeds = defaultSeedGroups();
    await _saveCache(seeds);
    return (groups: seeds, fromServer: false);
  }

  Future<List<LineMemberOption>> fetchLineMembers() async {
    final res = await UbWebApi.instance.getUb({
      'action': 'get_members',
      'shift': 'ALL',
      '_t': '${DateTime.now().millisecondsSinceEpoch}',
    });
    if (res.ok && res.map['status'] == 'success' && res.map['data'] is List) {
      return (res.map['data'] as List)
          .whereType<Map>()
          .map((m) => LineMemberOption.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return const [];
  }

  Future<({bool synced, String message})> saveGroup(SgaGroup group) async {
    final current = await _loadCache();
    final list = current.isNotEmpty ? current : defaultSeedGroups();
    final idx = list.indexWhere((g) => g.id == group.id);
    if (idx >= 0) {
      list[idx] = group;
    } else {
      list.add(group);
    }
    await _saveCache(list);

    final payload = {
      'id': int.tryParse(group.id) ?? 0,
      'code': group.code,
      'name': group.name,
      'shift': group.shift,
      'posArea': group.posArea,
      'circleTema': group.circleTema,
      'tlName': group.tlName,
      'tlNoreg': group.tlNoreg,
      'members': group.members.map((m) => m.toJson()).toList(),
    };
    final res = await UbWebApi.instance.postUb('save_sga_group', payload);
    if (res.ok && res.map['status'] == 'success') {
      return (synced: true, message: 'Group "${group.name}" tersimpan ke MySQL!');
    }
    return (
      synced: false,
      message: res.statusCode > 0
          ? 'Tersimpan di lokal (MySQL HTTP ${res.statusCode}).'
          : 'Tersimpan di lokal (offline).',
    );
  }

  Future<({bool synced, String message})> deleteGroup(SgaGroup group) async {
    final current = await _loadCache();
    final list = current.isNotEmpty ? current : defaultSeedGroups();
    list.removeWhere((g) => g.id == group.id);
    await _saveCache(list);

    final numericId = int.tryParse(group.id);
    if (numericId == null) {
      return (synced: false, message: 'Group dihapus dari lokal.');
    }
    final res = await UbWebApi.instance.postUb('delete_sga_group', {'id': numericId});
    if (res.ok) {
      return (synced: true, message: 'Group "${group.name}" dihapus dari MySQL.');
    }
    return (synced: false, message: 'Group dihapus dari lokal.');
  }

  Future<List<SgaGroup>> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kGroups);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<Map>().map((m) => SgaGroup.fromJson(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCache(List<SgaGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGroups, jsonEncode(groups.map((g) => g.toJson()).toList()));
  }
}
