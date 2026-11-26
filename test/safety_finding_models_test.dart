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

  test('SafetyFinding JSON round-trip and riskDelta calculation', () {
    final seed = defaultSafetyFindings().first;
    final restored = SafetyFinding.fromJson(seed.toJson());
    expect(restored.no, seed.no);
    expect(restored.before.totalPoints, 11);
    expect(restored.after.totalPoints, 8);
    expect(restored.riskDelta?.diff, 3);
    expect(restored.hasKaizenReport, isTrue);
  });

  test('Safety sub-hub marks /safety/temuan as native ready', () {
    final safety = HubCatalog.subHubs['safety']!;
    final temuan = safety.modules.firstWhere((m) => m.route == '/safety/temuan');
    expect(temuan.isNativeReady, isTrue);
  });
}
