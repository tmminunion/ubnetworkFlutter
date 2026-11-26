// 1:1 Dart port of ubnetwork/app/productivity/cbu/page.tsx & ckd/page.tsx aggregation

import 'dart:convert';

import 'checksheet_models.dart';

class CbuDayRecord {
  CbuDayRecord({
    required this.date,
    required this.dayNumber,
    required this.dayName,
    required this.isWeekend,
    required this.shiftLabel,
    required this.totalCbu,
    required this.source,
    required this.models,
    required this.shares,
  });

  final String date;
  final int dayNumber;
  final String dayName;
  final bool isWeekend;
  final String shiftLabel;
  final int totalCbu;
  final String source; // ratio | manual
  final Map<String, int> models; // code -> qty
  final Map<String, double> shares; // code -> pct
}

class CbuMonthlySummary {
  const CbuMonthlySummary({
    required this.grandTotal,
    required this.activeDays,
    required this.avgPerDay,
    required this.modelTotals,
    required this.topModelName,
    required this.topModelQty,
    required this.topModelShare,
    required this.ratioDays,
    required this.manualDays,
  });

  final int grandTotal;
  final int activeDays;
  final int avgPerDay;
  final Map<String, int> modelTotals;
  final String topModelName;
  final int topModelQty;
  final double topModelShare;
  final int ratioDays;
  final int manualDays;
}

class CkdDayRecord {
  CkdDayRecord({
    required this.date,
    required this.dayNumber,
    required this.dayName,
    required this.isWeekend,
    required this.totalCkd,
    required this.parts,
  });

  final String date;
  final int dayNumber;
  final String dayName;
  final bool isWeekend;
  final int totalCkd;
  final Map<String, int> parts; // partNo -> qty
}

class CkdMonthlySummary {
  const CkdMonthlySummary({
    required this.grandTotal,
    required this.workDays,
    required this.avgDaily,
    required this.partTotals,
    required this.topPartNo,
    required this.topPartName,
    required this.topPartQty,
    required this.topPartPercent,
  });

  final int grandTotal;
  final int workDays;
  final int avgDaily;
  final Map<String, int> partTotals;
  final String topPartNo;
  final String topPartName;
  final int topPartQty;
  final int topPartPercent;
}

class CbuCkdMath {
  CbuCkdMath._();

  static const List<String> dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

  static List<CbuDayRecord> aggregateCbu({
    required String ym,
    required String shiftFilter, // ALL | WHITE | RED
    required List<CbuModelItem> modelsConfig,
    required List<Map<String, dynamic>> rawReports,
  }) {
    final parts = ym.split('-');
    final y = int.tryParse(parts[0]) ?? 2026;
    final m = (int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1).clamp(1, 12);
    final dim = DateTime(y, m + 1, 0).day;

    return List.generate(dim, (i) {
      final day = i + 1;
      final dateStr = '$ym-${day.toString().padLeft(2, '0')}';
      final dt = DateTime(y, m, day);
      final wd = dt.weekday;
      final isWeekend = wd == DateTime.saturday || wd == DateTime.sunday;

      final dayReps = rawReports.where((r) {
        if ('${r['tanggal'] ?? ''}' != dateStr) return false;
        if (shiftFilter != 'ALL' && '${r['shift'] ?? ''}'.toUpperCase() != shiftFilter) return false;
        return true;
      }).toList();

      final modelMap = <String, int>{for (final mc in modelsConfig) mc.code: 0};
      var totalDay = 0;
      var hasRatio = false;
      final shifts = <String>{};

      for (final rep in dayReps) {
        final sh = '${rep['shift'] ?? ''}'.toUpperCase();
        if (sh.isNotEmpty) shifts.add(sh);
        if ('${rep['model_cbu_source'] ?? ''}' == 'ratio') hasRatio = true;

        List<dynamic> parsed = const [];
        final rawData = rep['models_cbu_data'] ?? rep['models_cbu'];
        if (rawData is List) {
          parsed = rawData;
        } else if (rawData is String && rawData.isNotEmpty) {
          try {
            final dec = jsonDecode(rawData);
            if (dec is List) parsed = dec;
          } catch (_) {}
        }

        if (parsed.isNotEmpty) {
          for (final item in parsed) {
            if (item is Map) {
              final code = '${item['code'] ?? ''}'.toLowerCase();
              final qty = item['qty'] is num ? (item['qty'] as num).toInt() : (int.tryParse('${item['qty'] ?? 0}') ?? 0);
              if (code.isNotEmpty) {
                modelMap[code] = (modelMap[code] ?? 0) + qty;
                totalDay += qty;
              }
            }
          }
        }
      }

      final shares = <String, double>{};
      for (final mc in modelsConfig) {
        final q = modelMap[mc.code] ?? 0;
        shares[mc.code] = totalDay > 0 ? double.parse(((q / totalDay) * 100).toStringAsFixed(1)) : 0.0;
      }

      return CbuDayRecord(
        date: dateStr,
        dayNumber: day,
        dayName: dayNames[wd % 7],
        isWeekend: isWeekend,
        shiftLabel: shifts.isEmpty ? '-' : shifts.join(' & '),
        totalCbu: totalDay,
        source: hasRatio ? 'ratio' : 'manual',
        models: modelMap,
        shares: shares,
      );
    });
  }

