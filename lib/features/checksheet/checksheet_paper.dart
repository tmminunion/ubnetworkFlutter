import 'package:flutter/material.dart';

import '../../models/checksheet_models.dart';

/// Kertas Digital A3 Proporsi 950px — Clone 1:1 UBnetwork Daily Production Checksheet.
class ChecksheetPaper extends StatelessWidget {
  const ChecksheetPaper({
    super.key,
    required this.report,
    required this.stats,
    required this.onTapHeader,
    required this.onTapSlot,
    required this.onAutoFillAll,
    required this.onTapCbu,
    required this.onTapCkd,
    required this.onTapAbsen,
    required this.onTapNoBody,
    required this.onTapOvertime,
  });

  final ChecksheetReport report;
  final ChecksheetStats stats;
  final VoidCallback onTapHeader;
  final void Function(int slotNo) onTapSlot;
  final VoidCallback onAutoFillAll;
  final VoidCallback onTapCbu;
  final VoidCallback onTapCkd;
  final VoidCallback onTapAbsen;
  final VoidCallback onTapNoBody;
  final VoidCallback onTapOvertime;

  static const _mono = TextStyle(fontFamily: 'monospace', color: Color(0xFF0F172A));

  String _breakRange() {
    HourlySlot? s4;
    HourlySlot? s5;
    for (final s in report.slots) {
      if (s.no == 4) s4 = s;
      if (s.no == 5) s5 = s;
    }
    if (s4 != null && s5 != null) {
      final p4 = s4.timeRange.split('-');
      final p5 = s5.timeRange.split('-');
      if (p4.length == 2 && p5.length == 2 && p4[1].trim() != p5[0].trim()) {
        return '${p4[1].trim()} - ${p5[0].trim()}';
      }
    }
    return report.session == 'night' ? '00:00 - 00:45' : '11:45 - 12:30';
  }

