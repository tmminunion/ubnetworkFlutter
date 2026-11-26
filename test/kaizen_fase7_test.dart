import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/data/hub_catalog.dart';
import 'package:ubnetwork_flutter/models/kaizen_activity_models.dart';

void main() {
  test('HubCatalog has all 5 Kaizen activities with expected routes', () {
    final routes = HubCatalog.kaizenActivities.map((k) => k.route).toList();
    expect(routes, containsAll(['/safety/group', '/qcc', '/tpm', '/5r', '/sw']));
  });

  test('QCC seeds provide 3 circles and 8-step PDCA A3 report JSON round-trip', () {
    final circles = KaizenActivitySeeds.qccCircles();
    expect(circles.length, 3);

    final rep = KaizenActivitySeeds.qccDefaultReport(circles.first);
    expect(rep.currentStep, 6);
    expect(rep.actionPlans.length, 3);
    expect(rep.fishboneBranches, isNotEmpty);

    final decoded = QccA3Report.fromJson(rep.toJson());
    expect(decoded.themeNo, rep.themeNo);
    expect(decoded.baselineDefectRate, 4.82);
    expect(decoded.resultDefectRate, 0.18);
    expect(decoded.actionPlans.length, 3);
  });

  test('5R audit recalculates 5 pillars and assigns Toyota Rank Grade A-D', () {
    final audit = KaizenActivitySeeds.fiveRAudit();
    final tags = KaizenActivitySeeds.fiveRRedTags();
    audit.recalculate(tags);
    expect(audit.totalScore, 96);
    expect(audit.rankGrade, 'A');
    expect(audit.redTagCount, 3);

    // Drop scores to test Rank B
    for (final c in audit.checklists.take(3)) {
      c.actualScore = 6;
    }
    audit.recalculate(tags);
    expect(audit.totalScore, 85);
    expect(audit.rankGrade, 'B');
  });

  test('SW Observasi seeds support TT 2.4m (14 jobs) and TT 1.9m (21 jobs) with 10-cycle study', () {
    final jobs24 = KaizenActivitySeeds.swJobsForProfile('prof-tt-24');
    final jobs19 = KaizenActivitySeeds.swJobsForProfile('prof-tt-19');
    expect(jobs24.length, 14);
    expect(jobs19.length, 21);

    final elements = KaizenActivitySeeds.swElementsForJob(jobs24.first);
    expect(elements.length, 10);
    expect(elements.first.totalTime, 7.0);

    final obs = KaizenActivitySeeds.swObservationsForJob(jobs24.first);
    expect(obs.length, 10);
  });

  test('TPM seeds include 4 world-class metrics, 4 Jishu Hozen SOPs, and 4 action plans', () {
    expect(KaizenActivitySeeds.tpmMetrics.length, 4);
    expect(KaizenActivitySeeds.tpmSopItems.length, 4);
    expect(KaizenActivitySeeds.tpmActionPlans().length, 4);
  });
}
