import 'package:flutter/material.dart';

class HubPillarItem {
  const HubPillarItem({
    required this.id,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.highlight,
    required this.badge,
    required this.route,
    required this.gradient,
    required this.accentColor,
    required this.icon,
  });

  final String id;
  final String code;
  final String title;
  final String subtitle;
  final String highlight;
  final String badge;
  final String route;
  final List<Color> gradient;
  final Color accentColor;
  final IconData icon;
}

class QuickAppItem {
  const QuickAppItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final Color color;
}

class SubModuleItem {
  const SubModuleItem({
    required this.id,
    required this.title,
    required this.desc,
    required this.route,
    required this.badge,
    required this.gradient,
    required this.accentColor,
    required this.icon,
    this.isNativeReady = false,
  });

  final String id;
  final String title;
  final String desc;
  final String route;
  final String badge;
  final List<Color> gradient;
  final Color accentColor;
  final IconData icon;
  final bool isNativeReady;
}

class SubHubConfig {
  const SubHubConfig({
    required this.id,
    required this.code,
    required this.typeLabel,
    required this.title,
    required this.subtitle,
    required this.tagline,
    required this.pathLabel,
    required this.gradient,
    required this.accentColor,
    required this.icon,
    required this.modules,
  });

  final String id;
  final String code;
  final String typeLabel;
  final String title;
  final String subtitle;
  final String tagline;
  final String pathLabel;
  final List<Color> gradient;
  final Color accentColor;
  final IconData icon;
  final List<SubModuleItem> modules;
}

class DisplayPillarItem {
  const DisplayPillarItem({
    required this.slug,
    required this.chip,
    required this.shortName,
    required this.fullName,
    required this.gradient,
    required this.accentColor,
  });

  final String slug;
  final String chip;
  final String shortName;
  final String fullName;
  final List<Color> gradient;
  final Color accentColor;
}

class DisplayRowMeta {
  const DisplayRowMeta({
    required this.key,
    required this.name,
    required this.desc,
    required this.icon,
  });

  final String key;
  final String name;
  final String desc;
  final IconData icon;
}

class HubCatalog {
  HubCatalog._();

  // =========================================================================
  // 1. 6 PILAR UTAMA MANUFAKTUR (S - Q - P - C - HR - E)
  // =========================================================================
  static const List<HubPillarItem> kpiPillars = [
    HubPillarItem(
      id: 'safety',
      code: 'S',
      title: 'Safety',
      subtitle: 'Keselamatan Kerja',
      highlight: '1.428 Hari LTI Free',
      badge: 'Zero Accident',
      route: '/safety',
      gradient: [Color(0xFF10B981), Color(0xFF16A34A)],
      accentColor: Color(0xFF34D399),
      icon: Icons.health_and_safety_rounded,
    ),
    HubPillarItem(
      id: 'quality',
      code: 'Q',
      title: 'Quality',
      subtitle: 'Kualitas Produk',
      highlight: 'FPY 99.82% • 18 PPM',
      badge: 'Built-in Quality',
      route: '/quality',
      gradient: [Color(0xFF2563EB), Color(0xFF4F46E5)],
      accentColor: Color(0xFF38BDF8),
      icon: Icons.verified_rounded,
    ),
    HubPillarItem(
      id: 'productivity',
      code: 'P',
      title: 'Productivity',
      subtitle: 'Produktivitas Lini',
      highlight: 'Efisiensi 98% • 25 UPH',
      badge: 'Suite Lengkap',
      route: '/productivity',
      gradient: [Color(0xFF06B6D4), Color(0xFF2563EB)],
      accentColor: Color(0xFF22D3EE),
      icon: Icons.precision_manufacturing_rounded,
    ),
    HubPillarItem(
      id: 'cost',
      code: 'C',
      title: 'Cost',
      subtitle: 'Biaya & Efisiensi',
      highlight: 'Saving Rp 42.8 Juta',
      badge: 'Lean Budget',
      route: '/cost',
      gradient: [Color(0xFFF59E0B), Color(0xFFE11D48)],
      accentColor: Color(0xFFFBBF24),
      icon: Icons.savings_rounded,
    ),
    HubPillarItem(
      id: 'hr',
      code: 'HR',
      title: 'HR & Morale',
      subtitle: 'SDM & Disiplin',
      highlight: 'Kehadiran 98.6%',
      badge: '43 Manpower',
      route: '/hr',
      gradient: [Color(0xFF7C3AED), Color(0xFFC026D3)],
      accentColor: Color(0xFFC084FC),
      icon: Icons.groups_rounded,
    ),
    HubPillarItem(
      id: 'env',
      code: 'E',
      title: 'Environment',
      subtitle: 'Lingkungan & Energi',
      highlight: 'Target 0 Leak • Lean Energy',
      badge: 'Green Plant',
      route: '/env',
      gradient: [Color(0xFF10B981), Color(0xFF15803D)],
      accentColor: Color(0xFF4ADE80),
      icon: Icons.eco_rounded,
    ),
  ];

