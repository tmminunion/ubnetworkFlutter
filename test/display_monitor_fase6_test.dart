import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/data/hub_catalog.dart';
import 'package:ubnetwork_flutter/features/display/display_paper_defaults.dart';
import 'package:ubnetwork_flutter/models/display_monitor_models.dart';

void main() {
  group('DisplayMonitorCatalog & 1:1 Next.js PaperFrame Defaults', () {
    test('provides metadata and 12-month Fiscal Year series for all 7 pillars x 4 rows', () {
      for (final p in HubCatalog.displayPillars) {
        for (final r in HubCatalog.displayRows) {
          final meta = DisplayMonitorCatalog.metaFor(p.slug, r.key);
          expect(meta.pillarSlug, p.slug);
          expect(meta.rowKey, r.key);
          expect(meta.fySeries.length, 12);
          expect(meta.bannerTitle, isNotEmpty);
        }
      }
    });

    test('uses 1600x900 16:9 PaperFrame dimensions and static header titles 1:1 with Next.js', () {
      expect(kDisplayPaperW, 1600.0);
      expect(kDisplayPaperH, 900.0);

      expect(
        resolvePaperHeaderTitle(slug: 'safety', shortName: 'SAFETY', rowKey: 'proses'),
        'PROSES KPI · LIST UP PROBLEM FINDINGS UB ASSY',
      );
      expect(
        resolvePaperHeaderTitle(slug: 'productivity', shortName: 'PRODUCTIVITY', rowKey: 'sub'),
        'SUB KPI · EFISIENSI',
      );
      expect(
        resolvePaperHeaderTitle(slug: 'quality', shortName: 'QUALITY', rowKey: 'sub'),
        'SUB KPI · DEFECT',
      );
      expect(
        resolvePaperHeaderTitle(slug: 'cost', shortName: 'COST', rowKey: 'main'),
        'MAIN KPI · COST UNDER BODY ASSY',
      );
      expect(
        resolvePaperHeaderTitle(slug: 'cost', shortName: 'COST', rowKey: 'sub'),
        'SUB KPI · CONTROL COST DAILY',
      );
      expect(
        resolvePaperHeaderTitle(slug: 'cost', shortName: 'COST', rowKey: 'proses'),
        'PROSES KPI · TEMUAN COST',
      );
      expect(
        resolvePaperHeaderTitle(slug: 'hr-dev', shortName: 'HR-DEV', rowKey: 'kaizen'),
        'KAIZEN REPORT · HR-DEV',
      );
    });

    test('parses Hoshin Sub Department Action Plan Gantt schedule bars 1:1', () {
      final parsed = parseActionPlanBars([
        'Apr-Mei Assessment#1',
        'Jun-Jul Training#1',
        'Apr-Mei Study',
      ]);
      expect(parsed.bars.length, 3);
      expect(parsed.lanes, 2);
      expect(parsed.bars[0].start, 0);
      expect(parsed.bars[0].end, 1);
      expect(parsed.bars[0].lane, 0);
      expect(parsed.bars[2].lane, 1);
    });

    test('formats Fiscal Year months Apr-Mar and Cost May-Apr 1:1', () {
      final fyM = DisplayFyMath.fyMonths(2026);
      expect(fyM.first, 'Apr-26');
      expect(fyM.last, 'Mar-27');

      final costM = DisplayFyMath.costMonths(2026);
      expect(costM.first, 'May-26');
      expect(costM.last, 'Apr-27');
    });
  });
}