  static CbuMonthlySummary summarizeCbu(
    List<CbuDayRecord> days,
    List<CbuModelItem> modelsConfig,
  ) {
    final grand = days.fold<int>(0, (acc, d) => acc + d.totalCbu);
    final active = days.where((d) => d.totalCbu > 0).length;
    final avg = active > 0 ? (grand / active).round() : 0;

    final totals = <String, int>{};
    for (final mc in modelsConfig) {
      totals[mc.code] = days.fold<int>(0, (acc, d) => acc + (d.models[mc.code] ?? 0));
    }

    var topCode = modelsConfig.isNotEmpty ? modelsConfig.first.code : 'zenix';
    var topQty = -1;
    totals.forEach((code, qty) {
      if (qty > topQty) {
        topQty = qty;
        topCode = code;
      }
    });
    final safeTopQty = topQty < 0 ? 0 : topQty;
    final topName = modelsConfig.where((m) => m.code == topCode).map((m) => m.name).firstOrNull ?? topCode;
    final topShare = grand > 0 ? double.parse(((safeTopQty / grand) * 100).toStringAsFixed(1)) : 0.0;

    return CbuMonthlySummary(
      grandTotal: grand,
      activeDays: active,
      avgPerDay: avg,
      modelTotals: totals,
      topModelName: topName,
      topModelQty: safeTopQty,
      topModelShare: topShare,
      ratioDays: days.where((d) => d.totalCbu > 0 && d.source == 'ratio').length,
      manualDays: days.where((d) => d.totalCbu > 0 && d.source == 'manual').length,
    );
  }

  static List<CkdDayRecord> aggregateCkd({
    required String ym,
    required String shiftFilter, // ALL | WHITE | RED
    required List<CkdPartItem> partsConfig,
    required List<Map<String, dynamic>> rawReports,
  }) {
    final parts = ym.split('-');
    final y = int.tryParse(parts[0]) ?? 2026;
    final m = (int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1).clamp(1, 12);
    final dim = DateTime(y, m + 1, 0).day;

    return List.generate(dim, (i) {
      final day = i + 1;
      final dateStr = '$ym-${day.toString().padLeft(2, '0')}';
      final dt = DateTime(y, m, day);
      final wd = dt.weekday;
      final isWeekend = wd == DateTime.saturday || wd == DateTime.sunday;

      final dayReps = rawReports.where((r) {
        if ('${r['tanggal'] ?? ''}' != dateStr) return false;
        if (shiftFilter != 'ALL' && '${r['shift'] ?? ''}'.toUpperCase() != shiftFilter) return false;
        return true;
      }).toList();

      final partsMap = <String, int>{for (final pc in partsConfig) pc.partNo: 0};
      var totalDay = 0;

      for (final rep in dayReps) {
        List<dynamic> parsed = const [];
        final rawData = rep['ckd_parts'] ?? rep['ckd_parts_data'];
        if (rawData is List) {
          parsed = rawData;
        } else if (rawData is String && rawData.isNotEmpty) {
          try {
            final dec = jsonDecode(rawData);
            if (dec is List) parsed = dec;
          } catch (_) {}
        }

        for (final item in parsed) {
          if (item is Map) {
            final pNo = '${item['part_no'] ?? item['part_code'] ?? ''}'.trim();
            final qty = item['qty'] is num ? (item['qty'] as num).toInt() : (int.tryParse('${item['qty'] ?? 0}') ?? 0);
            if (pNo.isNotEmpty) {
              partsMap[pNo] = (partsMap[pNo] ?? 0) + qty;
              totalDay += qty;
            }
          }
        }
      }

      return CkdDayRecord(
        date: dateStr,
        dayNumber: day,
        dayName: dayNames[wd % 7],
        isWeekend: isWeekend,
        totalCkd: totalDay,
        parts: partsMap,
      );
    });
  }

  static CkdMonthlySummary summarizeCkd(
    List<CkdDayRecord> days,
    List<CkdPartItem> partsConfig,
  ) {
    final grand = days.fold<int>(0, (acc, d) => acc + d.totalCkd);
    final workDays = days.where((d) => d.totalCkd > 0).length;
    final avg = workDays > 0 ? (grand / workDays).round() : 0;

    final totals = <String, int>{};
    for (final pc in partsConfig) {
      totals[pc.partNo] = days.fold<int>(0, (acc, d) => acc + (d.parts[pc.partNo] ?? 0));
    }

    var topNo = partsConfig.isNotEmpty ? partsConfig.first.partNo : '-';
    var topQty = -1;
    totals.forEach((pNo, qty) {
      if (qty > topQty) {
        topQty = qty;
        topNo = pNo;
      }
    });
    final safeQty = topQty < 0 ? 0 : topQty;
    final topName = partsConfig.where((p) => p.partNo == topNo).map((p) => p.partName).firstOrNull ?? topNo;
    final topPct = grand > 0 ? ((safeQty / grand) * 100).round() : 0;

    return CkdMonthlySummary(
      grandTotal: grand,
      workDays: workDays,
      avgDaily: avg,
      partTotals: totals,
      topPartNo: topNo,
      topPartName: topName,
      topPartQty: safeQty,
      topPartPercent: topPct,
    );
  }
}