  // =========================================================================
  // 2. AKTIVITAS KAIZEN (SGA, QCC, TPM, 5R, SW)
  // =========================================================================
  static const List<HubPillarItem> kaizenActivities = [
    HubPillarItem(
      id: 'sga',
      code: 'SGA',
      title: 'SGA',
      subtitle: 'Small Group Activity',
      highlight: '18 Tema Aktif',
      badge: 'Shopfloor',
      route: '/safety/group',
      gradient: [Color(0xFFF59E0B), Color(0xFFDC2626)],
      accentColor: Color(0xFFFB923C),
      icon: Icons.diversity_3_rounded,
    ),
    HubPillarItem(
      id: 'qcc',
      code: 'QCC',
      title: 'QCC',
      subtitle: 'Quality Control Circle',
      highlight: '6 Gugus • Gold Award',
      badge: 'PDCA',
      route: '/qcc',
      gradient: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
      accentColor: Color(0xFF818CF8),
      icon: Icons.workspace_premium_rounded,
    ),
    HubPillarItem(
      id: 'tpm',
      code: 'TPM',
      title: 'TPM',
      subtitle: 'Total Productive Maint.',
      highlight: 'OEE 91.4% • Zero Stop',
      badge: 'Jishu Hozen',
      route: '/tpm',
      gradient: [Color(0xFF2563EB), Color(0xFF10B981)],
      accentColor: Color(0xFF34D399),
      icon: Icons.build_circle_rounded,
    ),
    HubPillarItem(
      id: '5r',
      code: '5R',
      title: '5R / 5S',
      subtitle: 'Ringkas Rapi Resik Rawat Rajin',
      highlight: 'Audit Skor 98.8%',
      badge: 'Workplace',
      route: '/5r',
      gradient: [Color(0xFF10B981), Color(0xFF0891B2)],
      accentColor: Color(0xFF2DD4BF),
      icon: Icons.cleaning_services_rounded,
    ),
    HubPillarItem(
      id: 'sw',
      code: 'SW',
      title: 'SW Observasi',
      subtitle: 'Standardized Work',
      highlight: 'Kepatuhan 98.9%',
      badge: 'SOP Audit',
      route: '/sw',
      gradient: [Color(0xFF0EA5E9), Color(0xFF4F46E5)],
      accentColor: Color(0xFF38BDF8),
      icon: Icons.fact_check_rounded,
    ),
  ];

  // =========================================================================
  // 3. UB QUICK APP DX (11 ALAT CEPAT)
  // =========================================================================
  static const List<QuickAppItem> quickApps = [
    QuickAppItem(
      id: 'henkaten',
      title: 'Henkaten Board',
      subtitle: 'Perubahan 4M (Man, Machine, Material, Method)',
      route: '/henkaten',
      icon: Icons.swap_horiz_rounded,
      color: Color(0xFFF59E0B),
    ),
    QuickAppItem(
      id: 'task-hub',
      title: 'Task Hub Interaktif',
      subtitle: 'Kanban & penugasan harian regu',
      route: '/productivity/tasks',
      icon: Icons.task_alt_rounded,
      color: Color(0xFF22D3EE),
    ),
    QuickAppItem(
      id: 'postit',
      title: 'Post-It Board',
      subtitle: 'Catatan cepat & follow-up shopfloor',
      route: '/postit',
      icon: Icons.sticky_note_2_rounded,
      color: Color(0xFFFACC15),
    ),
    QuickAppItem(
      id: 'after-prod',
      title: 'After Produksi & 5R',
      subtitle: 'Penugasan 5S akhir shift',
      route: '/productivity/after-prod',
      icon: Icons.checklist_rtl_rounded,
      color: Color(0xFF10B981),
    ),
    QuickAppItem(
      id: 'ubdrive',
      title: 'UBdrive',
      subtitle: 'Arsip dokumen & file SharePoint UB',
      route: '/ubdrive',
      icon: Icons.cloud_done_rounded,
      color: Color(0xFF3B82F6),
    ),
    QuickAppItem(
      id: 'energy',
      title: 'Control Energi Harian',
      subtitle: 'Monitoring kWh harian Red & White',
      route: '/env/daily',
      icon: Icons.bolt_rounded,
      color: Color(0xFF34D399),
    ),
    QuickAppItem(
      id: 'env-temuan',
      title: 'Temuan Lingkungan & Kaizen',
      subtitle: 'Air leakage #lub & Kaizen #klub',
      route: '/env/temuan',
      icon: Icons.air_rounded,
      color: Color(0xFF2DD4BF),
    ),
    QuickAppItem(
      id: 'bacadoa',
      title: 'Matrik Baca Doa Asare',
      subtitle: 'Rotasi pimpin doa & senam pagi',
      route: '/bacadoa',
      icon: Icons.menu_book_rounded,
      color: Color(0xFFA855F7),
    ),
    QuickAppItem(
      id: 'docs',
      title: 'Dokumentasi Sistem',
      subtitle: 'Panduan penggunaan UBnetwork',
      route: '/docs',
      icon: Icons.description_rounded,
      color: Color(0xFF94A3B8),
    ),
    QuickAppItem(
      id: 'andon',
      title: 'Andon Live Monitor',
      subtitle: 'Status lini & alarm real-time',
      route: '/andon',
      icon: Icons.sensors_rounded,
      color: Color(0xFFF43F5E),
    ),
    QuickAppItem(
      id: 'idea',
      title: 'Idea',
      subtitle: 'Kaizen SQPCHR & Innovation Portal',
      route: '/idnu',
      icon: Icons.lightbulb_rounded,
      color: Color(0xFF38BDF8),
    ),
  ];