  @override
  Widget build(BuildContext context) {
    final dtCompact = report.tanggal.replaceAll('-', '');
    return DefaultTextStyle(
      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
      child: Container(
        width: 950,
        constraints: const BoxConstraints(minHeight: 1340),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: const Color(0xFF94A3B8), width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 40, offset: Offset(0, 18)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(dtCompact),
            const SizedBox(height: 12),
            _buildHourlySection(),
            const SizedBox(height: 14),
            _buildCbuCkdRow(),
            const SizedBox(height: 12),
            _buildBottomFourBoxes(),
            if (stats.intProblems.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildIntProblemsBox(),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF94A3B8))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SISTEM INFORMASI MANUFAKTUR DIGITAL • UBnetwork',
                    style: _mono.copyWith(fontSize: 10, color: const Color(0xFF64748B)),
                  ),
                  Text(
                    'DIGITAL FORM ID: UB-CHK-$dtCompact-${report.shift}',
                    style: _mono.copyWith(fontSize: 10, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String dtCompact) {
    final isRed = report.shift == 'RED';
    final isNight = report.session == 'night';
    return InkWell(
      onTap: onTapHeader,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
            child: Column(
              children: [
                // Baris 1: 3 Kolom Kop TMMIN
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 30,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            border: Border(right: BorderSide(color: Colors.black, width: 2)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'PT. TOYOTA MOTOR MFG. INDONESIA',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'PRESS & WELDING PRODUCTION DIVISION',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                'WELDING BODY#1 DEPT',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 50,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(right: BorderSide(color: Colors.black, width: 2)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'PRODUCTION CONTROL BOARD RECORD',
                                style: _mono.copyWith(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 1),
                              ),
                              const Text(
                                'DAILY PRODUCTION REPORT',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1, color: Color(0xFF020617)),
                              ),
                              Text(
                                'DOC ID: TMMIN-UB-CHK-$dtCompact-${report.shift}',
                                style: _mono.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 20,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: const Color(0xFFF8FAFC),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                            decoration: BoxDecoration(
                              color: isRed ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isRed ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isNight ? '🌙 NIGHT SHIFT' : '☀️ DAY SHIFT',
                                  style: _mono.copyWith(fontSize: 8.5, fontWeight: FontWeight.w700, color: const Color(0xFF64748B)),
                                ),
                                Text(
                                  report.shift,
                                  style: _mono.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: isRed ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.only(top: 2),
                                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFCBD5E1)))),
                                  child: Text(
                                    report.workMode == 'puasa' ? '🌙 BULAN RAMADHAN' : 'STANDARD PRODUCTION',
                                    style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Baris 2: Meta Grid Table
                Container(
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black, width: 2))),
                  child: Column(
                    children: [
                      // Header Row
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            _metaHeadCell('TANGGAL', 16),
                            _metaHeadCell('LINE PRODUKSI', 18),
                            Expanded(
                              flex: 30,
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE2E8F0),
                                      border: Border(
                                        right: BorderSide(color: Colors.black),
                                        bottom: BorderSide(color: Colors.black),
                                      ),
                                    ),
                                    child: const Text(
                                      'SHIFT',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _metaSubHeadCell('RED'),
                                      _metaSubHeadCell('WHITE'),
                                      _metaSubHeadCell('DAY / NIGHT'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            _metaHeadCell('TAKT TIME', 14),
                            _metaHeadCell('PIC (PERSON IN CHARGE)', 22, last: true),
                          ],
                        ),
                      ),
                      // Value Row
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            _metaValCell(UbMasterData.formatDDMMYYYY(report.tanggal), 16, bold: true),
                            _metaValCell(report.lineName.toUpperCase(), 18, bold: true),
                            Expanded(
                              flex: 10,
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: isRed ? const Color(0xFFFEE2E2) : Colors.white,
                                  border: const Border(right: BorderSide(color: Colors.black)),
                                ),
                                child: Text(
                                  isRed ? '✔' : '–',
                                  style: _mono.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: isRed ? const Color(0xFFB91C1C) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 10,
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                decoration: BoxDecoration(
                                  color: !isRed ? const Color(0xFFF1F5F9) : Colors.white,
                                  border: const Border(right: BorderSide(color: Colors.black)),
                                ),
                                child: Text(
                                  !isRed ? '✔' : '–',
                                  style: _mono.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: !isRed ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 10,
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black))),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        color: !isNight ? const Color(0xFFFBBF24) : const Color(0xFFF1F5F9),
                                        child: Text(
                                          'D',
                                          style: _mono.copyWith(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: !isNight ? Colors.black : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                      Container(width: 1, height: 14, color: Colors.black),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        color: isNight ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                        child: Text(
                                          'N',
                                          style: _mono.copyWith(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: isNight ? Colors.white : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            _metaValCell(
                              report.taktTime.toString().replaceAll('.', ','),
                              14,
                              bold: true,
                              color: const Color(0xFF1D4ED8),
                              fontSize: 13.5,
                            ),
                            _metaValCell(
                              report.picName.split('/').first.trim().toUpperCase(),
                              22,
                              bold: true,
                              color: const Color(0xFF172554),
                              last: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isNight && report.otAwal != 'none')
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFCD34D)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '⚡ PRE-SHIFT OVERTIME (SLOT 1): ${report.otAwal == '30m' ? '30 MENIT (20:30 - 21:00)' : '1 JAM (20:00 - 21:00)'}',
                    style: _mono.copyWith(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF78350F)),
                  ),
                  const Text(
                    'Target kumulatif lini dihitung mulai Slot No 1',
                    style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Color(0xFF92400E)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _metaHeadCell(String text, int flex, {bool last = false}) => Expanded(
        flex: flex,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            border: Border(
              right: last ? BorderSide.none : const BorderSide(color: Colors.black),
              bottom: const BorderSide(color: Colors.black),
            ),
          ),
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
        ),
      );

  Widget _metaSubHeadCell(String text) => Expanded(
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: const BoxDecoration(
            color: Color(0xFFCBD5E1),
            border: Border(
              right: BorderSide(color: Colors.black),
              bottom: BorderSide(color: Colors.black),
            ),
          ),
          child: Text(text, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF334155))),
        ),
      );

  Widget _metaValCell(String text, int flex, {bool bold = false, Color? color, double fontSize = 11, bool last = false}) =>
      Expanded(
        flex: flex,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(right: last ? BorderSide.none : const BorderSide(color: Colors.black)),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: _mono.copyWith(
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: color ?? const Color(0xFF0F172A),
            ),
          ),
        ),
      );

  Widget _buildHourlySection() {
    final breakRange = _breakRange();
    final rows = <Widget>[];

    // Table Header
    rows.add(
      Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE2E8F0),
          border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _th('No', 34),
              _th('Jam Kerja', 108, align: Alignment.centerLeft),
              _th('PLAN', 48, bg: const Color(0xFFF0F9FF)),
              _th('ACT', 48, bg: const Color(0xFFECFDF5)),
              _th('DIFF', 48, bg: const Color(0xFFF1F5F9)),
              _th('Line/ST', 52, fontSize: 10),
              Expanded(child: _thFlex('Problem / Kejadian Line Stop', align: Alignment.centerLeft)),
              _th('Countermeasure', 155, align: Alignment.centerLeft),
              _th('EFF (%)', 52, bg: const Color(0xFFEFF6FF), last: true, fontSize: 10),
            ],
          ),
        ),
      ),
    );

    for (final cs in stats.computedSlots) {
      final r = cs.slot;
      final isBlocked = r.isBlocked;
      final hasProb = r.problems.isNotEmpty || r.problem.trim().isNotEmpty;
      final isFilled = r.act != null;
      final slotDiff = isFilled ? (r.act! - r.plan) : null;

      final rowBg = isBlocked
          ? const Color(0xFFE2E8F0)
          : (hasProb ? const Color(0xFFFFF1F2) : Colors.white);

      rows.add(
        InkWell(
          onTap: () => onTapSlot(r.no),
          child: Container(
            decoration: BoxDecoration(
              color: rowBg,
              border: const Border(bottom: BorderSide(color: Colors.black)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _tdFixed('${r.no}', 34, bold: true, color: isBlocked ? const Color(0xFF94A3B8) : const Color(0xFF334155)),
                  _tdFixed(r.timeRange, 108, align: Alignment.centerLeft, color: isBlocked ? const Color(0xFF94A3B8) : const Color(0xFF0F172A)),
                  _twoRowCell(
                    width: 48,
                    top: isBlocked ? '-' : '${r.plan}',
                    bot: isBlocked ? '-' : '${cs.cumPlan}',
                    topColor: isBlocked ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                    botBg: isBlocked ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
                    botColor: isBlocked ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                  _twoRowCell(
                    width: 48,
                    top: (isBlocked || !isFilled) ? '-' : '${r.act}',
                    bot: (isBlocked || cs.cumAct == null) ? '-' : '${cs.cumAct}',
                    topColor: (isBlocked || !isFilled) ? const Color(0xFF94A3B8) : const Color(0xFF020617),
                    topBold: isFilled && !isBlocked,
                    botBg: (isBlocked || cs.cumAct == null) ? (isBlocked ? const Color(0xFFE2E8F0) : const Color(0xFFF8FAFC)) : const Color(0xFFECFDF5),
                    botColor: (isBlocked || cs.cumAct == null) ? const Color(0xFF94A3B8) : const Color(0xFF065F46),
                    botBold: cs.cumAct != null && !isBlocked,
                  ),
                  _twoRowCell(
                    width: 48,
                    top: (isBlocked || slotDiff == null || slotDiff == 0) ? '-' : (slotDiff > 0 ? '+$slotDiff' : '$slotDiff'),
                    bot: (isBlocked || cs.cumDiff == null || cs.cumDiff == 0) ? '-' : (cs.cumDiff! > 0 ? '+${cs.cumDiff}' : '${cs.cumDiff}'),
                    topColor: (isBlocked || slotDiff == null)
                        ? const Color(0xFF94A3B8)
                        : (slotDiff > 0 ? const Color(0xFF047857) : (slotDiff == 0 ? const Color(0xFF475569) : const Color(0xFFDC2626))),
                    botBg: (isBlocked || cs.cumDiff == null)
                        ? (isBlocked ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9))
                        : (cs.cumDiff! > 0 ? const Color(0xFFECFDF5) : (cs.cumDiff == 0 ? const Color(0xFFF1F5F9) : const Color(0xFFFFF1F2))),
                    botColor: (isBlocked || cs.cumDiff == null)
                        ? const Color(0xFF94A3B8)
                        : (cs.cumDiff! > 0 ? const Color(0xFF065F46) : (cs.cumDiff == 0 ? const Color(0xFF475569) : const Color(0xFFBE123C))),
                    topBold: true,
                    botBold: true,
                  ),
                  _tdFixed(
                    isBlocked
                        ? '-'
                        : (r.problems.isNotEmpty
                            ? r.problems.map((p) => p.lineStation.isNotEmpty ? p.lineStation : p.machineName).where((x) => x.isNotEmpty).toSet().join('\n')
                            : (hasProb && r.lineStation.isNotEmpty ? r.lineStation : '-')),
                    52,
                    fontSize: 10,
                    bold: true,
                    color: isBlocked ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black))),
                      alignment: Alignment.centerLeft,
                      child: _buildProblemCell(r, isBlocked, isFilled),
                    ),
                  ),
                  Container(
                    width: 155,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black))),
                    alignment: Alignment.centerLeft,
                    child: isBlocked
                        ? const SizedBox.shrink()
                        : Text(
                            r.problems.isNotEmpty
                                ? r.problems.map((p) => p.countermeasure.isNotEmpty ? p.countermeasure : '-').join('\n')
                                : (r.countermeasure.isNotEmpty ? r.countermeasure : '-'),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: (r.problems.isEmpty && r.countermeasure.isEmpty) ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                            ),
                          ),
                  ),
                  _twoRowCell(
                    width: 52,
                    top: (isBlocked || cs.hourEff == '-') ? '-' : '${cs.hourEff}%',
                    bot: (isBlocked || cs.cumEff == '-') ? '-' : '${cs.cumEff}%',
                    topColor: (isBlocked || cs.hourEff == '-')
                        ? const Color(0xFF94A3B8)
                        : ((double.tryParse(cs.hourEff) ?? 0) >= 100
                            ? const Color(0xFF047857)
                            : ((double.tryParse(cs.hourEff) ?? 0) >= 90 ? const Color(0xFF1D4ED8) : const Color(0xFFDC2626))),
                    botBg: (isBlocked || cs.cumEff == '-')
                        ? (isBlocked ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9))
                        : ((double.tryParse(cs.cumEff) ?? 0) >= 100
                            ? const Color(0xFFECFDF5)
                            : ((double.tryParse(cs.cumEff) ?? 0) >= 90 ? const Color(0xFFEFF6FF) : const Color(0xFFFFF1F2))),
                    botColor: (isBlocked || cs.cumEff == '-')
                        ? const Color(0xFF94A3B8)
                        : ((double.tryParse(cs.cumEff) ?? 0) >= 100
                            ? const Color(0xFF065F46)
                            : ((double.tryParse(cs.cumEff) ?? 0) >= 90 ? const Color(0xFF1E40AF) : const Color(0xFFBE123C))),
                    botBold: true,
                    last: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Baris ISTIRAHAT setelah Slot #4
      if (r.no == 4) {
        rows.add(
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
            ),
            child: Text(
              'ISTIRAHAT   ($breakRange)',
              textAlign: TextAlign.center,
              style: _mono.copyWith(fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ),
        );
      }
    }

    // Footer TOTAL AKUMULASI
    rows.add(
      Container(
        decoration: const BoxDecoration(
          color: Color(0xFFE2E8F0),
          border: Border(top: BorderSide(color: Colors.black, width: 2)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 142,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                alignment: Alignment.centerRight,
                decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black))),
                child: const Text('TOTAL AKUMULASI', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900)),
              ),
              _tdFixed('${stats.totalPlan}', 48, bold: true, bg: const Color(0xFFE0F2FE)),
              _tdFixed('${stats.totalAct}', 48, bold: true, bg: const Color(0xFFD1FAE5)),
              _tdFixed(
                stats.diff == 0 ? '-' : (stats.diff > 0 ? '+${stats.diff}' : '${stats.diff}'),
                48,
                bold: true,
                bg: stats.diff > 0
                    ? const Color(0xFFD1FAE5)
                    : (stats.diff == 0 ? const Color(0xFFF1F5F9) : const Color(0xFFFFE4E6)),
                color: stats.diff > 0
                    ? const Color(0xFF065F46)
                    : (stats.diff == 0 ? const Color(0xFF334155) : const Color(0xFF9F1239)),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black))),
                  child: Row(
                    children: [
                      Text(
                        'TOTAL DELAY: ${stats.totalDelayMin} Menit',
                        style: _mono.copyWith(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFFBE123C)),
                      ),
                      if (stats.minusUnits > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '-${stats.minusUnits}U',
                            style: _mono.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFBE123C)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _tdFixed('${stats.efficiency}%', 52, bold: true, bg: const Color(0xFFDBEAFE), color: const Color(0xFF172554), last: true),
            ],
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule_rounded, size: 15, color: Color(0xFF1D4ED8)),
                SizedBox(width: 5),
                Text(
                  'OUTPUT PRODUKSI PER JAM & REKAM KENDALA LINI (LINE STOP)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
              ],
            ),
            InkWell(
              onTap: onAutoFillAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '⭐ Auto-Fill Semua Target OK',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF78350F)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _buildProblemCell(HourlySlot r, bool isBlocked, bool isFilled) {
    if (isBlocked) return const SizedBox.shrink();
    if (r.problems.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: r.problems.map((p) {
          final isExt = p.category == 'EXT';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isExt ? const Color(0xFFFFFBEB) : const Color(0xFFFFF1F2),
                    border: Border.all(color: isExt ? const Color(0xFFFCD34D) : const Color(0xFFFDA4AF)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    isExt ? 'EXT' : 'INT',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: isExt ? const Color(0xFF92400E) : const Color(0xFF9F1239)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    p.problem.isNotEmpty ? p.problem : '-',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (p.delayMin > 0)
                  Text('${p.delayMin}m ', style: _mono.copyWith(fontSize: 10, color: const Color(0xFF64748B))),
                if (p.lossUnits > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      border: Border.all(color: const Color(0xFFFECDD3)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '-${p.lossUnits}U',
                      style: _mono.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFBE123C)),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      );
    }
    if (r.problem.trim().isNotEmpty) {
      return Text(r.problem, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF881337)));
    }
    if (isFilled && r.act! >= r.plan) {
      return const Center(child: Text('⭐', style: TextStyle(fontSize: 15)));
    }
    return const Center(
      child: Text('- normal -', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFFCBD5E1))),
    );
  }

  Widget _th(String text, double width, {Color? bg, Alignment align = Alignment.center, bool last = false, double fontSize = 11}) =>
      Container(
        width: width,
        alignment: align,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          border: Border(right: last ? BorderSide.none : const BorderSide(color: Colors.black)),
        ),
        child: Text(text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900)),
      );

  Widget _thFlex(String text, {Alignment align = Alignment.center}) => Container(
        alignment: align,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.black))),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
      );

  Widget _tdFixed(String text, double width, {bool bold = false, Color? bg, Color? color, Alignment align = Alignment.center, double fontSize = 11.5, bool last = false}) =>
      Container(
        width: width,
        alignment: align,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          border: Border(right: last ? BorderSide.none : const BorderSide(color: Colors.black)),
        ),
        child: Text(
          text,
          textAlign: align == Alignment.centerLeft ? TextAlign.left : TextAlign.center,
          style: _mono.copyWith(fontSize: fontSize, fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: color ?? const Color(0xFF0F172A)),
        ),
      );

  Widget _twoRowCell({
    required double width,
    required String top,
    required String bot,
    required Color topColor,
    required Color botBg,
    required Color botColor,
    bool topBold = false,
    bool botBold = false,
    bool last = false,
  }) =>
      Container(
        width: width,
        decoration: BoxDecoration(border: Border(right: last ? BorderSide.none : const BorderSide(color: Colors.black))),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              alignment: Alignment.center,
              child: Text(top, style: _mono.copyWith(fontSize: 11.5, fontWeight: topBold ? FontWeight.w900 : FontWeight.w700, color: topColor)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: botBg,
                border: const Border(top: BorderSide(color: Color(0xFFCBD5E1))),
              ),
              child: Text(bot, style: _mono.copyWith(fontSize: 10, fontWeight: botBold ? FontWeight.w900 : FontWeight.w600, color: botColor)),
            ),
          ],
        ),
      );

  Widget _buildCbuCkdRow() {
    final isManual = report.cbuSource == 'manual';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kotak 1: CBU
          Expanded(
            child: InkWell(
              onTap: onTapCbu,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(bottom: 5),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black))),
                          child: Row(
                            children: [
                              const Icon(Icons.directions_car_rounded, size: 16, color: Color(0xFF1D4ED8)),
                              const SizedBox(width: 6),
                              const Text('PRODUKSI MODEL CBU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isManual ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                                  border: Border.all(color: isManual ? const Color(0xFFFCD34D) : const Color(0xFF6EE7B7)),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  isManual ? '✏️ MANUAL' : '⚡ AUTO RASIO',
                                  style: _mono.copyWith(fontSize: 8, fontWeight: FontWeight.w800, color: isManual ? const Color(0xFF92400E) : const Color(0xFF065F46)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...report.cbuModels.map((m) => Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1)))),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(m.name.toUpperCase(), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                                      const SizedBox(width: 4),
                                      Text('(${m.ratio}x)', style: _mono.copyWith(fontSize: 9, color: const Color(0xFF94A3B8))),
                                    ],
                                  ),
                                  Text('${m.qty} Unit', style: _mono.copyWith(fontSize: 12, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            )),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xCCDBEAFE),
                        border: Border(top: BorderSide(color: Color(0xFF1D4ED8), width: 2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL PRODUKSI CBU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF172554))),
                          Text('${stats.totalCbu} Unit', style: _mono.copyWith(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF172554))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Kotak 2: CKD
          Expanded(
            child: InkWell(
              onTap: onTapCkd,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(bottom: 5),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black))),
                      child: const Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF0E7490)),
                          SizedBox(width: 6),
                          Text('PRODUKSI PART CKD (SUB-ASSY EXPORT)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    ...report.ckdParts.map((p) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                          child: Row(
                            children: [
                              Text(p.partNo, style: _mono.copyWith(fontSize: 10.5, fontWeight: FontWeight.w800)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(p.partName, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                              ),
                              Text('${p.qty} Unit', style: _mono.copyWith(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF164E63))),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomFourBoxes() {
    final absMems = report.members.where((m) => m.status != 'Hadir' && m.status.isNotEmpty).toList();
    final intEffNum = double.tryParse(stats.internalEfficiency) ?? 0;
    final isEffOk = intEffNum >= 98.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. MP ABSENSI
          Expanded(
            child: InkWell(
              onTap: onTapAbsen,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _smallBoxHead(Icons.groups_rounded, 'MP ABSENSI', const Color(0xFF047857)),
                    Row(
                      children: [
                        Expanded(child: _miniBadge('Hadir: ${stats.hadirCount}', const Color(0xFFECFDF5), const Color(0xFF047857), const Color(0xFFA7F3D0))),
                        const SizedBox(width: 3),
                        Expanded(child: _miniBadge('Absen: ${stats.absentCount}', stats.absentCount > 0 ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC), stats.absentCount > 0 ? const Color(0xFFBE123C) : const Color(0xFF64748B), const Color(0xFFE2E8F0))),
                        const SizedBox(width: 3),
                        Expanded(child: _miniBadge('${stats.attendanceRate}%', const Color(0xFFD1FAE5), const Color(0xFF065F46), const Color(0xFF6EE7B7))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (absMems.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)),
                        child: Text('- Formasi Lengkap -', textAlign: TextAlign.center, style: _mono.copyWith(fontSize: 9, color: const Color(0xFF64748B))),
                      )
                    else
                      ...absMems.take(4).map((m) => Container(
                            margin: const EdgeInsets.only(bottom: 3),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFFFF1F2), border: Border.all(color: const Color(0xFFFECDD3)), borderRadius: BorderRadius.circular(3)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(m.name, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Color(0xFF4C0519)), overflow: TextOverflow.ellipsis)),
                                Text(m.status, style: _mono.copyWith(fontSize: 8, fontWeight: FontWeight.w900, color: const Color(0xFF881337))),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 2. RECORD NO BODY
          Expanded(
            child: InkWell(
              onTap: onTapNoBody,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _smallBoxHead(Icons.fact_check_outlined, 'RECORD NO BODY', const Color(0xFF7E22CE)),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(3)),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _grid2Cell('BODY START', report.noBodyStart.isNotEmpty ? '#${report.noBodyStart}' : '-', const Color(0xFFF8FAFC), const Color(0xFF0F172A), borderRight: true, borderBottom: true)),
                              Expanded(child: _grid2Cell('BODY FINISH', report.noBodyFinish.isNotEmpty ? '#${report.noBodyFinish}' : '-', const Color(0xFFFAF5FF), const Color(0xFF3B0764), borderBottom: true)),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: _grid2Cell('TOTAL RUN', '${stats.bodyRun} Unit', const Color(0xFFEEF2FF), const Color(0xFF1E1B4B), borderRight: true)),
                              Expanded(child: _grid2Cell('JAM STOP', report.jamStopProduksi.isNotEmpty ? '${report.jamStopProduksi} WIB' : '-', const Color(0xFFFFF1F2), const Color(0xFF4C0519))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFEFF),
                        border: Border.all(color: const Color(0xFF67E8F9)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          const Text('🕒 WAKTU SELESAI (SISTEM)', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: Color(0xFF164E63))),
                          Text('${stats.estimatedFinishTime} WIB', style: _mono.copyWith(fontSize: 10.5, fontWeight: FontWeight.w900, color: const Color(0xFF083344))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 3. TARGET & OT
          Expanded(
            child: InkWell(
              onTap: onTapOvertime,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _smallBoxHead(Icons.track_changes_rounded, 'TARGET & OT', const Color(0xFF0E7490)),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(3)),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _grid2Cell('TARGET CCR', '${stats.effectiveCcrPlan} Unit', const Color(0xFFECFEFF), const Color(0xFF083344), borderRight: true, borderBottom: true)),
                              Expanded(child: _grid2Cell('TOTAL OUTPUT', '${stats.totalAct} Unit', const Color(0xFFFAF5FF), const Color(0xFF3B0764), borderBottom: true, sub: '${stats.ccrDiff >= 0 ? '+' : ''}${stats.ccrDiff} vs CCR', subColor: stats.ccrDiff >= 0 ? const Color(0xFF047857) : const Color(0xFFBE123C))),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: _grid2Cell('PLAN OVERTIME', '${stats.otPlanHours}h (${stats.otPlanUnits} U)', const Color(0xFFF8FAFC), const Color(0xFF0F172A), borderRight: true)),
                              Expanded(child: _grid2Cell('ACT OVERTIME', '${stats.otActHours}h (${stats.otActUnits} U)', const Color(0xFFFFFBEB), const Color(0xFF451A03))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 4. EFISIENSI
          Expanded(
            child: InkWell(
              onTap: onTapNoBody,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _smallBoxHead(Icons.speed_rounded, 'EFISIENSI', const Color(0xFFBE123C)),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(3)),
                      child: Column(
                        children: [
                          _effRow('Internal (INT)', '${stats.intDelayMin}m', stats.intLossUnits > 0 ? '-${stats.intLossUnits}U' : '0U', stats.intEffPct == '-' ? '-' : '${stats.intEffPct}%'),
                          _effRow('External (EXT)', '${stats.extDelayMin}m', stats.extLossUnits > 0 ? '-${stats.extLossUnits}U' : '0U', stats.extEffPct == '-' ? '-' : '${stats.extEffPct}%'),
                          _effRow('TOTAL', '${double.parse((stats.intDelayMin + stats.extDelayMin).toStringAsFixed(1))}m', stats.totalLossUnits > 0 ? '-${stats.totalLossUnits}U' : '0U', stats.totalEffPct == '-' ? '-' : '${stats.totalEffPct}%', isTotal: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: const Color(0xFFF0F9FF), border: Border.all(color: const Color(0xFF38BDF8)), borderRadius: BorderRadius.circular(4)),
                            child: Column(
                              children: [
                                const Text('TARGET EFF INT', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Color(0xFF0C4A6E))),
                                Text('98%', style: _mono.copyWith(fontSize: 13.5, fontWeight: FontWeight.w900, color: const Color(0xFF082F49))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isEffOk ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                              border: Border.all(color: isEffOk ? const Color(0xFF10B981) : const Color(0xFFF43F5E)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              children: [
                                const Text('ACTUAL EFF INT', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                                Text(
                                  '${stats.internalEfficiency}%',
                                  style: _mono.copyWith(fontSize: 13.5, fontWeight: FontWeight.w900, color: isEffOk ? const Color(0xFF065F46) : const Color(0xFFBE123C)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntProblemsBox() {
    final totDel = stats.intProblems.fold<double>(0, (a, g) => a + g.totalDelay);
    final totU = stats.intProblems.fold<int>(0, (a, g) => a + g.totalUnits);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF1F2),
              border: Border(bottom: BorderSide(color: Colors.black)),
            ),
            child: Row(
              children: [
                const Text('⚠️ KETERANGAN PROBLEM / CHOKOTEI LINE STOP (INT)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF881337))),
                const Spacer(),
                Text('${stats.intProblems.length} Problem INT', style: _mono.copyWith(fontSize: 9.5, fontWeight: FontWeight.w800, color: const Color(0xFF9F1239))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                ...stats.intProblems.asMap().entries.map((e) {
                  final g = e.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                    decoration: BoxDecoration(
                      color: e.key.isEven ? Colors.white : const Color(0xFFF8FAFC),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 24, child: Text('${e.key + 1}', style: _mono.copyWith(fontSize: 9.5))),
                        Expanded(flex: 4, child: Text(g.problem, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))),
                        Expanded(flex: 4, child: Text(g.countermeasure.isNotEmpty ? g.countermeasure : '-', style: const TextStyle(fontSize: 10, color: Color(0xFF475569)))),
                        SizedBox(width: 56, child: Text('${g.totalDelay}m', textAlign: TextAlign.center, style: _mono.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF9F1239)))),
                        SizedBox(width: 48, child: Text(g.totalUnits > 0 ? '-${g.totalUnits}U' : '-', textAlign: TextAlign.center, style: _mono.copyWith(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFBE123C)))),
                      ],
                    ),
                  );
                }),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  color: const Color(0xFFFFF1F2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'TOTAL DELAY INT: ${totDel.toStringAsFixed(1)}m (${totU > 0 ? '-${totU}U' : '0U'})',
                        style: _mono.copyWith(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF881337)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallBoxHead(IconData icon, String title, Color color) => Container(
        padding: const EdgeInsets.only(bottom: 4),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black))),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis)),
          ],
        ),
      );

  Widget _miniBadge(String text, Color bg, Color fg, Color border) => Container(
        padding: const EdgeInsets.symmetric(vertical: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(3)),
        child: Text(text, style: _mono.copyWith(fontSize: 8.5, fontWeight: FontWeight.w800, color: fg), overflow: TextOverflow.ellipsis),
      );

  Widget _grid2Cell(String label, String val, Color bg, Color fg, {bool borderRight = false, bool borderBottom = false, String? sub, Color? subColor}) =>
      Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: bg,
          border: Border(
            right: borderRight ? const BorderSide(color: Colors.black) : BorderSide.none,
            bottom: borderBottom ? const BorderSide(color: Colors.black) : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
            const SizedBox(height: 2),
            Text(val, style: _mono.copyWith(fontSize: 10.5, fontWeight: FontWeight.w900, color: fg)),
            if (sub != null) Text(sub, style: _mono.copyWith(fontSize: 7.5, fontWeight: FontWeight.w800, color: subColor ?? fg)),
          ],
        ),
      );

  Widget _effRow(String lbl, String minTxt, String unitTxt, String pctTxt, {bool isTotal = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isTotal ? const Color(0xFFF1F5F9) : Colors.white,
          border: isTotal ? null : const Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
        ),
        child: Row(
          children: [
            Expanded(flex: 4, child: Text(lbl, style: TextStyle(fontSize: 8, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700))),
            SizedBox(width: 34, child: Text(minTxt, textAlign: TextAlign.center, style: _mono.copyWith(fontSize: 8, fontWeight: FontWeight.w800))),
            SizedBox(width: 28, child: Text(unitTxt, textAlign: TextAlign.center, style: _mono.copyWith(fontSize: 8, fontWeight: FontWeight.w800, color: const Color(0xFFE11D48)))),
            SizedBox(width: 34, child: Text(pctTxt, textAlign: TextAlign.center, style: _mono.copyWith(fontSize: 8, fontWeight: FontWeight.w900, color: const Color(0xFF047857)))),
          ],
        ),
      );
}
