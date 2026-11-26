import 'package:flutter_test/flutter_test.dart';
import 'package:ubnetwork_flutter/data/hub_catalog.dart';
import 'package:ubnetwork_flutter/models/display_monitor_models.dart';

void main() {
  group('DisplayMonitorCatalog', () {
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
  });
}