  // =========================================================================
  // 4. DISPLAY KPI — GL MANAGEMENT BOARD (7 PILAR x 4 KERTAS)
  // =========================================================================
  static const List<DisplayPillarItem> displayPillars = [
    DisplayPillarItem(
      slug: 'hoshin',
      chip: 'H',
      shortName: 'HOSHIN',
      fullName: 'Hoshin Kanri & Policy',
      gradient: [Color(0xFFFBBF24), Color(0xFFF97316)],
      accentColor: Color(0xFFFCD34D),
    ),
    DisplayPillarItem(
      slug: 'safety',
      chip: 'S',
      shortName: 'SAFETY',
      fullName: 'Keselamatan Kerja',
      gradient: [Color(0xFF34D399), Color(0xFF16A34A)],
      accentColor: Color(0xFF6EE7B7),
    ),
    DisplayPillarItem(
      slug: 'quality',
      chip: 'Q',
      shortName: 'QUALITY',
      fullName: 'Kualitas Produk',
      gradient: [Color(0xFF38BDF8), Color(0xFF2563EB)],
      accentColor: Color(0xFF7DD3FC),
    ),
    DisplayPillarItem(
      slug: 'productivity',
      chip: 'P',
      shortName: 'PRODUCTIVITY',
      fullName: 'Produktivitas Lini',
      gradient: [Color(0xFFA78BFA), Color(0xFF9333EA)],
      accentColor: Color(0xFFC4B5FD),
    ),
    DisplayPillarItem(
      slug: 'cost',
      chip: 'C',
      shortName: 'COST',
      fullName: 'Biaya & Efisiensi',
      gradient: [Color(0xFF22D3EE), Color(0xFF0D9488)],
      accentColor: Color(0xFF67E8F9),
    ),
    DisplayPillarItem(
      slug: 'hr-dev',
      chip: 'HR',
      shortName: 'HR-DEV',
      fullName: 'SDM & Pengembangan',
      gradient: [Color(0xFFFB7185), Color(0xFFDB2777)],
      accentColor: Color(0xFFFDA4AF),
    ),
    DisplayPillarItem(
      slug: 'env',
      chip: 'E',
      shortName: 'ENV',
      fullName: 'Lingkungan & Energi',
      gradient: [Color(0xFFA3E635), Color(0xFF16A34A)],
      accentColor: Color(0xFFBEF264),
    ),
  ];

  static const List<DisplayRowMeta> displayRows = [
    DisplayRowMeta(
      key: 'main',
      name: 'Main KPI',
      desc: 'Capaian per Fiscal Year',
      icon: Icons.bar_chart_rounded,
    ),
    DisplayRowMeta(
      key: 'sub',
      name: 'Sub KPI',
      desc: 'Rincian harian per regu',
      icon: Icons.layers_rounded,
    ),
    DisplayRowMeta(
      key: 'proses',
      name: 'Proses KPI',
      desc: 'Kontrol proses',
      icon: Icons.account_tree_rounded,
    ),
    DisplayRowMeta(
      key: 'kaizen',
      name: 'Kaizen',
      desc: 'Perbaikan & masalah',
      icon: Icons.lightbulb_outline_rounded,
    ),
  ];

