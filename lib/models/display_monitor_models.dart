class DisplayFyMonthPoint {
  const DisplayFyMonthPoint({
    required this.monthLabel,
    required this.plan,
    required this.actual,
  });

  final String monthLabel;
  final double plan;
  final double actual;
}

class DisplayPaperMeta {
  const DisplayPaperMeta({
    required this.pillarSlug,
    required this.rowKey,
    required this.bannerTitle,
    required this.kpiUnit,
    required this.targetLabel,
    required this.docCode,
    required this.fySeries,
  });

  final String pillarSlug;
  final String rowKey;
  final String bannerTitle;
  final String kpiUnit;
  final String targetLabel;
  final String docCode;
  final List<DisplayFyMonthPoint> fySeries;
}

class DisplayMonitorCatalog {
  DisplayMonitorCatalog._();

  static const List<String> fyMonths = [
    'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar',
  ];

  static DisplayPaperMeta metaFor(String pillarSlug, String rowKey) {
    final rowTitle = switch (rowKey) {
      'main' => 'MAIN KPI (FISCAL YEAR)',
      'sub' => 'SUB KPI (DAILY 1–31 RED & WHITE)',
      'proses' => 'PROSES KPI — LIST UP PROBLEM FINDINGS',
      'kaizen' => 'KAIZEN REPORT — BEFORE & AFTER',
      _ => 'KPI BOARD',
    };

    switch (pillarSlug) {
      case 'hoshin':
        return DisplayPaperMeta(
          pillarSlug: pillarSlug,
          rowKey: rowKey,
          bannerTitle: 'HOSHIN KANRI & POLICY — $rowTitle',
          kpiUnit: '%',
          targetLabel: 'Target ≥ 95%',
          docCode: 'TMMIN-UB-H-${rowKey.toUpperCase()}',
          fySeries: _series([95, 95, 95, 95, 95, 95, 95, 95, 95, 95, 95, 95], [96, 97, 96, 98, 97, 98, 99, 98, 0, 0, 0, 0]),
        );
      case 'safety':
        return DisplayPaperMeta(
          pillarSlug: pillarSlug,
          rowKey: rowKey,
          bannerTitle: 'SAFETY (ZERO ACCIDENT) — $rowTitle',
          kpiUnit: 'Case',
          targetLabel: 'Target 0 LTI',
          docCode: 'TMMIN-UB-S-${rowKey.toUpperCase()}',
          fySeries: _series([100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100], [100, 100, 100, 100, 100, 100, 100, 100, 0, 0, 0, 0]),
        );
      case 'quality':
        return DisplayPaperMeta(
          pillarSlug: pillarSlug,
          rowKey: rowKey,
          bannerTitle: 'QUALITY (BUILT-IN QUALITY) — $rowTitle',
          kpiUnit: 'D/U',
          targetLabel: 'Target ≤ 0.02 D/U',
          docCode: 'TMMIN-UB-Q-${rowKey.toUpperCase()}',
          fySeries: _series([99.5, 99.5, 99.5, 99.5, 99.5, 99.5, 99.5, 99.5, 99.5, 99.5, 99.5, 99.5], [99.7, 99.8, 99.6, 99.9, 99.8, 99.7, 99.8, 99.82, 0, 0, 0, 0]),
        );
      case 'productivity':
        return DisplayPaperMeta(
          pillarSlug: pillarSlug,
          rowKey: rowKey,
          bannerTitle: 'PRODUCTIVITY (UB ASSY LINE) — $rowTitle',
          kpiUnit: '%',
          targetLabel: 'Target ≥ 95% Eff · 25 UPH',
          docCode: 'TMMIN-UB-P-${rowKey.toUpperCase()}',
          fySeries: _series([95, 95, 95, 95, 95, 95, 95, 95, 95, 95, 95, 95], [96.2, 97.1, 95.8, 97.5, 98.0, 97.4, 98.1, 98.0, 0, 0, 0, 0]),
        );
      case 'cost':
        return DisplayPaperMeta(
          pillarSlug: pillarSlug,
          rowKey: rowKey,
          bannerTitle: 'COST (LEAN BUDGET & O. SUPPLY) — $rowTitle',
          kpiUnit: '%',
          targetLabel: 'Target ≤ 100% Budget',
          docCode: 'TMMIN-UB-C-${rowKey.toUpperCase()}',
          fySeries: _series([100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100], [92, 89, 94, 91, 88, 90, 87, 89, 0, 0, 0, 0]),
        );
      case 'hr-dev':
        return DisplayPaperMeta(
          pillarSlug: pillarSlug,
          rowKey: rowKey,
          bannerTitle: 'HR-DEV & MORALE (IDEA & DISIPLIN) — $rowTitle',
          kpiUnit: 'Idea/MP',
          targetLabel: 'Target ≥ 2.0 Idea/MP · 100% Part.',
          docCode: 'TMMIN-UB-HR-${rowKey.toUpperCase()}',
          fySeries: _series([2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0], [2.1, 2.2, 2.0, 2.3, 2.4, 2.2, 2.5, 2.3, 0, 0, 0, 0]),
        );
      case 'env':
      default:
        return DisplayPaperMeta(
          pillarSlug: pillarSlug,
          rowKey: rowKey,
          bannerTitle: 'ENVIRONMENT (ENERGY & AIR LEAKAGE) — $rowTitle',
          kpiUnit: 'kWh',
          targetLabel: 'Target ≤ 850 kWh/shift · 0 Leak',
          docCode: 'TMMIN-UB-E-${rowKey.toUpperCase()}',
          fySeries: _series([850, 850, 850, 850, 850, 850, 850, 850, 850, 850, 850, 850], [820, 815, 830, 810, 805, 812, 798, 802, 0, 0, 0, 0]),
        );
    }
  }

  static List<DisplayFyMonthPoint> _series(List<double> plans, List<double> acts) {
    return List.generate(
      fyMonths.length,
      (i) => DisplayFyMonthPoint(monthLabel: fyMonths[i], plan: plans[i], actual: acts[i]),
    );
  }

}
