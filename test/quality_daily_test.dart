import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/data/hub_catalog.dart';
import 'package:ubnetwork_flutter/models/quality_daily_models.dart';

void main() {
  test('QualityMath calculates D/U, dayDefect, and teamSummary accurately', () {
    final rec = QualityMonthlyRecord(ym: '2026-11', kind: 'out', targetDu: 0.025);
    rec.redZeroDays.add(1);
    rec.findings.add(
      QualityFinding(
        id: 'QO-1',
        date: '2026-11-02',
        team: 'red',
        kind: 'out',
        problem: 'Porosity weld bead',
        qty: 2,
      ),
    );

    expect(QualityMath.dayDefect(rec, 'red', 1), 0);
    expect(QualityMath.dayDefect(rec, 'red', 2), 2);
    expect(QualityMath.dayDefect(rec, 'red', 3), isNull);

    final prod = List<int?>.filled(30, null);
    prod[0] = 200;
    prod[1] = 200;
    final sum = QualityMath.teamSummary(rec, 'red', 30, prod);
    expect(sum.totalProd, 400);
    expect(sum.totalDefect, 2);
    expect(QualityMath.fmtDu(sum.du), '0.005');
  });

  test('QualityMonthlyRecord JSON round-trip preserves target, zeroDays, and findings', () {
    final rec = QualityMonthlyRecord(ym: '2026-11', kind: 'in', targetDu: 0.030);
    rec.whiteZeroDays.add(5);
    rec.findings.add(
      QualityFinding(
        id: 'QI-1',
        date: '2026-11-06',
        team: 'white',
        kind: 'in',
        problem: 'Spatter',
        qty: 3,
      ),
    );
    final restored = QualityMonthlyRecord.fromJson(rec.toJson(), ym: '2026-11', kind: 'in');
    expect(restored.targetDu, 0.030);
    expect(restored.whiteZeroDays.contains(5), isTrue);
    expect(restored.findings.length, 1);
    expect(restored.findings.first.qty, 3);
  });

  test('Quality sub-hub marks both /quality/daily/out and /quality/daily/in as native ready', () {
    final quality = HubCatalog.subHubs['quality']!;
    final readyRoutes = quality.modules.where((m) => m.isNativeReady).map((m) => m.route).toSet();
    expect(readyRoutes, containsAll(['/quality/daily/out', '/quality/daily/in']));
  });
}
