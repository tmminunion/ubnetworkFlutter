import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/models/cost_env_models.dart';

void main() {
  group('CostPaceMath', () {
    test('computes total, pct, projection, and paceLevel accurately', () {
      final vals = List<double?>.filled(31, null);
      vals[0] = 5;
      vals[1] = 5;
      vals[2] = 5; // 15 in 3 days => projection 150 in 30 days

      final bad = CostPaceMath.computeItemMetrics(vals, 30, 100);
      expect(bad.total, 15.0);
      expect(bad.pct, 15.0);
      expect(bad.projection, 150.0);
      expect(bad.paceLevel, 'bad');

      final ok = CostPaceMath.computeItemMetrics(vals, 30, 200);
      expect(ok.paceLevel, 'ok');
    });

    test('formatRupiah formats Indonesian currency cleanly', () {
      expect(formatRupiah(1250000), 'Rp 1.250.000');
      expect(formatRupiah(0), 'Rp 0');
    });
  });

  group('EnvEnergyMath', () {
    test('computes Red, White, combined kWh totals, averages, and compliance rates', () {
      final r = List<double?>.filled(31, null);
      final w = List<double?>.filled(31, null);
      r[0] = 800; // OK (<= 850)
      r[1] = 900; // X (> 850)
      w[0] = 750; // OK
      w[1] = 820; // OK

      final m = EnvEnergyMonth(ym: '2026-11', target: 850, red: r, white: w);
      final s = EnvEnergyMath.computeSummary(m);

      expect(s.totalRed, 1700.0);
      expect(s.avgRed, 850.0);
      expect(s.rateRed, 50);

      expect(s.totalWhite, 1570.0);
      expect(s.avgWhite, 785.0);
      expect(s.rateWhite, 100);

      expect(s.totalCombined, 3270.0);
    });
  });

  group('AirLeakage & CostFinding JSON round-trip', () {
    test('AirLeakageFinding serializes #lub / #klub fields', () {
      const f = AirLeakageFinding(
        id: 'LUB01',
        date: '2026-11-26',
        shift: 'red',
        member: 'Budi',
        area: 'Pos 2',
        problem: '#lub Selang bocor',
        countermeasure: 'Ganti fitting one-touch',
        kaizenTitle: '#klub Pengunci selang',
        isKaizen: true,
        status: 'closed',
      );
      final parsed = AirLeakageFinding.fromJson(f.toJson());
      expect(parsed.id, 'LUB01');
      expect(parsed.isKaizen, isTrue);
      expect(parsed.status, 'closed');
    });

    test('CostFinding serializes cleanly', () {
      const cf = CostFinding(
        id: 'C01',
        date: '2026-11-26',
        team: 'white',
        kind: 'supply',
        process: 'Tip Cap',
        foundWhere: 'Pos 4',
        problem: 'Pemakaian boros',
        amount: 250000,
        countermeasure: 'Cek tekanan tip dresser',
        pic: 'TL White',
      );
      final parsed = CostFinding.fromJson(cf.toJson());
      expect(parsed.id, 'C01');
      expect(parsed.kindLabel, 'O. Supply');
      expect(parsed.amount, 250000);
    });
  });
}
