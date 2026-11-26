import 'package:flutter/material.dart';

import '../../core/theme.dart';

class _DocSection {
  const _DocSection({
    required this.id,
    required this.title,
    required this.summary,
    required this.icon,
    required this.color,
    required this.points,
    this.note,
  });

  final String id;
  final String title;
  final String summary;
  final IconData icon;
  final Color color;
  final List<String> points;
  final String? note;
}

class DocsScreen extends StatefulWidget {
  const DocsScreen({super.key});

  @override
  State<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen> {
  String _query = '';

  static const List<_DocSection> _sections = [
    _DocSection(
      id: 'ringkasan',
      title: 'Ringkasan Sistem UBnetwork',
      summary: 'Hub aplikasi shopfloor lini Underbody (UB Assy) untuk regu Red & White.',
      icon: Icons.hub_rounded,
      color: UbColors.cyan,
      points: [
        '6 Pilar Manufaktur: Safety (S), Quality (Q), Productivity (P), Cost (C), HR-Dev (HR), dan Environment (E).',
        'Display KPI: 28 kertas KPI (7 kolom × 4 baris) untuk GL Management Board & cetak PDF.',
        'Checksheet A3 Interaktif: bisa di-pan, zoom, isi per jam, auto carry-over No. Body, dan sync ke MySQL + SharePoint.',
        'Bot Hotline UBAI: input temuan langsung dari WhatsApp lewat tagar #sub, #qub, #pub, #vm.',
      ],
      note: 'Prinsip utama: input sekali, tampil otomatis di Monitoring, Display, dan Laporan.',
    ),
    _DocSection(
      id: 'login',
      title: 'Login & Keamanan (1:1 Next.js)',
      summary: '3 metode login resmi terhubung ke server UBnetwork.',
      icon: Icons.lock_person_rounded,
      color: UbColors.emerald,
      points: [
        'Noreg & Telp: masukkan NOREG + 6 digit terakhir nomor HP/WA yang terdaftar di Roster.',
        'OTP WhatsApp: masukkan NOREG → terima kode OTP 6 digit di WhatsApp → ketik di 6 kotak angka.',
        'Login Sistem: masuk dengan Password Gerbang / Shift Red / Shift White.',
        'Role shift otomatis menyesuaikan user yang login (RED, WHITE, atau ALL/ADMIN).',
      ],
    ),
    _DocSection(
      id: 'checksheet',
      title: 'Checksheet Produksi A3 & Sync Online',
      summary: 'Alur kerja Checksheet Productivity berbasis shift hari ini.',
      icon: Icons.assignment_rounded,
      color: UbColors.primaryBlue,
      points: [
        'Saat dibuka, Checksheet otomatis mengambil tanggal hari ini (WIB) & shift user yang login.',
        'Data diambil secara online dari server MySQL (action=get_report) agar sinkron antar perangkat.',
        'Tap ikon Wi-Fi di pojok kanan atas untuk memuat ulang data terbaru dari server.',
        'Tap tombol Kirim untuk menyimpan perubahan ke MySQL & SharePoint NUDB.',
      ],
      note: 'Jika ikon Wi-Fi berwarna merah (Offline), periksa koneksi internet sebelum melakukan sinkronisasi.',
    ),
    _DocSection(
      id: 'pilar',
      title: 'Modul Operasional per Pilar',
      summary: 'Ringkasan modul Safety, Quality, Productivity, Cost, HR, dan Environment.',
      icon: Icons.layers_rounded,
      color: UbColors.purple,
      points: [
        'Safety (S): Temuan Safety (Matriks Risiko Aa–Cc), KYT Monitoring 12 Bulan, Group SGA, Safety Device, BIRA, Safety KPI.',
        'Quality (Q): Defect Out Flow & Defect In Proses (Grafik D/U, Tabel 1–31, Zero Defect, Temuan CRUD).',
        'Productivity (P): Checksheet A3, Monitoring 1–31, Chokotei Pareto 80/20 & Manual, CBU/CKD 1–31, Roster & Absensi.',
        'Quick App Dx: Henkaten Board 4M, Post-It Board, UBdrive SharePoint, dan Dokumentasi Sistem.',
      ],
    ),
    _DocSection(
      id: 'ubdrive',
      title: 'UBdrive (SharePoint NUDB)',
      summary: 'Kelola dokumen, folder, dan arsip berbagi lini Underbody.',
      icon: Icons.cloud_done_rounded,
      color: UbColors.amber,
      points: [
        'Telusuri folder SharePoint berakar di 03. Drive secara real-time.',
        'Buat folder baru dengan tombol ikon folder+ di pojok kanan atas.',
        'Tap file untuk menyalin link unduhan resmi SharePoint ke clipboard.',
        'Hapus file/folder hanya untuk role Leader (masuk ke Recycle Bin SharePoint).',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? _sections
        : _sections.where((s) {
            return s.title.toLowerCase().contains(q) ||
                s.summary.toLowerCase().contains(q) ||
                s.points.any((p) => p.toLowerCase().contains(q));
          }).toList();

    return Scaffold(
      backgroundColor: UbColors.bg,
      appBar: AppBar(
        backgroundColor: UbColors.bg,
        title: const Text(
          'Dokumentasi Sistem',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Cari panduan, modul, atau cara penggunaan...',
                prefixIcon: Icon(Icons.search_rounded, size: 19),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
              itemCount: shown.length,
              itemBuilder: (ctx, idx) {
                final sec = shown[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: UbColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: sec.color.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: sec.color.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(sec.icon, color: sec.color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sec.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  sec.summary,
                                  style: const TextStyle(
                                    color: UbColors.textMuted,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...sec.points.map((pt) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.chevron_right_rounded, size: 16, color: sec.color),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    pt,
                                    style: const TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 12.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      if (sec.note != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: sec.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: sec.color.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16, color: sec.color),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sec.note!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