  // =========================================================================
  // 5. SUB-HUB CONFIGS (/safety, /quality, /productivity, /cost, /hr, /env)
  // =========================================================================
  static final Map<String, SubHubConfig> subHubs = {
    'safety': const SubHubConfig(
      id: 'safety',
      code: 'S',
      typeLabel: 'KPI Pillar',
      title: 'Safety (Keselamatan Kerja)',
      subtitle: 'K3, Zero Accident, KYT & Safety Patrol Shopfloor',
      tagline: 'Zero Accident',
      pathLabel: '~/Underbody/Plant/S • Safety First',
      gradient: [Color(0xFF10B981), Color(0xFF14B8A6), Color(0xFF16A34A)],
      accentColor: Color(0xFF34D399),
      icon: Icons.health_and_safety_rounded,
      modules: [
        SubModuleItem(
          id: 'kyt',
          title: 'KYT Monitoring (12 Bulan)',
          desc: 'Matriks pemantauan pelaksanaan target 1 bulan 1 KYT per group SGA (Shift Red & White) periode 12 bulan.',
          route: '/kyt/monitoring',
          badge: 'NATIVE READY',
          gradient: [Color(0xFFF59E0B), Color(0xFFEA580C)],
          accentColor: Color(0xFFFBBF24),
          icon: Icons.warning_amber_rounded,
          isNativeReady: true,
        ),
        SubModuleItem(
          id: 'temuan',
          title: 'Temuan Safety (List Up Problem)',
          desc: 'Pencatatan, penanggulangan, dan verifikasi temuan potensi bahaya hasil patrol keselamatan shopfloor.',
          route: '/safety/temuan',
          badge: 'NATIVE READY',
          gradient: [Color(0xFFF43F5E), Color(0xFFDC2626)],
          accentColor: Color(0xFFFB7185),
          icon: Icons.assignment_late_rounded,
          isNativeReady: true,
        ),
        SubModuleItem(
          id: 'group',
          title: 'Group SGA (Small Group Activity)',
          desc: 'Struktur kelompok kerja K3 Shift Red & White, penanggung jawab Team Leader (TL), dan roster member.',
          route: '/safety/group',
          badge: 'NATIVE READY',
          gradient: [Color(0xFF06B6D4), Color(0xFF2563EB)],
          accentColor: Color(0xFF22D3EE),
          icon: Icons.groups_2_rounded,
          isNativeReady: true,
        ),
        SubModuleItem(
          id: 'device',
          title: 'Safety Device & Interlock',
          desc: 'Pengecekan harian interlock gate robot, sensor light curtain, area scanner, dan tombol emergency stop.',
          route: '/safety/device',
          badge: 'NATIVE READY',
          gradient: [Color(0xFF2563EB), Color(0xFF4F46E5)],
          accentColor: Color(0xFF60A5FA),
          icon: Icons.memory_rounded,
          isNativeReady: true,
        ),
        SubModuleItem(
          id: 'bira',
          title: 'BIRA (Bimbingan & Arahan K3)',
          desc: 'Observasi perilaku selamat, bimbingan keselamatan langsung oleh GL/TL, dan evaluasi Unsafe Action.',
          route: '/safety/bira',
          badge: 'NATIVE READY',
          gradient: [Color(0xFF10B981), Color(0xFF0D9488)],
          accentColor: Color(0xFF34D399),
          icon: Icons.supervisor_account_rounded,
          isNativeReady: true,
        ),
        SubModuleItem(
          id: 'kpi',
          title: 'Safety KPI & Zero Accident',
          desc: 'Dashboard hari kerja selamat tanpa LTI, rekap nearmiss Hiyari Hatto, dan evaluasi audit safety patrol.',
          route: '/safety/kpi',
          badge: 'NATIVE READY',
          gradient: [Color(0xFFA855F7), Color(0xFFDB2777)],
          accentColor: Color(0xFFC084FC),
          icon: Icons.monitor_heart_rounded,
          isNativeReady: true,
        ),
        SubModuleItem(
          id: 'display-proses',
          title: 'Display Safety Proses KPI (GL Board)',
          desc: 'Lembar A4 standar List Up Problem Findings UB Assy. Format resmi GL Board lengkap dengan Print & PDF.',
          route: '/display/safety/proses',
          badge: 'A4 Board & PDF',
          gradient: [Color(0xFF10B981), Color(0xFF16A34A)],
          accentColor: Color(0xFF34D399),
          icon: Icons.verified_user_rounded,
        ),
        SubModuleItem(
          id: 'patrol-slide',
          title: 'Safety Patrol Monitor Slide',
          desc: 'Slide show presentasi Safety Patrol (Welcome & Hotline #sub) untuk tampilan layar TV shopfloor.',
          route: '/monitor?id=deck_mwbf55dj_yqye',
          badge: 'Slide Show TV',
          gradient: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
          accentColor: Color(0xFF38BDF8),
          icon: Icons.slideshow_rounded,
        ),
      ],
    ),
    'quality': const SubHubConfig(
      id: 'quality',
      code: 'Q',
      typeLabel: 'KPI Pillar',
      title: 'Quality (Kualitas Produk)',
      subtitle: 'Built-in Quality, Defect Zero, Poka-Yoke & QA Gates',
      tagline: 'Jangan Terima, Jangan Buat, Jangan Teruskan Cacat',
      pathLabel: '~/Underbody/Plant/Q • Built-in Quality',
      gradient: [Color(0xFF2563EB), Color(0xFF06B6D4), Color(0xFF4F46E5)],
      accentColor: Color(0xFF22D3EE),
      icon: Icons.verified_rounded,
      modules: [
        SubModuleItem(
          id: 'daily-out',
          title: 'Defect Out Flow',
          desc: 'Catat temuan defect Out Flow per tanggal dan regu Red & White. Total defect dan D/U otomatis lengkap dengan grafik & Kaizen.',
          route: '/quality/daily/out',
          badge: 'NATIVE READY',
          gradient: [Color(0xFF06B6D4), Color(0xFF2563EB)],
          accentColor: Color(0xFF22D3EE),
          icon: Icons.output_rounded,
          isNativeReady: true,
        ),
        SubModuleItem(
          id: 'daily-in',
          title: 'Defect In Proses',
          desc: 'Catat temuan defect In Proses per tanggal dan regu Red & White. Total defect dan D/U otomatis lengkap dengan grafik & Kaizen.',
          route: '/quality/daily/in',
          badge: 'NATIVE READY',
          gradient: [Color(0xFFF59E0B), Color(0xFFEA580C)],
          accentColor: Color(0xFFFBBF24),
          icon: Icons.account_tree_rounded,
          isNativeReady: true,
        ),
        SubModuleItem(
          id: 'display-sub',
          title: 'Display Sub KPI Quality',
          desc: 'Kertas 16:9 grafik D/U harian dan tabel Date 1-31 (Produksi, Defect, D/U) untuk UB Assy Red & White.',
          route: '/display/quality/sub',
          badge: 'Display Sub',
          gradient: [Color(0xFF6366F1), Color(0xFF7C3AED)],
          accentColor: Color(0xFF818CF8),
          icon: Icons.tv_rounded,
        ),
        SubModuleItem(
          id: 'display-proses',
          title: 'Display Proses KPI Quality',
          desc: 'Tampilan lembar asli List Up Problem defect Quality di GL Management Board.',
          route: '/display/quality/proses',
          badge: 'GL Board',
          gradient: [Color(0xFFA855F7), Color(0xFF4F46E5)],
          accentColor: Color(0xFFC084FC),
          icon: Icons.dashboard_rounded,
        ),
        SubModuleItem(
          id: 'display-kaizen',
          title: 'Display Kaizen Quality',
          desc: 'Rekapitulasi ide Kaizen penanggulangan cacat produk, poka-yoke, dan peningkatan mutu.',
          route: '/display/quality/kaizen',
          badge: 'Kaizen Board',
          gradient: [Color(0xFF10B981), Color(0xFF0D9488)],
          accentColor: Color(0xFF34D399),
          icon: Icons.auto_awesome_rounded,
        ),
        SubModuleItem(
          id: 'display-main',
          title: 'Display Main KPI Quality',
          desc: 'Kertas 16:9 grafik First-Pass Yield (FPY), defect rate, dan performa mutu Underbody.',
          route: '/display/quality/main',
          badge: 'Main KPI',
          gradient: [Color(0xFF3B82F6), Color(0xFF0891B2)],
          accentColor: Color(0xFF60A5FA),
          icon: Icons.bar_chart_rounded,
        ),
      ],
    ),
    'productivity': const SubHubConfig(
      id: 'productivity',
      code: 'P',
      typeLabel: 'KPI Pillar',
      title: 'Productivity (Produktivitas Lini)',
      subtitle: 'Checksheet A3, Efisiensi 1-31, Chokotei, CBU/CKD & Roster',
      tagline: 'Target 25 UPH • Takt Time 2.4m • Zero Delay',
      pathLabel: '~/Underbody/Plant/P • Productivity Suite',
      gradient: [Color(0xFF06B6D4), Color(0xFF2563EB), Color(0xFF4F46E5)],
      accentColor: Color(0xFF22D3EE),
      icon: Icons.precision_manufacturing_rounded,
      modules: [
        SubModuleItem(
          id: 'checksheet',
          title: 'Daily Production Checksheet',
          desc: 'Kanvas Kertas A3 interaktif: input Act/Plan per jam, Chokotei, Absensi, Output CBU/CKD, offline-first + cetak PDF.',
          route: '/productivity/checksheet',
          badge: 'NATIVE A3 READY',
          gradient: [Color(0xFF06B6D4), Color(0xFF2563EB)],
          accentColor: Color(0xFF22D3EE),
          icon: Icons.assignment_rounded,
          isNativeReady: true,
        ),
        SubModuleItem(
          id: 'monitoring',
          title: 'Monitoring Produksi & Efisiensi 1-31',
          desc: 'Rekapitulasi bulanan Act vs Plan, efisiensi internal, dan total menit delay tanggal 1-31 Red & White.',
          route: '/productivity/monitoring',
          badge: 'NATIVE READY',
          gradient: [Color(0xFF10B981), Color(0xFF0891B2)],
          accentColor: Color(0xFF34D399),
          icon: Icons.analytics_rounded,
          isNativeReady: true,
        ),
        SubModuleItem(
          id: 'chokotei',
          title: 'Analisis Chokotei & Pareto Mesin',
          desc: 'Diagram Pareto problem mesin, frekuensi stop, dan durasi kehilangan waktu produksi.',
          route: '/productivity/chokotei',
          badge: 'NATIVE READY',
          gradient: [Color(0xFFF43F5E), Color(0xFFEA580C)],
          accentColor: Color(0xFFFB7185),
          icon: Icons.troubleshoot_rounded,
          isNativeReady: true,
        ),
        SubModuleItem(
          id: 'chokotei-manual',
          title: 'Chokotei Manual',
          desc: 'Input cepat kejadian Chokotei manual per shift dan histori penanganan di lapangan.',
          route: '/productivity/chokotei-manual',
          badge: 'NATIVE READY',
          gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
          accentColor: Color(0xFFFBBF24),
          icon: Icons.edit_note_rounded,
          isNativeReady: true,
        ),
        SubModuleItem(
          id: 'kaizen-report',
          title: 'Kaizen Report',
          desc: 'Laporan penanggulangan problem & Kaizen Productivity untuk GL Management Board.',
          route: '/productivity/kaizen',
          badge: 'Kaizen Board',
          gradient: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          accentColor: Color(0xFFA78BFA),
          icon: Icons.auto_awesome_rounded,
        ),
        SubModuleItem(
          id: 'print-a3',
          title: 'Canvas A3 Landscape (Print Mode)',
          desc: 'Buka langsung kanvas A3 siap cetak PDF dan pratinjau layout kertas resmi Underbody.',
          route: '/productivity/print',
          badge: 'NATIVE A3 READY',
          gradient: [Color(0xFF0EA5E9), Color(0xFF1D4ED8)],
          accentColor: Color(0xFF38BDF8),
          icon: Icons.print_rounded,
          isNativeReady: true,
        ),
        SubModuleItem(
          id: 'cbu',
          title: 'Monitoring Model CBU 1-31',
          desc: 'Rekap output harian per model CBU (Innova Zenix, Fortuner, Kijang Innova) tanggal 1-31.',
          route: '/productivity/cbu',
          badge: 'Model CBU',
          gradient: [Color(0xFF3B82F6), Color(0xFF4F46E5)],
          accentColor: Color(0xFF60A5FA),
          icon: Icons.directions_car_filled_rounded,
        ),
        SubModuleItem(
          id: 'ckd',
          title: 'Monitoring Part CKD Export 1-31',
          desc: 'Tracking produksi part CKD Export (57403-KK010 & 57404-KK010) harian dan akumulasi bulanan.',
          route: '/productivity/ckd',
          badge: 'CKD Export',
          gradient: [Color(0xFF14B8A6), Color(0xFF059669)],
          accentColor: Color(0xFF2DD4BF),
          icon: Icons.inventory_2_rounded,
        ),
        SubModuleItem(
          id: 'shift-template',
          title: 'Master Jam Kerja & Template Shift',
          desc: 'Pengaturan jam kerja normal, overtime, istirahat, dan template slot waktu produksi.',
          route: '/productivity/shift-template',
          badge: 'Master Shift',
          gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          accentColor: Color(0xFF818CF8),
          icon: Icons.schedule_rounded,
        ),
        SubModuleItem(
          id: 'settings',
          title: 'Pengaturan Lini & Opsi Produksi',
          desc: 'Konfigurasi Role akses, Line Name, Takt Time, URL API server, dan sync SharePoint.',
          route: '/productivity/settings',
          badge: 'NATIVE READY',
          gradient: [Color(0xFF475569), Color(0xFF1E293B)],
          accentColor: Color(0xFF94A3B8),
          icon: Icons.tune_rounded,
          isNativeReady: true,
        ),
        SubModuleItem(
          id: 'roster',
          title: 'Struktural Tim & Roster Anggota',
          desc: 'Daftar GL, TL, dan operator regu Red & White beserta posisi kerja di lini.',
          route: '/productivity/roster',
          badge: 'Manpower',
          gradient: [Color(0xFFEC4899), Color(0xFFBE185D)],
          accentColor: Color(0xFFF472B6),
          icon: Icons.badge_rounded,
        ),
        SubModuleItem(
          id: 'absensi',
          title: 'Rekap & Analisis Absensi Tim',
          desc: 'Persentase kehadiran, cuti, sakit, ijin, dan training bulanan regu Red & White.',
          route: '/productivity/absensi',
          badge: 'Absensi',
          gradient: [Color(0xFFA855F7), Color(0xFF7C3AED)],
          accentColor: Color(0xFFC084FC),
          icon: Icons.how_to_reg_rounded,
        ),
        SubModuleItem(
          id: 'after-prod',
          title: 'UBAI After-Prod (Penugasan 5S)',
          desc: 'Pembagian area 5S akhir shift secara adil dan otomatis untuk anggota tim.',
          route: '/productivity/after-prod',
          badge: 'After Prod 5S',
          gradient: [Color(0xFF10B981), Color(0xFF047857)],
          accentColor: Color(0xFF34D399),
          icon: Icons.cleaning_services_rounded,
        ),
        SubModuleItem(
          id: 'tasks',
          title: 'Task Manager Post-It Hub',
          desc: 'Papan tugas interaktif Post-It untuk koordinasi antar shift Red & White.',
          route: '/productivity/tasks',
          badge: 'Task Hub',
          gradient: [Color(0xFFEAB308), Color(0xFFCA8A04)],
          accentColor: Color(0xFFFACC15),
          icon: Icons.sticky_note_2_rounded,
        ),
      ],
    ),
    'cost': const SubHubConfig(
      id: 'cost',
      code: 'C',
      typeLabel: 'KPI Pillar',
      title: 'Cost (Biaya & Efisiensi)',
      subtitle: 'Lean Budget, Scrap Reduction, Energy Saving & Kaizen Cost',
      tagline: 'Eliminasi 7 Pemborosan (Muda) Demi Efisiensi Maksimal',
      pathLabel: '~/Underbody/Plant/C • Lean Budget',
      gradient: [Color(0xFFF59E0B), Color(0xFFEAB308), Color(0xFFE11D48)],
      accentColor: Color(0xFFFBBF24),
      icon: Icons.savings_rounded,
      modules: [
        SubModuleItem(
          id: 'cost-daily',
          title: 'Control Cost Daily (UB Assy)',
          desc: 'Catatan pemakaian harian per item (O. Supply, consumable tools, dll.) untuk regu Red dan White.',
          route: '/cost/daily',
          badge: 'Harian Red & White',
          gradient: [Color(0xFFF59E0B), Color(0xFFCA8A04)],
          accentColor: Color(0xFFFBBF24),
          icon: Icons.table_chart_rounded,
        ),
        SubModuleItem(
          id: 'cost-temuan',
          title: 'Temuan Cost (List Up Problem)',
          desc: 'Pencatatan pemborosan atau pemakaian berlebih per tanggal dan regu, langsung tampil di Display Proses KPI Cost.',
          route: '/cost/temuan',
          badge: 'CRUD Temuan',
          gradient: [Color(0xFFF43F5E), Color(0xFFDC2626)],
          accentColor: Color(0xFFFB7185),
          icon: Icons.assignment_late_rounded,
        ),
        SubModuleItem(
          id: 'display-sub',
          title: 'Display Sub KPI Cost',
          desc: 'Kertas 16:9 grafik pemakaian bulanan dan tabel harian Date 1-31 (Plan vs Act) untuk UB Assy Red & White.',
          route: '/display/cost/sub',
          badge: 'Display Sub',
          gradient: [Color(0xFF06B6D4), Color(0xFF2563EB)],
          accentColor: Color(0xFF22D3EE),
          icon: Icons.tv_rounded,
        ),
        SubModuleItem(
          id: 'display-proses',
          title: 'Display Proses KPI Cost',
          desc: 'Tampilan lembar asli temuan problem pemborosan cost di GL Management Board.',
          route: '/display/cost/proses',
          badge: 'GL Board',
          gradient: [Color(0xFFA855F7), Color(0xFF4F46E5)],
          accentColor: Color(0xFFC084FC),
          icon: Icons.dashboard_rounded,
        ),
        SubModuleItem(
          id: 'display-kaizen',
          title: 'Display Kaizen Cost',
          desc: 'Rekapitulasi ide Kaizen efisiensi biaya, penghematan budget, dan eliminasi 7 Muda lini Underbody.',
          route: '/display/cost/kaizen',
          badge: 'Kaizen Board',
          gradient: [Color(0xFF10B981), Color(0xFF0D9488)],
          accentColor: Color(0xFF34D399),
          icon: Icons.auto_awesome_rounded,
        ),
        SubModuleItem(
          id: 'display-main',
          title: 'Display Main KPI Cost',
          desc: 'Kertas 16:9 grafik performa pencapaian budget dan total cost saving bulanan periode fiskal.',
          route: '/display/cost/main',
          badge: 'Main KPI',
          gradient: [Color(0xFF3B82F6), Color(0xFF0891B2)],
          accentColor: Color(0xFF60A5FA),
          icon: Icons.bar_chart_rounded,
        ),
      ],
    ),
    'hr': const SubHubConfig(
      id: 'hr',
      code: 'HR',
      typeLabel: 'KPI Pillar',
      title: 'HR & Morale (SDM & Disiplin)',
      subtitle: 'Manpower Roster, Kehadiran Tim, Skill Matrix & Motivasi',
      tagline: 'Orang yang Tepat, Keterampilan Unggul, Semangat Membara',
      pathLabel: '~/Underbody/Plant/HR • HR & Morale',
      gradient: [Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFFC026D3)],
      accentColor: Color(0xFFC084FC),
      icon: Icons.groups_rounded,
      modules: [
        SubModuleItem(
          id: 'bacadoa',
          title: 'Jadwal & Matrik Baca Doa',
          desc: 'Matrik rotasi baca doa briefing pagi (Asare) tanggal 1-31 per regu Red & White, rotasi otomatis & cetak A4.',
          route: '/bacadoa',
          badge: 'Matrik A4',
          gradient: [Color(0xFF10B981), Color(0xFF0D9488)],
          accentColor: Color(0xFF34D399),
          icon: Icons.menu_book_rounded,
        ),
        SubModuleItem(
          id: 'rankmp',
          title: 'Rank MP (List SharePoint)',
          desc: 'Database akumulasi poin bulanan operator dari pimpin doa & senam, disiplin kehadiran, dan ekspor Excel.',
          route: '/hr/rankmp',
          badge: 'SharePoint List',
          gradient: [Color(0xFF14B8A6), Color(0xFF2563EB)],
          accentColor: Color(0xFF2DD4BF),
          icon: Icons.emoji_events_rounded,
        ),
        SubModuleItem(
          id: 'idea',
          title: 'Monthly Idea Record',
          desc: 'Isi Idea harian dan Pembuat baru per regu Red & White, Jumlah MP, serta target Idea/MP & Participant %.',
          route: '/hr/idea',
          badge: 'Idea / MP',
          gradient: [Color(0xFF8B5CF6), Color(0xFF9333EA)],
          accentColor: Color(0xFFC084FC),
          icon: Icons.lightbulb_rounded,
        ),
        SubModuleItem(
          id: 'idnu',
          title: 'Idea',
          desc: 'Kirim Kaizen SQPCHR & Voice Member ke portal innovation.toyota.co.id pakai NOREG, pantau Approve LH & Paid.',
          route: '/idnu',
          badge: 'Innovation',
          gradient: [Color(0xFF06B6D4), Color(0xFF2563EB)],
          accentColor: Color(0xFF22D3EE),
          icon: Icons.tips_and_updates_rounded,
        ),
        SubModuleItem(
          id: 'temuan',
          title: 'Temuan & Kaizen HR-Dev',
          desc: 'Insert dan update temuan problem per tanggal dan regu lengkap dengan tombol Kaizen per temuan.',
          route: '/hr/temuan',
          badge: 'CRUD Temuan',
          gradient: [Color(0xFFF59E0B), Color(0xFFEA580C)],
          accentColor: Color(0xFFFBBF24),
          icon: Icons.checklist_rounded,
        ),
        SubModuleItem(
          id: 'display-sub',
          title: 'Display Sub KPI HR-Dev',
          desc: 'Kertas 16:9 grafik dan tabel data bulanan rasio Idea/MP & partisipasi anggota regu Red & White.',
          route: '/display/hr-dev/sub',
          badge: 'Display Sub',
          gradient: [Color(0xFF06B6D4), Color(0xFF2563EB)],
          accentColor: Color(0xFF22D3EE),
          icon: Icons.tv_rounded,
        ),
        SubModuleItem(
          id: 'display-proses',
          title: 'Display Proses KPI HR-Dev',
          desc: 'Tampilan lembar asli temuan problem HR-Dev & Morale di GL Management Board.',
          route: '/display/hr-dev/proses',
          badge: 'GL Board',
          gradient: [Color(0xFFA855F7), Color(0xFF4F46E5)],
          accentColor: Color(0xFFC084FC),
          icon: Icons.dashboard_rounded,
        ),
        SubModuleItem(
          id: 'display-kaizen',
          title: 'Display Kaizen HR-Dev',
          desc: 'Rekapitulasi Kaizen perbaikan SDM, kenyamanan kerja, dan motivasi tim.',
          route: '/display/hr-dev/kaizen',
          badge: 'Kaizen Board',
          gradient: [Color(0xFF10B981), Color(0xFF0D9488)],
          accentColor: Color(0xFF34D399),
          icon: Icons.auto_awesome_rounded,
        ),
        SubModuleItem(
          id: 'display-main',
          title: 'Display Main KPI HR-Dev',
          desc: 'Kertas 16:9 Monthly Idea Record (Ratio & Participant): tabel Apr-Mar dan grafik Red & White.',
          route: '/display/hr-dev/main',
          badge: 'Main KPI',
          gradient: [Color(0xFF6366F1), Color(0xFF7C3AED)],
          accentColor: Color(0xFF818CF8),
          icon: Icons.bar_chart_rounded,
        ),
      ],
    ),
    'env': const SubHubConfig(
      id: 'env',
      code: 'E',
      typeLabel: 'KPI Pillar',
      title: 'Environment (Lingkungan & Energi)',
      subtitle: 'Energy Saving, Air Leakage Reduction, 3R & Green Plant',
      tagline: 'Efisiensi Energi Maksimal Menuju Green Shopfloor Zero Emission',
      pathLabel: '~/Underbody/Plant/E • Green Plant',
      gradient: [Color(0xFF10B981), Color(0xFF14B8A6), Color(0xFF16A34A)],
      accentColor: Color(0xFF34D399),
      icon: Icons.eco_rounded,
      modules: [
        SubModuleItem(
          id: 'env-air-leakage',
          title: 'Air Leakage (Checksheet & Temuan #lub)',
          desc: 'Checksheet harian kebocoran angin, temuan problem #lub, serta penanggulangan & Kaizen #klub di SharePoint List.',
          route: '/env/air-leakage',
          badge: 'SharePoint #lub · #klub',
          gradient: [Color(0xFF06B6D4), Color(0xFF059669)],
          accentColor: Color(0xFF22D3EE),
          icon: Icons.air_rounded,
        ),
        SubModuleItem(
          id: 'env-daily',
          title: 'Control Daily Activity (Energi Listrik)',
          desc: 'Pencatatan konsumsi energi listrik harian (kWh) per regu Red dan White, evaluasi target, dan akumulasi bulanan.',
          route: '/env/daily',
          badge: 'Harian Red & White',
          gradient: [Color(0xFF10B981), Color(0xFF0D9488)],
          accentColor: Color(0xFF34D399),
          icon: Icons.bolt_rounded,
        ),
        SubModuleItem(
          id: 'env-temuan',
          title: 'Temuan Lingkungan & Kaizen',
          desc: 'Pencatatan temuan kebocoran angin (Air Leakage), pemborosan energi, dan abnormalitas lingkungan + Kaizen Report.',
          route: '/env/temuan',
          badge: 'CRUD & Kaizen',
          gradient: [Color(0xFFF59E0B), Color(0xFFEA580C)],
          accentColor: Color(0xFFFBBF24),
          icon: Icons.assignment_late_rounded,
        ),
        SubModuleItem(
          id: 'display-sub',
          title: 'Display Sub KPI Environment',
          desc: 'Kertas 16:9 grafik konsumsi energi listrik harian (kWh) dan tabel Date 1-31 (Plan vs Act) Red & White.',
          route: '/display/env/sub',
          badge: 'Display Sub',
          gradient: [Color(0xFF06B6D4), Color(0xFF2563EB)],
          accentColor: Color(0xFF22D3EE),
          icon: Icons.tv_rounded,
        ),
        SubModuleItem(
          id: 'display-proses',
          title: 'Display Proses KPI Environment',
          desc: 'Tampilan lembar asli temuan problem lingkungan (Air Leakage & Energi) di GL Management Board.',
          route: '/display/env/proses',
          badge: 'GL Board',
          gradient: [Color(0xFFA855F7), Color(0xFF4F46E5)],
          accentColor: Color(0xFFC084FC),
          icon: Icons.dashboard_rounded,
        ),
        SubModuleItem(
          id: 'display-kaizen',
          title: 'Display Kaizen Environment',
          desc: 'Rekapitulasi Kaizen Report area E (perbaikan kebocoran angin, isolasi panas, penghematan energi).',
          route: '/display/env/kaizen',
          badge: 'Kaizen Board',
          gradient: [Color(0xFF10B981), Color(0xFF0D9488)],
          accentColor: Color(0xFF34D399),
          icon: Icons.auto_awesome_rounded,
        ),
        SubModuleItem(
          id: 'display-main',
          title: 'Display Main KPI Environment',
          desc: 'Kertas 16:9 grafik tren tahunan Air Leakage dan target lingkungan periode fiskal.',
          route: '/display/env/main',
          badge: 'Main KPI',
          gradient: [Color(0xFF84CC16), Color(0xFF16A34A)],
          accentColor: Color(0xFFA3E635),
          icon: Icons.bar_chart_rounded,
        ),
      ],
    ),
  };
}
