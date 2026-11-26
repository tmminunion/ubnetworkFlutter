import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/data/hub_catalog.dart';
import 'package:ubnetwork_flutter/models/safety_finding_models.dart';

void main() {
  test('Toyota Karawang Plant Risk Matrix evaluates Aa, Ab, Ba, Bb, Bc, Cc accurately', () {
    // 12 + 5 + 8 = 25 -> Aa (Bahaya besar)
    final aa = SafetyRiskMaster.evaluateSafetyRisk(12, 5, 8);
    expect(aa.total, 25);
    expect(aa.rank, 'Aa');
    expect(aa.category, 'A');

    // 6 + 5 + 8 = 19 -> Ab (Bahaya besar)
    final ab = SafetyRiskMaster.evaluateSafetyRisk(6, 5, 8);
    expect(ab.total, 19);
    expect(ab.rank, 'Ab');

    // 12 + 3 + 1 = 16 -> Ba (Bahaya sedang)
    final ba = SafetyRiskMaster.evaluateSafetyRisk(12, 3, 1);
    expect(ba.total, 16);
    expect(ba.rank, 'Ba');

    // 6 + 5 + 4 = 15 -> Bb
    final bb = SafetyRiskMaster.evaluateSafetyRisk(6, 5, 4);
    expect(bb.total, 15);
    expect(bb.rank, 'Bb');

    // 2 + 5 + 4 = 11 -> Bc
    final bc = SafetyRiskMaster.evaluateSafetyRisk(2, 5, 4);
    expect(bc.total, 11);
    expect(bc.rank, 'Bc');

    // 2 + 5 + 1 = 8 -> Cc (Bahaya kecil)
    final cc = SafetyRiskMaster.evaluateSafetyRisk(2, 5, 1);
    expect(cc.total, 8);
    expect(cc.rank, 'Cc');
    expect(cc.category, 'C');
  });

  test('isRankDown detects risk reduction correctly', () {
    expect(SafetyRiskMaster.isRankDown('Ab', 'Cc'), isTrue);
    expect(SafetyRiskMaster.isRankDown('Bc', 'Cc'), isTrue);
    expect(SafetyRiskMaster.isRankDown('Cc', 'Cc'), isFalse);
    expect(SafetyRiskMaster.isRankDown('Cc', 'Bb'), isFalse);
  });

  test('SafetyFinding JSON round-trip, Atlas closedAt, and riskDelta calculation', () {
    final atlasPayload = <String, dynamic>{
      '_id': 's41',
      'no': '41',
      'status': 'closed',
      'shift': 'red',
      'foundAt': '2026-11-26',
      'closedAt': '2026-11-26',
      'location': 'UB ASSY',
      'process': 'REAR FLOOR 560',
      'photo': 'ub_mwwy8uov571b09.jpg',
      'photoAfter': 'https://nudb.bungtemin.net/gambar/ub_mwwy9xj16aa571.jpg',
      'theme': 'Bolt anchor kendor',
      'result': 'sudah di rapihkan',
      'caption': 'Bolt anchor lifter kendor',
      'hazard': 0,
      'sources': [4],
      'before': {
        'accident': 'Tertimpa',
        'code': 'B',
        'typeName': 'Big Heavy (Tertimpa)',
        'injury': {'desc': 'Level b', 'point': 6},
        'frequency': {'desc': 'Tinggi', 'point': 5},
        'countermeasure': {'desc': 'Rendah', 'point': 8},
        'rank': 'Ab',
      },
      'standard': 'Kencangkan bolt sesuai torsi standar',
      'pic': 'MH Anwar',
      'date': '2026-11-26',
      'cm': 'Dikencangkan & diberi marking torsi',
      'after': {
        'accident': 'Tertimpa',
        'code': 'B',
        'typeName': 'Big Heavy (Tertimpa)',
        'injury': {'desc': 'Level c', 'point': 2},
        'frequency': {'desc': 'Rendah', 'point': 3},
        'countermeasure': {'desc': 'Tinggi', 'point': 1},
        'rank': 'Cc',
      },
    };

    final f = SafetyFinding.fromJson(atlasPayload);
    expect(f.isServerId, isTrue);
    expect(f.closedAt, '2026-11-26');
    expect(f.resolvedPhoto, 'https://nudb.bungtemin.net/gambar/ub_mwwy8uov571b09.jpg');
    expect(f.resolvedPhotoAfter, 'https://nudb.bungtemin.net/gambar/ub_mwwy9xj16aa571.jpg');
    expect(f.before.totalPoints, 19);
    expect(f.after.totalPoints, 6);
    expect(f.riskDelta?.diff, 13);
    expect(f.hasKaizenReport, isTrue);

    final serverBody = f.toServerPayload();
    expect(serverBody.containsKey('_id'), isFalse);
    expect(serverBody['photo'], 'ub_mwwy8uov571b09.jpg');
    expect(serverBody['photoAfter'], 'https://nudb.bungtemin.net/gambar/ub_mwwy9xj16aa571.jpg');
  });

  test('resolveMediaUrl, kaizenTag, formatBulanId, and fyLabelOf match Next.js 1:1', () {
    expect(
      SafetyRiskMaster.resolveMediaUrl('http://nudb.bungtemin.net/gambar/ub_abc.png'),
      'https://nudb.bungtemin.net/gambar/ub_abc.png',
    );
    expect(
      SafetyRiskMaster.resolveMediaUrl('/api/media?url=ub_abc.png'),
      'https://ubnetwork.vercel.app/api/media?url=ub_abc.png',
    );
    expect(SafetyRiskMaster.kaizenTag('41', 'S'), '#S-41');
    expect(SafetyRiskMaster.formatBulanId('2026-11-26'), 'November 2026');
    expect(SafetyRiskMaster.fyLabelOf('2026-11-26'), 'FY26');
    expect(SafetyRiskMaster.fyLabelOf('2027-02-10'), 'FY26');
  });

  test('Safety sub-hub marks /safety/temuan as native ready', () {
    final safety = HubCatalog.subHubs['safety']!;
    final temuan = safety.modules.firstWhere((m) => m.route == '/safety/temuan');
    expect(temuan.isNativeReady, isTrue);
  });
}
