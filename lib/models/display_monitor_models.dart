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

class MonitorSlideModel {
  const MonitorSlideModel({
    required this.id,
    required this.name,
    required this.badge,
    required this.headline,
    required this.subheadline,
    required this.metrics,
    required this.bullets,
    required this.accentHex,
    this.durationSec = 10,
  });

  final String id;
  final String name;
  final String badge;
  final String headline;
  final String subheadline;
  final List<({String label, String value, String unit})> metrics;
  final List<String> bullets;
  final int accentHex;
  final int durationSec;
}

class MonitorDeckModel {
  const MonitorDeckModel({
    required this.id,
    required this.title,
    required this.shortLabel,
    required this.slides,
  });

  final String id;
  final String title;
  final String shortLabel;
  final List<MonitorSlideModel> slides;
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

  static List<MonitorDeckModel> buildDecks({
    required int localChecksheets,
    required int openSafetyFindings,
    required int totalKaizen,
    required String lineName,
  }) {
    return [
      MonitorDeckModel(
        id: 'main',
        title: 'UNDERBODY PLANT MONITOR',
        shortLabel: 'Plant',
        slides: [
          MonitorSlideModel(
            id: 'plant-sqpcehr',
            name: 'Ringkasan SQPCEHR Shopfloor',
            badge: 'LIVE PLANT KPI',
            headline: '$lineName — Zero Accident & Built-in Quality',
            subheadline: 'Papan Informasi Digital Shopfloor Karawang Plant',
            metrics: [
              (label: 'SAFE DAYS', value: '1.428', unit: 'Hari LTI Free'),
              (label: 'FPY QUALITY', value: '99.82%', unit: '18 PPM'),
              (label: 'EFISIENSI', value: '98.0%', unit: '25 UPH'),
              (label: 'CHECKSHEET', value: '$localChecksheets', unit: 'Laporan Lokal'),
            ],
            bullets: const [
              'Utamakan Safety First: cek interlock gate robot & STOP 6 sebelum start produksi.',
              'Built-in Quality: Jangan Terima, Jangan Buat, Jangan Teruskan Cacat.',
              'Laporkan abnormalitas Chokotei & Air Leakage (#lub) secara real-time.',
            ],
            accentHex: 0xFF06B6D4,
          ),
          MonitorSlideModel(
            id: 'plant-safety',
            name: 'Safety Patrol & Hotline #sub',
            badge: 'SAFETY FIRST',
            headline: 'Budaya Zero Accident & Hiyari Hatto',
            subheadline: 'Evaluasi Temuan Patrol & Target 1 Bulan 1 KYT per SGA',
            metrics: [
              (label: 'TEMUAN OPEN', value: '$openSafetyFindings', unit: 'Patrol Item'),
              (label: 'KYT TARGET', value: '100%', unit: '1x / Bulan / SGA'),
              (label: 'KAIZEN AKTIF', value: '$totalKaizen', unit: 'Report'),
            ],
            bullets: const [
              'Gunakan APD lengkap (Helm, Kacamata Safety, Sarung Tangan, Sepatu Safety).',
              'Pastikan area robot terkunci interlock sebelum masuk zona kerja.',
              'Kirim temuan potensi bahaya via aplikasi UBnetwork Flutter (offline-ready).',
            ],
            accentHex: 0xFF10B981,
          ),
          MonitorSlideModel(
            id: 'plant-energy',
            name: 'Green Plant — Energy & 5S',
            badge: 'ENVIRONMENT & 5S',
            headline: 'Zero Air Leakage (#lub) & Lean Energy',
            subheadline: 'Matikan panel, kipas, dan cek selang angin saat istirahat & akhir shift',
            metrics: [
              (label: 'TARGET ENERGI', value: '≤ 850', unit: 'kWh / Shift'),
              (label: 'AIR LEAKAGE', value: '0', unit: 'Target Titik Bocor'),
              (label: 'SKOR 5R', value: '98.8%', unit: 'Audit Shopfloor'),
            ],
            bullets: const [
              'Cek kebocoran angin di regulator FRL, clamp jig, dan coupler robot.',
              'Jalankan pembagian tugas After-Prod 5S sebelum jam pulang.',
            ],
            accentHex: 0xFFF59E0B,
          ),
        ],
      ),
      const MonitorDeckModel(
        id: 'qae',
        title: 'WELCOME QAE & MANAGEMENT VISIT',
        shortLabel: 'Welcome QAE',
        slides: [
          MonitorSlideModel(
            id: 'qae-welcome',
            name: 'Welcome to Underbody Assy',
            badge: 'WELCOME VISIT',
            headline: 'Selamat Datang Tim QAE & Management',
            subheadline: 'PT. TMMIN — Underbody Assy Line · Digital GL Management Board',
            metrics: [
              (label: 'QUALITY GATE', value: '100%', unit: 'Poka-Yoke Active'),
              (label: 'DEFECT OUT', value: '0', unit: 'Target Zero Outflow'),
              (label: 'MANPOWER', value: '43', unit: 'Red & White Shift'),
            ],
            bullets: [
              'Seluruh checksheet produksi, defect, dan Kaizen terdigitalisasi 100%.',
              'Monitoring D/U Out Flow & In Proses real-time per tanggal 1–31.',
            ],
            accentHex: 0xFF3B82F6,
          ),
        ],
      ),
      const MonitorDeckModel(
        id: 'deck_mwbf55dj_yqye',
        title: 'SAFETY PATROL MONITOR SLIDE',
        shortLabel: 'Safety Patrol',
        slides: [
          MonitorSlideModel(
            id: 'sp-welcome',
            name: 'Safety Patrol & Hotline #sub',
            badge: 'SAFETY PATROL',
            headline: 'Safety Patrol Underbody — Zero Accident',
            subheadline: 'Matriks Risiko Toyota Karawang Plant (Aa – Cc) & STOP 6',
            metrics: [
              (label: 'LTI FREE', value: '1.428', unit: 'Hari Selamat'),
              (label: 'STOP 6', value: '0', unit: 'Insiden Kritis'),
              (label: 'HOTLINE', value: '#sub', unit: 'Lapor Cepat'),
            ],
            bullets: [
              'A: Terjepit · B: Tertabrak · C: Tertimpa · D: Jatuh · E: Listrik · F: Panas/Api.',
              'Prioritaskan penanggulangan Rank Aa & Ab maksimal 1×24 jam.',
            ],
            accentHex: 0xFFEF4444,
          ),
        ],
      ),
    ];
  }
}
